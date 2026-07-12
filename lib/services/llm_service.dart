import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/config/env_config.dart';
import '../features/settings/settings_provider.dart';
import '../providers/app_providers.dart';

class LLMService {
  final Ref _ref;

  LLMService(this._ref);

  Dio get _dio => _ref.read(dioProvider);

  String get _openAiApiKey => EnvConfig.openAiApiKey;

  String get _ollamaUrl => _ref.read(settingsProvider).ollamaUrl;
  String get _ollamaModel => _ref.read(settingsProvider).ollamaModel;

  /// Primary completion caller, decides dynamically between OpenAI, Ollama, or Fallback
  Future<String> getCompletion({
    required String prompt,
    String? systemInstruction,
  }) async {
    // 1. Try OpenAI if key is present
    if (_openAiApiKey.isNotEmpty) {
      try {
        return await _callOpenAI(
          prompt: prompt,
          systemInstruction: systemInstruction,
        );
      } catch (e) {
        print('[LLMService] OpenAI call failed: $e. Trying Ollama...');
      }
    }

    // 2. Try Ollama if configured
    if (_ollamaUrl.isNotEmpty) {
      try {
        return await _callOllama(
          prompt: prompt,
          systemInstruction: systemInstruction,
        );
      } catch (e) {
        print('[LLMService] Ollama call failed: $e.');
      }
    }

    throw Exception(
      'All LLM endpoints are currently unavailable. Ensure internet connection or Ollama setup.',
    );
  }

  /// Calls LLM and parses JSON output safely
  Future<Map<String, dynamic>> getJsonCompletion({
    required String prompt,
    String? systemInstruction,
  }) async {
    final rawText = await getCompletion(
      prompt:
          '$prompt\n\nReturn ONLY a valid JSON object. Do not include markdown code block wrappers (e.g. ```json). Do not add any text before or after the JSON.',
      systemInstruction: systemInstruction,
    );
    return _extractJson(rawText);
  }

  Future<String> _callOpenAI({
    required String prompt,
    String? systemInstruction,
  }) async {
    const String url = 'https://api.openai.com/v1/chat/completions';

    final messages = <Map<String, String>>[];
    if (systemInstruction != null && systemInstruction.isNotEmpty) {
      messages.add({'role': 'system', 'content': systemInstruction});
    }
    messages.add({'role': 'user', 'content': prompt});

    final payload = {
      'model': 'gpt-4o-mini',
      'messages': messages,
      'temperature': 0.3,
    };

    int retryCount = 0;
    const int maxRetries = 3;
    Duration delay = const Duration(seconds: 2);

    while (true) {
      try {
        final response = await _dio.post(
          url,
          options: Options(
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $_openAiApiKey',
            },
            connectTimeout: const Duration(seconds: 15),
            receiveTimeout: const Duration(seconds: 45),
          ),
          data: payload,
        );

        if (response.statusCode == 200) {
          final choices = response.data['choices'] as List?;
          if (choices != null && choices.isNotEmpty) {
            final content = choices[0]['message']?['content'] as String?;
            if (content != null) {
              return content.trim();
            }
          }
        }
        throw Exception(
          'OpenAI returned invalid status code: ${response.statusCode}',
        );
      } catch (e) {
        retryCount++;
        if (retryCount >= maxRetries) {
          rethrow;
        }
        await Future.delayed(delay);
        delay *= 2;
      }
    }
  }

  Future<String> _callOllama({
    required String prompt,
    String? systemInstruction,
  }) async {
    final String url = '$_ollamaUrl/api/generate';

    final finalPrompt =
        systemInstruction != null && systemInstruction.isNotEmpty
        ? '$systemInstruction\n\nPrompt:\n$prompt'
        : prompt;

    final payload = {
      'model': _ollamaModel.isNotEmpty ? _ollamaModel : 'qwen2.5:7b',
      'prompt': finalPrompt,
      'stream': false,
      'options': {'temperature': 0.3},
    };

    int retryCount = 0;
    const int maxRetries = 3;
    Duration delay = const Duration(seconds: 2);

    while (true) {
      try {
        final response = await _ref
            .read(dioProvider)
            .post(
              url,
              options: Options(
                headers: {'Content-Type': 'application/json'},
                connectTimeout: const Duration(seconds: 15),
                receiveTimeout: const Duration(seconds: 60),
              ),
              data: payload,
            );

        if (response.statusCode == 200) {
          final content = response.data['response'] as String?;
          if (content != null) {
            return content.trim();
          }
        }
        throw Exception(
          'Ollama returned invalid status code: ${response.statusCode}',
        );
      } catch (e) {
        retryCount++;
        if (retryCount >= maxRetries) {
          rethrow;
        }
        await Future.delayed(delay);
        delay *= 2;
      }
    }
  }

  /// Robust extraction of JSON from response content, supporting markdown code blocks.
  Map<String, dynamic> _extractJson(String content) {
    var cleaned = content.trim();

    // Strip markdown wrapper tags if present
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

    try {
      final sanitized = _sanitizeJsonString(cleaned);
      return jsonDecode(sanitized) as Map<String, dynamic>;
    } catch (_) {}

    // Try to locate a JSON object pattern ({...}) inside the response
    final int firstBrace = cleaned.indexOf('{');
    final int lastBrace = cleaned.lastIndexOf('}');
    if (firstBrace != -1 && lastBrace != -1 && lastBrace > firstBrace) {
      final String jsonCandidate = cleaned.substring(firstBrace, lastBrace + 1);
      try {
        final sanitizedCandidate = _sanitizeJsonString(jsonCandidate);
        return jsonDecode(sanitizedCandidate) as Map<String, dynamic>;
      } catch (_) {}
    }

    throw const FormatException(
      'Could not parse a valid JSON response from the LLM model.',
    );
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
}

final llmServiceProvider = Provider<LLMService>((ref) => LLMService(ref));
