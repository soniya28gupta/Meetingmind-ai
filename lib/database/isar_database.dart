import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'schemas/meeting_models.dart';

class IsarDatabase {
  static IsarDatabase? _instance;
  late final Isar isar;

  IsarDatabase._(this.isar);

  static IsarDatabase get instance {
    if (_instance == null) {
      throw StateError('IsarDatabase has not been initialized. Call initialize() first.');
    }
    return _instance!;
  }

  static Future<void> initialize() async {
    if (_instance != null) return;

    final dir = await getApplicationDocumentsDirectory();
    final isarInstance = await Isar.open(
      [
        UserModelSchema,
        MeetingModelSchema,
        TranscriptSegmentModelSchema,
        TranscriptModelSchema,
        SummaryModelSchema,
        ActionItemModelSchema,
        DecisionModelSchema,
        ChatMessageModelSchema,
        SpeakerProfileModelSchema,
        SpeakerEmotionModelSchema,
        SpeakerAnalyticsModelSchema,
        SensorReadingModelSchema,
        DeviceInfoModelSchema,
        DailyMetricsModelSchema,
      ],
      directory: dir.path,
      inspector: true, // Enable local database inspector for debugging
    );

    _instance = IsarDatabase._(isarInstance);
  }

  // Generic helpers for CRUD operations
  Future<void> writeTxn<T>(Future<T> Function() callback) async {
    await isar.writeTxn(callback);
  }

  Future<void> clearAll() async {
    await isar.writeTxn(() => isar.clear());
  }
}
