import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/schemas/meeting_models.dart';
import 'llm_service.dart';

class MeetingAIService {
  final Ref _ref;

  MeetingAIService(this._ref);

  LLMService get _llmService => _ref.read(llmServiceProvider);

  /// Generates the full meeting analysis structure from the transcript text.
  Future<Map<String, dynamic>> generateMeetingAnalysis(
    String fullTranscript,
  ) async {
    if (fullTranscript.trim().isEmpty) {
      throw Exception('Transcript is empty. Cannot generate meeting analysis.');
    }

    final prompt =
        '''
Analyze the following meeting transcript and extract a detailed summary and metadata:
1. Executive Summary: A concise overview paragraph.
2. Key Decisions: Major agreements or resolutions.
3. Action Items: List of specific tasks with assignee, deadline, and priority (High, Medium, Low).
4. Risks & Concerns: Roadblocks, risks, or conflicts.
5. Next Steps: Future tasks or phases.
6. Important Dates & Deadlines: Critical dates mentioned.
7. Questions Raised: Questions asked by speakers.
8. Open Issues: Items left unresolved.

Return your response ONLY as a JSON block with this exact structure:
{
  "executiveSummary": "Concise summary...",
  "meetingNotes": "Detailed meeting notes as bullet points...",
  "keyTakeaways": "Key takeaways or highlights...",
  "decisions": [
    "Decision 1...",
    "Decision 2..."
  ],
  "actionItems": [
    {
      "task": "Task description",
      "assignee": "Name",
      "deadline": "Date/Time or weekday",
      "priority": "High/Medium/Low"
    }
  ],
  "risks": "Risks or roadblocks...",
  "nextSteps": "Next steps...",
  "importantDates": "Important dates & deadlines...",
  "questionsRaised": "Questions raised...",
  "openIssues": "Open unresolved issues..."
}

Transcript:
$fullTranscript
''';

    try {
      final json = await _llmService.getJsonCompletion(
        prompt: prompt,
        systemInstruction:
            'You are a professional meeting minutes generator. Extract details with maximum precision. Do not hallucinate or change names.',
      );

      // Structure into SummaryModel
      final summary = SummaryModel();

      // We fold the additional AI details into the existing schema text fields gracefully:
      final String execSummary = (json['executiveSummary'] ?? '').toString();
      final String questions = (json['questionsRaised'] ?? '').toString();
      final String openIssues = (json['openIssues'] ?? '').toString();

      // Fold questions & open issues into executiveSummary
      final execSummaryBuf = StringBuffer(execSummary);
      if (questions.isNotEmpty) {
        execSummaryBuf.writeln('\n\n❓ Questions Raised:\n$questions');
      }
      if (openIssues.isNotEmpty) {
        execSummaryBuf.writeln('\n\n⚠️ Open Issues:\n$openIssues');
      }
      summary.executiveSummary = execSummaryBuf.toString().trim();

      summary.meetingNotes = (json['meetingNotes'] ?? '').toString();
      summary.keyTakeaways = (json['keyTakeaways'] ?? '').toString();

      // Fold next steps into followUps
      final String nextSteps = (json['nextSteps'] ?? '').toString();
      summary.followUps = nextSteps.isNotEmpty
          ? '🚀 Next Steps:\n$nextSteps'
          : '';

      summary.risks = (json['risks'] ?? '').toString();

      // Fold important dates into deadlines
      final String importantDates = (json['importantDates'] ?? '').toString();
      summary.deadlines = importantDates;

      // Extract Action Items list
      final actionItemsList = <ActionItemModel>[];
      final actionItemsRaw = json['actionItems'];
      if (actionItemsRaw is List) {
        for (final item in actionItemsRaw) {
          if (item is Map) {
            final task = (item['task'] ?? '').toString();
            if (task.isNotEmpty) {
              final assignee = (item['assignee'] ?? 'Unassigned').toString();
              final deadlineStr = (item['deadline'] ?? '').toString();
              final priority = (item['priority'] ?? 'Medium').toString();

              final parsedDeadline = _parseDeadlineDate(deadlineStr);

              actionItemsList.add(
                ActionItemModel()
                  ..description = task
                  ..assignedTo = assignee
                  ..deadline = parsedDeadline
                  ..priority = priority
                  ..isCompleted = false,
              );
            }
          }
        }
      }

      // Extract Decisions list
      final decisionsList = <DecisionModel>[];
      final decisionsRaw = json['decisions'];
      if (decisionsRaw is List) {
        for (final item in decisionsRaw) {
          final desc = item.toString().trim();
          if (desc.isNotEmpty) {
            decisionsList.add(DecisionModel()..description = desc);
          }
        }
      }

      return {
        'summary': summary,
        'actionItems': actionItemsList,
        'decisions': decisionsList,
      };
    } catch (e) {
      print('[MeetingAIService ERROR] Analysis generation failed: $e');
      rethrow;
    }
  }

  DateTime? _parseDeadlineDate(String deadlineStr) {
    if (deadlineStr.isEmpty) return null;
    final lower = deadlineStr.toLowerCase().trim();
    final now = DateTime.now();

    if (lower == 'today') {
      return DateTime(now.year, now.month, now.day);
    }
    if (lower == 'tomorrow') {
      final tomorrow = now.add(const Duration(days: 1));
      return DateTime(tomorrow.year, tomorrow.month, tomorrow.day);
    }
    if (lower == 'next week') {
      final nextWeek = now.add(const Duration(days: 7));
      return DateTime(nextWeek.year, nextWeek.month, nextWeek.day);
    }

    final weekdays = {
      'monday': DateTime.monday,
      'tuesday': DateTime.tuesday,
      'wednesday': DateTime.wednesday,
      'thursday': DateTime.thursday,
      'friday': DateTime.friday,
      'saturday': DateTime.saturday,
      'sunday': DateTime.sunday,
    };

    for (final entry in weekdays.entries) {
      if (lower == entry.key) {
        int daysToAdd = entry.value - now.weekday;
        if (daysToAdd <= 0) daysToAdd += 7;
        final target = now.add(Duration(days: daysToAdd));
        return DateTime(target.year, target.month, target.day);
      }
    }

    return DateTime.tryParse(deadlineStr);
  }
}

final meetingAiServiceProvider = Provider<MeetingAIService>(
  (ref) => MeetingAIService(ref),
);
