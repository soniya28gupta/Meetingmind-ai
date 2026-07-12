import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:just_audio/just_audio.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/pdf_helper.dart';
import '../../database/schemas/meeting_models.dart';
import '../../database/isar_database.dart';
import 'package:isar/isar.dart';
import '../../providers/app_providers.dart';
import '../../widgets/glass_card.dart';
import '../recording/recording_provider.dart';
import '../../services/speaker_service.dart';
import 'meeting_chat_provider.dart';
import 'meetings_provider.dart';
import '../../services/ollama_connection_manager.dart';
import '../../services/emotion_health_service.dart';

class MeetingDetailsScreen extends ConsumerStatefulWidget {
  final int meetingId;

  const MeetingDetailsScreen({super.key, required this.meetingId});

  @override
  ConsumerState<MeetingDetailsScreen> createState() =>
      _MeetingDetailsScreenState();
}

class _MeetingDetailsScreenState extends ConsumerState<MeetingDetailsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final AudioPlayer _audioPlayer = AudioPlayer();
  final _chatController = TextEditingController();
  final _chatScrollController = ScrollController();
  final _searchController = TextEditingController();

  String _searchQuery = '';
  double _playbackSpeed = 1.0;
  bool _audioAvailable = false;
  bool _isGeneratingSummary = false;
  bool _showSpeakerLabels = true;
  String _statusFilter = 'All';
  String _priorityFilter = 'All';

  Duration _audioPosition = Duration.zero;
  Duration _audioDuration = Duration.zero;
  bool _isPlaying = false;

  StreamSubscription? _posSub;
  StreamSubscription? _durSub;
  StreamSubscription? _stateSub;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _initAudio();
  }

  Future<void> _runSummaryGeneration(MeetingModel meeting) async {
    if (_isGeneratingSummary) return;

    // Get transcript text and check if empty
    final transcript = meeting.transcript.value;
    final fullTranscriptText = transcript != null
        ? transcript.segments
              .toList()
              .map((e) => 'Speaker ${e.speaker}: ${e.text}')
              .join('\n')
        : '';

    if (fullTranscriptText.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '⚠️ Transcript is empty. Speak or import audio to generate a transcript first.',
          ),
          backgroundColor: AppColors.warning,
          duration: Duration(seconds: 4),
        ),
      );
      return;
    }

    setState(() => _isGeneratingSummary = true);
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🤖 Generating Analysis...'),
          duration: Duration(seconds: 4),
        ),
      );

      await ref.read(recordingProvider.notifier).regenerateSummary(meeting.id);

      // Force refresh the stream provider to show the new summary immediately
      ref.invalidate(meetingDetailsStreamProvider(meeting.id));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Analysis Complete'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      print("[AI Summary Generation] Exception caught in UI: $e");
      if (mounted) {
        final cleanError = e.toString().replaceAll('Exception: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Generation failed: $cleanError'),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isGeneratingSummary = false);
      }
    }
  }

  Future<void> _initAudio() async {
    final meeting = await ref
        .read(meetingRepositoryProvider)
        .getMeetingById(widget.meetingId);
    if (meeting != null &&
        meeting.audioFilePath != null &&
        meeting.audioFilePath!.isNotEmpty) {
      try {
        await _audioPlayer.setFilePath(meeting.audioFilePath!);
        setState(() => _audioAvailable = true);

        _posSub = _audioPlayer.positionStream.listen((pos) {
          setState(() => _audioPosition = pos);
        });

        _durSub = _audioPlayer.durationStream.listen((dur) {
          setState(() => _audioDuration = dur ?? Duration.zero);
        });

        _stateSub = _audioPlayer.playerStateStream.listen((state) {
          setState(() => _isPlaying = state.playing);
        });
      } catch (_) {
        setState(() => _audioAvailable = false);
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _posSub?.cancel();
    _durSub?.cancel();
    _stateSub?.cancel();
    _audioPlayer.dispose();
    _chatController.dispose();
    _chatScrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _togglePlayback() {
    if (_isPlaying) {
      _audioPlayer.pause();
    } else {
      _audioPlayer.play();
    }
  }

  void _changeSpeed(double speed) {
    _audioPlayer.setSpeed(speed);
    setState(() => _playbackSpeed = speed);
  }

  void _seekTo(double seconds) {
    _audioPlayer.seek(Duration(milliseconds: (seconds * 1000).toInt()));
  }

  void _scrollChatToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_chatScrollController.hasClients) {
        _chatScrollController.animateTo(
          _chatScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final meetingDetailAsync = ref.watch(
      meetingDetailsStreamProvider(widget.meetingId),
    );

    ref.listen<AsyncValue<List<ChatMessageModel>>>(
      meetingChatProvider(widget.meetingId),
      (previous, next) {
        final prevList = previous?.value ?? [];
        final nextList = next.value ?? [];
        if (nextList.length > prevList.length) {
          final lastMsg = nextList.last;
          if (!lastMsg.isUser) {
            if (lastMsg.message == '🤖 AI is thinking...') {
              // No action needed for thinking placeholder
            } else if (lastMsg.message?.startsWith(
                  '⚠️ Failed to get response',
                ) ??
                false) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('⚠️ Failed to get response'),
                  backgroundColor: AppColors.error,
                  duration: Duration(seconds: 2),
                ),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('✅ Response received'),
                  backgroundColor: AppColors.success,
                  duration: Duration(seconds: 2),
                ),
              );
            }
          }
        }
      },
    );

    return Scaffold(
      appBar: AppBar(
        title: meetingDetailAsync.when(
          data: (m) {
            final ollamaState = ref.watch(ollamaConnectionManagerProvider);
            Color statusColor;
            String statusText;
            switch (ollamaState.status) {
              case OllamaConnectionStatus.connected:
                statusColor = AppColors.success;
                statusText = 'Ollama Connected';
                break;
              case OllamaConnectionStatus.reconnecting:
                statusColor = AppColors.warning;
                statusText = 'Ollama Reconnecting...';
                break;
              case OllamaConnectionStatus.waitingForOllama:
                statusColor = AppColors.warning;
                statusText = 'Waiting for Ollama...';
                break;
              case OllamaConnectionStatus.offline:
                statusColor = AppColors.error;
                statusText = 'Ollama Offline';
                break;
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  m?.title ?? 'Meeting Details',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: statusColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      statusText,
                      style: TextStyle(
                        fontSize: 9,
                        color: statusColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
          loading: () => const Text('Loading...'),
          error: (_, __) => const Text('Error'),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          meetingDetailAsync.when(
            data: (meeting) => meeting != null
                ? PopupMenuButton<String>(
                    icon: const Icon(Icons.share_outlined),
                    onSelected: (val) {
                      if (val == 'pdf') {
                        ExportHelper.shareMeetingPdf(meeting);
                      } else if (val == 'docx') {
                        ExportHelper.shareMeetingDocx(meeting);
                      } else if (val == 'markdown') {
                        ExportHelper.shareMeetingMarkdown(meeting);
                      } else {
                        ExportHelper.shareMeetingText(meeting);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'pdf',
                        child: Text('Export PDF Report'),
                      ),
                      const PopupMenuItem(
                        value: 'docx',
                        child: Text('Export Word DOCX'),
                      ),
                      const PopupMenuItem(
                        value: 'markdown',
                        child: Text('Export Markdown'),
                      ),
                      const PopupMenuItem(
                        value: 'text',
                        child: Text('Export Plain Text'),
                      ),
                    ],
                  )
                : const SizedBox(),
            loading: () => const SizedBox(),
            error: (_, __) => const SizedBox(),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicator: UnderlineTabIndicator(
            borderSide: const BorderSide(color: AppColors.accent, width: 3),
            insets: const EdgeInsets.symmetric(horizontal: 16),
          ),
          labelColor: AppColors.accent,
          unselectedLabelColor: AppColors.textMuted,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
          tabs: const [
            Tab(text: '🎙️ Transcript'),
            Tab(text: '📋 Summary'),
            Tab(text: '✅ Tasks'),
            Tab(text: '🤖 AI Chat'),
            Tab(text: '🔊 Audio'),
          ],
        ),
      ),
      body: FuturisticBackground(
        child: meetingDetailAsync.when(
          data: (meeting) {
            if (meeting == null) {
              return const Center(child: Text('Meeting not found'));
            }

            return Column(
              children: [
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildTranscriptTab(meeting),
                      _buildSummaryTab(meeting),
                      _buildTasksTab(meeting),
                      _buildChatTab(meeting),
                      _buildAudioTab(meeting),
                    ],
                  ),
                ),
                // Persistent Mini Player at bottom
                if (_audioAvailable &&
                    MediaQuery.of(context).viewInsets.bottom == 0)
                  _buildMiniPlayer(),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(
            child: Text(
              'Error loading meeting: $err',
              style: const TextStyle(color: AppColors.error),
            ),
          ),
        ),
      ),
    );
  }

  // --- TAB A: TRANSCRIPT ---
  Widget _buildTranscriptTab(MeetingModel meeting) {
    final allSegments = meeting.transcript.value?.segments.toList() ?? [];
    final audioPositionSecs = _audioPosition.inMilliseconds / 1000.0;

    // --- Group consecutive same-speaker segments into speaker blocks ---
    final List<_SpeakerBlock> blocks = [];
    if (allSegments.isNotEmpty) {
      _SpeakerBlock current = _SpeakerBlock(
        speaker: allSegments.first.speaker ?? 1,
        profile: allSegments.first.speakerProfile.value,
        sentences: [allSegments.first],
      );
      for (int i = 1; i < allSegments.length; i++) {
        final seg = allSegments[i];
        if (seg.speaker == current.speaker) {
          current.sentences.add(seg);
        } else {
          blocks.add(current);
          current = _SpeakerBlock(
            speaker: seg.speaker ?? 1,
            profile: seg.speakerProfile.value,
            sentences: [seg],
          );
        }
      }
      blocks.add(current);
    }

    // Check if diarization exists (more than 1 distinct speaker)
    final distinctSpeakers = allSegments.map((s) => s.speaker).toSet();
    final hasDiarization = distinctSpeakers.length > 1;

    // Build the full plain text for copy/share
    String buildFullText() {
      if (!hasDiarization || !_showSpeakerLabels) {
        return allSegments.map((s) => s.text ?? '').join(' ');
      }
      return blocks
          .map((b) {
            final name = b.profile?.name ?? 'Speaker ${b.speaker}';
            final text = b.sentences.map((s) => s.text ?? '').join(' ');
            return '$name:\n$text';
          })
          .join('\n\n');
    }

    return Column(
      children: [
        // ── Search bar + action toolbar ──
        Container(
          color: AppColors.surface,
          padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
          child: Column(
            children: [
              // Search bar
              TextFormField(
                controller: _searchController,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                ),
                decoration: InputDecoration(
                  hintText: 'Search transcript...',
                  hintStyle: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 14,
                  ),
                  prefixIcon: const Icon(
                    Icons.search,
                    color: AppColors.textMuted,
                    size: 20,
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(
                            Icons.clear,
                            color: AppColors.textMuted,
                            size: 18,
                          ),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: AppColors.surfaceLight,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (v) => setState(() => _searchQuery = v),
              ),
              const SizedBox(height: 8),
              // Action row
              Row(
                children: [
                  _TranscriptActionButton(
                    icon: Icons.copy_rounded,
                    label: 'Copy',
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: buildFullText()));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('📋 Transcript copied to clipboard'),
                          backgroundColor: AppColors.success,
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                  if (hasDiarization)
                    _TranscriptActionButton(
                      icon: _showSpeakerLabels
                          ? Icons.person_rounded
                          : Icons.person_off_rounded,
                      label: _showSpeakerLabels
                          ? 'Hide Speakers'
                          : 'Show Speakers',
                      onTap: () => setState(
                        () => _showSpeakerLabels = !_showSpeakerLabels,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: AppColors.surfaceLight),

        // ── Main continuous transcript ──
        Expanded(
          child: allSegments.isEmpty
              ? _buildEmptyTranscript()
              : SelectionArea(
                  child: ListView.builder(
                    padding: EdgeInsets.fromLTRB(
                      20,
                      16,
                      20,
                      _audioAvailable ? 120.0 : 32.0,
                    ),
                    itemCount: (!hasDiarization || !_showSpeakerLabels)
                        ? 1
                        : blocks.length,
                    itemBuilder: (context, idx) {
                      // ── Single-speaker or labels-off: one continuous article ──
                      if (!hasDiarization || !_showSpeakerLabels) {
                        return _buildContinuousDocument(
                          allSegments,
                          audioPositionSecs,
                        );
                      }

                      // ── Multi-speaker: one block per speaker turn ──
                      final block = blocks[idx];
                      final profile = block.profile;
                      final String name =
                          profile?.name ?? 'Speaker ${block.speaker}';
                      final String emoji = profile?.avatarEmoji ?? '🎙️';
                      final Color color = Color(
                        profile?.colorValue ?? 0xFF9C27B0,
                      );
                      final blockStart = block.sentences.first.startTime;
                      final startMin = (blockStart / 60).toInt();
                      final startSec = (blockStart % 60)
                          .toInt()
                          .toString()
                          .padLeft(2, '0');

                      // Is any sentence in this block currently active?
                      final isActiveBlock = block.sentences.any(
                        (s) =>
                            audioPositionSecs >= s.startTime &&
                            audioPositionSecs < s.endTime,
                      );

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Speaker header row
                            GestureDetector(
                              onTap: () {
                                if (profile != null)
                                  _showSpeakerProfileDialog(profile);
                              },
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 16,
                                    backgroundColor: color.withValues(
                                      alpha: 0.15,
                                    ),
                                    child: Text(
                                      emoji,
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    name,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: color,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '[$startMin:$startSec]',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: AppColors.textMuted,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            // Sentence-level rich text for this block
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: isActiveBlock
                                  ? const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    )
                                  : EdgeInsets.zero,
                              decoration: isActiveBlock
                                  ? BoxDecoration(
                                      color: AppColors.primary.withValues(
                                        alpha: 0.07,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: AppColors.primary.withValues(
                                          alpha: 0.2,
                                        ),
                                        width: 1,
                                      ),
                                    )
                                  : null,
                              child: _buildInlineRichText(
                                block.sentences,
                                audioPositionSecs,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  /// Builds a single continuous document for single-speaker or labels-off mode.
  Widget _buildContinuousDocument(
    List<TranscriptSegmentModel> segments,
    double audioPositionSecs,
  ) {
    return _buildInlineRichText(segments, audioPositionSecs);
  }

  /// Builds a RichText widget that renders all given segments as an inline
  /// paragraph with active-sentence highlighting and search-query highlighting.
  Widget _buildInlineRichText(
    List<TranscriptSegmentModel> segments,
    double audioPositionSecs,
  ) {
    final List<TextSpan> spans = [];
    for (int i = 0; i < segments.length; i++) {
      final seg = segments[i];
      final text = (seg.text ?? '').trim();
      if (text.isEmpty) continue;

      // Active sentence = audio playback within this segment's time range
      final bool isActive =
          audioPositionSecs >= seg.startTime && audioPositionSecs < seg.endTime;

      // Search highlight
      final bool hasMatch =
          _searchQuery.isNotEmpty &&
          text.toLowerCase().contains(_searchQuery.toLowerCase());

      if (hasMatch && _searchQuery.isNotEmpty) {
        // Split into matched and unmatched parts
        final lowerText = text.toLowerCase();
        int cursor = 0;
        while (cursor < text.length) {
          final matchIdx = lowerText.indexOf(
            _searchQuery.toLowerCase(),
            cursor,
          );
          if (matchIdx == -1) {
            spans.add(
              TextSpan(
                text: text.substring(cursor),
                style: _sentenceStyle(isActive),
                recognizer: _seekRecognizer(seg.startTime),
              ),
            );
            break;
          }
          if (matchIdx > cursor) {
            spans.add(
              TextSpan(
                text: text.substring(cursor, matchIdx),
                style: _sentenceStyle(isActive),
                recognizer: _seekRecognizer(seg.startTime),
              ),
            );
          }
          spans.add(
            TextSpan(
              text: text.substring(matchIdx, matchIdx + _searchQuery.length),
              style: _sentenceStyle(isActive).copyWith(
                backgroundColor: Colors.yellow.shade700.withValues(alpha: 0.55),
                color: Colors.black,
              ),
              recognizer: _seekRecognizer(seg.startTime),
            ),
          );
          cursor = matchIdx + _searchQuery.length;
        }
      } else {
        spans.add(
          TextSpan(
            text: text,
            style: _sentenceStyle(isActive),
            recognizer: _seekRecognizer(seg.startTime),
          ),
        );
      }

      // Add a space between sentences
      if (i < segments.length - 1) {
        spans.add(const TextSpan(text: ' '));
      }
    }

    return RichText(
      text: TextSpan(children: spans),
      textAlign: TextAlign.left,
    );
  }

  TextStyle _sentenceStyle(bool isActive) {
    if (isActive) {
      return const TextStyle(
        fontSize: 16,
        height: 1.7,
        color: AppColors.accent,
        fontWeight: FontWeight.w600,
        backgroundColor: Color(0x18C084FC),
      );
    }
    return const TextStyle(
      fontSize: 16,
      height: 1.7,
      color: AppColors.textPrimary,
      fontWeight: FontWeight.normal,
    );
  }

  // ignore: deprecated_member_use
  TapGestureRecognizer _seekRecognizer(double startTime) {
    final recognizer = TapGestureRecognizer();
    recognizer.onTap = () => _seekTo(startTime);
    return recognizer;
  }

  Widget _buildEmptyTranscript() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.mic_none_rounded,
            size: 56,
            color: AppColors.textMuted.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 16),
          const Text(
            'No transcript yet',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Record a meeting or import an audio file\nto generate a transcript.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  void _showSpeakerProfileDialog(SpeakerProfileModel profile) {
    final nameController = TextEditingController(text: profile.name);
    final emojiController = TextEditingController(text: profile.avatarEmoji);
    int selectedColor = profile.colorValue ?? 0xFF9C27B0;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Text(
                'Edit Speaker Profile',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: nameController,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: const InputDecoration(
                        labelText: 'Speaker Name',
                        labelStyle: TextStyle(color: AppColors.textMuted),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.white12),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: AppColors.primary),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: emojiController,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: const InputDecoration(
                        labelText: 'Avatar Emoji',
                        labelStyle: TextStyle(color: AppColors.textMuted),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.white12),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: AppColors.primary),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Select Theme Color:',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children:
                          [
                            0xFF9C27B0, // Deep Purple
                            0xFF2196F3, // Deep Blue
                            0xFF4CAF50, // Neon Green
                            0xFFFFC107, // Amber Yellow
                            0xFFFF5722, // Coral Pink
                            0xFF009688, // Teal
                            0xFFFF9800, // Orange
                            0xFF3F51B5, // Indigo
                          ].map((colorHex) {
                            final isSelected = selectedColor == colorHex;
                            return GestureDetector(
                              onTap: () {
                                setDialogState(() {
                                  selectedColor = colorHex;
                                });
                              },
                              child: CircleAvatar(
                                radius: 16,
                                backgroundColor: Color(colorHex),
                                child: isSelected
                                    ? const Icon(
                                        Icons.check,
                                        color: Colors.black,
                                        size: 16,
                                      )
                                    : null,
                              ),
                            );
                          }).toList(),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (nameController.text.trim().isEmpty) return;
                    profile.name = nameController.text.trim();
                    profile.avatarEmoji = emojiController.text.trim().isNotEmpty
                        ? emojiController.text.trim()
                        : '👤';
                    profile.colorValue = selectedColor;

                    await ref
                        .read(speakerServiceProvider)
                        .updateSpeakerProfile(profile);
                    if (context.mounted) {
                      Navigator.pop(context);
                      ref.invalidate(
                        meetingDetailsStreamProvider(widget.meetingId),
                      );
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // --- TAB B: SUMMARY ---
  Widget _buildSummaryTab(MeetingModel meeting) {
    if (_isGeneratingSummary) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: AppColors.secondary),
            const SizedBox(height: 24),
            Text(
              '🤖 Generating AI Summary...',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Please wait while the AI analyzes the transcript.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
          ],
        ),
      );
    }

    final summary = meeting.summary.value;
    final decisions = meeting.decisions.toList();

    final segments =
        meeting.transcript.value?.segments.toList() ??
        <TranscriptSegmentModel>[];

    // Fetch persistent Speaker details from Isar
    final isar = IsarDatabase.instance.isar;
    final speakerEmotions = isar.speakerEmotionModels
        .filter()
        .meeting((m) => m.idEqualTo(meeting.id))
        .findAllSync();
    for (final e in speakerEmotions) {
      e.speakerProfile.loadSync();
    }
    final speakerAnalytics = isar.speakerAnalyticsModels
        .filter()
        .meeting((m) => m.idEqualTo(meeting.id))
        .findAllSync();
    for (final a in speakerAnalytics) {
      a.speakerProfile.loadSync();
    }

    // Build visual emotion timeline chunks
    final List<Map<String, dynamic>> timelineIntervals = [];
    final double duration = meeting.durationSeconds;
    if (duration > 0) {
      final double intervalSize = duration > 300 ? 120.0 : 60.0;
      int numIntervals = (duration / intervalSize).ceil();
      for (int i = 0; i < numIntervals; i++) {
        final start = i * intervalSize;
        final end = math.min((i + 1) * intervalSize, duration);
        final segsInRange = segments
            .where((s) => s.startTime < end && s.endTime > start)
            .toList();

        String emotion = 'Neutral';
        if (segsInRange.isNotEmpty) {
          final firstSeg = segsInRange.first;
          final spkEmotionObj = speakerEmotions
              .where(
                (e) =>
                    e.speakerProfile.value?.name ==
                    firstSeg.speakerProfile.value?.name,
              )
              .toList();
          if (spkEmotionObj.isNotEmpty) {
            emotion = spkEmotionObj.first.emotion ?? 'Neutral';
          }
        }

        timelineIntervals.add({
          'label':
              '${(start / 60).toInt().toString().padLeft(2, '0')}:${(start % 60).toInt().toString().padLeft(2, '0')} - ${(end / 60).toInt().toString().padLeft(2, '0')}:${(end % 60).toInt().toString().padLeft(2, '0')}',
          'emotion': emotion,
        });
      }
    }

    // Calculate speaking duration per speaker (Speaker Insights)
    final Map<int, double> speakerDurations = {};
    double totalDuration = 0.0;

    for (final seg in segments) {
      final speaker = seg.speaker ?? 0;
      final segDuration = (seg.endTime - seg.startTime).clamp(
        0.0,
        double.infinity,
      );
      speakerDurations[speaker] =
          (speakerDurations[speaker] ?? 0.0) + segDuration;
      totalDuration += segDuration;
    }

    final List<MapEntry<int, double>> participationList = [];
    if (totalDuration > 0) {
      speakerDurations.forEach((speaker, spkDur) {
        participationList.add(MapEntry(speaker, spkDur / totalDuration));
      });
      participationList.sort((a, b) => a.key.compareTo(b.key));
    }

    // Dynamic Category Detection based on meeting title
    String category = 'General';
    IconData categoryIcon = Icons.dashboard_customize_rounded;
    Color categoryColor = AppColors.primary;
    final titleLower = (meeting.title ?? '').toLowerCase();
    if (titleLower.contains('standup') ||
        titleLower.contains('daily') ||
        titleLower.contains('sync')) {
      category = 'Standup';
      categoryIcon = Icons.loop_rounded;
      categoryColor = AppColors.secondary;
    } else if (titleLower.contains('review') ||
        titleLower.contains('demo') ||
        titleLower.contains('retrospective')) {
      category = 'Review';
      categoryIcon = Icons.rate_review_rounded;
      categoryColor = AppColors.accent;
    } else if (titleLower.contains('planning') ||
        titleLower.contains('roadmap') ||
        titleLower.contains('sprint')) {
      category = 'Planning';
      categoryIcon = Icons.calendar_today_rounded;
      categoryColor = AppColors.success;
    } else if (titleLower.contains('brainstorm') ||
        titleLower.contains('idea') ||
        titleLower.contains('design')) {
      category = 'Brainstorm';
      categoryIcon = Icons.psychology_rounded;
      categoryColor = AppColors.warning;
    }

    final dateFormatted = meeting.createdAt != null
        ? DateFormat('MMMM dd, yyyy').format(meeting.createdAt!)
        : 'Unknown Date';

    final minVal = meeting.durationSeconds / 60.0;
    final durationStr = minVal >= 1.0
        ? '${minVal.toStringAsFixed(0)}m ${(meeting.durationSeconds % 60).toStringAsFixed(0)}s'
        : '${meeting.durationSeconds.toStringAsFixed(0)}s';

    return SingleChildScrollView(
      padding: EdgeInsets.only(
        left: 20.0,
        right: 20.0,
        top: 20.0,
        bottom: _audioAvailable ? 110.0 : 20.0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Row of metadata chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildChip(
                  icon: Icons.calendar_month_rounded,
                  label: dateFormatted,
                  color: Colors.white.withValues(alpha: 0.05),
                  textColor: AppColors.textPrimary,
                ),
                const SizedBox(width: 8),
                _buildChip(
                  icon: Icons.timer_outlined,
                  label: durationStr,
                  color: Colors.white.withValues(alpha: 0.05),
                  textColor: AppColors.textPrimary,
                ),
                const SizedBox(width: 8),
                _buildChip(
                  icon: categoryIcon,
                  label: category,
                  color: categoryColor.withValues(alpha: 0.12),
                  textColor: categoryColor,
                  borderColor: categoryColor.withValues(alpha: 0.25),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          if (summary == null && decisions.isEmpty) ...[
            const SizedBox(height: 20),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.auto_awesome_rounded,
                    color: AppColors.textMuted,
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'AI Summary not generated',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => _runSummaryGeneration(meeting),
                    icon: const Icon(Icons.auto_awesome_rounded),
                    label: const Text('Generate AI Summary'),
                  ),
                ],
              ),
            ),
          ] else ...[
            // Executive Summary Card
            if (summary?.executiveSummary != null) ...[
              Row(
                children: [
                  const Icon(
                    Icons.summarize_outlined,
                    color: AppColors.secondary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Executive Summary',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.surface,
                      AppColors.surfaceLight.withValues(alpha: 0.4),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border(
                    left: const BorderSide(
                      color: AppColors.secondary,
                      width: 4,
                    ),
                    top: BorderSide(color: Colors.white10),
                    right: BorderSide(color: Colors.white10),
                    bottom: BorderSide(color: Colors.white10),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(16),
                child: Text(
                  summary!.executiveSummary!,
                  style: const TextStyle(
                    height: 1.5,
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Wearable Wellness Analytics Section
            if (meeting.heartRateAverage != null) ...[
              BiometricInsightsCard(meeting: meeting),
              const SizedBox(height: 24),
            ],

            // Visual Emotion Timeline (Feature 7)
            if (timelineIntervals.isNotEmpty) ...[
              Row(
                children: [
                  const Icon(
                    Icons.timeline_rounded,
                    color: AppColors.secondary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Visual Emotion Timeline',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              GlassCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 14,
                ),
                borderColor: AppColors.secondary.withValues(alpha: 0.15),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: timelineIntervals.map((interval) {
                      final emo = interval['emotion'] as String;
                      final String emoji = getEmotionEmoji(emo);
                      final Color labelColor = getEmotionColor(emo);
                      return Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: labelColor.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: labelColor.withValues(alpha: 0.25),
                            width: 1.2,
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(emoji, style: const TextStyle(fontSize: 24)),
                            const SizedBox(height: 6),
                            Text(
                              emo,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: labelColor,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              interval['label'] as String,
                              style: const TextStyle(
                                fontSize: 8,
                                color: AppColors.textMuted,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Detailed Notes Card
            if ((summary?.meetingNotes ?? '').isNotEmpty) ...[
              Row(
                children: [
                  const Icon(
                    Icons.notes_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Detailed Notes',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              GlassCard(
                borderColor: AppColors.primary.withValues(alpha: 0.15),
                child: Text(
                  summary?.meetingNotes ?? '',
                  style: const TextStyle(
                    height: 1.5,
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Speaker Takeaways Card (Feature 9)
            if ((summary?.keyTakeaways ?? '').isNotEmpty) ...[
              Row(
                children: [
                  const Icon(
                    Icons.stars_rounded,
                    color: AppColors.accent,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Speaker-Specific Takeaways',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.surface,
                      AppColors.surfaceLight.withValues(alpha: 0.4),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.accent.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                padding: const EdgeInsets.all(16),
                child: Text(
                  summary?.keyTakeaways ?? '',
                  style: const TextStyle(
                    height: 1.5,
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Risks & Concerns Card
            if ((summary?.risks ?? '').isNotEmpty) ...[
              Row(
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: AppColors.error,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Risks & Roadblocks',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              GlassCard(
                borderColor: AppColors.error.withValues(alpha: 0.15),
                child: Text(
                  summary?.risks ?? '',
                  style: const TextStyle(
                    height: 1.5,
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Next Steps Card
            if ((summary?.followUps ?? '').isNotEmpty) ...[
              Row(
                children: [
                  const Icon(
                    Icons.next_plan_outlined,
                    color: AppColors.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Next Steps',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              GlassCard(
                borderColor: AppColors.primary.withValues(alpha: 0.15),
                child: Text(
                  summary?.followUps ?? '',
                  style: const TextStyle(
                    height: 1.5,
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Important Dates & Deadlines Card
            if ((summary?.deadlines ?? '').isNotEmpty) ...[
              Row(
                children: [
                  const Icon(
                    Icons.date_range_rounded,
                    color: AppColors.secondary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Important Dates & Deadlines',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              GlassCard(
                borderColor: AppColors.secondary.withValues(alpha: 0.15),
                child: Text(
                  summary?.deadlines ?? '',
                  style: const TextStyle(
                    height: 1.5,
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Important Decisions Card
            if (decisions.isNotEmpty) ...[
              Row(
                children: [
                  const Icon(
                    Icons.gavel_rounded,
                    color: AppColors.success,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Important Decisions',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              GlassCard(
                borderColor: AppColors.success.withValues(alpha: 0.2),
                child: Column(
                  children: decisions.map((d) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.check_circle_outline_rounded,
                            color: AppColors.success,
                            size: 18,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              d.description ?? '',
                              style: const TextStyle(
                                fontSize: 14,
                                height: 1.4,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Speaker Mood Observations (Feature 8)
            if (speakerEmotions.isNotEmpty) ...[
              Row(
                children: [
                  const Icon(
                    Icons.face_rounded,
                    color: AppColors.accent,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Speaker Mood & Observations',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ...speakerEmotions.map((se) {
                final profile = se.speakerProfile.value;
                final name = profile?.name ?? 'Speaker';
                final emoji = profile?.avatarEmoji ?? '👤';
                final color = Color(profile?.colorValue ?? 0xFF9C27B0);

                final mood = se.emotion ?? 'Neutral';
                final moodEmoji = getEmotionEmoji(mood);

                String observation =
                    "Steady, moderate pitch, highly stable and clear delivery.";
                if (mood == "Happy" || mood == "Excited") {
                  observation =
                      "Positive tone, highly engaged, energetic participation.";
                } else if (mood == "Frustrated") {
                  observation =
                      "Tense voice tone, rapid speaking rate, possible friction.";
                } else if (mood == "Thinking") {
                  observation =
                      "Frequent pauses, introspective tone, deliberate speaking rate.";
                } else if (mood == "Nervous" || mood == "Concerned") {
                  observation =
                      "Shaky pitch fluctuations, tentative energy levels.";
                }

                return Card(
                  color: Colors.white.withValues(alpha: 0.02),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: color.withValues(alpha: 0.15)),
                  ),
                  margin: const EdgeInsets.only(bottom: 10),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: color.withValues(alpha: 0.15),
                          child: Text(
                            emoji,
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    name,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: color,
                                    ),
                                  ),
                                  Text(
                                    '$moodEmoji $mood (${(se.confidence * 100).toStringAsFixed(0)}%)',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      color: getEmotionColor(mood),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                observation,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
              const SizedBox(height: 16),
            ],

            // Speaker Participation Section
            if (participationList.isNotEmpty) ...[
              Row(
                children: [
                  const Icon(
                    Icons.pie_chart_outline_rounded,
                    color: AppColors.secondary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Speaker Participation Insights',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              GlassCard(
                borderColor: AppColors.secondary.withValues(alpha: 0.15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ...participationList.map((entry) {
                      final percent = (entry.value * 100).toStringAsFixed(0);
                      final double spkDur = speakerDurations[entry.key] ?? 0.0;
                      final spkMin = (spkDur / 60).toInt();
                      final spkSec = (spkDur % 60).toInt();
                      final spkTimeStr = spkMin > 0
                          ? '${spkMin}m ${spkSec}s'
                          : '${spkSec}s';

                      final matchingSegments = segments
                          .where((s) => s.speaker == entry.key)
                          .toList();
                      final profile = matchingSegments.isNotEmpty
                          ? matchingSegments.first.speakerProfile.value
                          : null;
                      final String name =
                          profile?.name ?? 'Speaker ${entry.key}';
                      final String emoji = profile?.avatarEmoji ?? '👤';
                      final Color color = Color(
                        profile?.colorValue ?? 0xFF9C27B0,
                      );

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 14,
                              backgroundColor: color.withValues(alpha: 0.15),
                              child: Text(
                                emoji,
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      Text(
                                        '$spkTimeStr ($percent%)',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                          color: color,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: entry.value,
                                      backgroundColor: Colors.white.withValues(
                                        alpha: 0.05,
                                      ),
                                      color: color,
                                      minHeight: 6,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        color,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Voice Tone Analysis Section
            Row(
              children: [
                const Icon(
                  Icons.psychology_outlined,
                  color: AppColors.secondary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Overall Tone Observation',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _buildVoiceEmotionCard(meeting),
          ],
        ],
      ),
    );
  }

  String getEmotionEmoji(String emotion) {
    switch (emotion.toLowerCase()) {
      case 'happy':
        return '😀';
      case 'excited':
        return '🔥';
      case 'confident':
        return '💪';
      case 'calm':
        return '😌';
      case 'concerned':
        return '😟';
      case 'frustrated':
        return '😡';
      case 'bored':
        return '😴';
      case 'nervous':
        return '😨';
      case 'thinking':
        return '🤔';
      default:
        return '😐';
    }
  }

  Color getEmotionColor(String emotion) {
    switch (emotion.toLowerCase()) {
      case 'happy':
      case 'excited':
        return AppColors.secondary;
      case 'confident':
        return AppColors.primary;
      case 'calm':
        return AppColors.success;
      case 'concerned':
      case 'nervous':
        return AppColors.warning;
      case 'frustrated':
        return AppColors.error;
      case 'thinking':
        return AppColors.accent;
      default:
        return AppColors.textMuted;
    }
  }

  // --- TAB C: TASKS (ACTION ITEMS) ---
  Widget _buildTasksTab(MeetingModel meeting) {
    final actionItems = meeting.actionItems.toList();

    // Sort active first, then sort active by priority (High -> Medium -> Low), completed at bottom.
    final sortedActionItems = List<ActionItemModel>.from(actionItems)
      ..sort((a, b) {
        if (a.isCompleted != b.isCompleted) {
          return a.isCompleted ? 1 : -1;
        }
        final pA = (a.priority ?? 'Low').toLowerCase();
        final pB = (b.priority ?? 'Low').toLowerCase();
        final score = {'high': 3, 'medium': 2, 'low': 1};
        final valA = score[pA] ?? 1;
        final valB = score[pB] ?? 1;
        return valB.compareTo(valA);
      });

    if (actionItems.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    width: 1,
                  ),
                ),
                child: const Icon(
                  Icons.playlist_add_check_rounded,
                  color: AppColors.primary,
                  size: 48,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'No Action Items Found',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'AI has not generated or identified any action items from this meeting transcript.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final totalTasks = actionItems.length;
    final completedTasks = actionItems.where((item) => item.isCompleted).length;
    final pendingTasks = totalTasks - completedTasks;
    final highPriorityTasks = actionItems
        .where((item) => (item.priority ?? '').toLowerCase() == 'high')
        .length;
    final completionRate = totalTasks > 0 ? completedTasks / totalTasks : 0.0;

    final filteredActionItems = sortedActionItems.where((item) {
      if (_statusFilter == 'Pending' && item.isCompleted) return false;
      if (_statusFilter == 'Completed' && !item.isCompleted) return false;
      if (_priorityFilter != 'All' &&
          (item.priority ?? 'Low').toLowerCase() !=
              _priorityFilter.toLowerCase())
        return false;
      return true;
    }).toList();

    return Column(
      children: [
        // Premium Completion Progress Header Card
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
          child: GlassCard(
            padding: const EdgeInsets.all(16),
            borderColor: AppColors.primary.withValues(alpha: 0.2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.assignment_turned_in_rounded,
                          color: AppColors.secondary,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Action Items Progress',
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                        ),
                      ],
                    ),
                    Text(
                      '$completedTasks of $totalTasks Completed',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: AppColors.secondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: completionRate,
                    backgroundColor: Colors.white.withValues(alpha: 0.05),
                    color: AppColors.secondary,
                    minHeight: 8,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Analytics Row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 4.0),
          child: Row(
            children: [
              _buildStatCard('Total', totalTasks, AppColors.primary),
              const SizedBox(width: 6),
              _buildStatCard('Pending', pendingTasks, AppColors.warning),
              const SizedBox(width: 6),
              _buildStatCard('Completed', completedTasks, AppColors.success),
              const SizedBox(width: 6),
              _buildStatCard(
                'High Priority',
                highPriorityTasks,
                AppColors.error,
              ),
            ],
          ),
        ),

        // Filters Row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
          child: Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _statusFilter,
                  dropdownColor: AppColors.surfaceLight,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Filter Status',
                    labelStyle: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Colors.white10),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: AppColors.secondary),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  items: ['All', 'Pending', 'Completed']
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _statusFilter = val);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _priorityFilter,
                  dropdownColor: AppColors.surfaceLight,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Filter Priority',
                    labelStyle: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Colors.white10),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: AppColors.secondary),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  items: ['All', 'High', 'Medium', 'Low']
                      .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _priorityFilter = val);
                  },
                ),
              ),
            ],
          ),
        ),

        // Tasks list
        Expanded(
          child: filteredActionItems.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.filter_list_off_rounded,
                        color: AppColors.textMuted,
                        size: 36,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'No tasks match the selected filters.',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _statusFilter = 'All';
                            _priorityFilter = 'All';
                          });
                        },
                        child: const Text('Reset Filters'),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: EdgeInsets.only(
                    left: 20,
                    right: 20,
                    top: 10,
                    bottom: _audioAvailable ? 110.0 : 20.0,
                  ),
                  itemCount: filteredActionItems.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final item = filteredActionItems[index];
                    final deadlineStr = item.deadline != null
                        ? DateFormat('yyyy-MM-dd').format(item.deadline!)
                        : 'No Deadline';

                    // Priority mapping
                    final String priorityStr = (item.priority ?? 'Low')
                        .toUpperCase();
                    Color priorityColor = AppColors.textMuted;
                    if (priorityStr == 'HIGH') {
                      priorityColor = AppColors.error;
                    } else if (priorityStr == 'MEDIUM') {
                      priorityColor = AppColors.warning;
                    }

                    return GlassCard(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      borderColor: item.isCompleted
                          ? AppColors.success.withValues(alpha: 0.25)
                          : priorityColor.withValues(alpha: 0.25),
                      borderWidth: item.isCompleted ? 1.0 : 1.5,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 2.0),
                            child: Transform.scale(
                              scale: 1.1,
                              child: Checkbox(
                                value: item.isCompleted,
                                activeColor: AppColors.success,
                                checkColor: Colors.black,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                onChanged: (bool? checked) async {
                                  if (checked != null) {
                                    await ref
                                        .read(taskRepositoryProvider)
                                        .updateTaskStatus(item.id, checked);
                                    // Refresh parent meeting details
                                    ref.invalidate(
                                      meetingDetailsStreamProvider(
                                        widget.meetingId,
                                      ),
                                    );
                                    ref.invalidate(meetingsListStreamProvider);
                                  }
                                },
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        item.description ?? '',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          height: 1.4,
                                          decoration: item.isCompleted
                                              ? TextDecoration.lineThrough
                                              : null,
                                          color: item.isCompleted
                                              ? AppColors.textMuted
                                              : AppColors.textPrimary,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    if (!item.isCompleted)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: priorityColor.withValues(
                                            alpha: 0.15,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                          border: Border.all(
                                            color: priorityColor.withValues(
                                              alpha: 0.3,
                                            ),
                                            width: 1,
                                          ),
                                        ),
                                        child: Text(
                                          priorityStr,
                                          style: TextStyle(
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                            color: priorityColor,
                                          ),
                                        ),
                                      ),
                                    PopupMenuButton<String>(
                                      icon: const Icon(
                                        Icons.more_vert,
                                        size: 20,
                                        color: AppColors.textSecondary,
                                      ),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(
                                        minWidth: 100,
                                      ),
                                      color: AppColors.surfaceLight,
                                      onSelected: (val) {
                                        if (val == 'edit') {
                                          _showEditTaskDialog(item);
                                        } else if (val == 'delete') {
                                          _showDeleteTaskDialog(item);
                                        }
                                      },
                                      itemBuilder: (context) => [
                                        const PopupMenuItem(
                                          value: 'edit',
                                          child: Text(
                                            'Edit',
                                            style: TextStyle(
                                              color: AppColors.textPrimary,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                        const PopupMenuItem(
                                          value: 'delete',
                                          child: Text(
                                            'Delete',
                                            style: TextStyle(
                                              color: AppColors.error,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    if (item.assignedTo != null &&
                                        item.assignedTo!.isNotEmpty) ...[
                                      const Icon(
                                        Icons.person_outline_rounded,
                                        size: 13,
                                        color: AppColors.textSecondary,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        item.assignedTo!,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textSecondary,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                    ],
                                    const Icon(
                                      Icons.calendar_today_rounded,
                                      size: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      deadlineStr,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: AppColors.textSecondary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, int count, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
        ),
        child: Column(
          children: [
            Text(
              '$count',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 8.5,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditTaskDialog(ActionItemModel item) {
    final descController = TextEditingController(text: item.description);
    final assigneeController = TextEditingController(text: item.assignedTo);
    String priority = item.priority ?? 'Medium';
    DateTime? selectedDate = item.deadline;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Text(
                'Edit Task',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: descController,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: const InputDecoration(
                        labelText: 'Task Description',
                        labelStyle: TextStyle(color: AppColors.textMuted),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: assigneeController,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: const InputDecoration(
                        labelText: 'Assignee',
                        labelStyle: TextStyle(color: AppColors.textMuted),
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: priority,
                      dropdownColor: AppColors.surfaceLight,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: const InputDecoration(
                        labelText: 'Priority',
                        labelStyle: TextStyle(color: AppColors.textMuted),
                      ),
                      items: ['High', 'Medium', 'Low']
                          .map(
                            (p) => DropdownMenuItem(value: p, child: Text(p)),
                          )
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() => priority = val);
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_today_rounded,
                          size: 16,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          selectedDate != null
                              ? DateFormat('yyyy-MM-dd').format(selectedDate!)
                              : 'No Deadline Set',
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 13,
                          ),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: selectedDate ?? DateTime.now(),
                              firstDate: DateTime.now().subtract(
                                const Duration(days: 365),
                              ),
                              lastDate: DateTime.now().add(
                                const Duration(days: 365 * 5),
                              ),
                              builder: (context, child) {
                                return Theme(
                                  data: Theme.of(context).copyWith(
                                    colorScheme: const ColorScheme.dark(
                                      primary: AppColors.secondary,
                                      onPrimary: Colors.black,
                                      surface: AppColors.surface,
                                      onSurface: AppColors.textPrimary,
                                    ),
                                    dialogBackgroundColor: AppColors.surface,
                                  ),
                                  child: child!,
                                );
                              },
                            );
                            if (date != null) {
                              setDialogState(() => selectedDate = date);
                            }
                          },
                          child: const Text(
                            'Pick Date',
                            style: TextStyle(color: AppColors.secondary),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (descController.text.trim().isEmpty) return;
                    item.description = descController.text.trim();
                    item.assignedTo = assigneeController.text.trim();
                    item.priority = priority;
                    item.deadline = selectedDate;
                    await ref.read(taskRepositoryProvider).updateTask(item);
                    if (context.mounted) {
                      Navigator.pop(context);
                      ref.invalidate(
                        meetingDetailsStreamProvider(widget.meetingId),
                      );
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showDeleteTaskDialog(ActionItemModel item) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Delete Task',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Text(
            'Are you sure you want to delete this task?',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancel',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
              onPressed: () async {
                await ref.read(taskRepositoryProvider).deleteTask(item.id);
                if (context.mounted) {
                  Navigator.pop(context);
                  ref.invalidate(
                    meetingDetailsStreamProvider(widget.meetingId),
                  );
                }
              },
              child: const Text(
                'Delete',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  // --- TAB D: AI CHAT (RAG) ---
  Widget _buildChatTab(MeetingModel meeting) {
    final chatAsync = ref.watch(meetingChatProvider(meeting.id));

    return Column(
      children: [
        // Meeting Context Card at the top
        _buildContextCard(meeting),

        Expanded(
          child: chatAsync.when(
            data: (messages) {
              if (messages.isEmpty) {
                return _buildChatEmptyState(meeting);
              }

              // Scroll to bottom on load/new msg
              _scrollChatToBottom();

              return ListView.builder(
                controller: _chatScrollController,
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 16,
                  bottom: _audioAvailable ? 110.0 : 16.0,
                ),
                itemCount: messages.length,
                itemBuilder: (context, idx) {
                  final msg = messages[idx];

                  // 1. Thinking placeholder
                  if (!msg.isUser && msg.message == '🤖 Thinking...') {
                    return const Padding(
                      padding: EdgeInsets.only(bottom: 12.0),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: PulsingThinkingBubble(),
                      ),
                    );
                  }

                  // 2. Error message bubble
                  final bool isConnectionError =
                      msg.message?.startsWith('⚠️ Connection Error') ?? false;
                  final bool isAiUnavailable =
                      msg.message?.startsWith('⚠️ AI Unavailable') ?? false;

                  if (!msg.isUser && (isConnectionError || isAiUnavailable)) {
                    final originalText = idx > 0
                        ? (messages[idx - 1].message ?? '')
                        : '';
                    final parts = (msg.message ?? '').split('\nDetails:');
                    final title = parts.isNotEmpty
                        ? parts[0]
                        : (isConnectionError
                              ? '⚠️ Connection Error'
                              : '⚠️ AI Unavailable');
                    final details = parts.length > 1 ? parts[1].trim() : '';

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: ChatErrorBubble(
                          errorMessage: title,
                          details: details,
                          onRetry: () {
                            ref
                                .read(meetingChatProvider(meeting.id).notifier)
                                .retryLastMessage(originalText);
                          },
                        ),
                      ),
                    );
                  }

                  // 3. Normal Message
                  final isLastAiMessage =
                      !msg.isUser && (idx == messages.length - 1);

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: Column(
                      crossAxisAlignment: msg.isUser
                          ? CrossAxisAlignment.end
                          : CrossAxisAlignment.start,
                      children: [
                        Align(
                          alignment: msg.isUser
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: GlassCard(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            margin: EdgeInsets.only(
                              left: msg.isUser ? 40.0 : 0.0,
                              right: msg.isUser ? 0.0 : 40.0,
                            ),
                            borderColor: msg.isUser
                                ? AppColors.accent.withOpacity(0.35)
                                : AppColors.border,
                            gradientColors: msg.isUser
                                ? [AppColors.primary, AppColors.secondary]
                                : null,
                            child: msg.isUser
                                ? Text(
                                    msg.message ?? '',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      height: 1.4,
                                      color: AppColors.textPrimary,
                                    ),
                                  )
                                : _buildParsedMessageContent(msg.message ?? ''),
                          ),
                        ),
                        if (isLastAiMessage)
                          Padding(
                            padding: const EdgeInsets.only(left: 8.0, top: 4.0),
                            child: _buildSmartSuggestions(meeting),
                          ),
                      ],
                    ),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Center(
              child: Text(
                'Chat Error: $err',
                style: const TextStyle(color: AppColors.error),
              ),
            ),
          ),
        ),

        // Bottom Floating Input box (Modern AI Interface)
        Container(
          margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: AppTheme.glassBoxDecoration(
            opacity: 0.08,
            borderColor: AppColors.border,
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(
                  Icons.add_circle_outline_rounded,
                  color: AppColors.textSecondary,
                  size: 22,
                ),
                onPressed: () {
                  // Attachment action placeholder
                },
              ),
              IconButton(
                icon: const Icon(
                  Icons.mic_none_rounded,
                  color: AppColors.textSecondary,
                  size: 22,
                ),
                onPressed: () {
                  // Voice search action placeholder
                },
              ),
              Expanded(
                child: TextFormField(
                  controller: _chatController,
                  textInputAction: TextInputAction.send,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13.5,
                  ),
                  onFieldSubmitted: (val) {
                    if (val.trim().isNotEmpty) {
                      ref
                          .read(meetingChatProvider(meeting.id).notifier)
                          .sendMessage(val.trim());
                      _chatController.clear();
                    }
                  },
                  decoration: const InputDecoration(
                    hintText: 'Ask about this meeting...',
                    hintStyle: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 13,
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    filled: false,
                    contentPadding: EdgeInsets.symmetric(horizontal: 8),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppColors.primaryGradient,
                  boxShadow: AppTheme.neonGlow(
                    color: AppColors.secondary,
                    radius: 4,
                  ),
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.send_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                  onPressed: () {
                    final text = _chatController.text.trim();
                    if (text.isNotEmpty) {
                      ref
                          .read(meetingChatProvider(meeting.id).notifier)
                          .sendMessage(text);
                      _chatController.clear();
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildContextCard(MeetingModel meeting) {
    final segments = meeting.transcript.value?.segments.toList() ?? [];
    final speakersCount = segments
        .map((s) => s.speaker)
        .toSet()
        .where((s) => s != null)
        .length;
    final hasTranscript = segments.isNotEmpty;
    final hasSummary = meeting.summary.value != null;

    final dateStr = meeting.createdAt != null
        ? DateFormat('MMM dd, yyyy').format(meeting.createdAt!)
        : 'No Date';

    final minVal = meeting.durationSeconds / 60.0;
    final durationStr = minVal >= 1.0
        ? '${minVal.toStringAsFixed(0)}m ${(meeting.durationSeconds % 60).toStringAsFixed(0)}s'
        : '${meeting.durationSeconds.toStringAsFixed(0)}s';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        borderColor: Colors.white.withValues(alpha: 0.05),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildContextItem(Icons.calendar_month_rounded, dateStr, 'Date'),
            _buildContextItem(Icons.timer_outlined, durationStr, 'Duration'),
            _buildContextItem(
              Icons.people_outline_rounded,
              '$speakersCount',
              'Speakers',
            ),
            _buildContextItem(
              Icons.description_outlined,
              hasTranscript ? 'Available' : 'Empty',
              'Transcript',
              color: hasTranscript ? AppColors.success : AppColors.warning,
            ),
            _buildContextItem(
              Icons.auto_awesome_rounded,
              hasSummary ? 'Ready' : 'Not Run',
              'AI Status',
              color: hasSummary ? AppColors.secondary : AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContextItem(
    IconData icon,
    String value,
    String label, {
    Color? color,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color ?? AppColors.textMuted),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: color ?? AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 8, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildChatEmptyState(MeetingModel meeting) {
    final suggestedQuestions = [
      'Summarize this meeting',
      'What tasks were assigned?',
      'What decisions were made?',
      'What deadlines were mentioned?',
      'What are the next steps?',
      'Who spoke the most?',
    ];

    final quickActionChips = [
      {
        'label': 'Summary',
        'query': 'Summarize this meeting and provide the key highlights.',
      },
      {
        'label': 'Action Items',
        'query':
            'What are the concrete action items and assignments from this meeting?',
      },
      {
        'label': 'Decisions',
        'query': 'List all key decisions made during this discussion.',
      },
      {
        'label': 'Deadlines',
        'query': 'What deadlines, dates, or due dates were mentioned?',
      },
      {
        'label': 'Risks',
        'query':
            'Identify any risks, concerns, or unresolved issues mentioned in the meeting.',
      },
      {
        'label': 'Next Steps',
        'query':
            'What are the logical next steps for the team following this discussion?',
      },
      {
        'label': 'Key Topics',
        'query':
            'What were the main topics discussed and how much time was spent on each?',
      },
      {
        'label': 'Speaker Insights',
        'query':
            'Provide insights on speaker participation and who drove the conversation.',
      },
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 10),
          Center(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.secondary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                color: AppColors.secondary,
                size: 32,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '🤖 Meeting Assistant',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Ask questions about this meeting transcript and get instant AI-powered insights.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),

          // Quick Action Chips Header
          const Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: quickActionChips.map((chip) {
              return InkWell(
                onTap: () {
                  ref
                      .read(meetingChatProvider(meeting.id).notifier)
                      .sendMessage(chip['query']!);
                },
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.flash_on_rounded,
                        size: 12,
                        color: AppColors.secondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        chip['label']!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 24),

          // Suggested Questions List
          const Text(
            'Suggested Questions',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 10),
          ...suggestedQuestions.map((question) {
            return Card(
              color: Colors.white.withValues(alpha: 0.02),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
              ),
              margin: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                onTap: () {
                  ref
                      .read(meetingChatProvider(meeting.id).notifier)
                      .sendMessage(question);
                },
                borderRadius: BorderRadius.circular(10),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.help_outline_rounded,
                        size: 14,
                        color: AppColors.textMuted,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          question,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 12,
                        color: AppColors.textMuted,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildParsedMessageContent(String text) {
    final List<Widget> children = [];
    final lines = text.split('\n');

    String currentSection = '';
    List<String> sectionLines = [];

    void flushSection() {
      if (sectionLines.isEmpty) return;

      final content = sectionLines.join('\n').trim();
      if (currentSection == 'summary') {
        children.add(_buildSummaryCard(content));
      } else if (currentSection == 'tasks') {
        children.add(_buildTasksCard(sectionLines));
      } else if (currentSection == 'decisions') {
        children.add(_buildDecisionsCard(sectionLines));
      } else if (currentSection == 'deadlines') {
        children.add(_buildDeadlinesCard(sectionLines));
      } else {
        children.add(_buildFormattedText(content));
      }
      sectionLines = [];
    }

    for (final line in lines) {
      final trimmed = line.trim();
      final lower = trimmed.toLowerCase();

      if (lower.startsWith('📋 meeting summary') ||
          lower.startsWith('executive summary:') ||
          lower.startsWith('summary:')) {
        flushSection();
        currentSection = 'summary';
        if (!lower.startsWith('📋 meeting summary')) {
          sectionLines.add(line);
        }
      } else if (lower.startsWith('action items:') ||
          lower.startsWith('tasks:') ||
          lower.startsWith('action items') ||
          lower.startsWith('action items detected:')) {
        flushSection();
        currentSection = 'tasks';
      } else if (lower.startsWith('decisions:') ||
          lower.startsWith('key decisions:')) {
        flushSection();
        currentSection = 'decisions';
      } else if (lower.startsWith('deadlines:') ||
          lower.startsWith('key deadlines:')) {
        flushSection();
        currentSection = 'deadlines';
      } else if (trimmed.isEmpty) {
        if (currentSection != 'summary') {
          flushSection();
          currentSection = '';
        } else {
          sectionLines.add(line);
        }
      } else {
        sectionLines.add(line);
      }
    }
    flushSection();

    if (children.isEmpty) {
      return _buildFormattedText(text);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children
          .map(
            (w) =>
                Padding(padding: const EdgeInsets.only(bottom: 8.0), child: w),
          )
          .toList(),
    );
  }

  Widget _buildFormattedText(String text) {
    final lines = text.split('\n');
    final List<Widget> lineWidgets = [];

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) {
        lineWidgets.add(const SizedBox(height: 6));
        continue;
      }

      final isBullet =
          trimmed.startsWith('•') ||
          trimmed.startsWith('-') ||
          trimmed.startsWith('*');
      var cleanText = trimmed;
      if (isBullet) {
        cleanText = trimmed.substring(1).trim();
      }

      // Parse bolding (**text**)
      final List<TextSpan> spans = [];
      final boldRegex = RegExp(r'\*\*(.*?)\*\*');
      int lastIndex = 0;
      final matches = boldRegex.allMatches(cleanText);

      for (final match in matches) {
        if (match.start > lastIndex) {
          spans.add(
            TextSpan(text: cleanText.substring(lastIndex, match.start)),
          );
        }
        spans.add(
          TextSpan(
            text: match.group(1),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.secondary,
            ),
          ),
        );
        lastIndex = match.end;
      }
      if (lastIndex < cleanText.length) {
        spans.add(TextSpan(text: cleanText.substring(lastIndex)));
      }

      if (isBullet) {
        lineWidgets.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  ' •  ',
                  style: TextStyle(color: AppColors.secondary, fontSize: 14),
                ),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.4,
                        color: AppColors.textPrimary,
                      ),
                      children: spans,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      } else {
        lineWidgets.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2.0),
            child: RichText(
              text: TextSpan(
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.4,
                  color: AppColors.textPrimary,
                ),
                children: spans,
              ),
            ),
          ),
        );
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: lineWidgets,
    );
  }

  Widget _buildSummaryCard(String content) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.surfaceLight.withValues(alpha: 0.1),
            AppColors.surfaceLight.withValues(alpha: 0.25),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: const Border(
          left: BorderSide(color: AppColors.secondary, width: 4),
        ),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(
                Icons.summarize_outlined,
                color: AppColors.secondary,
                size: 18,
              ),
              SizedBox(width: 8),
              Text(
                'Executive Summary',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: AppColors.secondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(
              fontSize: 13,
              height: 1.4,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTasksCard(List<String> lines) {
    final List<Widget> taskWidgets = [];
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;

      var cleanText = trimmed;
      if (cleanText.startsWith('-') ||
          cleanText.startsWith('•') ||
          cleanText.startsWith('*')) {
        cleanText = cleanText.substring(1).trim();
      }
      if (cleanText.startsWith('[ ]') || cleanText.startsWith('[x]')) {
        cleanText = cleanText.substring(3).trim();
      }
      if (cleanText.isEmpty) continue;

      taskWidgets.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.check_box_outline_blank_rounded,
                color: AppColors.primary,
                size: 16,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  cleanText,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (taskWidgets.isEmpty) return const SizedBox();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(
                Icons.playlist_add_check_rounded,
                color: AppColors.primary,
                size: 18,
              ),
              SizedBox(width: 8),
              Text(
                'Extracted Action Items',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...taskWidgets,
        ],
      ),
    );
  }

  Widget _buildDecisionsCard(List<String> lines) {
    final List<Widget> decisionWidgets = [];
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;
      var cleanText = trimmed;
      if (cleanText.startsWith('-') ||
          cleanText.startsWith('•') ||
          cleanText.startsWith('*')) {
        cleanText = cleanText.substring(1).trim();
      }
      if (cleanText.isEmpty) continue;
      decisionWidgets.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.gavel_rounded,
                color: AppColors.success,
                size: 16,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  cleanText,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
    if (decisionWidgets.isEmpty) return const SizedBox();
    return Container(
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.15)),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(
                Icons.check_circle_outline_rounded,
                color: AppColors.success,
                size: 18,
              ),
              SizedBox(width: 8),
              Text(
                'Key Decisions',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: AppColors.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...decisionWidgets,
        ],
      ),
    );
  }

  Widget _buildDeadlinesCard(List<String> lines) {
    final List<Widget> deadlineWidgets = [];
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;
      var cleanText = trimmed;
      if (cleanText.startsWith('-') ||
          cleanText.startsWith('•') ||
          cleanText.startsWith('*')) {
        cleanText = cleanText.substring(1).trim();
      }
      if (cleanText.isEmpty) continue;
      deadlineWidgets.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.calendar_today_rounded,
                color: AppColors.warning,
                size: 14,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  cleanText,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
    if (deadlineWidgets.isEmpty) return const SizedBox();
    return Container(
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.15)),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(
                Icons.notification_important_rounded,
                color: AppColors.warning,
                size: 18,
              ),
              SizedBox(width: 8),
              Text(
                'Deadlines & Milestones',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: AppColors.warning,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...deadlineWidgets,
        ],
      ),
    );
  }

  Widget _buildSmartSuggestions(MeetingModel meeting) {
    final suggestions = [
      'Tell me more',
      'Show action items',
      'Show deadlines',
      'Explain decisions',
      'Generate executive summary',
    ];

    return Padding(
      padding: const EdgeInsets.only(top: 8.0, bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(
              'Follow-up suggestions:',
              style: TextStyle(
                fontSize: 11,
                color: AppColors.textMuted,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 6),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: suggestions.map((s) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ActionChip(
                    backgroundColor: Colors.white.withValues(alpha: 0.02),
                    side: const BorderSide(color: Colors.white10),
                    label: Text(
                      s,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.secondary,
                      ),
                    ),
                    onPressed: () {
                      ref
                          .read(meetingChatProvider(meeting.id).notifier)
                          .sendMessage(s);
                    },
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // --- TAB E: AUDIO DETAILS ---
  Widget _buildAudioTab(MeetingModel meeting) {
    final dateStr = meeting.createdAt != null
        ? DateFormat('MMMM dd, yyyy - HH:mm').format(meeting.createdAt!)
        : 'Unknown';

    return SingleChildScrollView(
      padding: EdgeInsets.only(
        left: 24.0,
        right: 24.0,
        top: 24.0,
        bottom: _audioAvailable ? 110.0 : 24.0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Meeting Audio Details',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 16),

          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow(
                  'Audio Path',
                  meeting.audioFilePath ?? 'No file saved',
                ),
                const Divider(color: Colors.white10, height: 24),
                _buildInfoRow('Created on', dateStr),
                const Divider(color: Colors.white10, height: 24),
                _buildInfoRow(
                  'Raw File Size',
                  _audioAvailable ? 'Valid WAV File' : 'Unavailable',
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
          const Text(
            'Playback Speed Control',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 12),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [0.5, 1.0, 1.5, 2.0].map((speed) {
              final isSelected = _playbackSpeed == speed;
              return ChoiceChip(
                label: Text(
                  '${speed}x',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                selected: isSelected,
                selectedColor: AppColors.secondary,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.black : Colors.white,
                ),
                onSelected: _audioAvailable ? (_) => _changeSpeed(speed) : null,
              );
            }).toList(),
          ),

          const SizedBox(height: 40),

          // Regenerate summaries button
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: const BorderSide(color: AppColors.primary),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => _runSummaryGeneration(meeting),
            icon: const Icon(Icons.refresh, color: AppColors.primary),
            label: const Text(
              'Regenerate AI Analysis',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // --- PERSISTENT BOTTOM MINI PLAYER ---
  Widget _buildMiniPlayer() {
    final totalSecs = _audioDuration.inSeconds.toDouble();
    final currentSecs = _audioPosition.inSeconds.toDouble();

    final currentMin = (_audioPosition.inSeconds ~/ 60).toString().padLeft(
      2,
      '0',
    );
    final currentSec = (_audioPosition.inSeconds % 60).toString().padLeft(
      2,
      '0',
    );

    final totalMin = (_audioDuration.inSeconds ~/ 60).toString().padLeft(
      2,
      '0',
    );
    final totalSec = (_audioDuration.inSeconds % 60).toString().padLeft(2, '0');

    final double screenWidth = MediaQuery.of(context).size.width;
    final bool useTwoRows = screenWidth < 360;

    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(20),
        topRight: Radius.circular(20),
      ),
      borderColor: AppColors.primary.withValues(alpha: 0.3),
      borderWidth: 1.0,
      opacity: 0.12,
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (useTwoRows) ...[
              // Row 1: Slider and durations
              Row(
                children: [
                  Text(
                    '$currentMin:$currentSec',
                    style: const TextStyle(
                      fontSize: 11,
                      fontFamily: 'monospace',
                    ),
                  ),
                  Expanded(
                    child: Slider(
                      value: currentSecs.clamp(0.0, totalSecs),
                      max: totalSecs > 0.0 ? totalSecs : 1.0,
                      activeColor: AppColors.secondary,
                      inactiveColor: AppColors.surfaceLight,
                      onChanged: (val) {
                        _seekTo(val);
                      },
                    ),
                  ),
                  Text(
                    '$totalMin:$totalSec',
                    style: const TextStyle(
                      fontSize: 11,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
              // Row 2: Control Button centered
              Center(
                child: IconButton(
                  icon: Icon(
                    _isPlaying
                        ? Icons.pause_circle_filled_rounded
                        : Icons.play_circle_fill_rounded,
                  ),
                  iconSize: 40,
                  color: AppColors.secondary,
                  onPressed: _togglePlayback,
                ),
              ),
            ] else ...[
              // Single Row layout
              Row(
                children: [
                  IconButton(
                    icon: Icon(
                      _isPlaying
                          ? Icons.pause_circle_filled_rounded
                          : Icons.play_circle_fill_rounded,
                    ),
                    iconSize: 44,
                    color: AppColors.secondary,
                    onPressed: _togglePlayback,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$currentMin:$currentSec',
                    style: const TextStyle(
                      fontSize: 12,
                      fontFamily: 'monospace',
                    ),
                  ),
                  Expanded(
                    child: Slider(
                      value: currentSecs.clamp(0.0, totalSecs),
                      max: totalSecs > 0.0 ? totalSecs : 1.0,
                      activeColor: AppColors.secondary,
                      inactiveColor: AppColors.surfaceLight,
                      onChanged: (val) {
                        _seekTo(val);
                      },
                    ),
                  ),
                  Text(
                    '$totalMin:$totalSec',
                    style: const TextStyle(
                      fontSize: 12,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildChip({
    required IconData icon,
    required String label,
    required Color color,
    required Color textColor,
    Color? borderColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        border: borderColor != null
            ? Border.all(color: borderColor, width: 1)
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: textColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVoiceEmotionCard(MeetingModel meeting) {
    final healthState = ref.watch(emotionHealthServiceProvider);

    final emotion = meeting.detectedEmotion;
    final confidence = meeting.emotionConfidence ?? 0.0;
    final isLocal = meeting.isLocalEstimation ?? false;
    final hasEmotion =
        emotion != null &&
        emotion.isNotEmpty &&
        emotion.toLowerCase() != 'feature unavailable';

    String getEmoji(String emo) {
      switch (emo.toLowerCase()) {
        case 'happy':
          return '😀';
        case 'excited':
          return '🤩';
        case 'confident':
          return '😎';
        case 'calm':
          return '😌';
        case 'concerned':
          return '😟';
        case 'frustrated':
          return '😡';
        case 'angry':
          return '😡';
        case 'sad':
          return '😔';
        case 'bored':
          return '😴';
        case 'nervous':
          return '😨';
        case 'thinking':
          return '🤔';
        default:
          return '😐';
      }
    }

    Color getColor(String emo) {
      switch (emo.toLowerCase()) {
        case 'happy':
        case 'excited':
          return AppColors.secondary;
        case 'confident':
          return AppColors.primary;
        case 'calm':
          return AppColors.success;
        case 'concerned':
        case 'nervous':
          return AppColors.warning;
        case 'frustrated':
        case 'angry':
          return AppColors.error;
        case 'thinking':
          return AppColors.accent;
        default:
          return AppColors.textMuted;
      }
    }

    // STATE 1: ANALYZING / PROCESSING
    if (healthState.status == EmotionBackendStatus.processing ||
        healthState.status == EmotionBackendStatus.analyzing) {
      return GlassCard(
        borderColor: AppColors.secondary.withValues(alpha: 0.3),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
          child: Column(
            children: const [
              SizedBox(
                width: 36,
                height: 36,
                child: CircularProgressIndicator(
                  color: AppColors.secondary,
                  strokeWidth: 3,
                ),
              ),
              SizedBox(height: 16),
              Text(
                'Processing Voice Features...',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  letterSpacing: 0.5,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Running speech intelligence pipeline on Flask server...',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
            ],
          ),
        ),
      );
    }

    // RETRYING / RECONNECTING STATE
    if (healthState.status == EmotionBackendStatus.retrying) {
      final attemptStr = "Attempt ${healthState.retryAttempt}/3";
      return GlassCard(
        borderColor: AppColors.warning.withValues(alpha: 0.3),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
          child: Column(
            children: [
              const SizedBox(
                width: 36,
                height: 36,
                child: CircularProgressIndicator(
                  color: AppColors.warning,
                  strokeWidth: 3,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Emotion Analysis Status: Retrying ($attemptStr)',
                style: const TextStyle(
                  color: AppColors.warning,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                healthState.errorMessage ?? 'Reconnecting to Flask backend...',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // STATE 2: CONNECTED (No results yet)
    if (!hasEmotion && healthState.status == EmotionBackendStatus.connected) {
      return GlassCard(
        borderColor: AppColors.success.withValues(alpha: 0.3),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: const [
                  Icon(
                    Icons.check_circle_outline_rounded,
                    color: AppColors.success,
                    size: 24,
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Emotion Analysis Status: Connected',
                      style: TextStyle(
                        color: AppColors.success,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'Voice tone emotion analysis backend is online on port 5000. Ready to analyze speech patterns.',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _isGeneratingSummary
                    ? null
                    : () => _runSummaryGeneration(meeting),
                icon: const Icon(Icons.analytics_outlined, size: 18),
                label: const Text('Analyze Voice Tone Emotion'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // STATE 5: FAILED (No emotion, offline/fallback active)
    if (!hasEmotion &&
        (healthState.status == EmotionBackendStatus.offline ||
            healthState.status == EmotionBackendStatus.fallbackActive)) {
      return GlassCard(
        borderColor: AppColors.error.withValues(alpha: 0.3),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: const [
                  Icon(
                    Icons.error_outline_rounded,
                    color: AppColors.error,
                    size: 24,
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Voice Tone Backend Offline',
                      style: TextStyle(
                        color: AppColors.error,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Could not connect to the Flask emotion analysis server on port 5000.',
                style: TextStyle(
                  color: AppColors.textPrimary.withValues(alpha: 0.9),
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
              if (healthState.errorMessage != null &&
                  healthState.errorMessage!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: AppColors.error.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Text(
                    'Root Cause Details:\n${healthState.errorMessage}',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _isGeneratingSummary
                    ? null
                    : () => _runSummaryGeneration(meeting),
                icon: const Icon(Icons.offline_bolt_outlined, size: 18),
                label: const Text('Run Local Emotion Estimation'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _isGeneratingSummary
                    ? null
                    : () => ref
                          .read(emotionHealthServiceProvider.notifier)
                          .checkConnection(isPassive: false),
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Retry Connection to Backend'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textPrimary,
                  side: BorderSide(
                    color: AppColors.textSecondary.withValues(alpha: 0.3),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final cardColor = getColor(emotion ?? '');
    final emoji = getEmoji(emotion ?? '');
    final isOnline = healthState.status == EmotionBackendStatus.connected;

    // STATE 3 & 4: COMPLETED / FALLBACK ACTIVE (Showing results)
    return GlassCard(
      borderColor: cardColor.withValues(alpha: 0.4),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(emoji, style: const TextStyle(fontSize: 38)),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Detected Emotion: $emotion',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                          color: cardColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Confidence: ${(confidence * 100).toStringAsFixed(1)}%',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.refresh_rounded,
                    color: AppColors.textMuted,
                  ),
                  tooltip: 'Re-analyze',
                  onPressed: _isGeneratingSummary
                      ? null
                      : () => _runSummaryGeneration(meeting),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(color: AppColors.surfaceLight),
            const SizedBox(height: 8),

            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: (isLocal || !isOnline)
                        ? AppColors.warning
                        : AppColors.success,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    (isLocal || !isOnline)
                        ? 'Using local emotion estimation (based on transcript heuristics).'
                        : 'Voice tone analysis active (powered by server DSP models).',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: (isLocal || !isOnline)
                          ? AppColors.warning
                          : AppColors.secondary,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class PulsingThinkingBubble extends StatefulWidget {
  const PulsingThinkingBubble({super.key});

  @override
  State<PulsingThinkingBubble> createState() => _PulsingThinkingBubbleState();
}

class _PulsingThinkingBubbleState extends State<PulsingThinkingBubble>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  Timer? _messageTimer;

  int _messageIndex = 0;

  final List<Map<String, dynamic>> _messages = [
    {'text': 'Analyzing Meeting Context...', 'icon': Icons.psychology_outlined},
    {'text': 'Reviewing Transcript...', 'icon': Icons.search_rounded},
    {'text': 'Generating Insights...', 'icon': Icons.offline_bolt_outlined},
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _messageTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (mounted) {
        setState(() {
          _messageIndex = (_messageIndex + 1) % _messages.length;
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _messageTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final current = _messages[_messageIndex];
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: 0.4 + (_controller.value * 0.6),
          child: GlassCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            borderColor: AppColors.secondary.withValues(alpha: 0.4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  current['icon'] as IconData,
                  color: AppColors.secondary,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Text(
                  current['text'] as String,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 10),
                const SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.secondary,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class ChatErrorBubble extends StatelessWidget {
  final String errorMessage;
  final String details;
  final VoidCallback onRetry;

  const ChatErrorBubble({
    super.key,
    required this.errorMessage,
    required this.details,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 40.0),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.error.withValues(alpha: 0.4),
          width: 1.5,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.error_outline_rounded,
                color: AppColors.error,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                errorMessage,
                style: const TextStyle(
                  color: AppColors.error,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          if (details.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              details,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                textStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: onRetry,
              icon: const Icon(Icons.replay_rounded, size: 16),
              label: const Text('Retry'),
            ),
          ),
        ],
      ),
    );
  }
}

class BiometricInsightsCard extends StatefulWidget {
  final MeetingModel meeting;

  const BiometricInsightsCard({super.key, required this.meeting});

  @override
  State<BiometricInsightsCard> createState() => _BiometricInsightsCardState();
}

class _BiometricInsightsCardState extends State<BiometricInsightsCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final m = widget.meeting;
    if (m.heartRateAverage == null) return const SizedBox();

    return GlassCard(
      padding: EdgeInsets.zero,
      borderColor: AppColors.secondary.withValues(alpha: 0.2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Row
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  const Icon(
                    Icons.favorite_rounded,
                    color: AppColors.error,
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Meeting Wellness Analytics',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Biometric correlation & wellness coach insights',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _isExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: AppColors.textMuted,
                  ),
                ],
              ),
            ),
          ),

          if (_isExpanded) ...[
            const Divider(color: Colors.white10, height: 1, thickness: 1),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Averages grid
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildMiniMetric(
                        'Avg HR',
                        '${m.heartRateAverage!.toStringAsFixed(0)} bpm',
                        AppColors.error,
                      ),
                      _buildMiniMetric(
                        'Peak HR',
                        '${m.heartRatePeak!.toStringAsFixed(0)} bpm',
                        AppColors.warning,
                      ),
                      _buildMiniMetric(
                        'Avg Stress',
                        '${m.stressAverage!.toStringAsFixed(0)}%',
                        AppColors.primary,
                      ),
                      _buildMiniMetric(
                        'Engagement',
                        '${m.engagementScore!.toStringAsFixed(0)}%',
                        AppColors.secondary,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Expandable insights list
                  _buildInsightItem(
                    title: 'Mental Strain & Stress',
                    value: '${m.stressAverage!.toStringAsFixed(0)}%',
                    insight:
                        m.stressAnalysis ??
                        'Telemetry indicates stable heart rate variability and moderate cognitive load.',
                    color: AppColors.primary,
                    icon: Icons.speed_rounded,
                  ),
                  const SizedBox(height: 14),
                  _buildInsightItem(
                    title: 'Engagement & Focus',
                    value: '${m.engagementScore!.toStringAsFixed(0)}%',
                    insight:
                        m.engagementAnalysis ??
                        'High engagement detected, correlating speaking segments with steady cardiovascular load.',
                    color: AppColors.secondary,
                    icon: Icons.bolt_rounded,
                  ),
                  const SizedBox(height: 14),
                  _buildInsightItem(
                    title: 'Meeting Energy Drain',
                    value: m.energyDrain != null
                        ? '${m.energyDrain!.toStringAsFixed(0)} kcal'
                        : 'N/A',
                    insight:
                        m.energyAnalysis ??
                        'Caloric drain and physical exhaustion calculated based on meeting duration and average heart rate elevation.',
                    color: AppColors.accent,
                    icon: Icons.battery_charging_full_rounded,
                  ),
                  if (m.focusAnalysis != null) ...[
                    const SizedBox(height: 14),
                    _buildInsightItem(
                      title: 'Cognitive Focus Score',
                      value: 'Active',
                      insight: m.focusAnalysis!,
                      color: AppColors.success,
                      icon: Icons.psychology_rounded,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMiniMetric(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
        ),
      ],
    );
  }

  Widget _buildInsightItem({
    required String title,
    required String value,
    required String insight,
    required Color color,
    required IconData icon,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    value,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: color,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                insight,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Data model for a speaker block in the transcript view
// ─────────────────────────────────────────────────────────────────────────────
class _SpeakerBlock {
  final int speaker;
  final SpeakerProfileModel? profile;
  final List<TranscriptSegmentModel> sentences;

  _SpeakerBlock({
    required this.speaker,
    required this.profile,
    required this.sentences,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Small pill-shaped action button for the transcript toolbar
// ─────────────────────────────────────────────────────────────────────────────
class _TranscriptActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _TranscriptActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: AppColors.accent),
            const SizedBox(width: 5),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.accent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
