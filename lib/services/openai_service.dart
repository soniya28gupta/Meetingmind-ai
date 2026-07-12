import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/config/app_config.dart';
import '../database/schemas/meeting_models.dart';
import '../features/settings/settings_provider.dart';
import '../providers/app_providers.dart';

class OpenAIService {
  final Ref? _ref;

  OpenAIService([this._ref]);

  Dio get _dio {
    if (_ref != null) {
      return _ref.read(dioProvider);
    }
    return Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 120),
        sendTimeout: const Duration(seconds: 120),
      ),
    );
  }

  String get _ollamaBaseUrl {
    if (_ref != null) {
      final url = _ref.read(settingsProvider).ollamaUrl;
      if (url.isNotEmpty) return url;
    }
    return AppConfig.ollamaBaseUrl;
  }

  String get _ollamaModel {
    if (_ref != null) {
      final model = _ref.read(settingsProvider).ollamaModel;
      if (model.isNotEmpty) return model;
    }
    return 'qwen2.5:7b';
  }

  Future<String> _findWorkingOllamaUrl() async {
    return _ollamaBaseUrl;
  }

  /// Helper method to make POST request with retry logic (up to 3 times)
  Future<Response> _postWithRetry(
    String path, {
    required Map<String, dynamic> data,
  }) async {
    final activeBaseUrl = await _findWorkingOllamaUrl();

    int retryCount = 0;
    const int maxRetries = 3;
    Duration delay = const Duration(seconds: 2);
    final String url = '$activeBaseUrl$path';

    while (true) {
      final startTime = DateTime.now();
      print("===== OLLAMA REQUEST START =====");
      print("Ollama URL: $url");
      print("Request Start Time: $startTime");
      print("Payload: $data");
      print("Attempt: ${retryCount + 1} / $maxRetries");

      try {
        final response = await _dio.post(
          url,
          options: Options(
            headers: {'Content-Type': 'application/json'},
            connectTimeout: const Duration(seconds: 20),
            receiveTimeout: const Duration(seconds: 120),
            sendTimeout: const Duration(seconds: 120),
          ),
          data: data,
        );

        final endTime = DateTime.now();
        print("===== OLLAMA REQUEST SUCCESS =====");
        print("Ollama URL: $url");
        print("Request End Time: $endTime");
        print("Duration: ${endTime.difference(startTime).inMilliseconds} ms");
        print("Response Status: ${response.statusCode}");
        print("Response Body:\n${response.data}");
        return response;
      } catch (e) {
        final endTime = DateTime.now();
        print("===== OLLAMA REQUEST FAILURE =====");
        print("Ollama URL: $url");
        print("Request End Time: $endTime");
        print("Duration: ${endTime.difference(startTime).inMilliseconds} ms");
        print("Error Details: $e");

        retryCount++;
        if (retryCount >= maxRetries) {
          throw _parseDioErrorCustom(e, activeBaseUrl);
        }
        print(
          "[Ollama Connection Retry] Waiting ${delay.inSeconds}s before next attempt...",
        );
        await Future.delayed(delay);
        delay = delay * 2;
      }
    }
  }

  /// Parses raw exception/DioError to user-friendly error messages
  Exception _parseDioErrorCustom(dynamic error, String activeUrl) {
    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
          return Exception(
            'Connection timed out. Ensure the Ollama server is running at $activeUrl and accessible.',
          );
        case DioExceptionType.sendTimeout:
          return Exception(
            'Failed to send data to the server at $activeUrl. Please check your network.',
          );
        case DioExceptionType.receiveTimeout:
          return Exception(
            'The Ollama server at $activeUrl took too long to respond. The model might still be loading or generating.',
          );
        case DioExceptionType.badResponse:
          final statusCode = error.response?.statusCode;
          return Exception(
            'Server at $activeUrl returned an error status ($statusCode). Please verify the server state.',
          );
        case DioExceptionType.cancel:
          return Exception('The request to $activeUrl was cancelled.');
        case DioExceptionType.connectionError:
          return Exception(
            'Cannot connect to the Ollama server at $activeUrl. Verify the IP address, running status, and network connection.',
          );
        default:
          if (error.error is SocketException) {
            return Exception(
              'Network connection error at $activeUrl: ${error.error}. Please check local network connectivity.',
            );
          }
          return Exception('API error at $activeUrl: ${error.message}');
      }
    }
    return Exception(error.toString());
  }

  String _sanitizeJsonString(String jsonStr) {
    final buf = StringBuffer();
    bool inQuote = false;
    bool escape = false;
    for (int i = 0; i < jsonStr.length; i++) {
      final char = jsonStr[i];
      if (escape) {
        buf.write(char);
        escape = false;
        continue;
      }
      if (char == '\\') {
        buf.write(char);
        escape = true;
        continue;
      }
      if (char == '"') {
        inQuote = !inQuote;
        buf.write(char);
        continue;
      }
      if (char == '\n' && inQuote) {
        buf.write('\\n');
      } else if (char == '\r' && inQuote) {
        buf.write('\\r');
      } else {
        buf.write(char);
      }
    }
    return buf.toString();
  }

  /// Robust extraction of JSON from response content, supporting markdown code blocks.
  Map<String, dynamic> _extractJson(String content) {
    var cleaned = content.trim();

    // 1. Strip markdown wrapper tags if present
    if (cleaned.startsWith('```')) {
      final firstNewline = cleaned.indexOf('\n');
      if (firstNewline != -1) {
        cleaned = cleaned.substring(firstNewline + 1);
      } else {
        cleaned = cleaned.substring(3);
      }
    }
    if (cleaned.endsWith('```')) {
      cleaned = cleaned.substring(0, cleaned.length - 3);
    }
    cleaned = cleaned.trim();

    if (cleaned.toLowerCase().startsWith('json')) {
      cleaned = cleaned.substring(4).trim();
    }

    // Attempt 1: Direct JSON parsing
    try {
      final sanitized = _sanitizeJsonString(cleaned);
      return jsonDecode(sanitized) as Map<String, dynamic>;
    } catch (_) {}

    // Attempt 2: Try to locate a JSON object pattern ({...}) inside the response
    final int firstBrace = cleaned.indexOf('{');
    final int lastBrace = cleaned.lastIndexOf('}');
    if (firstBrace != -1 && lastBrace != -1 && lastBrace > firstBrace) {
      final String jsonCandidate = cleaned.substring(firstBrace, lastBrace + 1);
      try {
        final sanitizedCandidate = _sanitizeJsonString(jsonCandidate);
        return jsonDecode(sanitizedCandidate) as Map<String, dynamic>;
      } catch (_) {}
    }

    // Attempt 3: Regex match markdown code block ```json ... ``` or ``` ... ```
    final RegExp exp = RegExp(r'```(?:json)?\s*(\{[\s\S]*?\})\s*```');
    final Match? match = exp.firstMatch(cleaned);
    if (match != null && match.groupCount >= 1) {
      final String? group = match.group(1);
      if (group != null) {
        try {
          final sanitizedGroup = _sanitizeJsonString(group.trim());
          return jsonDecode(sanitizedGroup) as Map<String, dynamic>;
        } catch (_) {}
      }
    }

    throw const FormatException(
      'Could not parse a valid JSON response from the Ollama model.',
    );
  }

  /// Generates a structured summary, list of action items, and decisions from the transcript
  Future<Map<String, dynamic>> generateMeetingAnalysis({
    required String fullTranscript,
  }) async {
    try {
      final activeBaseUrl = await _findWorkingOllamaUrl();
      print("===== OLLAMA REQUEST =====");
      print("Ollama URL: $activeBaseUrl");
      print("Model name: $_ollamaModel");
      print("Transcript length: ${fullTranscript.length}");
      print(
        "Transcript content preview: ${fullTranscript.substring(0, fullTranscript.length > 200 ? 200 : fullTranscript.length)}...",
      );

      final requestData = {
        'model': _ollamaModel,
        'prompt':
            '''
Analyze this meeting transcript and extract:
1. Executive Summary: A very concise summary paragraph under the key "summary". It MUST start with: "📋 Meeting Summary".
2. Detailed Notes: Detailed notes of the meeting under the key "meetingNotes" as bullet points.
3. Speaker Key Takeaways: Speaker-specific key points and observations under the key "keyTakeaways". Format them clearly with emoji speaker names (e.g. 👤 Speaker 1:\n- Point 1\n- Point 2).
4. Risks & Concerns: Risks, roadblocks, or concerns under the key "risks" as bullet points.
5. Deadlines & Milestones: Dates, deadlines, and milestones mentioned under the key "deadlines" as bullet points.
6. Action Items: List of action items under the key "actionItems", containing "task", "assignee", "deadline", "priority", "status" (set to "pending").
7. Key Decisions: List of key decisions under the key "decisions" as simple string descriptions.

Return your response ONLY as a valid JSON block matching this structure:
{
  "summary": "📋 Meeting Summary\\n• Main discussion point.\\n• Key decision made.\\n• Important outcome achieved.",
  "meetingNotes": "• Note 1.\\n• Note 2.",
  "keyTakeaways": "👤 Speaker 1:\\n- Key point 1.\\n👤 Speaker 2:\\n- Key point 2.",
  "risks": "• Risk 1.\\n• Risk 2.",
  "deadlines": "• Deadline 1.\\n• Deadline 2.",
  "actionItems": [
    {
      "task": "Submit the final report",
      "assignee": "Sonia",
      "deadline": "Friday",
      "priority": "High",
      "status": "pending"
    }
  ],
  "decisions": [
    "Approved project budget"
  ]
}

Do NOT output any markdown wrappers outside of the JSON block itself. Return ONLY the JSON object.

Transcript:
$fullTranscript
''',
        'stream': false,
      };
      print("Request payload: $requestData");

      final response = await _postWithRetry('/api/generate', data: requestData);

      print("Response status code: ${response.statusCode}");
      print("Response body:\n${response.data}");

      if (response.statusCode != 200) {
        throw Exception('Server returned status ${response.statusCode}');
      }

      final content = response.data['response'] as String?;
      if (content == null || content.isEmpty) {
        throw Exception('Server returned an empty response.');
      }

      print("===== OLLAMA RESPONSE RECEIVED =====");

      Map<String, dynamic> jsonResult;
      try {
        jsonResult = _extractJson(content);
        print("===== JSON DECODED SUCCESSFULLY =====");
      } catch (jsonErr) {
        print(
          "[Ollama JSON Error] Failed to parse JSON from response. Exact response content was:\n$content",
        );
        throw Exception(
          'Ollama response returned invalid JSON formatting: $jsonErr. Exact response content was:\n$content',
        );
      }

      // Robust fallback parsing
      final rawSummaryText =
          (jsonResult['summary'] ?? jsonResult['executiveSummary'] ?? '')
              .toString();
      final summary = SummaryModel()
        ..executiveSummary = rawSummaryText
        ..meetingNotes = (jsonResult['meetingNotes'] ?? '').toString()
        ..keyTakeaways = (jsonResult['keyTakeaways'] ?? '').toString()
        ..risks = (jsonResult['risks'] ?? '').toString()
        ..deadlines = (jsonResult['deadlines'] ?? '').toString();

      final actionItemsList = <ActionItemModel>[];
      if (jsonResult['actionItems'] is List) {
        for (final item in jsonResult['actionItems']) {
          if (item is Map) {
            final taskStr = (item['task'] ?? item['description'])?.toString();
            if (taskStr != null && taskStr.isNotEmpty) {
              final deadlineStr = item['deadline']?.toString();
              DateTime? deadline;
              if (deadlineStr != null && deadlineStr.trim().isNotEmpty) {
                deadline = _parseSmartDeadline(deadlineStr);
              }

              // Priority auto-classification rules
              var priorityStr = item['priority']?.toString() ?? 'Medium';
              final taskLower = taskStr.toLowerCase();
              final deadlineLower = (deadlineStr ?? '').toLowerCase();
              if (taskLower.contains('urgent') ||
                  taskLower.contains('asap') ||
                  taskLower.contains('today') ||
                  deadlineLower.contains('today')) {
                priorityStr = 'High';
              }

              final assigneeStr = (item['assignee'] ?? item['assignedTo'])
                  ?.toString();
              final statusStr = item['status']?.toString() ?? 'pending';
              final isCompleted =
                  statusStr.toLowerCase() == 'completed' ||
                  statusStr.toLowerCase() == 'done';

              actionItemsList.add(
                ActionItemModel()
                  ..description = taskStr
                  ..assignedTo = assigneeStr
                  ..deadline = deadline
                  ..priority = priorityStr
                  ..isCompleted = isCompleted,
              );
            }
          }
        }
      }

      final decisionsList = <DecisionModel>[];
      final rawDecisions = jsonResult['decisions'];
      if (rawDecisions is List) {
        for (final item in rawDecisions) {
          final desc = item?.toString();
          if (desc != null && desc.isNotEmpty) {
            decisionsList.add(DecisionModel()..description = desc);
          }
        }
      }

      print("===== PARSED MEETING DETAILS =====");
      print("Summary Length: ${summary.executiveSummary?.length ?? 0}");
      print("Action Items Count: ${actionItemsList.length}");
      print("Decisions Count: ${decisionsList.length}");

      return {
        'summary': summary,
        'actionItems': actionItemsList,
        'decisions': decisionsList,
      };
    } catch (e, stackTrace) {
      print(
        "[AI Summary Error] generateMeetingAnalysis failed: $e. Using local offline fallback.",
      );
      print(stackTrace);
      return _generateMeetingAnalysisFallback(fullTranscript);
    }
  }

  /// Generates a customized AI insight for wearable biometrics synced to the transcript
  Future<Map<String, String>> generateBiometricAnalysis({
    required double heartRateAverage,
    required double heartRatePeak,
    required double stressAverage,
    required String transcript,
  }) async {
    try {
      final activeBaseUrl = await _findWorkingOllamaUrl();
      final requestData = {
        'model': _ollamaModel,
        'prompt':
            '''
Based on the following meeting biometrics and transcript, generate short, professional insight summaries (1-2 sentences each) for the user's:
1. Stress Analysis: How did the user's stress fluctuate? (e.g. "User stress increased during discussion.")
2. Engagement Analysis: How engaged was the user? (e.g. "Engagement dropped after minute 32.")
3. Focus Analysis: How focused was the user? (e.g. "Focus remained high during project planning.")
4. Energy Analysis: What was the energy drain? (e.g. "Heart rate remained stable throughout the meeting.")

Biometrics:
- Average Heart Rate: $heartRateAverage bpm
- Peak Heart Rate: $heartRatePeak bpm
- Average Stress Level: $stressAverage / 100

Transcript:
$transcript

Return your response ONLY as a JSON block with these keys:
{
  "stressAnalysis": "Summary of stress levels during the meeting.",
  "engagementAnalysis": "Summary of engagement levels.",
  "focusAnalysis": "Summary of cognitive focus peaks.",
  "energyAnalysis": "Summary of energy drain and cardiovascular state."
}
''',
        'stream': false,
      };

      final response = await _postWithRetry('/api/generate', data: requestData);
      if (response.statusCode == 200) {
        final content = response.data['response'] as String?;
        if (content != null && content.isNotEmpty) {
          final jsonResult = _extractJson(content);
          return {
            'stressAnalysis': (jsonResult['stressAnalysis'] ?? '').toString(),
            'engagementAnalysis': (jsonResult['engagementAnalysis'] ?? '')
                .toString(),
            'focusAnalysis': (jsonResult['focusAnalysis'] ?? '').toString(),
            'energyAnalysis': (jsonResult['energyAnalysis'] ?? '').toString(),
          };
        }
      }
    } catch (_) {}

    return _generateBiometricAnalysisFallback(
      heartRateAverage,
      heartRatePeak,
      stressAverage,
    );
  }

  Map<String, String> _generateBiometricAnalysisFallback(
    double heartRateAverage,
    double heartRatePeak,
    double stressAverage,
  ) {
    String stressText;
    if (stressAverage > 70) {
      stressText =
          'User stress level was elevated during intense periods of the discussion, peaking alongside key deliverables.';
    } else if (stressAverage > 45) {
      stressText =
          'Moderate stress response detected. Stress level increased slightly during key presentation turns.';
    } else {
      stressText =
          'User stress remained stable and in the calm zone throughout the meeting.';
    }

    String engagementText;
    if (heartRateAverage > 85) {
      engagementText =
          'Active cardiovascular participation indicates high conversational engagement.';
    } else {
      engagementText =
          'Circadian metrics indicate relaxed active listening and steady focus levels.';
    }

    String focusText;
    if (stressAverage < 40) {
      focusText =
          'Cognitive focus was optimal and calm, showing high capability for decision making.';
    } else {
      focusText =
          'High heart rate variability indicators suggest high cognitive processing during complex sections.';
    }

    String energyText =
        'Heart rate averaged $heartRateAverage bpm and remained stable throughout the meeting.';

    return {
      'stressAnalysis': stressText,
      'engagementAnalysis': engagementText,
      'focusAnalysis': focusText,
      'energyAnalysis': energyText,
    };
  }

  /// Local offline fallback parser for when Ollama is unreachable.
  Map<String, dynamic> _generateMeetingAnalysisFallback(String fullTranscript) {
    print("[OpenAIService] Running local offline fallback analysis parser...");

    final lines = fullTranscript.split('\n');
    final Map<String, List<String>> speakerSentences = {};
    final allSentencesWithSpeaker = <Map<String, String>>[];

    // Split sentences and attribute them to speakers
    for (final line in lines) {
      final parts = line.split(':');
      if (parts.length >= 2) {
        final speaker = parts[0].trim();
        final text = parts.sublist(1).join(':').trim();
        if (text.isNotEmpty) {
          final sentences = text.split(RegExp(r'(?<=[.!?])\s+'));
          speakerSentences.putIfAbsent(speaker, () => []);
          for (final s in sentences) {
            final cleanedS = s.trim();
            if (cleanedS.isNotEmpty) {
              speakerSentences[speaker]!.add(cleanedS);
              allSentencesWithSpeaker.add({
                'speaker': speaker,
                'text': cleanedS,
              });
            }
          }
        }
      } else if (line.trim().isNotEmpty) {
        final cleanedS = line.trim();
        final sentences = cleanedS.split(RegExp(r'(?<=[.!?])\s+'));
        for (final s in sentences) {
          if (s.trim().isNotEmpty) {
            allSentencesWithSpeaker.add({
              'speaker': 'Unknown',
              'text': s.trim(),
            });
          }
        }
      }
    }

    // 1. Generate Summary
    final summaryBuf = StringBuffer();
    summaryBuf.writeln('📋 Meeting Summary (Offline Fallback)');
    if (allSentencesWithSpeaker.isEmpty) {
      summaryBuf.writeln(
        '• No transcript content was captured in this meeting.',
      );
    } else {
      summaryBuf.writeln(
        '• A meeting was recorded with ${speakerSentences.keys.length} speaker(s).',
      );
      int count = 0;
      for (final item in allSentencesWithSpeaker) {
        final txt = item['text']!;
        if (txt.toLowerCase().contains('need to') ||
            txt.toLowerCase().contains('decided') ||
            txt.toLowerCase().contains('agree')) {
          summaryBuf.writeln('• Highlight: "${item['speaker']}: $txt"');
          count++;
          if (count >= 3) break;
        }
      }
      if (count == 0) {
        final limit = allSentencesWithSpeaker.length < 2
            ? allSentencesWithSpeaker.length
            : 2;
        for (int i = 0; i < limit; i++) {
          summaryBuf.writeln(
            '• Discussed: "${allSentencesWithSpeaker[i]['speaker']}: ${allSentencesWithSpeaker[i]['text']}"',
          );
        }
      }
    }

    // 2. Detailed Notes
    final notesBuf = StringBuffer();
    int noteCount = 0;
    for (final item in allSentencesWithSpeaker) {
      final txt = item['text']!;
      if (txt.length > 20 &&
          !txt.toLowerCase().startsWith('hello') &&
          !txt.toLowerCase().startsWith('hi') &&
          !txt.toLowerCase().startsWith('ok')) {
        notesBuf.writeln('• ${item['speaker']}: $txt');
        noteCount++;
        if (noteCount >= 10) break;
      }
    }
    if (notesBuf.isEmpty) {
      notesBuf.writeln('• Discussed general status and updates.');
    }

    // 3. Speaker Key Takeaways
    final takeawaysBuf = StringBuffer();
    for (final entry in speakerSentences.entries) {
      takeawaysBuf.writeln('👤 ${entry.key}:');
      int spkTakeawayCount = 0;
      for (final s in entry.value) {
        if (s.toLowerCase().contains('think') ||
            s.toLowerCase().contains('want') ||
            s.toLowerCase().contains('will') ||
            s.toLowerCase().contains('need') ||
            s.length > 30) {
          takeawaysBuf.writeln('  - $s');
          spkTakeawayCount++;
          if (spkTakeawayCount >= 3) break;
        }
      }
      if (spkTakeawayCount == 0 && entry.value.isNotEmpty) {
        takeawaysBuf.writeln(
          '  - Participated in discussions: "${entry.value.first}"',
        );
      }
    }
    if (takeawaysBuf.isEmpty) {
      takeawaysBuf.writeln('👤 Unknown:\n  - Discussed topics in meeting.');
    }

    // 4. Risks & Concerns
    final risksBuf = StringBuffer();
    final riskKeywords = [
      'risk',
      'worry',
      'concern',
      'block',
      'slow',
      'delay',
      'issue',
      'problem',
      'fail',
      'difficult',
      'error',
      'bug',
      'prevent',
    ];
    int riskCount = 0;
    for (final item in allSentencesWithSpeaker) {
      final txt = item['text']!;
      final txtLower = txt.toLowerCase();
      if (riskKeywords.any((k) => txtLower.contains(k))) {
        risksBuf.writeln('• ${item['speaker']}: $txt');
        riskCount++;
        if (riskCount >= 5) break;
      }
    }
    if (risksBuf.isEmpty) {
      risksBuf.writeln('• No specific roadblocks or risks were identified.');
    }

    // 5. Deadlines & Milestones
    final deadlinesBuf = StringBuffer();
    final deadlineKeywords = [
      'deadline',
      'by ',
      'due',
      'tomorrow',
      'friday',
      'monday',
      'tuesday',
      'wednesday',
      'thursday',
      'saturday',
      'sunday',
      'next week',
      'milestone',
    ];
    int deadlineCount = 0;
    for (final item in allSentencesWithSpeaker) {
      final txt = item['text']!;
      final txtLower = txt.toLowerCase();
      if (deadlineKeywords.any((k) => txtLower.contains(k))) {
        deadlinesBuf.writeln('• ${item['speaker']}: $txt');
        deadlineCount++;
        if (deadlineCount >= 5) break;
      }
    }
    if (deadlinesBuf.isEmpty) {
      deadlinesBuf.writeln(
        '• No specific deadlines or milestone dates were mentioned.',
      );
    }

    final summary = SummaryModel()
      ..executiveSummary = summaryBuf.toString().trim()
      ..meetingNotes = notesBuf.toString().trim()
      ..keyTakeaways = takeawaysBuf.toString().trim()
      ..risks = risksBuf.toString().trim()
      ..deadlines = deadlinesBuf.toString().trim();

    // 6. Action Items
    final actionItemsList = <ActionItemModel>[];
    final actionKeywords = [
      'todo',
      'need to',
      'must',
      'should',
      'will ',
      'task',
      'assignee',
      'action item',
    ];
    int taskCount = 0;
    for (final item in allSentencesWithSpeaker) {
      final txt = item['text']!;
      final txtLower = txt.toLowerCase();
      if (actionKeywords.any((k) => txtLower.contains(k))) {
        String? assignee;
        final speaker = item['speaker']!;
        if (speaker != 'Unknown') {
          assignee = speaker;
        }

        if (txtLower.contains('i will') || txtLower.contains('i need to')) {
          assignee = speaker;
        } else {
          final willMatch = RegExp(r'\b([A-Z][a-z]+)\s+will\b').firstMatch(txt);
          if (willMatch != null) {
            assignee = willMatch.group(1);
          }
        }

        String deadlineStr = '';
        for (final k in [
          'tomorrow',
          'friday',
          'monday',
          'tuesday',
          'wednesday',
          'thursday',
          'saturday',
          'sunday',
          'next week',
        ]) {
          if (txtLower.contains(k)) {
            deadlineStr = k;
            break;
          }
        }

        DateTime? deadline;
        if (deadlineStr.isNotEmpty) {
          deadline = _parseSmartDeadline(deadlineStr);
        }

        String priority = 'Medium';
        if (txtLower.contains('urgent') ||
            txtLower.contains('asap') ||
            txtLower.contains('must') ||
            txtLower.contains('critical')) {
          priority = 'High';
        }

        actionItemsList.add(
          ActionItemModel()
            ..description = txt
            ..assignedTo = assignee ?? 'Unassigned'
            ..deadline = deadline
            ..priority = priority
            ..isCompleted = false,
        );

        taskCount++;
        if (taskCount >= 10) break;
      }
    }

    // 7. Key Decisions
    final decisionsList = <DecisionModel>[];
    final decisionKeywords = [
      'decide',
      'agree',
      'approve',
      'confirm',
      'resolve',
      'settle',
      'conclusion',
    ];
    int decCount = 0;
    for (final item in allSentencesWithSpeaker) {
      final txt = item['text']!;
      final txtLower = txt.toLowerCase();
      if (decisionKeywords.any((k) => txtLower.contains(k))) {
        decisionsList.add(DecisionModel()..description = txt);
        decCount++;
        if (decCount >= 5) break;
      }
    }

    return {
      'summary': summary,
      'actionItems': actionItemsList,
      'decisions': decisionsList,
    };
  }

  /// Parses smart deadline words to concrete dates
  DateTime? _parseSmartDeadline(String deadlineStr) {
    final now = DateTime.now();
    final lower = deadlineStr.trim().toLowerCase();

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
        if (daysToAdd <= 0) {
          daysToAdd += 7;
        }
        final target = now.add(Duration(days: daysToAdd));
        return DateTime(target.year, target.month, target.day);
      }
    }

    if (lower.startsWith('next ')) {
      final dayPart = lower.substring(5).trim();
      for (final entry in weekdays.entries) {
        if (dayPart == entry.key) {
          int daysToAdd = entry.value - now.weekday;
          if (daysToAdd <= 0) {
            daysToAdd += 7;
          }
          daysToAdd += 7;
          final target = now.add(Duration(days: daysToAdd));
          return DateTime(target.year, target.month, target.day);
        }
      }
    }

    try {
      final parsed = DateTime.tryParse(deadlineStr);
      if (parsed != null) return parsed;
    } catch (_) {}

    return null;
  }

  Future<String> askMeetingQuestion({
    required String fullTranscript,
    required List<ChatMessageModel> chatHistory,
    required String currentQuestion,
  }) async {
    try {
      print("===== OLLAMA CHAT REQUEST =====");
      print("Endpoint: $_ollamaBaseUrl");
      print("Model: $_ollamaModel");

      final response = await _postWithRetry(
        '/api/generate',
        data: {
          'model': _ollamaModel,
          'prompt':
              '''
You are a meeting assistant.

Meeting Transcript:
$fullTranscript

Question:
$currentQuestion

Answer:
''',
          'stream': false,
        },
      );

      final responseText = response.data['response'] as String?;
      if (responseText == null) {
        throw Exception('Server returned null response.');
      }
      print("===== OLLAMA CHAT RESPONSE RECEIVED =====");
      return responseText;
    } catch (e) {
      print("ASK QUESTION ERROR: $e");
      rethrow;
    }
  }

  /// Sends a raw transcript block to Ollama for grammar and punctuation correction.
  /// Returns the corrected transcript, or the original text as fallback if Ollama fails.
  Future<String> correctTranscriptGrammar(String rawTranscript) async {
    if (rawTranscript.trim().isEmpty) return rawTranscript;
    try {
      print(
        '[TranscriptCorrection] Sending text to Ollama for grammar correction...',
      );
      final response = await _postWithRetry(
        '/api/generate',
        data: {
          'model': _ollamaModel,
          'prompt': '''You are a professional transcript editor.
Improve grammar and punctuation of the following meeting transcript without changing any meaning, names, or content.
Return ONLY the corrected transcript text with no explanations, no preamble, no "Here is the corrected text:" prefix.
Preserve paragraph structure where natural sentence breaks occur.

Transcript:
$rawTranscript''',
          'stream': false,
        },
      );
      final responseText = response.data['response'] as String?;
      if (responseText == null || responseText.trim().isEmpty) {
        print(
          '[TranscriptCorrection] Ollama returned empty response. Using original.',
        );
        return rawTranscript;
      }
      print('[TranscriptCorrection] Grammar correction complete.');
      return responseText.trim();
    } catch (e) {
      print(
        '[TranscriptCorrection] Ollama grammar correction failed: $e. Using original transcript.',
      );
      return rawTranscript;
    }
  }

  Future<Map<String, dynamic>> checkOllamaHealth() async {
    final activeBaseUrl = await _findWorkingOllamaUrl();
    final targetModel = _ollamaModel;
    print(
      "[Ollama Health Check] Checking connectivity to: $activeBaseUrl/api/tags",
    );
    final startTime = DateTime.now();

    try {
      final response = await _dio.get(
        '$activeBaseUrl/api/tags',
        options: Options(
          connectTimeout: const Duration(seconds: 20),
          receiveTimeout: const Duration(seconds: 120),
        ),
      );

      final endTime = DateTime.now();
      print(
        "[Ollama Health Check] Success in ${endTime.difference(startTime).inMilliseconds} ms",
      );
      print("[Ollama Health Check] Status Code: ${response.statusCode}");
      print("[Ollama Health Check] Response Body: ${response.data}");

      if (response.statusCode == 200) {
        final data = response.data;
        List<String> models = [];
        if (data is Map && data['models'] is List) {
          for (var m in data['models']) {
            if (m is Map && m['name'] != null) {
              models.add(m['name'].toString());
            }
          }
        }

        if (models.isEmpty) {
          return {
            'online': false,
            'url': activeBaseUrl,
            'reason': 'no model loaded',
            'details':
                'Ollama server has no models installed. Please pull a model (e.g., ollama pull $targetModel).',
            'models': <String>[],
          };
        }

        // Check if the configured model exists in the list
        final hasConfiguredModel = models.any(
          (m) => m == targetModel || m.startsWith('$targetModel:'),
        );
        if (!hasConfiguredModel) {
          return {
            'online': false,
            'url': activeBaseUrl,
            'reason': 'no model loaded',
            'details':
                'Model "$targetModel" is not loaded on Ollama. Loaded models: ${models.join(", ")}.',
            'models': models,
          };
        }

        return {
          'online': true,
          'url': activeBaseUrl,
          'reason': 'connected',
          'details': 'Connected to Ollama at $activeBaseUrl',
          'models': models,
        };
      }

      return {
        'online': false,
        'url': activeBaseUrl,
        'reason': 'invalid URL',
        'details':
            'Server returned unexpected status code: ${response.statusCode}',
        'models': <String>[],
      };
    } catch (e) {
      final endTime = DateTime.now();
      print(
        "[Ollama Health Check ERROR] Health check failed in ${endTime.difference(startTime).inMilliseconds} ms. Error: $e",
      );

      String reason = 'connection refused';
      String details = e.toString();

      if (e is DioException) {
        final err = e;
        if (err.type == DioExceptionType.connectionTimeout ||
            err.type == DioExceptionType.receiveTimeout ||
            err.type == DioExceptionType.sendTimeout) {
          reason = 'timeout';
          details =
              'Connection timed out after 20 seconds. Ensure the server is reachable.';
        } else if (err.type == DioExceptionType.connectionError) {
          reason = 'connection refused';
          details =
              'Connection refused. Ensure Ollama is running at $activeBaseUrl and listening on the correct network interface.';
        } else if (err.type == DioExceptionType.badResponse) {
          reason = 'invalid URL';
          details =
              'Ollama server returned bad response (HTTP ${err.response?.statusCode}).';
        } else {
          reason = 'connection refused';
          details = 'Network error: ${err.message}';
        }
      } else if (e is FormatException) {
        reason = 'invalid URL';
        details = 'Invalid URL format or response was not JSON: $e';
      }

      return {
        'online': false,
        'url': activeBaseUrl,
        'reason': reason,
        'details': details,
        'models': <String>[],
      };
    }
  }

  Map<String, dynamic> _estimateEmotionsKeywordFallback(
    String fullTranscript,
    List<int> speakerIndexes,
  ) {
    print(
      "[OpenAIService] Running local keyword-based heuristic emotion estimation...",
    );
    final List<Map<String, dynamic>> speakerList = [];

    final keywordMaps = {
      'happy': [
        'happy',
        'great',
        'glad',
        'awesome',
        'wonderful',
        'good',
        'pleased',
        'cheerful',
      ],
      'excited': [
        'excited',
        'amazing',
        'fantastic',
        'love',
        'cool',
        'super',
        'joy',
        'eager',
      ],
      'confident': [
        'confident',
        'sure',
        'solve',
        'resolved',
        'clear',
        'execute',
        'achieve',
        'positive',
      ],
      'concerned': [
        'concerned',
        'worry',
        'anxious',
        'afraid',
        'risk',
        'problem',
        'warn',
        'careful',
      ],
      'frustrated': [
        'frustrated',
        'annoy',
        'stuck',
        'block',
        'slow',
        'delay',
        'issue',
        'complaint',
      ],
      'angry': [
        'angry',
        'mad',
        'furious',
        'bad',
        'worst',
        'fail',
        'hate',
        'dislike',
      ],
      'bored': ['bored', 'tired', 'slow', 'sleepy', 'dull', 'tedious'],
      'nervous': ['nervous', 'shaky', 'uncertain', 'tense', 'scared'],
      'thinking': [
        'thinking',
        'consider',
        'ponder',
        'maybe',
        'perhaps',
        'wonder',
        'analyze',
      ],
      'calm': ['calm', 'relax', 'peace', 'quiet', 'smooth', 'stable'],
    };

    Map<String, dynamic> estimateText(String text) {
      final textLower = text.toLowerCase();
      final counts = <String, int>{};
      for (final entry in keywordMaps.entries) {
        int count = 0;
        for (final keyword in entry.value) {
          final matches = RegExp(
            RegExp.escape(keyword),
          ).allMatches(textLower).length;
          count += matches;
        }
        if (count > 0) {
          counts[entry.key] = count;
        }
      }

      if (counts.isEmpty) {
        return {'emotion': 'Neutral', 'confidence': 0.85};
      }

      final sorted = counts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      final primary = sorted.first.key;

      final emotionFormatted = primary[0].toUpperCase() + primary.substring(1);

      double confidence = 0.70 + (sorted.first.value * 0.05);
      if (confidence > 0.95) confidence = 0.95;

      return {'emotion': emotionFormatted, 'confidence': confidence};
    }

    final lines = fullTranscript.split('\n');
    final Map<int, StringBuffer> speakerTexts = {};
    for (final index in speakerIndexes) {
      speakerTexts[index] = StringBuffer();
    }

    for (final line in lines) {
      final match = RegExp(
        r'^(?:Speaker\s+|👤\s*Speaker\s+)?(\d+)[\s:]',
        caseSensitive: false,
      ).firstMatch(line);
      if (match != null) {
        final spkNum = int.tryParse(match.group(1) ?? '');
        if (spkNum != null && speakerTexts.containsKey(spkNum)) {
          speakerTexts[spkNum]!.write('$line ');
        }
      }
    }

    for (final index in speakerIndexes) {
      final spkText = speakerTexts[index]?.toString().trim() ?? '';
      final est = estimateText(spkText);
      speakerList.add({
        'speakerIndex': index,
        'emotion': est['emotion'],
        'confidence': est['confidence'],
      });
    }

    final overall = estimateText(fullTranscript);

    return {
      'overallEmotion': overall['emotion'],
      'overallConfidence': overall['confidence'],
      'speakers': speakerList,
    };
  }

  Future<Map<String, dynamic>> estimateEmotions({
    required String fullTranscript,
    required List<int> speakerIndexes,
  }) async {
    try {
      final activeBaseUrl = await _findWorkingOllamaUrl();
      print(
        "[OpenAIService] Querying Ollama for local emotion estimation at $activeBaseUrl...",
      );

      final prompt =
          '''
Analyze this meeting transcript and estimate the emotional tone:
1. For each speaker index in this list: $speakerIndexes, estimate their primary emotion from this list: Happy, Neutral, Confident, Excited, Frustrated, Angry, Sad, Calm. Return a confidence score between 0.0 and 1.0.
2. Estimate the overall emotion of the meeting from the same list.

Return your response ONLY as a valid JSON block matching this structure:
{
  "overallEmotion": "Neutral",
  "overallConfidence": 0.85,
  "speakers": [
    {
      "speakerIndex": 0,
      "emotion": "Happy",
      "confidence": 0.92
    }
  ]
}

Do NOT output any markdown wrappers outside of the JSON block itself. Return ONLY the JSON object.

Transcript:
$fullTranscript
''';

      final requestData = {
        'model': _ollamaModel,
        'prompt': prompt,
        'stream': false,
      };

      final response = await _postWithRetry('/api/generate', data: requestData);

      if (response.statusCode == 200) {
        final content = response.data['response'] as String?;
        if (content != null && content.isNotEmpty) {
          final jsonResult = _extractJson(content);
          return jsonResult;
        }
      }
      throw Exception("Invalid response from Ollama");
    } catch (e) {
      print(
        "[OpenAIService] Ollama emotion estimation failed, falling back to local heuristic: $e",
      );
      return _estimateEmotionsKeywordFallback(fullTranscript, speakerIndexes);
    }
  }
}
