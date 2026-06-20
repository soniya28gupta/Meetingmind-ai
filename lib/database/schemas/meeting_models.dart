import 'package:isar/isar.dart';

part 'meeting_models.g.dart';

@collection
class UserModel {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  String? uid; // Firebase User ID
  String? email;
  String? displayName;
  String? photoUrl;
  String? phoneNumber;
  String? bio;
  String? company;
  String? designation;
  DateTime? lastSynced;
}

@collection
class MeetingModel {
  Id id = Isar.autoIncrement;

  @Index()
  String? userId; // Owner User ID
  
  String? title;
  DateTime? createdAt;
  double durationSeconds = 0.0;
  String? audioFilePath;
  bool isSynced = false;
  bool isRecording = false;
  String? detectedEmotion;
  double? emotionConfidence;
  bool? isLocalEstimation;

  // Wearable Sensor Metrics
  double? heartRateAverage;
  double? heartRatePeak;
  double? stressAverage;
  double? sleepScore;
  double? engagementScore;
  double? energyDrain;
  String? wellnessInsightText;
  String? stressAnalysis;
  String? engagementAnalysis;
  String? focusAnalysis;
  String? energyAnalysis;

  final transcript = IsarLink<TranscriptModel>();
  final summary = IsarLink<SummaryModel>();
  
  @Backlink(to: 'meeting')
  final actionItems = IsarLinks<ActionItemModel>();
  
  @Backlink(to: 'meeting')
  final decisions = IsarLinks<DecisionModel>();
  
  @Backlink(to: 'meeting')
  final chatMessages = IsarLinks<ChatMessageModel>();
}

@collection
class TranscriptSegmentModel {
  Id id = Isar.autoIncrement;

  @Index()
  String? userId; // Owner User ID

  int? speaker; // Speaker index (e.g. 0, 1, 2)
  String? text;
  double startTime = 0.0; // In seconds
  double endTime = 0.0; // In seconds
  
  final transcript = IsarLink<TranscriptModel>();
  final speakerProfile = IsarLink<SpeakerProfileModel>();
}

@collection
class TranscriptModel {
  Id id = Isar.autoIncrement;

  @Index()
  String? userId; // Owner User ID
  
  @Backlink(to: 'transcript')
  final segments = IsarLinks<TranscriptSegmentModel>();
}

@collection
class SummaryModel {
  Id id = Isar.autoIncrement;

  @Index()
  String? userId; // Owner User ID

  String? executiveSummary;
  String? meetingNotes;
  String? keyTakeaways;
  String? followUps;
  String? risks;
  String? deadlines;
}

@collection
class ActionItemModel {
  Id id = Isar.autoIncrement;

  @Index()
  String? userId; // Owner User ID

  String? description;
  DateTime? deadline;
  bool isCompleted = false;
  String? assignedTo;
  String? priority; // High, Medium, Low

  final meeting = IsarLink<MeetingModel>();
  final speakerProfile = IsarLink<SpeakerProfileModel>();
}

@collection
class DecisionModel {
  Id id = Isar.autoIncrement;

  @Index()
  String? userId; // Owner User ID

  String? description;

  final meeting = IsarLink<MeetingModel>();
  final speakerProfile = IsarLink<SpeakerProfileModel>();
}

@collection
class ChatMessageModel {
  Id id = Isar.autoIncrement;

  @Index()
  String? userId; // Owner User ID

  String? message;
  bool isUser = true;
  DateTime? timestamp;

  final meeting = IsarLink<MeetingModel>();
}

@collection
class SpeakerProfileModel {
  Id id = Isar.autoIncrement;

  @Index()
  String? userId; // Owner User ID

  String? name;
  
  int? colorValue; // Color integer
  String? avatarEmoji; // Default emoji representation
  List<double>? voiceEmbedding; // log spectral band energy (13 values)
  int meetingCount = 0;
  DateTime? createdAt;
}

@collection
class SpeakerEmotionModel {
  Id id = Isar.autoIncrement;

  @Index()
  String? userId; // Owner User ID

  String? emotion;
  double confidence = 0.0;
  double startTime = 0.0;
  double endTime = 0.0;

  final speakerProfile = IsarLink<SpeakerProfileModel>();
  final meeting = IsarLink<MeetingModel>();
}

@collection
class SpeakerAnalyticsModel {
  Id id = Isar.autoIncrement;

  @Index()
  String? userId; // Owner User ID

  double speakingTimeSeconds = 0.0;
  int wordCount = 0;
  double participationPercentage = 0.0;
  double interactionScore = 0.0;

  final speakerProfile = IsarLink<SpeakerProfileModel>();
  final meeting = IsarLink<MeetingModel>();
}

@collection
class SensorReadingModel {
  Id id = Isar.autoIncrement;

  @Index()
  String? userId;

  String? deviceId;
  DateTime? timestamp;
  int? heartRate;
  double? stress;
  int? steps;
  int? battery;
  double? sleep;
  bool isSynced = false;
}

@collection
class DeviceInfoModel {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  String? deviceId;

  String? name;
  String? type;
  int? battery;
  String? connectionState;
  DateTime? lastConnectedAt;
  bool isAutoReconnectEnabled = true;
}

@collection
class DailyMetricsModel {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  DateTime? date;

  int? totalSteps;
  double? averageHeartRate;
  double? sleepHours;
  double? sleepScore;
  double? stressScore;
  int? batteryLevel;
}
