import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/gradient_button.dart';
import '../../widgets/glass_card.dart';
import '../meetings/meeting_details_screen.dart';
import 'recording_provider.dart';
import '../wearable/wearable_provider.dart';
import '../wearable/wearable_models.dart';
import '../meetings/meetings_provider.dart';
import '../meetings/meeting_chat_provider.dart';
import '../../providers/transcript_provider.dart';
import '../../database/schemas/meeting_models.dart';

class RecordingDialog extends ConsumerStatefulWidget {
  const RecordingDialog({super.key});

  @override
  ConsumerState<RecordingDialog> createState() => _RecordingDialogState();
}

class _RecordingDialogState extends ConsumerState<RecordingDialog>
    with TickerProviderStateMixin {
  final _titleController = TextEditingController();
  final _scrollController = ScrollController();
  final _chatScrollController = ScrollController();
  final _chatTextController = TextEditingController();
  late TabController _recordingTabController;
  bool _setupPhase = true;

  @override
  void initState() {
    super.initState();
    _titleController.text =
        'Meeting - ${DateFormat('MMM dd, yyyy').format(DateTime.now())}';
    _recordingTabController = TabController(length: 4, vsync: this);

    final recState = ref.read(recordingProvider);
    if (recState.status == RecordingStatus.recording ||
        recState.status == RecordingStatus.paused) {
      _setupPhase = false;
    } else {
      _setupPhase = true;
      if (recState.status != RecordingStatus.idle) {
        Future.microtask(() {
          ref.read(recordingProvider.notifier).reset();
        });
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _scrollController.dispose();
    _chatScrollController.dispose();
    _chatTextController.dispose();
    _recordingTabController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOut,
        );
      }
    });
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

  void _showDiscardConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: const BorderSide(color: AppColors.border),
          ),
          title: const Text(
            'Discard Meeting?',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Text(
            'Are you sure you want to discard this recording? All live transcripts and progress will be permanently lost.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(color: AppColors.textMuted),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                ref.read(recordingProvider.notifier).stopMeeting(cancel: true);
                Navigator.of(context).pop();
              },
              child: const Text(
                'Discard',
                style: TextStyle(color: AppColors.error),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final recordingState = ref.watch(recordingProvider);
    final transcriptState = ref.watch(transcriptProvider);

    // Auto-scroll transcript to bottom as formatted segments grow
    ref.listen(transcriptProvider, (previous, next) {
      if (previous?.formattedSegments.length != next.formattedSegments.length ||
          previous?.currentSentence != next.currentSentence) {
        _scrollToBottom();
      }
    });

    final elapsedMin = (recordingState.secondsElapsed ~/ 60).toString().padLeft(
      2,
      '0',
    );
    final elapsedSec = (recordingState.secondsElapsed % 60).toString().padLeft(
      2,
      '0',
    );

    final double screenHeight = MediaQuery.of(context).size.height;
    final double viewInsetsBottom = MediaQuery.of(context).viewInsets.bottom;
    final double dialogHeight = (screenHeight - viewInsetsBottom) * 0.90;

    final bool showActivePanel =
        !_setupPhase &&
        recordingState.status != RecordingStatus.idle &&
        recordingState.status != RecordingStatus.connecting &&
        recordingState.status != RecordingStatus.processing &&
        recordingState.status != RecordingStatus.completed &&
        recordingState.status != RecordingStatus.error;

    return Container(
      height: showActivePanel ? dialogHeight : null,
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(32),
        ),
      ),
      child: FuturisticBackground(
        child: Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 16,
            bottom: viewInsetsBottom + 16,
          ),
          child: Column(
            mainAxisSize: showActivePanel ? MainAxisSize.max : MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Drag handle indicator
              Center(
                child: Container(
                  width: 44,
                  height: 4.5,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              if (_setupPhase &&
                  recordingState.status == RecordingStatus.idle) ...[
                // SETUP PHASE SCREEN (REDESIGNED GLASS CARD)
                GlassCard(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'New Meeting Session',
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 22,
                            ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Give your meeting a name to start continuous recording.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          hintText: 'Meeting Title',
                          prefixIcon: Icon(
                            Icons.title,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Container(
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: AppTheme.neonGlow(
                            color: AppColors.secondary,
                            radius: 10,
                          ),
                        ),
                        child: ElevatedButton(
                          onPressed: () {
                            final state = ref.read(recordingProvider);
                            if (state.status != RecordingStatus.idle) {
                              return;
                            }
                            setState(() => _setupPhase = false);
                            ref
                                .read(recordingProvider.notifier)
                                .startMeeting(_titleController.text.trim());
                          },
                          child: const Text('Start Recording'),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else if (recordingState.status == RecordingStatus.connecting ||
                  recordingState.status == RecordingStatus.processing) ...[
                // CONNECTING / PROCESSING SPINNER STATE
                const SizedBox(height: 40),
                const Center(
                  child: CircularProgressIndicator(color: AppColors.accent),
                ),
                const SizedBox(height: 24),
                Text(
                  recordingState.status == RecordingStatus.connecting
                      ? 'Initializing Microphone & Deepgram Socket...'
                      : 'Compiling structured summary & decisions...',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 40),
              ] else if (recordingState.status == RecordingStatus.error) ...[
                // ERROR PANEL
                const Icon(
                  Icons.error_outline_rounded,
                  color: AppColors.error,
                  size: 56,
                ),
                const SizedBox(height: 16),
                Text(
                  'Recording Error',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(color: AppColors.error),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  recordingState.errorMessage ?? 'An unknown error occurred.',
                  style: const TextStyle(color: AppColors.textSecondary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    setState(() => _setupPhase = true);
                    ref
                        .read(recordingProvider.notifier)
                        .stopMeeting(cancel: true);
                  },
                  child: const Text('Go Back'),
                ),
              ] else if (recordingState.status ==
                  RecordingStatus.completed) ...[
                // SUCCESS/SUMMARY SCREEN
                const SizedBox(height: 16),
                const Center(
                  child: Icon(
                    Icons.check_circle_outline_rounded,
                    color: AppColors.success,
                    size: 60,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Meeting Saved Successfully',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Structured summary, action items, and decisions have been generated.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                if (recordingState.activeMeeting?.heartRateAverage != null) ...[
                  const SizedBox(height: 20),
                  GlassCard(
                    padding: const EdgeInsets.all(16),
                    borderColor: AppColors.primary.withOpacity(0.2),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              Icons.analytics_outlined,
                              color: AppColors.accent,
                              size: 18,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Meeting Biometrics Summary',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildSummaryMetric(
                              'Avg HR',
                              '${recordingState.activeMeeting!.heartRateAverage!.toStringAsFixed(0)} bpm',
                              Icons.favorite_border,
                              AppColors.error,
                            ),
                            _buildSummaryMetric(
                              'Peak HR',
                              '${recordingState.activeMeeting!.heartRatePeak!.toStringAsFixed(0)} bpm',
                              Icons.trending_up,
                              AppColors.warning,
                            ),
                            _buildSummaryMetric(
                              'Avg Stress',
                              '${recordingState.activeMeeting!.stressAverage!.toStringAsFixed(0)}%',
                              Icons.speed,
                              AppColors.primary,
                            ),
                            _buildSummaryMetric(
                              'Engagement',
                              '${recordingState.activeMeeting!.engagementScore!.toStringAsFixed(0)}%',
                              Icons.bolt,
                              AppColors.secondary,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                Container(
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: AppTheme.neonGlow(
                      color: AppColors.secondary,
                      radius: 8,
                    ),
                  ),
                  child: ElevatedButton(
                    onPressed: () {
                      final meeting = recordingState.activeMeeting;
                      Navigator.of(context).pop();
                      if (meeting != null) {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) =>
                                MeetingDetailsScreen(meetingId: meeting.id),
                          ),
                        );
                      }
                    },
                    child: const Text('View Transcript & Summary'),
                  ),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text(
                    'Back to Dashboard',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ] else ...[
                // ACTIVE RECORDING PANEL SCREEN
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            recordingState.activeMeeting?.title ??
                                'Active Session',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color:
                                      recordingState.status ==
                                          RecordingStatus.recording
                                      ? AppColors.error
                                      : AppColors.warning,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                recordingState.status ==
                                        RecordingStatus.recording
                                    ? 'Recording Live...'
                                    : 'Recording paused',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '$elapsedMin:$elapsedSec',
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Liquid Animated Assistant Orb Panel (ChatGPT Voice Mode Aesthetic)
                GlassCard(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  borderColor: AppColors.border,
                  child: Column(
                    children: [
                      ChatGPTVoiceOrb(
                        isRecording:
                            recordingState.status == RecordingStatus.recording,
                        currentVolume: recordingState.currentVolume,
                      ),
                      const SizedBox(height: 12),
                      _AnimatedWaveform(
                        isActive:
                            recordingState.status == RecordingStatus.recording,
                        volumeHistory: recordingState.volumeHistory,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Custom TabBar Controls
                Container(
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: TabBar(
                    controller: _recordingTabController,
                    indicator: UnderlineTabIndicator(
                      borderSide: const BorderSide(
                        color: AppColors.accent,
                        width: 3,
                      ),
                      insets: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    indicatorColor: AppColors.accent,
                    labelColor: AppColors.accent,
                    unselectedLabelColor: AppColors.textMuted,
                    labelStyle: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                    tabs: const [
                      Tab(text: 'Transcript'),
                      Tab(text: 'Summary'),
                      Tab(text: 'Tasks'),
                      Tab(text: 'Ask AI'),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Tab Views
                Expanded(
                  child: TabBarView(
                    controller: _recordingTabController,
                    children: [
                      _buildLiveTranscriptTab(transcriptState),
                      _buildLiveSummaryTab(recordingState.activeMeeting?.id),
                      _buildLiveTasksTab(recordingState.activeMeeting?.id),
                      _buildLiveChatTab(recordingState.activeMeeting?.id),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Glass Pill Control Bar
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: AppTheme.glassBoxDecoration(
                    opacity: 0.12,
                    borderColor: AppColors.border,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Discard / Close
                      IconButton.filledTonal(
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white.withOpacity(0.06),
                        ),
                        onPressed: () {
                          _showDiscardConfirmationDialog(context);
                        },
                        icon: const Icon(Icons.close, color: Colors.white),
                        iconSize: 24,
                      ),

                      // Pause / Resume (Glows!)
                      GestureDetector(
                        onTap: () {
                          if (recordingState.status ==
                              RecordingStatus.recording) {
                            ref.read(recordingProvider.notifier).pauseMeeting();
                          } else {
                            ref
                                .read(recordingProvider.notifier)
                                .resumeMeeting();
                          }
                        },
                        child: Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors:
                                  recordingState.status ==
                                      RecordingStatus.recording
                                  ? [AppColors.warning, const Color(0xFFF59E0B)]
                                  : [
                                      AppColors.success,
                                      const Color(0xFF10B981),
                                    ],
                            ),
                            boxShadow: AppTheme.neonGlow(
                              color:
                                  recordingState.status ==
                                      RecordingStatus.recording
                                  ? AppColors.warning
                                  : AppColors.success,
                              radius: 8,
                            ),
                          ),
                          child: Icon(
                            recordingState.status == RecordingStatus.recording
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                      ),

                      // Finish / Save
                      IconButton.filled(
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.primary,
                        ),
                        onPressed: () async {
                          await ref
                              .read(recordingProvider.notifier)
                              .stopMeeting();
                        },
                        icon: const Icon(Icons.check, color: Colors.white),
                        iconSize: 24,
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // --- TRANSCRIPT TAB ---
  Widget _buildLiveTranscriptTab(TranscriptState transcriptState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Horizontal chips row
        if (transcriptState.detectedChips.isNotEmpty) ...[
          SizedBox(
            height: 38,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: transcriptState.detectedChips.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final chip = transcriptState.detectedChips[index];
                return ActionChip(
                  avatar: Text(
                    chip.emoji,
                    style: const TextStyle(fontSize: 12),
                  ),
                  label: Text(
                    '${chip.type}: ${chip.value}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  backgroundColor: Colors.white.withOpacity(0.06),
                  side: const BorderSide(color: AppColors.border),
                  onPressed: () {},
                );
              },
            ),
          ),
          const SizedBox(height: 8),
        ],

        // Scroller list (Glass design)
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: AppTheme.glassBoxDecoration(
              opacity: 0.05,
              borderColor: AppColors.border,
            ),
            child:
                transcriptState.formattedSegments.isEmpty &&
                    transcriptState.currentSentence.isEmpty
                ? const Center(
                    child: Text(
                      'Speak now... Live formatted transcripts will appear here in batches.',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 13,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  )
                : ListView(
                    controller: _scrollController,
                    children: [
                      ...transcriptState.formattedSegments.map((seg) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: (seg.speaker ?? 1) % 2 == 0
                                      ? AppColors.primary.withOpacity(0.15)
                                      : AppColors.accent.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Speaker ${seg.speaker}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10,
                                    color: (seg.speaker ?? 1) % 2 == 0
                                        ? AppColors.accentLight
                                        : AppColors.accent,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  seg.text ?? '',
                                  style: const TextStyle(
                                    fontSize: 13.5,
                                    height: 1.45,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                      if (transcriptState.currentSentence.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Row(
                            children: [
                              const SizedBox(
                                width: 10,
                                height: 10,
                                child: CircularProgressIndicator(
                                  strokeWidth: 1.5,
                                  color: AppColors.accent,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  transcriptState.currentSentence,
                                  style: const TextStyle(
                                    fontSize: 13.5,
                                    fontStyle: FontStyle.italic,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  // --- LIVE SUMMARY TAB ---
  Widget _buildLiveSummaryTab(int? meetingId) {
    if (meetingId == null) return const SizedBox();
    final meetingDetail = ref.watch(meetingDetailsStreamProvider(meetingId));

    return meetingDetail.when(
      data: (meeting) {
        final summary = meeting?.summary.value?.executiveSummary ?? '';
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: AppTheme.glassBoxDecoration(
            opacity: 0.05,
            borderColor: AppColors.border,
          ),
          child: SingleChildScrollView(
            child: Text(
              summary.isEmpty
                  ? '📋 Live summary will automatically be generated in the background as the meeting continues...'
                  : summary,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13.5,
                height: 1.5,
              ),
            ),
          ),
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.accent),
      ),
      error: (_, __) =>
          const Center(child: Text('Failed to load live summary')),
    );
  }

  // --- LIVE TASKS TAB ---
  Widget _buildLiveTasksTab(int? meetingId) {
    if (meetingId == null) return const SizedBox();
    final meetingDetail = ref.watch(meetingDetailsStreamProvider(meetingId));

    return meetingDetail.when(
      data: (meeting) {
        final actions = meeting?.actionItems.toList() ?? [];
        final decisions = meeting?.decisions.toList() ?? [];

        if (actions.isEmpty && decisions.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(14),
            decoration: AppTheme.glassBoxDecoration(
              opacity: 0.05,
              borderColor: AppColors.border,
            ),
            alignment: Alignment.center,
            child: const Text(
              'Waiting for action items or key decisions to be detected...',
              style: TextStyle(color: AppColors.textMuted, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          );
        }

        return ListView(
          children: [
            if (decisions.isNotEmpty) ...[
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  '🎯 Key Decisions',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.accent,
                    fontSize: 14,
                  ),
                ),
              ),
              ...decisions.map(
                (d) => ListTile(
                  leading: const Icon(
                    Icons.check_circle_outline,
                    color: AppColors.accent,
                    size: 16,
                  ),
                  title: Text(
                    d.description ?? '',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
              ),
              const Divider(color: Colors.white10),
            ],
            if (actions.isNotEmpty) ...[
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  '📌 Action Items',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.accentLight,
                    fontSize: 14,
                  ),
                ),
              ),
              ...actions.map(
                (a) => ListTile(
                  leading: Icon(
                    Icons.assignment_turned_in_outlined,
                    color: a.priority == 'High'
                        ? AppColors.error
                        : AppColors.accentLight,
                    size: 16,
                  ),
                  title: Text(
                    a.description ?? '',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  subtitle: Text(
                    'Assignee: ${a.assignedTo ?? "Unassigned"} • Priority: ${a.priority}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textMuted,
                    ),
                  ),
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
              ),
            ],
          ],
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.accent),
      ),
      error: (_, __) => const Center(child: Text('Failed to load tasks')),
    );
  }

  // --- LIVE CHAT TAB ---
  Widget _buildLiveChatTab(int? meetingId) {
    if (meetingId == null) return const SizedBox();
    final chatState = ref.watch(meetingChatProvider(meetingId));

    ref.listen(meetingChatProvider(meetingId), (previous, next) {
      _scrollChatToBottom();
    });

    return Column(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: AppTheme.glassBoxDecoration(
              opacity: 0.05,
              borderColor: AppColors.border,
            ),
            child: chatState.when(
              data: (messages) {
                if (messages.isEmpty) {
                  return const Center(
                    child: Text(
                      'Ask AI questions about what has been said in this meeting so far.',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 13,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  );
                }
                return ListView.builder(
                  controller: _chatScrollController,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    return Align(
                      alignment: msg.isUser
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: msg.isUser
                              ? AppColors.primary.withOpacity(0.3)
                              : Colors.white.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: msg.isUser
                                ? AppColors.accent.withOpacity(0.2)
                                : AppColors.border,
                          ),
                        ),
                        child: Text(
                          msg.message ?? '',
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.accent),
              ),
              error: (_, __) =>
                  const Center(child: Text('Failed to load chat history')),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _chatTextController,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textPrimary,
                ),
                decoration: const InputDecoration(
                  hintText: 'Ask AI about this meeting...',
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                onFieldSubmitted: (val) {
                  if (val.trim().isEmpty) return;
                  ref
                      .read(meetingChatProvider(meetingId).notifier)
                      .sendMessage(val.trim());
                  _chatTextController.clear();
                },
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.send, color: AppColors.accent),
              onPressed: () {
                final txt = _chatTextController.text.trim();
                if (txt.isEmpty) return;
                ref
                    .read(meetingChatProvider(meetingId).notifier)
                    .sendMessage(txt);
                _chatTextController.clear();
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSummaryMetric(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: AppColors.textPrimary,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
        ),
      ],
    );
  }
}

class _PulsatingHeartIcon extends StatefulWidget {
  const _PulsatingHeartIcon();

  @override
  State<_PulsatingHeartIcon> createState() => _PulsatingHeartIconState();
}

class _PulsatingHeartIconState extends State<_PulsatingHeartIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
      lowerBound: 0.8,
      upperBound: 1.2,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _controller,
      child: const Icon(Icons.favorite, color: AppColors.error, size: 13),
    );
  }
}

/// Dynamic organic glowing orb painter representing ChatGPT
class ChatGPTVoiceOrb extends StatefulWidget {
  final bool isRecording;
  final double currentVolume;
  const ChatGPTVoiceOrb({
    super.key,
    required this.isRecording,
    required this.currentVolume,
  });

  @override
  State<ChatGPTVoiceOrb> createState() => _ChatGPTVoiceOrbState();
}

class _ChatGPTVoiceOrbState extends State<ChatGPTVoiceOrb>
    with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isRecording) {
      // Idle / Paused: breathing microphone icon
      return ScaleTransition(
        scale: Tween<double>(begin: 0.94, end: 1.06).animate(
          CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
        ),
        child: Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [AppColors.primary, AppColors.secondary],
            ),
            boxShadow: AppTheme.neonGlow(
              color: AppColors.secondary,
              radius: 16,
            ),
            border: Border.all(color: Colors.white30, width: 1.5),
          ),
          child: const Icon(
            Icons.mic_none_rounded,
            color: Colors.white,
            size: 36,
          ),
        ),
      );
    }

    // Active recording: overlapping rotating gradient circles pulsing with real volume
    return AnimatedBuilder(
      animation: _rotationController,
      builder: (context, child) {
        final double volumePulse =
            widget.currentVolume * 40.0; // Dynamic scale up to 40px

        return SizedBox(
          width: 130,
          height: 130,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer glow border
              Container(
                width: 90 + volumePulse,
                height: 90 + volumePulse,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withOpacity(0.12),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accent.withOpacity(
                        0.25 + (widget.currentVolume * 0.3),
                      ),
                      blurRadius: 20 + (widget.currentVolume * 24),
                      spreadRadius: 1 + (widget.currentVolume * 4),
                    ),
                  ],
                ),
              ),
              // Overlapping rotating sweep gradient 1
              Transform.rotate(
                angle: _rotationController.value * 2 * math.pi,
                child: Container(
                  width: 86 + (widget.currentVolume * 10),
                  height: 86 + (widget.currentVolume * 10),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: SweepGradient(
                      colors: [
                        AppColors.primary.withOpacity(0.6),
                        AppColors.accent.withOpacity(0.4),
                        AppColors.secondary.withOpacity(0.5),
                        AppColors.primary.withOpacity(0.6),
                      ],
                    ),
                  ),
                ),
              ),
              // Opposite rotating sweep gradient 2
              Transform.rotate(
                angle: -_rotationController.value * 2 * math.pi * 1.4,
                child: Container(
                  width: 76 + (widget.currentVolume * 6),
                  height: 76 + (widget.currentVolume * 6),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: SweepGradient(
                      colors: [
                        AppColors.secondary.withOpacity(0.5),
                        AppColors.accentLight.withOpacity(0.6),
                        AppColors.primary.withOpacity(0.4),
                        AppColors.secondary.withOpacity(0.5),
                      ],
                    ),
                  ),
                ),
              ),
              // Center microphone button
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.background,
                  border: Border.all(color: Colors.white24, width: 1.5),
                ),
                child: const Icon(
                  Icons.mic_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AnimatedWaveform extends StatelessWidget {
  final bool isActive;
  final List<double> volumeHistory;

  const _AnimatedWaveform({
    required this.isActive,
    required this.volumeHistory,
  });

  @override
  Widget build(BuildContext context) {
    const int totalBars = 25;
    final displayHistory = List<double>.filled(totalBars, 0.0);

    if (isActive && volumeHistory.isNotEmpty) {
      int startIdx = totalBars - volumeHistory.length;
      if (startIdx < 0) startIdx = 0;
      for (
        int i = 0;
        i < volumeHistory.length && (startIdx + i) < totalBars;
        i++
      ) {
        displayHistory[startIdx + i] = volumeHistory[i];
      }
    }

    return SizedBox(
      height: 36,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: List.generate(totalBars, (index) {
          final amplitude = displayHistory[index];
          final double height = isActive ? (amplitude * 28.0 + 4.0) : 4.0;

          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 2.0),
            width: 3.5,
            height: height,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.accent],
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
              ),
              borderRadius: BorderRadius.circular(2.0),
              boxShadow: [
                if (isActive && amplitude > 0.05)
                  BoxShadow(
                    color: AppColors.accent.withOpacity(0.35),
                    blurRadius: 4,
                    spreadRadius: 0.5,
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }
}
