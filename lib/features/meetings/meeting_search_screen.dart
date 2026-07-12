import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:isar/isar.dart';
import '../../core/theme/app_theme.dart';
import '../../database/isar_database.dart';
import '../../database/schemas/meeting_models.dart';
import '../../widgets/glass_card.dart';
import 'meeting_details_screen.dart';

class MeetingSearchScreen extends ConsumerStatefulWidget {
  const MeetingSearchScreen({super.key});

  @override
  ConsumerState<MeetingSearchScreen> createState() =>
      _MeetingSearchScreenState();
}

class _MeetingSearchScreenState extends ConsumerState<MeetingSearchScreen> {
  final _searchController = TextEditingController();
  List<_SearchResult> _results = [];
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _results = [];
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
      final isar = IsarDatabase.instance.isar;
      final qLower = query.toLowerCase().trim();

      // Retrieve all meetings to search transcripts
      final meetings = await isar.meetingModels
          .where()
          .sortByCreatedAtDesc()
          .findAll();
      final List<_SearchResult> matches = [];

      for (final meeting in meetings) {
        await meeting.transcript.load();
        final transcript = meeting.transcript.value;
        if (transcript == null) continue;

        await transcript.segments.load();
        final segments = transcript.segments.toList();

        for (final segment in segments) {
          final text = segment.text ?? '';
          if (text.toLowerCase().contains(qLower)) {
            await segment.speakerProfile.load();
            final profile = segment.speakerProfile.value;
            final speakerName = profile?.name ?? 'Speaker ${segment.speaker}';

            matches.add(
              _SearchResult(
                meeting: meeting,
                segment: segment,
                speakerName: speakerName,
                speakerEmoji: profile?.avatarEmoji ?? '👤',
                speakerColor: Color(profile?.colorValue ?? 0xFF9C27B0),
              ),
            );
          }
        }
      }

      setState(() {
        _results = matches;
      });
    } catch (e) {
      print('Search failed: $e');
    } finally {
      setState(() {
        _isSearching = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Search Previous Meetings',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: FuturisticBackground(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Search Input
              TextFormField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search "Firebase", "Deadline", "Rahul"...',
                  prefixIcon: const Icon(
                    Icons.search,
                    color: AppColors.textMuted,
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            _performSearch('');
                          },
                        )
                      : null,
                ),
                onChanged: _performSearch,
              ),
              const SizedBox(height: 20),

              // Search Results or states
              Expanded(
                child: _isSearching
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.secondary,
                        ),
                      )
                    : _results.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _searchController.text.isEmpty
                                  ? Icons.search_rounded
                                  : Icons.sentiment_dissatisfied_rounded,
                              color: AppColors.textMuted,
                              size: 48,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _searchController.text.isEmpty
                                  ? 'Enter keywords to search across meetings'
                                  : 'No matching sentences or speakers found',
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        itemCount: _results.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final res = _results[index];
                          final startMin = (res.segment.startTime / 60).toInt();
                          final startSec = (res.segment.startTime % 60)
                              .toInt()
                              .toString()
                              .padLeft(2, '0');
                          final timestamp = '$startMin:$startSec';
                          final dateStr = res.meeting.createdAt != null
                              ? DateFormat(
                                  'MMM dd, yyyy',
                                ).format(res.meeting.createdAt!)
                              : '';

                          return InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => MeetingDetailsScreen(
                                    meetingId: res.meeting.id,
                                  ),
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: GlassCard(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // Meeting Title / Date header
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          res.meeting.title ??
                                              'Untitled Meeting',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                            color: AppColors.secondary,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Text(
                                        dateStr,
                                        style: const TextStyle(
                                          color: AppColors.textMuted,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),

                                  // Speaker / Timestamp
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 10,
                                        backgroundColor: res.speakerColor
                                            .withValues(alpha: 0.15),
                                        child: Text(
                                          res.speakerEmoji,
                                          style: const TextStyle(fontSize: 10),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        res.speakerName,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: res.speakerColor,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '[$timestamp]',
                                        style: const TextStyle(
                                          fontFamily: 'monospace',
                                          color: AppColors.textMuted,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),

                                  // Matching Sentence Text
                                  Text(
                                    res.segment.text ?? '',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      height: 1.4,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchResult {
  final MeetingModel meeting;
  final TranscriptSegmentModel segment;
  final String speakerName;
  final String speakerEmoji;
  final Color speakerColor;

  _SearchResult({
    required this.meeting,
    required this.segment,
    required this.speakerName,
    required this.speakerEmoji,
    required this.speakerColor,
  });
}
