import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/schemas/meeting_models.dart';
import '../features/settings/settings_provider.dart';
import '../providers/app_providers.dart';

class EmotionService {
  final Ref? _ref;
  EmotionService([this._ref]);

  Dio get _dio {
    if (_ref != null) {
      return _ref.read(dioProvider);
    }
    return Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 90),
    ));
  }

  Future<String> _findWorkingBackendUrl() async {
    if (_ref != null) {
      final ollamaUrl = _ref.read(settingsProvider).ollamaUrl;
      if (ollamaUrl.isNotEmpty) {
        try {
          final uri = Uri.parse(ollamaUrl);
          if (uri.host.isNotEmpty) {
            final backendUrl = 'http://${uri.host}:5000';
            print("💡 Derived Emotion Backend URL from Ollama URL: $backendUrl");
            return backendUrl;
          }
        } catch (e) {
          print("[EmotionService] Failed to parse Ollama URL host for backend deriving: $e");
        }
      }
    }
    // Fallback if settings are not loaded yet or invalid:
    return 'http://10.0.2.2:5000';
  }

  Future<Map<String, dynamic>> detectEmotion() async {
    final activeUrl = await _findWorkingBackendUrl();
    final response = await _dio.get('$activeUrl/emotion');
    return Map<String, dynamic>.from(response.data);
  }

  /// Send the audio file and its diarized segments to the Flask server for advanced speech intelligence.
  Future<Map<String, dynamic>> analyzeAudio({
    required String audioFilePath,
    required List<TranscriptSegmentModel> segments,
  }) async {
    final activeUrl = await _findWorkingBackendUrl();
    print("[EmotionService] Uploading audio to $activeUrl/analyze_audio for DSP processing...");
    
    final List<Map<String, dynamic>> segJsonList = segments.map((seg) => {
      'startTime': seg.startTime,
      'endTime': seg.endTime,
      'speaker': seg.speaker ?? 0,
      'text': seg.text ?? '',
    }).toList();

    final formData = FormData.fromMap({
      'audio': await MultipartFile.fromFile(audioFilePath, filename: 'audio.wav'),
      'segments': jsonEncode(segJsonList),
    });

    final response = await _dio.post(
      '$activeUrl/analyze_audio',
      data: formData,
    );
    
    print("[EmotionService] DSP analysis response received.");
    return Map<String, dynamic>.from(response.data);
  }
}