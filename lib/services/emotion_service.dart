import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/schemas/meeting_models.dart';
import '../features/settings/settings_provider.dart';
import '../providers/app_providers.dart';
import '../core/config/backend_config.dart';
import 'emotion_health_service.dart';

class EmotionService {
  final Ref? _ref;
  EmotionService([this._ref]);

  Dio get _dio {
    if (_ref != null) {
      return _ref.read(dioProvider);
    }
    return Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 90),
      ),
    );
  }

  Future<String> _findWorkingBackendUrl() async {
    // 1. In release mode or production/release environments, ALWAYS return the production URL
    final env = BackendConfig.environment;
    final isProdOrRelease =
        env == BackendEnv.production ||
        env == BackendEnv.release ||
        kReleaseMode;

    if (isProdOrRelease) {
      return BackendConfig.configuredUrl;
    }

    // 2. Otherwise in dev/debug mode, check if we have resolved an activeUrl from health check
    if (_ref != null) {
      final activeUrl = _ref.read(emotionHealthServiceProvider).activeUrl;
      if (activeUrl.isNotEmpty) {
        return activeUrl;
      }
    }

    // 3. Fallback to configuredUrl if non-empty
    final envUrl = BackendConfig.configuredUrl;
    if (envUrl.isNotEmpty) {
      return envUrl;
    }

    // 4. In debug/development mode only: try to derive from Ollama URL
    if (_ref != null) {
      final ollamaUrl = _ref.read(settingsProvider).ollamaUrl;
      if (ollamaUrl.isNotEmpty) {
        try {
          final uri = Uri.parse(ollamaUrl);
          if (uri.host.isNotEmpty) {
            final backendUrl = 'http://${uri.host}:5000';
            print(
              "💡 Derived Emotion Backend URL from Ollama URL: $backendUrl",
            );
            return backendUrl;
          }
        } catch (e) {
          print(
            "[EmotionService] Failed to parse Ollama URL host for backend deriving: $e",
          );
        }
      }
    }
    // Fallback if settings are not loaded yet or invalid in debug mode:
    return 'http://10.0.2.2:5000';
  }

  Future<Map<String, dynamic>> detectEmotion() async {
    print("Emotion request started");
    try {
      final activeUrl = await _findWorkingBackendUrl();
      print("Waiting for response");
      final response = await _dio.get(
        '$activeUrl/emotion',
        options: Options(
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
          sendTimeout: const Duration(seconds: 15),
        ),
      );
      print("Emotion response received");
      final data = Map<String, dynamic>.from(response.data);
      print("Emotion parsing completed");
      return data;
    } catch (error) {
      print("Emotion analysis failed");
      print("Emotion error:");
      print(error);
      rethrow;
    }
  }

  /// Send the audio file and its diarized segments to the Flask server for advanced speech intelligence.
  Future<Map<String, dynamic>> analyzeAudio({
    required String audioFilePath,
    required List<TranscriptSegmentModel> segments,
  }) async {
    print("Emotion request started");
    try {
      final activeUrl = await _findWorkingBackendUrl();
      print(
        "[EmotionService] Uploading audio to $activeUrl/analyze_audio for DSP processing...",
      );

      print("Sending transcript");
      final List<Map<String, dynamic>> segJsonList = segments
          .map(
            (seg) => {
              'startTime': seg.startTime,
              'endTime': seg.endTime,
              'speaker': seg.speaker ?? 0,
              'text': seg.text ?? '',
            },
          )
          .toList();

      final formData = FormData.fromMap({
        'audio': await MultipartFile.fromFile(
          audioFilePath,
          filename: 'audio.wav',
        ),
        'segments': jsonEncode(segJsonList),
      });

      print("Waiting for response");
      final response = await _dio.post(
        '$activeUrl/analyze_audio',
        data: formData,
        options: Options(
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 120),
          sendTimeout: const Duration(seconds: 60),
        ),
      );

      print("Emotion response received");
      print("[EmotionService] DSP analysis response received.");
      final data = Map<String, dynamic>.from(response.data);
      print("Emotion parsing completed");
      return data;
    } catch (error) {
      print("Emotion analysis failed");
      print("Emotion error:");
      print(error);
      rethrow;
    }
  }
}
