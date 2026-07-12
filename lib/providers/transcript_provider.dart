import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/schemas/meeting_models.dart';
import '../providers/app_providers.dart';
import '../services/transcript_formatter.dart';
import '../services/llm_service.dart';

class SmartChip {
  final String
  type; // "Question", "Task", "Deadline", "Name", "Email", "Phone", "Link", "Action Item"
  final String value;
  final String emoji;

  SmartChip({required this.type, required this.value, required this.emoji});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SmartChip && type == other.type && value == other.value;

  @override
  int get hashCode => type.hashCode ^ value.hashCode;
}

class TranscriptState {
  final List<TranscriptSegmentModel> rawSegments;
  final List<TranscriptSegmentModel> formattedSegments;
  final List<SmartChip> detectedChips;
  final String currentSentence;
  final bool isFormatting;

  TranscriptState({
    this.rawSegments = const [],
    this.formattedSegments = const [],
    this.detectedChips = const [],
    this.currentSentence = '',
    this.isFormatting = false,
  });

  TranscriptState copyWith({
    List<TranscriptSegmentModel>? rawSegments,
    List<TranscriptSegmentModel>? formattedSegments,
    List<SmartChip>? detectedChips,
    String? currentSentence,
    bool? isFormatting,
  }) {
    return TranscriptState(
      rawSegments: rawSegments ?? this.rawSegments,
      formattedSegments: formattedSegments ?? this.formattedSegments,
      detectedChips: detectedChips ?? this.detectedChips,
      currentSentence: currentSentence ?? this.currentSentence,
      isFormatting: isFormatting ?? this.isFormatting,
    );
  }
}

class TranscriptNotifier extends StateNotifier<TranscriptState> {
  final Ref _ref;
  final List<TranscriptSegmentModel> _buffer = [];
  Timer? _batchTimer;
  int? _activeMeetingId;

  TranscriptNotifier(this._ref) : super(TranscriptState());

  void setMeetingId(int meetingId) {
    _activeMeetingId = meetingId;
    state = TranscriptState();
    _buffer.clear();
    _batchTimer?.cancel();
  }

  void reset() {
    _batchTimer?.cancel();
    _batchTimer = null;
    _buffer.clear();
    state = TranscriptState();
  }

  /// Handles incoming raw segments from Deepgram.
  void handleRawSegment(TranscriptSegmentModel segment, int meetingId) {
    _activeMeetingId = meetingId;

    // Add raw segment to state
    state = state.copyWith(
      rawSegments: [...state.rawSegments, segment],
      currentSentence: segment.text ?? '',
    );

    // Add to formatting buffer
    _buffer.add(segment);

    // Extract basic entities immediately using fast Regex
    _runFastRegexDetection(segment.text ?? '');

    // Reset/start batching timer (3-5 seconds)
    _batchTimer?.cancel();
    _batchTimer = Timer(const Duration(seconds: 4), () {
      _processBufferBatch();
    });
  }

  /// Flushes any pending buffered segments immediately.
  Future<void> flush() async {
    _batchTimer?.cancel();
    await _processBufferBatch();
  }

  /// Process the current buffered text segments using LLM formatting
  Future<void> _processBufferBatch() async {
    if (_buffer.isEmpty || _activeMeetingId == null) return;

    final batchToFormat = List<TranscriptSegmentModel>.from(_buffer);
    _buffer.clear();

    state = state.copyWith(isFormatting: true);

    try {
      final formatter = _ref.read(transcriptFormatterProvider);
      final formatted = await formatter.formatTranscriptSegments(batchToFormat);

      // Save formatted segments to Isar repository
      final meetingRepo = _ref.read(meetingRepositoryProvider);
      for (final segment in formatted) {
        await meetingRepo.addTranscriptSegment(_activeMeetingId!, segment);
      }

      // Add to formatted segments in state
      state = state.copyWith(
        formattedSegments: [...state.formattedSegments, ...formatted],
        currentSentence: '',
      );

      // Perform deeper semantic analysis on formatted text for Smart Chips
      final combinedText = formatted.map((e) => e.text).join(' ');
      _runLlmEntityDetection(combinedText);
    } catch (e) {
      print('[TranscriptNotifier ERROR] Batch formatting failed: $e');
    } finally {
      state = state.copyWith(isFormatting: false);
    }
  }

