import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../database/isar_database.dart';
import '../repositories/auth_repository.dart';
import '../repositories/meeting_repository.dart';
import '../repositories/task_repository.dart';
import '../services/audio_recording_service.dart';
import '../services/deepgram_service.dart';
import '../services/openai_service.dart';
import '../services/emotion_service.dart';
import '../features/settings/settings_provider.dart';

// Database Provider
final isarProvider = Provider((ref) => IsarDatabase.instance.isar);

final dioProvider = Provider<Dio>((ref) {
  return Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 120),
      sendTimeout: const Duration(seconds: 120),
    ),
  );
});

// Services Providers
final deepgramServiceProvider = Provider((ref) => DeepgramService());
final openAIServiceProvider = Provider<OpenAIService>(
  (ref) => OpenAIService(ref),
);
final emotionServiceProvider = Provider<EmotionService>(
  (ref) => EmotionService(ref),
);
final audioRecordingServiceProvider = Provider((ref) {
  final service = AudioRecordingService();
  ref.onDispose(() => service.dispose());
  return service;
});

// Repositories Providers
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return FirebaseAuthRepository();
});

final meetingRepositoryProvider = Provider<MeetingRepository>((ref) {
  return IsarMeetingRepository(ref);
});

final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  return IsarTaskRepository(ref);
});

final ollamaHealthProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  ref.watch(settingsProvider);
  final service = ref.watch(openAIServiceProvider);
  return await service.checkOllamaHealth();
});
