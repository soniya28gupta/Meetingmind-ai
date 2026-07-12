import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/schemas/meeting_models.dart';
import 'llm_service.dart';

class TranscriptFormatter {
  final Ref _ref;

  TranscriptFormatter(this._ref);

  LLMService get _llmService => _ref.read(llmServiceProvider);

  /// Cleans and formats a batch of segments using the LLM.
  /// Prepresses speaker tags to maintain speaker turns.
  Future<List<TranscriptSegmentModel>> formatTranscriptSegments(
    List<TranscriptSegmentModel> rawSegments,
  ) async {
    if (rawSegments.isEmpty) return [];

    // Compile the input turns
    final promptBuffer = StringBuffer();
    for (int i = 0; i < rawSegments.length; i++) {
      final seg = rawSegments[i];
      promptBuffer.writeln('Turn $i | Speaker ${seg.speaker}: ${seg.text}');
    }

    final systemInstruction = '''
You are a professional audio transcript formatting engine.
Your task is to fix grammar, add punctuation, capitalize sentences, remove filler words (like "um", "ah", "like", "you know", "so", "actually"), and merge broken sentences.

Instructions:
- Keep the exact same turn identifier prefix `Turn X | Speaker Y:` at the start of each line.
- Do NOT combine lines or turns. Output exactly one line per input line.
- Preserve the exact meaning. Do not add new information or summarize.
- If a turn contains only noise or filler words that are deleted, output the prefix followed by a single space or hyphen, but do not delete the line itself.
''';

    try {
      final completion = await _llmService.getCompletion(
        prompt: promptBuffer.toString().trim(),
        systemInstruction: systemInstruction,
      );

      final lines = completion.split('\n');
      final Map<int, String> indexToFormattedText = {};

      for (final line in lines) {
        final match = RegExp(
          r'^Turn\s+(\d+)\s*\|\s*Speaker\s+\d+\s*:\s*(.*)$',
          caseSensitive: false,
        ).firstMatch(line.trim());
        if (match != null) {
          final index = int.tryParse(match.group(1) ?? '');
          final text = match.group(2)?.trim() ?? '';
          if (index != null) {
            indexToFormattedText[index] = text;
          }
        }
      }

      // Reconstruct and update the segments
      final List<TranscriptSegmentModel> formattedSegments = [];
      for (int i = 0; i < rawSegments.length; i++) {
        final raw = rawSegments[i];
        final cleanText = indexToFormattedText[i] ?? raw.text ?? '';

        final formattedSeg = TranscriptSegmentModel()
          ..id = raw.id
          ..speaker = raw.speaker
          ..startTime = raw.startTime
          ..endTime = raw.endTime
          ..text = cleanText.isEmpty ? (raw.text ?? '') : cleanText;

        // Retain speaker profile link if available
        if (raw.speakerProfile.value != null) {
          formattedSeg.speakerProfile.value = raw.speakerProfile.value;
        }

        formattedSegments.add(formattedSeg);
      }

      return formattedSegments;
    } catch (e) {
      print(
        '[TranscriptFormatter ERROR] Formatting batch failed: $e. Falling back to raw segments.',
      );
      return rawSegments;
    }
  }
}

final transcriptFormatterProvider = Provider<TranscriptFormatter>(
  (ref) => TranscriptFormatter(ref),
);
