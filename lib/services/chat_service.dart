import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/schemas/meeting_models.dart';
import '../providers/app_providers.dart';
import 'llm_service.dart';

class ChatService {
  final Ref _ref;

  ChatService(this._ref);

  LLMService get _llmService => _ref.read(llmServiceProvider);

  /// Answers a question about a specific meeting using transcript-based RAG.
  Future<String> askAboutMeeting({
    required int meetingId,
    required String question,
    required List<ChatMessageModel> chatHistory,
  }) async {
    final meetingRepo = _ref.read(meetingRepositoryProvider);
    final meeting = await meetingRepo.getMeetingById(meetingId);
    if (meeting == null) {
      throw Exception('Meeting not found.');
    }

    final transcript = meeting.transcript.value;
    final segments = transcript != null
        ? transcript.segments.toList()
        : <TranscriptSegmentModel>[];
    if (segments.isEmpty) {
      return 'No transcript is available for this meeting to search.';
    }

    // Determine context size
    final fullTextList = segments.map((e) {
      final speakerName =
          e.speakerProfile.value?.name ?? 'Speaker ${e.speaker}';
      return '$speakerName: ${e.text}';
    }).toList();

    final String fullTranscript = fullTextList.join('\n');
    String ragContext = '';

    // If transcript is reasonably small (less than 4,000 words), pass full transcript to LLM
    if (fullTranscript.split(RegExp(r'\s+')).length <= 4000) {
      ragContext = fullTranscript;
    } else {
      // Perform simple local TF-IDF / keyword similarity matching for large transcripts
      ragContext = _retrieveRelevantContext(fullTextList, question);
    }

    final systemInstruction = '''
You are a helpful meeting assistant.
Answer the user's question about the meeting using ONLY the provided Meeting Context below.
Rules:
- Rely ONLY on the facts explicitly mentioned in the context.
- If the answer cannot be found in the context, reply: "I couldn't find the answer to that in the meeting transcript."
- Do NOT make assumptions or extrapolate. Keep the answer concise and direct.
''';

    final prompt =
        '''
Meeting Context:
----------------------
$ragContext
----------------------

Chat History:
${chatHistory.map((m) => '${m.isUser ? "User" : "AI"}: ${m.message}').join('\n')}

Question: $question
Answer:
''';

    return await _llmService.getCompletion(
      prompt: prompt,
      systemInstruction: systemInstruction,
    );
  }

  /// Splits the text list into chunks and scores them based on overlap with query tokens
  String _retrieveRelevantContext(List<String> transcriptLines, String query) {
    final queryTokens = query
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), '')
        .split(RegExp(r'\s+'))
        .where((t) => t.length > 2 && !_commonStopwords.contains(t))
        .toList();

    if (queryTokens.isEmpty) {
      // Fallback to first 40 lines if search query has no keywords
      return transcriptLines.take(40).join('\n');
    }

    // Group transcript into chunks of 5 lines
    final chunks = <List<String>>[];
    for (int i = 0; i < transcriptLines.length; i += 5) {
      chunks.add(transcriptLines.skip(i).take(5).toList());
    }

    final scoredChunks = <_ScoredChunk>[];
    for (final chunk in chunks) {
      final chunkText = chunk.join(' ').toLowerCase();
      double score = 0;
      for (final token in queryTokens) {
        if (chunkText.contains(token)) {
          score += 1.0;
        }
      }
      scoredChunks.add(_ScoredChunk(chunk, score));
    }

    // Sort by score descending
    scoredChunks.sort((a, b) => b.score.compareTo(a.score));

    // Take top 6 scored chunks and sort them chronologically (by their original order)
    final topChunks = scoredChunks.take(6).where((c) => c.score > 0).toList();
    if (topChunks.isEmpty) {
      // If no match found, fallback to first 30 lines
      return transcriptLines.take(30).join('\n');
    }

    // Find original indexes to sort chronologically
    final chronologicalChunks = <List<String>>[];
    for (final chunk in chunks) {
      if (topChunks.any((tc) => tc.lines == chunk)) {
        chronologicalChunks.add(chunk);
      }
    }

    return chronologicalChunks.expand((c) => c).join('\n');
  }

  static const _commonStopwords = {
    'the',
    'is',
    'at',
    'which',
    'on',
    'what',
    'who',
    'how',
    'why',
    'where',
    'this',
    'that',
    'these',
    'those',
    'there',
    'their',
    'them',
    'they',
    'you',
    'your',
    'and',
    'but',
    'for',
    'with',
    'about',
    'from',
    'into',
    'under',
    'over',
    'again',
    'then',
    'once',
    'here',
    'when',
    'both',
    'each',
    'few',
    'more',
    'most',
    'some',
  };
}

class _ScoredChunk {
  final List<String> lines;
  final double score;
  _ScoredChunk(this.lines, this.score);
}

final chatServiceProvider = Provider<ChatService>((ref) => ChatService(ref));
