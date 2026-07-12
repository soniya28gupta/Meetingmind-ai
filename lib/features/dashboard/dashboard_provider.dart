import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/app_providers.dart';
import '../../services/firestore_service.dart';
import '../../services/emotion_health_service.dart';

class DashboardData {
  final int totalMeetings;
  final double totalRecordingHours;
  final int completedTasks;
  final int pendingTasks;
  final List<double> weeklyActivity; // 7 elements, Mon - Sun
  final String productivityInsight;
  final bool isLoading;

  DashboardData({
    this.totalMeetings = 0,
    this.totalRecordingHours = 0.0,
    this.completedTasks = 0,
    this.pendingTasks = 0,
    this.weeklyActivity = const [0, 0, 0, 0, 0, 0, 0],
    this.productivityInsight =
        'Record your first meeting to get AI-driven performance insights.',
    this.isLoading = true,
  });

  DashboardData copyWith({
    int? totalMeetings,
    double? totalRecordingHours,
    int? completedTasks,
    int? pendingTasks,
    List<double>? weeklyActivity,
    String? productivityInsight,
    bool? isLoading,
  }) {
    return DashboardData(
      totalMeetings: totalMeetings ?? this.totalMeetings,
      totalRecordingHours: totalRecordingHours ?? this.totalRecordingHours,
      completedTasks: completedTasks ?? this.completedTasks,
      pendingTasks: pendingTasks ?? this.pendingTasks,
      weeklyActivity: weeklyActivity ?? this.weeklyActivity,
      productivityInsight: productivityInsight ?? this.productivityInsight,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class DashboardNotifier extends StateNotifier<DashboardData> {
  final Ref _ref;

  DashboardNotifier(this._ref) : super(DashboardData()) {
    _init();
  }

  void _init() {
    // Watch meetings and tasks to update dashboard automatically on database change
    _ref.read(meetingRepositoryProvider).watchMeetings().listen((meetings) {
      _calculateStats();
    });

    _ref.read(taskRepositoryProvider).watchTasks().listen((tasks) {
      _calculateStats();
    });
  }

  Future<void> _calculateStats() async {
    state = state.copyWith(isLoading: true);

    final meetings = await _ref
        .read(meetingRepositoryProvider)
        .getAllMeetings();
    final tasks = await _ref.read(taskRepositoryProvider).getAllTasks();

    int totalMeetings = meetings.length;
    double totalSeconds = meetings.fold(
      0.0,
      (sum, m) => sum + m.durationSeconds,
    );
    double totalHours = totalSeconds / 3600.0;

    int completed = tasks.where((t) => t.isCompleted).length;
    int pending = tasks.length - completed;

    // Weekly activity distribution (current calendar week, Mon - Sun)
    List<double> activity = List<double>.filled(7, 0.0);
    final now = DateTime.now();
    final startOfWeek = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 7));

    for (final meeting in meetings) {
      if (meeting.createdAt != null) {
        final date = meeting.createdAt!.toLocal();
        if (!date.isBefore(startOfWeek) && date.isBefore(endOfWeek)) {
          final index = date.weekday - 1; // Mon = 0, Sun = 6
          activity[index] += meeting.durationSeconds / 60.0; // Minutes recorded
        }

        // Sync activity log to Firestore
        final currentUid = _ref.read(authRepositoryProvider).currentUser?.uid;
        if (currentUid != null) {
          FirestoreService.instance.saveActivity(
            date,
            meeting.durationSeconds,
            currentUid,
          );
        }
      }
    }

    // Generate dynamic AI Insights based on ratios
    String insight;
    if (totalMeetings == 0) {
      insight =
          'Start recording your meetings. MeetingMind AI will track tasks and summarize them automatically.';
    } else if (tasks.isEmpty) {
      insight =
          'You have no action items yet. Keep speaking, and I will extract them from your meetings!';
    } else {
      double completionRate = completed / tasks.length;
      if (completionRate >= 0.8) {
        insight =
            'Outstanding! You completed ${(completionRate * 100).toStringAsFixed(0)}% of tasks. Focus remains extremely high this week.';
      } else if (completionRate >= 0.5) {
        insight =
            'On track. You completed ${(completionRate * 100).toStringAsFixed(0)}% of action items. $pending tasks are still awaiting follow-up.';
      } else {
        insight =
            'Action items are piling up. Consider reviewing deadlines on pending tasks to clear bottlenecks.';
      }
    }

    state = DashboardData(
      totalMeetings: totalMeetings,
      totalRecordingHours: totalHours,
      completedTasks: completed,
      pendingTasks: pending,
      weeklyActivity: activity,
      productivityInsight: insight,
      isLoading: false,
    );
  }
}

final dashboardProvider =
    StateNotifierProvider<DashboardNotifier, DashboardData>((ref) {
      return DashboardNotifier(ref);
    });

class EmotionTestState {
  final bool isLoading;
  final String? emotion;
  final double? confidence;
  final String? errorMessage;

  EmotionTestState({
    this.isLoading = false,
    this.emotion,
    this.confidence,
    this.errorMessage,
  });
}

class EmotionTestNotifier extends StateNotifier<EmotionTestState> {
  final Ref _ref;
  EmotionTestNotifier(this._ref) : super(EmotionTestState());

  Future<void> runTest() async {
    if (state.isLoading) return;
    state = EmotionTestState(isLoading: true);

    final String url =
        '${_ref.read(emotionHealthServiceProvider).activeUrl}/emotion';
    print('[EmotionTest] Running real-time emotion check at: $url');

    try {
      final result = await _ref.read(emotionServiceProvider).detectEmotion();
      final emotion = result['emotion'] as String? ?? 'Unknown';
      final confidence = (result['confidence'] as num?)?.toDouble() ?? 0.0;
      state = EmotionTestState(
        isLoading: false,
        emotion: emotion,
        confidence: confidence,
      );
      print(
        '[EmotionTest] Test successfully completed. Detected Emotion: $emotion, Confidence: $confidence',
      );
    } catch (e, stackTrace) {
      print('[EmotionTest] Connection failure during test. Target URL: $url');
      print('[EmotionTest] Error details: $e');
      print('[EmotionTest] Stack trace: $stackTrace');

      state = EmotionTestState(
        isLoading: false,
        errorMessage:
            'Connection failed. Ensure the emotion backend Flask service is running.',
      );
    }
  }

  void clearResult() {
    state = EmotionTestState();
  }
}

final emotionTestProvider =
    StateNotifierProvider<EmotionTestNotifier, EmotionTestState>((ref) {
      return EmotionTestNotifier(ref);
    });
