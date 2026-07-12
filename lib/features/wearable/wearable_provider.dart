import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:isar/isar.dart';
import '../../database/isar_database.dart';
import '../../database/schemas/meeting_models.dart';
import '../../services/llm_service.dart';
import 'wearable_models.dart';
import 'wearable_service.dart';
import 'wearable_repository.dart';
import 'device_metrics_service.dart';
import 'health_connect_service.dart';

// ─── State ───────────────────────────────────────────────────────────────────

class WearableState {
  final DeviceConnectionState connectionState;
  final DiscoveredDevice? connectedDevice;
  final List<DiscoveredDevice> discoveredDevices;
  final bool isScanning;
  final LiveSensorData liveData;
  final PhoneMetrics? phoneMetrics;
  final HealthSnapshot? healthSnapshot;
  final bool healthConnectAvailable;
  final WellnessSettings wellnessSettings;
  final List<SmartAlert> activeAlerts;
  final WellnessInsight aiInsight;
  final bool isLoadingInsight;
  final bool isSyncing;
  final String timeframeFilter; // 'today', 'week', 'month', 'year'
  final String
  selectedMetricType; // 'hr', 'steps', 'stress', 'sleep', 'calories', 'hrv'
  final String? errorMessage;

  WearableState({
    required this.connectionState,
    this.connectedDevice,
    this.discoveredDevices = const [],
    this.isScanning = false,
    required this.liveData,
    this.phoneMetrics,
    this.healthSnapshot,
    this.healthConnectAvailable = false,
    required this.wellnessSettings,
    this.activeAlerts = const [],
    required this.aiInsight,
    this.isLoadingInsight = false,
    this.isSyncing = false,
    this.timeframeFilter = 'today',
    this.selectedMetricType = 'hr',
    this.errorMessage,
  });

