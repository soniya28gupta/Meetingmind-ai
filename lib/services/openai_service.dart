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
    return Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 120),
      sendTimeout: const Duration(seconds: 120),
    ));
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
  Future<Response> _postWithRetry(String path, {required Map<String, dynamic> data}) async {
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
            headers: {
              'Content-Type': 'application/json',
            },
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
        print("[Ollama Connection Retry] Waiting ${delay.inSeconds}s before next attempt...");
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
          return Exception('Connection timed out. Ensure the Ollama server is running at $activeUrl and accessible.');
        case DioExceptionType.sendTimeout:
          return Exception('Failed to send data to the server at $activeUrl. Please check your network.');
        case DioExceptionType.receiveTimeout:
          return Exception('The Ollama server at $activeUrl took too long to respond. The model might still be loading or generating.');
        case DioExceptionType.badResponse:
          final statusCode = error.response?.statusCode;
          return Exception('Server at $activeUrl returned an error status ($statusCode). Please verify the server state.');
        case DioExceptionType.cancel:
          return Exception('The request to $activeUrl was cancelled.');
        case DioExceptionType.connectionError:
          return Exception('Cannot connect to the Ollama server at $activeUrl. Verify the IP address, running status, and network connection.');
        default:
          if (error.error is SocketException) {
            return Exception('Network connection error at $activeUrl: ${error.error}. Please check local network connectivity.');
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

    throw const FormatException('Could not parse a valid JSON response from the Ollama model.');
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
      print("Transcript content preview: ${fullTranscript.substring(0, fullTranscript.length > 200 ? 200 : fullTranscript.length)}...");

      final requestData = {
        'model': _ollamaModel,
        'prompt': '''
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

      final response = await _postWithRetry(
        '/api/generate',
        data: requestData,
      );

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
        print("[Ollama JSON Error] Failed to parse JSON from response. Exact response content was:\n$content");
        throw Exception('Ollama response returned invalid JSON formatting: $jsonErr. Exact response content was:\n$content');
      }

      // Robust fallback parsing
      final rawSummaryText = (jsonResult['summary'] ?? jsonResult['executiveSummary'] ?? '').toString();
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
              
              final assigneeStr = (item['assignee'] ?? item['assignedTo'])?.toString();
              final statusStr = item['status']?.toString() ?? 'pending';
              final isCompleted = statusStr.toLowerCase() == 'completed' || statusStr.toLowerCase() == 'done';
              
              actionItemsList.add(ActionItemModel()
                ..description = taskStr
                ..assignedTo = assigneeStr
                ..deadline = deadline
                ..priority = priorityStr
                ..isCompleted = isCompleted);
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
      print("[AI Summary Error] generateMeetingAnalysis failed: $e");
      print(stackTrace);
      rethrow;
    }
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
          'prompt': '''
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

  Future<Map<String, dynamic>> checkOllamaHealth() async {
    final activeBaseUrl = await _findWorkingOllamaUrl();
    final targetModel = _ollamaModel;
    print("[Ollama Health Check] Checking connectivity to: $activeBaseUrl/api/tags");
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
      print("[Ollama Health Check] Success in ${endTime.difference(startTime).inMilliseconds} ms");
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
            'details': 'Ollama server has no models installed. Please pull a model (e.g., ollama pull $targetModel).',
            'models': <String>[],
          };
        }
        
        // Check if the configured model exists in the list
        final hasConfiguredModel = models.any((m) => m == targetModel || m.startsWith('$targetModel:'));
        if (!hasConfiguredModel) {
          return {
            'online': false,
            'url': activeBaseUrl,
            'reason': 'no model loaded',
            'details': 'Model "$targetModel" is not loaded on Ollama. Loaded models: ${models.join(", ")}.',
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
        'details': 'Server returned unexpected status code: ${response.statusCode}',
        'models': <String>[],
      };
    } catch (e) {
      final endTime = DateTime.now();
      print("[Ollama Health Check ERROR] Health check failed in ${endTime.difference(startTime).inMilliseconds} ms. Error: $e");
      
      String reason = 'connection refused';
      String details = e.toString();
      
      if (e is DioException) {
        final err = e;
        if (err.type == DioExceptionType.connectionTimeout ||
            err.type == DioExceptionType.receiveTimeout ||
            err.type == DioExceptionType.sendTimeout) {
          reason = 'timeout';
          details = 'Connection timed out after 20 seconds. Ensure the server is reachable.';
        } else if (err.type == DioExceptionType.connectionError) {
          reason = 'connection refused';
          details = 'Connection refused. Ensure Ollama is running at $activeBaseUrl and listening on the correct network interface.';
        } else if (err.type == DioExceptionType.badResponse) {
          reason = 'invalid URL';
          details = 'Ollama server returned bad response (HTTP ${err.response?.statusCode}).';
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
}