  /// Fast regex-based detection for emails, phone numbers, and links
  void _runFastRegexDetection(String text) {
    final chips = <SmartChip>[];

    // Emails
    final emailExp = RegExp(
      r'[a-zA-Z0-9+_.-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}',
      caseSensitive: false,
    );
    for (final match in emailExp.allMatches(text)) {
      final matchStr = match.group(0);
      if (matchStr != null) {
        chips.add(SmartChip(type: 'Email', value: matchStr, emoji: '📧'));
      }
    }

    // Phone numbers (simplified)
    final phoneExp = RegExp(r'\b\d{3}[-.]?\d{3}[-.]?\d{4}\b');
    for (final match in phoneExp.allMatches(text)) {
      final matchStr = match.group(0);
      if (matchStr != null) {
        chips.add(SmartChip(type: 'Phone', value: matchStr, emoji: '📞'));
      }
    }

    // Links
    final linkExp = RegExp(
      r'https?:\/\/(?:www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b(?:[-a-zA-Z0-9()@:%_\+.~#?&/=]*)',
      caseSensitive: false,
    );
    for (final match in linkExp.allMatches(text)) {
      final matchStr = match.group(0);
      if (matchStr != null) {
        chips.add(SmartChip(type: 'Link', value: matchStr, emoji: '🔗'));
      }
    }

    // Update chips in state without duplicates
    if (chips.isNotEmpty) {
      final currentChips = List<SmartChip>.from(state.detectedChips);
      for (final newChip in chips) {
        if (!currentChips.any((c) => c.value == newChip.value)) {
          currentChips.add(newChip);
        }
      }
      state = state.copyWith(detectedChips: currentChips);
    }
  }

  /// Semantic LLM-based detection of questions, tasks, deadlines, action items, names
  Future<void> _runLlmEntityDetection(String text) async {
    final llmService = _ref.read(llmServiceProvider);

    final prompt =
        '''
Analyze this formatted transcript chunk and extract:
1. Names mentioned (e.g. Sonia, Rahul).
2. Questions raised (direct or indirect questions).
3. Deadlines (dates, times, weekdays).
4. Action Items / Tasks.

Return ONLY a JSON block like this:
{
  "names": ["Sonia", "Rahul"],
  "questions": ["What is the project budget?"],
  "deadlines": ["Friday morning"],
  "actionItems": ["Rahul to fix authentication"]
}
If nothing is found, return empty lists.

Transcript Chunk:
$text
''';

    try {
      final json = await llmService.getJsonCompletion(
        prompt: prompt,
        systemInstruction:
            'You are a precise data extractor. Extract only what is explicitly mentioned in the text.',
      );

      final chips = <SmartChip>[];

      final names = json['names'] as List?;
      if (names != null) {
        for (final val in names) {
          chips.add(
            SmartChip(type: 'Name', value: val.toString(), emoji: '👤'),
          );
        }
      }

      final questions = json['questions'] as List?;
      if (questions != null) {
        for (final val in questions) {
          chips.add(
            SmartChip(type: 'Question', value: val.toString(), emoji: '❓'),
          );
        }
      }

      final deadlines = json['deadlines'] as List?;
      if (deadlines != null) {
        for (final val in deadlines) {
          chips.add(
            SmartChip(type: 'Deadline', value: val.toString(), emoji: '📅'),
          );
        }
      }

      final actionItems = json['actionItems'] as List?;
      if (actionItems != null) {
        for (final val in actionItems) {
          chips.add(
            SmartChip(type: 'Action Item', value: val.toString(), emoji: '📌'),
          );
        }
      }

      if (chips.isNotEmpty) {
        final currentChips = List<SmartChip>.from(state.detectedChips);
        for (final newChip in chips) {
          if (!currentChips.any(
            (c) => c.value == newChip.value && c.type == newChip.type,
          )) {
            currentChips.add(newChip);
          }
        }
        state = state.copyWith(detectedChips: currentChips);
      }
    } catch (_) {}
  }
}

final transcriptProvider =
    StateNotifierProvider<TranscriptNotifier, TranscriptState>((ref) {
      return TranscriptNotifier(ref);
    });