  WearableState copyWith({
    DeviceConnectionState? connectionState,
    DiscoveredDevice? connectedDevice,
    bool clearDevice = false,
    List<DiscoveredDevice>? discoveredDevices,
    bool? isScanning,
    LiveSensorData? liveData,
    PhoneMetrics? phoneMetrics,
    HealthSnapshot? healthSnapshot,
    bool? healthConnectAvailable,
    WellnessSettings? wellnessSettings,
    List<SmartAlert>? activeAlerts,
    WellnessInsight? aiInsight,
    bool? isLoadingInsight,
    bool? isSyncing,
    String? timeframeFilter,
    String? selectedMetricType,
    String? errorMessage,
  }) {
    return WearableState(
      connectionState: connectionState ?? this.connectionState,
      connectedDevice: clearDevice
          ? null
          : (connectedDevice ?? this.connectedDevice),
      discoveredDevices: discoveredDevices ?? this.discoveredDevices,
      isScanning: isScanning ?? this.isScanning,
      liveData: liveData ?? this.liveData,
      phoneMetrics: phoneMetrics ?? this.phoneMetrics,
      healthSnapshot: healthSnapshot ?? this.healthSnapshot,
      healthConnectAvailable:
          healthConnectAvailable ?? this.healthConnectAvailable,
      wellnessSettings: wellnessSettings ?? this.wellnessSettings,
      activeAlerts: activeAlerts ?? this.activeAlerts,
      aiInsight: aiInsight ?? this.aiInsight,
      isLoadingInsight: isLoadingInsight ?? this.isLoadingInsight,
      isSyncing: isSyncing ?? this.isSyncing,
      timeframeFilter: timeframeFilter ?? this.timeframeFilter,
      selectedMetricType: selectedMetricType ?? this.selectedMetricType,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

// ─── Notifier ────────────────────────────────────────────────────────────────

class WearableNotifier extends StateNotifier<WearableState> {
  final Ref _ref;
  final _service = WearableService();
  final _repository = WearableRepository();
  final _deviceMetrics = DeviceMetricsService();
  final _healthConnect = HealthConnectService();

  StreamSubscription<List<DiscoveredDevice>>? _devicesSubscription;
  StreamSubscription<DeviceConnectionState>? _connectionSubscription;
  StreamSubscription<LiveSensorData>? _dataSubscription;
  StreamSubscription<PhoneMetrics>? _metricsSubscription;
  Timer? _healthRefreshTimer;

  WearableNotifier(this._ref)
    : super(
        WearableState(
          connectionState: DeviceConnectionState.disconnected,
          liveData: LiveSensorData.empty(),
          wellnessSettings: WellnessSettings(),
          aiInsight: WellnessInsight.initial(),
        ),
      ) {
    _initialize();
  }

  Future<void> _initialize() async {
    _service.initialize();
    _repository.initialize();

    // ── BLE subscriptions ──
    _connectionSubscription = _service.connectionStateStream.listen((cs) {
      state = state.copyWith(
        connectionState: cs,
        clearDevice: cs == DeviceConnectionState.disconnected,
        connectedDevice: cs != DeviceConnectionState.disconnected
            ? _service.connectedDevice
            : null,
      );
    });

    _dataSubscription = _service.liveSensorDataStream.listen((data) {
      // Merge incoming BLE data with existing live data (BLE updates only its fields)
      final merged = state.liveData.copyWith(
        heartRate: data.heartRate ?? state.liveData.heartRate,
        spo2: data.spo2 ?? state.liveData.spo2,
        stress: data.stress ?? state.liveData.stress,
        hrv: data.hrv ?? state.liveData.hrv,
        respirationRate: data.respirationRate ?? state.liveData.respirationRate,
        bodyTemperature: data.bodyTemperature ?? state.liveData.bodyTemperature,
      );

      final alerts = _computeAlerts(merged);
      state = state.copyWith(liveData: merged, activeAlerts: alerts);
    });

    _devicesSubscription = _service.discoveredDevicesStream.listen((devices) {
      state = state.copyWith(discoveredDevices: devices);
    });

    // ── Real phone metrics (battery, network) ──
    await _deviceMetrics.initialize();
    _metricsSubscription = _deviceMetrics.metricsStream.listen((metrics) {
      state = state.copyWith(phoneMetrics: metrics);
    });

    // ── Health Connect ──
    final hcAvailable = await _healthConnect.isAvailable();
    state = state.copyWith(healthConnectAvailable: hcAvailable);
    if (hcAvailable) {
      await _fetchHealthData();
      // Refresh Health Connect data every sync frequency interval
      _healthRefreshTimer = Timer.periodic(
        Duration(seconds: state.wellnessSettings.syncFrequencySeconds),
        (_) => _fetchHealthData(),
      );
    }
  }

  Future<void> _fetchHealthData() async {
    if (!state.wellnessSettings.autoSync) return;
    try {
      state = state.copyWith(isSyncing: true);
      final snapshot = await _healthConnect.fetchSnapshot();
      state = state.copyWith(healthSnapshot: snapshot);

      // Merge Health Connect data into liveData
      if (snapshot.isAvailable) {
        final merged = state.liveData.copyWith(
          steps: snapshot.steps ?? state.liveData.steps,
          sleep: snapshot.sleepHours ?? state.liveData.sleep,
          heartRate:
              state.liveData.heartRate ??
              snapshot.heartRate, // BLE takes priority
          calories: snapshot.calories ?? state.liveData.calories,
          distance: snapshot.distanceKm ?? state.liveData.distance,
          spo2: state.liveData.spo2 ?? snapshot.spo2,
          hrv: state.liveData.hrv ?? snapshot.hrv,
          respirationRate:
              state.liveData.respirationRate ?? snapshot.respirationRate,
          bodyTemperature:
              state.liveData.bodyTemperature ?? snapshot.bodyTemperature,
          floors: snapshot.floors ?? state.liveData.floors,
          activeMinutes: snapshot.activeMinutes ?? state.liveData.activeMinutes,
          sleepQuality: snapshot.sleepQuality ?? state.liveData.sleepQuality,
        );

        final alerts = _computeAlerts(merged);
        state = state.copyWith(
          liveData: merged,
          activeAlerts: alerts,
          isSyncing: false,
        );
      } else {
        state = state.copyWith(isSyncing: false);
      }
    } catch (e) {
      print('[WearableProvider] Health Connect fetch error: $e');
      state = state.copyWith(isSyncing: false);
    }
  }

  List<SmartAlert> _computeAlerts(LiveSensorData live) {
    final alerts = <SmartAlert>[];
    final now = DateTime.now();

    if (live.heartRate != null && live.heartRate! > 100) {
      alerts.add(
        SmartAlert(
          id: 'high_hr',
          title: 'Elevated Heart Rate',
          description:
              'Your heart rate is currently ${live.heartRate} bpm. Take a deep breath to settle down.',
          type: 'warning',
          timestamp: now,
        ),
      );
    }
    if (live.stress != null && live.stress! > 70) {
      alerts.add(
        SmartAlert(
          id: 'high_stress',
          title: 'High Stress Detected',
          description:
              'Biometrics indicate stress spikes. Try a 5-minute breathing exercise or stretch.',
          type: 'warning',
          timestamp: now,
        ),
      );
    }
    if (live.sleep != null && live.sleep! < 6.0) {
      alerts.add(
        SmartAlert(
          id: 'low_sleep',
          title: 'Low Sleep Recovery',
          description:
              'Only ${live.sleep!.toStringAsFixed(1)} hrs of sleep tracked last night. Take it easy today.',
          type: 'info',
          timestamp: now,
        ),
      );
    }
    if (live.spo2 != null && live.spo2! < 95) {
      alerts.add(
        SmartAlert(
          id: 'low_spo2',
          title: 'SpO₂ Dip Alert',
          description:
              'Blood oxygen levels dipped to ${live.spo2}%. Ensure proper air circulation.',
          type: 'warning',
          timestamp: now,
        ),
      );
    }

    if (alerts.isEmpty) {
      alerts.add(
        SmartAlert(
          id: 'optimal',
          title: 'Optimal Biometrics',
          description:
              'All system checks are clear. Ready to tackle your next meeting!',
          type: 'success',
          timestamp: now,
        ),
      );
    }

    return alerts;
  }

  int getWellnessScore(List<MeetingModel> meetings) {
    final live = state.liveData;
    double score = 85.0; // default baseline
    int components = 0;

    double sleepFactor = 0;
    if (live.sleep != null) {
      sleepFactor = (live.sleep! / 8.0).clamp(0.0, 1.2) * 100;
      components++;
    }

    double stepsFactor = 0;
    if (live.steps != null) {
      stepsFactor = (live.steps! / 10000.0).clamp(0.0, 1.0) * 100;
      components++;
    }

    double stressFactor = 0;
    if (live.stress != null) {
      stressFactor = (100 - live.stress!).clamp(0.0, 100.0);
      components++;
    }

    double hrFactor = 0;
    if (live.heartRate != null) {
      int hr = live.heartRate!;
      if (hr >= 60 && hr <= 80) {
        hrFactor = 100;
      } else {
        hrFactor = (100.0 - (hr - 70).abs() * 2.0).clamp(30.0, 100.0);
      }
      components++;
    }

    double meetingFactor = 100.0;
    if (meetings.isNotEmpty) {
      double totalDurationMinutes = 0;
      double avgStress = 0;
      int stressCount = 0;
      for (var m in meetings) {
        totalDurationMinutes += m.durationSeconds / 60.0;
        if (m.stressAverage != null) {
          avgStress += m.stressAverage!;
          stressCount++;
        }
      }
      double stressMultiplier = stressCount > 0
          ? (avgStress / stressCount)
          : 30.0;
      meetingFactor =
          (100.0 - (totalDurationMinutes * 0.2) - (stressMultiplier * 0.3))
              .clamp(40.0, 100.0);
      components++;
    }

    if (components > 0) {
      double totalWeights = 0;
      double weightedSum = 0;
      if (sleepFactor > 0) {
        weightedSum += sleepFactor * 0.25;
        totalWeights += 0.25;
      }
      if (stepsFactor > 0) {
        weightedSum += stepsFactor * 0.20;
        totalWeights += 0.20;
      }
      if (stressFactor > 0) {
        weightedSum += stressFactor * 0.20;
        totalWeights += 0.20;
      }
      if (hrFactor > 0) {
        weightedSum += hrFactor * 0.15;
        totalWeights += 0.15;
      }
      if (meetings.isNotEmpty) {
        weightedSum += meetingFactor * 0.20;
        totalWeights += 0.20;
      }
      if (totalWeights > 0) {
        score = weightedSum / totalWeights;
      }
    }

    return score.clamp(30.0, 100.0).round();
  }

  Future<void> generateAICoachInsight() async {
    if (!state.wellnessSettings.shareDataWithAI) {
      state = state.copyWith(
        aiInsight: WellnessInsight(
          coachAdvice:
              'AI Coach advice disabled. Please enable "AI Coach Analysis" in settings to share biometrics data.',
          bulletPoints: [
            'Privacy mode is active.',
            'Biometrics are stored locally on-device.',
            'Data correlation is disabled.',
          ],
          generatedAt: DateTime.now(),
        ),
      );
      return;
    }

    state = state.copyWith(isLoadingInsight: true);
    try {
      final isar = IsarDatabase.instance.isar;
      final userId =
          FirebaseAuth.instance.currentUser?.uid ?? 'offline_fallback';

      // Fetch meetings today
      final todayStart = DateTime.now().subtract(const Duration(hours: 24));
      final recentMeetings = await isar.meetingModels
          .filter()
          .userIdEqualTo(userId)
          .createdAtGreaterThan(todayStart)
          .findAll();

      final live = state.liveData;

      final promptBuffer = StringBuffer();
      promptBuffer.writeln(
        'Analyze the following biometric metrics and meeting stats to provide a concise coaching advice paragraph and 3 key bullet points:',
      );
      promptBuffer.writeln('- Heart Rate: ${live.heartRate ?? "Unknown"} BPM');
      promptBuffer.writeln('- Stress level: ${live.stress ?? "Unknown"}%');
      promptBuffer.writeln(
        '- Sleep duration: ${live.sleep ?? "Unknown"} hours',
      );
      promptBuffer.writeln('- Steps today: ${live.steps ?? "Unknown"}');
      promptBuffer.writeln('- Calories: ${live.calories ?? "Unknown"} kcal');
      promptBuffer.writeln('- HRV: ${live.hrv ?? "Unknown"} ms');
      promptBuffer.writeln('- SpO2: ${live.spo2 ?? "Unknown"}%');

      if (recentMeetings.isNotEmpty) {
        promptBuffer.writeln(
          '- Meetings logged today: ${recentMeetings.length}',
        );
        for (var m in recentMeetings) {
          promptBuffer.writeln(
            '  * Title: "${m.title}", Duration: ${(m.durationSeconds / 60).round()}m, Avg HR: ${m.heartRateAverage ?? "N/A"}, Stress Level: ${m.stressAverage ?? "N/A"}, Mood: ${m.detectedEmotion ?? "N/A"}',
          );
        }
      } else {
        promptBuffer.writeln('- No meetings recorded today.');
      }

      final prompt = promptBuffer.toString();
      final systemInstruction =
          'You are the MeetingMind AI Wellness Coach. Your tone is supportive, smart, encouraging, and focused on wellness correlations between meetings and biometrics. Format your output EXACTLY as a JSON object with two fields: "coachAdvice" (string) and "bulletPoints" (array of 3 strings). Example: {"coachAdvice": "Your stress remained low...", "bulletPoints": ["point 1", "point 2", "point 3"]}';

      final jsonResult = await _ref
          .read(llmServiceProvider)
          .getJsonCompletion(
            prompt: prompt,
            systemInstruction: systemInstruction,
          );

      final advice =
          jsonResult['coachAdvice'] as String? ??
          'Keep up the good work! Sync biometric trends regularly.';
      final bulletsRaw = jsonResult['bulletPoints'] as List? ?? [];
      final bullets = bulletsRaw.map((e) => e.toString()).toList();

      state = state.copyWith(
        aiInsight: WellnessInsight(
          coachAdvice: advice,
          bulletPoints: bullets.isNotEmpty
              ? bullets
              : WellnessInsight.initial().bulletPoints,
          generatedAt: DateTime.now(),
        ),
        isLoadingInsight: false,
      );
    } catch (e) {
      print(
        '[WearableProvider] AI Coach failed: $e. Falling back to local rules-based coach.',
      );
      final live = state.liveData;
      String advice =
          'Your biometrics are stable. Keep tracking to correlate meetings.';
      List<String> bullets = [
        'Keep daily stress levels low before heavy meeting loads.',
        'Aim for 8 hours of sleep for cognitive restoration.',
        'Take a short 10-minute walk between presentations.',
      ];

      if (live.stress != null && live.stress! > 60) {
        advice =
            'Your stress level is elevated today. Take small breathing breaks between meetings.';
        bullets[0] = 'High cognitive load detected. Hydrate and pause.';
      }

      state = state.copyWith(
        aiInsight: WellnessInsight(
          coachAdvice: advice,
          bulletPoints: bullets,
          generatedAt: DateTime.now(),
        ),
        isLoadingInsight: false,
      );
    }
  }

  void updateSettings(WellnessSettings settings) {
    state = state.copyWith(wellnessSettings: settings);
    // Reconfigure the Health Connect timer if freq changed
    _healthRefreshTimer?.cancel();
    if (state.healthConnectAvailable) {
      _healthRefreshTimer = Timer.periodic(
        Duration(seconds: settings.syncFrequencySeconds),
        (_) => _fetchHealthData(),
      );
    }
  }

  void setTimeframeFilter(String filter) {
    state = state.copyWith(timeframeFilter: filter);
  }

  void setSelectedMetricType(String type) {
    state = state.copyWith(selectedMetricType: type);
  }

  Future<void> startScan() async {
    state = state.copyWith(isScanning: true, discoveredDevices: []);
    await _service.startScanning();
  }

  Future<void> stopScan() async {
    await _service.stopScanning();
    state = state.copyWith(isScanning: false);
  }

  Future<void> connect(DiscoveredDevice device) async {
    state = state.copyWith(errorMessage: null);
    try {
      await _service.connectDevice(device);
      await _repository.saveConnectedDeviceInfo(device);
    } catch (e) {
      state = state.copyWith(
        connectionState: DeviceConnectionState.disconnected,
        clearDevice: true,
        errorMessage: 'Failed to connect to ${device.name}: ${e.toString()}',
      );
    }
  }

  Future<void> disconnect() async {
    await _service.disconnectDevice();
    await _repository.clearDeviceInfo();
    state = state.copyWith(
      connectionState: DeviceConnectionState.disconnected,
      clearDevice: true,
    );
  }

  Future<void> syncNow() async {
    await _fetchHealthData();
    await _repository.syncOfflineData();
  }

  Future<void> refreshHealthData() => _fetchHealthData();

  @override
  void dispose() {
    _devicesSubscription?.cancel();
    _connectionSubscription?.cancel();
    _dataSubscription?.cancel();
    _metricsSubscription?.cancel();
    _healthRefreshTimer?.cancel();
    _deviceMetrics.dispose();
    _service.dispose();
    super.dispose();
  }
}

// ─── Provider ────────────────────────────────────────────────────────────────

final wearableProvider = StateNotifierProvider<WearableNotifier, WearableState>(
  (ref) => WearableNotifier(ref),
);
