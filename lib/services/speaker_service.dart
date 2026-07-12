import 'dart:math' as math;
import 'package:isar/isar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/isar_database.dart';
import '../database/schemas/meeting_models.dart';
import '../providers/app_providers.dart';

final speakerServiceProvider = Provider<SpeakerService>((ref) {
  return SpeakerService(ref);
});

class SpeakerService {
  final Ref _ref;
  SpeakerService(this._ref);

  Isar get _isar => IsarDatabase.instance.isar;

  String get _currentUserId {
    final uid = _ref.read(authRepositoryProvider).currentUser?.uid;
    return uid ?? 'offline_fallback';
  }

  static const List<int> _defaultColors = [
    0xFF9C27B0, // Deep Purple
    0xFF2196F3, // Deep Blue
    0xFF4CAF50, // Neon Green
    0xFFFFC107, // Amber Yellow
    0xFFFF5722, // Coral Pink
    0xFF009688, // Teal
    0xFFFF9800, // Orange
    0xFF3F51B5, // Indigo
  ];

  static const List<String> _defaultEmojis = [
    '😊',
    '🤔',
    '😌',
    '😀',
    '😎',
    '🦁',
    '🦊',
    '🦄',
    '🐼',
    '🐸',
    '🐨',
    '🐯',
  ];

  /// Compute cosine similarity between two double vectors.
  double calculateCosineSimilarity(List<double> v1, List<double> v2) {
    if (v1.length != v2.length || v1.isEmpty) return 0.0;
    double dotProduct = 0.0;
    double normA = 0.0;
    double normB = 0.0;
    for (int i = 0; i < v1.length; i++) {
      dotProduct += v1[i] * v2[i];
      normA += v1[i] * v1[i];
      normB += v2[i] * v2[i];
    }
    if (normA == 0.0 || normB == 0.0) return 0.0;
    return dotProduct / (math.sqrt(normA) * math.sqrt(normB));
  }

  /// Get or create a persistent speaker profile based on voice embedding.
  Future<SpeakerProfileModel> getOrCreateSpeakerProfileForVoice({
    required List<double> voiceEmbedding,
    required String defaultName,
  }) async {
    final uid = _currentUserId;
    final allProfiles = await _isar.speakerProfileModels
        .filter()
        .userIdEqualTo(uid)
        .findAll();

    SpeakerProfileModel? bestMatch;
    double bestScore = 0.0;

    for (final profile in allProfiles) {
      if (profile.voiceEmbedding != null &&
          profile.voiceEmbedding!.isNotEmpty) {
        final score = calculateCosineSimilarity(
          voiceEmbedding,
          profile.voiceEmbedding!,
        );
        if (score > bestScore) {
          bestScore = score;
          bestMatch = profile;
        }
      }
    }

    // Threshold for voice match: 0.85 similarity
    if (bestMatch != null && bestScore >= 0.85) {
      print(
        "[SpeakerService] Matched voice with existing speaker profile: ${bestMatch.name} (score: $bestScore)",
      );
      bestMatch.meetingCount++;
      await _isar.writeTxn(() async {
        await _isar.speakerProfileModels.put(bestMatch!);
      });
      return bestMatch;
    }

    // Otherwise, create a brand new profile
    final index = allProfiles.length;
    final randomEmoji = _defaultEmojis[index % _defaultEmojis.length];
    final randomColor = _defaultColors[index % _defaultColors.length];

    final newProfile = SpeakerProfileModel()
      ..name = defaultName
      ..avatarEmoji = randomEmoji
      ..colorValue = randomColor
      ..voiceEmbedding = voiceEmbedding
      ..meetingCount = 1
      ..createdAt = DateTime.now()
      ..userId = uid;

    await _isar.writeTxn(() async {
      await _isar.speakerProfileModels.put(newProfile);
    });

    print("[SpeakerService] Created new speaker profile: ${newProfile.name}");
    return newProfile;
  }

  /// Get or create a speaker profile by name fallback (if DSP offline).
  Future<SpeakerProfileModel> getOrCreateSpeakerProfileByName(
    String name,
  ) async {
    final uid = _currentUserId;
    var profile = await _isar.speakerProfileModels
        .filter()
        .userIdEqualTo(uid)
        .nameEqualTo(name)
        .findFirst();
    if (profile != null) {
      return profile;
    }

    final allProfiles = await _isar.speakerProfileModels
        .filter()
        .userIdEqualTo(uid)
        .findAll();
    final index = allProfiles.length;
    final randomEmoji = _defaultEmojis[index % _defaultEmojis.length];
    final randomColor = _defaultColors[index % _defaultColors.length];

    profile = SpeakerProfileModel()
      ..name = name
      ..avatarEmoji = randomEmoji
      ..colorValue = randomColor
      ..meetingCount = 1
      ..createdAt = DateTime.now()
      ..userId = uid;

    await _isar.writeTxn(() async {
      await _isar.speakerProfileModels.put(profile!);
    });
    return profile;
  }

  /// Update an existing speaker profile.
  Future<void> updateSpeakerProfile(SpeakerProfileModel profile) async {
    if (profile.userId != _currentUserId) return;
    await _isar.writeTxn(() async {
      await _isar.speakerProfileModels.put(profile);
    });
  }

  /// Fetch all speaker profiles.
  Future<List<SpeakerProfileModel>> getAllSpeakerProfiles() async {
    return await _isar.speakerProfileModels
        .filter()
        .userIdEqualTo(_currentUserId)
        .findAll();
  }
}
