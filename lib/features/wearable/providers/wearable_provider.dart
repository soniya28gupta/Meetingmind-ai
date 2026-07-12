import 'dart:async';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:isar/isar.dart';
import '../../../database/isar_database.dart';
import '../../../database/schemas/meeting_models.dart';
import '../../../services/llm_service.dart';
import '../models/wearable_device.dart';
import '../models/sensor_reading.dart';
import '../wearables/wearable_service.dart';
import '../wearables/wearable_repository.dart';
import '../device_metrics_service.dart';
import '../health_connect_service.dart';

// Compat mapping to keep dashboard compilation clean
import '../wearable_models.dart' as old;

class WearableState {
  final old.DeviceConnectionState connectionState;
  final old.DiscoveredDevice? connectedDevice;
  final List<old.DiscoveredDevice> discoveredDevices;
  final bool isScanning;
  final old.LiveSensorData liveData;
  final old.PhoneMetrics? phoneMetrics;
  final old.HealthSnapshot? healthSnapshot;
  final bool healthConnectAvailable;
  final old.WellnessSettings wellnessSettings;
  final List<old.SmartAlert> activeAlerts;
  final old.WellnessInsight aiInsight;
  final bool isLoadingInsight;
  final bool isSyncing;
  final String timeframeFilter;
  final String selectedMetricType;
  final String? errorMessage;
  final bool isSimulationMode; // Simulation switcher

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
    this.isSimulationMode = false,
  });

  WearableState copyWith({
    old.DeviceConnectionState? connectionState,
    old.DiscoveredDevice? connectedDevice,
    bool clearDevice = false,
    List<old.DiscoveredDevice>? discoveredDevices,
    bool? isScanning,
    old.LiveSensorData? liveData,
    old.PhoneMetrics? phoneMetrics,
    old.HealthSnapshot? healthSnapshot,
    bool? healthConnectAvailable,
    old.WellnessSettings? wellnessSettings,
    List<old.SmartAlert>? activeAlerts,
    old.WellnessInsight? aiInsight,
    bool? isLoadingInsight,
    bool? isSyncing,
    String? timeframeFilter,
    String? selectedMetricType,
    String? errorMessage,
    bool? isSimulationMode,
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
      isSimulationMode: isSimulationMode ?? this.isSimulationMode,
    );
  }
}

class WearableNotifier extends StateNotifier<WearableState> {
  final Ref _ref;
  final _service = WearableService();
  final _repository = WearableRepository();
  final _deviceMetrics = DeviceMetricsService();
  final _healthConnect = HealthConnectService();

  StreamSubscription<SensorReading>? _dataSubscription;
  StreamSubscription<WearableDevice?>? _connectionSubscription;
  StreamSubscription<old.PhoneMetrics>? _metricsSubscription;
  Timer? _healthRefreshTimer;
  Timer? _simulationTimer;
  int _simulatedBattery = 100;
  int _simulatedSteps = 8200;
  int _simulatedCalories = 450;

  WearableNotifier(this._ref)
    : super(
        WearableState(
          connectionState: old.DeviceConnectionState.disconnected,
          liveData: old.LiveSensorData.empty(),
          wellnessSettings: old.WellnessSettings(),
          aiInsight: old.WellnessInsight.initial(),
        ),
      ) {
    _initialize();
  }

  Future<void> _initialize() async {
    _service.initialize();
    _repository.initialize();

    _connectionSubscription = _service.connectionStream.listen((device) {
      if (device != null) {
        state = state.copyWith(
          connectionState: device.isConnected
              ? old.DeviceConnectionState.connected
              : old.DeviceConnectionState.connecting,
          connectedDevice: old.DiscoveredDevice(
            id: device.id,
            name: device.name,
            type: old.WearableDeviceType.values.firstWhere(
              (e) => e.name == device.type.name,
              orElse: () => old.WearableDeviceType.genericHeartRate,
            ),
            rssi: device.rssi,
          ),
        );
      } else {
        state = state.copyWith(
          connectionState: old.DeviceConnectionState.disconnected,
          clearDevice: true,
        );
      }
    });

    _dataSubscription = _service.telemetryStream.listen((data) {
      if (state.isSimulationMode) return; // skip real BLE data if simulating

      final merged = state.liveData.copyWith(
        heartRate: data.heartRate ?? state.liveData.heartRate,
        stress: data.stress ?? state.liveData.stress,
        steps: data.steps ?? state.liveData.steps,
        sleep: data.sleep ?? state.liveData.sleep,
        calories: data.calories ?? state.liveData.calories,
        distance: data.distance ?? state.liveData.distance,
        spo2: data.spo2 ?? state.liveData.spo2,
        battery: data.battery ?? state.liveData.battery,
        hrv: data.hrv ?? state.liveData.hrv,
        respirationRate: data.respirationRate ?? state.liveData.respirationRate,
        bodyTemperature: data.bodyTemperature ?? state.liveData.bodyTemperature,
        floors: data.floors ?? state.liveData.floors,
        activeMinutes: data.activeMinutes ?? state.liveData.activeMinutes,
        sleepQuality: data.sleepQuality ?? state.liveData.sleepQuality,
        timestamp: DateTime.now(),
      );

      final alerts = _computeAlerts(merged);
      state = state.copyWith(liveData: merged, activeAlerts: alerts);
    });

    await _deviceMetrics.initialize();
    _metricsSubscription = _deviceMetrics.metricsStream.listen((metrics) {
      state = state.copyWith(phoneMetrics: metrics);
    });

    final hcAvailable = await _healthConnect.isAvailable();
    state = state.copyWith(healthConnectAvailable: hcAvailable);
    if (hcAvailable) {
      await _fetchHealthData();
      _healthRefreshTimer = Timer.periodic(
        Duration(seconds: state.wellnessSettings.syncFrequencySeconds),
        (_) => _fetchHealthData(),
      );
    }
  }

  Future<void> _fetchHealthData() async {
    if (!state.wellnessSettings.autoSync) return;
    if (state.isSimulationMode) return;

    try {
      state = state.copyWith(isSyncing: true);
      final snapshot = await _healthConnect.fetchSnapshot();
      state = state.copyWith(healthSnapshot: snapshot);

      // Trigger Health Connect Fallback if no BLE device is active
      final noActiveBle =
          state.connectionState == old.DeviceConnectionState.disconnected;

      if (snapshot.isAvailable && noActiveBle) {
        final merged = state.liveData.copyWith(
          steps: snapshot.steps ?? state.liveData.steps,
          sleep: snapshot.sleepHours ?? state.liveData.sleep,
          heartRate: snapshot.heartRate ?? state.liveData.heartRate,
          calories: snapshot.calories ?? state.liveData.calories,
          distance: snapshot.distanceKm ?? state.liveData.distance,
          spo2: snapshot.spo2 ?? state.liveData.spo2,
          hrv: snapshot.hrv ?? state.liveData.hrv,
          respirationRate:
              snapshot.respirationRate ?? state.liveData.respirationRate,
          bodyTemperature:
              snapshot.bodyTemperature ?? state.liveData.bodyTemperature,
          floors: snapshot.floors ?? state.liveData.floors,
          activeMinutes: snapshot.activeMinutes ?? state.liveData.activeMinutes,
          sleepQuality: snapshot.sleepQuality ?? state.liveData.sleepQuality,
          timestamp: DateTime.now(),
        );

        final alerts = _computeAlerts(merged);
        state = state.copyWith(liveData: merged, activeAlerts: alerts);
      }
      state = state.copyWith(isSyncing: false);
    } catch (e) {
      print('[WearableProvider] Health Connect sync failure: $e');
      state = state.copyWith(isSyncing: false);
    }
  }

  void toggleSimulationMode(bool enabled) {
    state = state.copyWith(isSimulationMode: enabled);
    _simulationTimer?.cancel();

    if (enabled) {
      print(
        '[WearableProvider] Simulation Mode Toggled ON. Starting simulator...',
      );
      _service.disconnect();
      state = state.copyWith(
        connectionState: old.DeviceConnectionState.connected,
        connectedDevice: old.DiscoveredDevice(
          id: 'sim_01',
          name: 'Mi Band Simulator',
          type: old.WearableDeviceType.xiaomiBand,
          rssi: -50,
        ),
      );

      _simulationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        final rand = Random();
        final hr = 65 + rand.nextInt(55); // 65–120 bpm
        final stress = 10.0 + rand.nextInt(80); // 10–90%
        final rssi = -40 - rand.nextInt(50); // -40 to -90 dBm

        if (timer.tick % 30 == 0 && _simulatedBattery > 0) {
          _simulatedBattery--;
        }
        _simulatedSteps += rand.nextInt(3);
        _simulatedCalories += rand.nextBool() ? 1 : 0;

        final simData = old.LiveSensorData(
          heartRate: hr,
          stress: stress,
          steps: _simulatedSteps,
          sleep: 7.4,
          calories: _simulatedCalories,
          distance: 6.2,
          spo2: 98,
          battery: _simulatedBattery,
          hrv: 55.0,
          respirationRate: 16.0,
          bodyTemperature: 36.6,
          timestamp: DateTime.now(),
        );

        final alerts = _computeAlerts(simData);
        state = state.copyWith(liveData: simData, activeAlerts: alerts);
      });
    } else {
      print(
        '[WearableProvider] Simulation Mode Toggled OFF. Resuming real hardware scan.',
      );
      state = state.copyWith(
        connectionState: old.DeviceConnectionState.disconnected,
        clearDevice: true,
        liveData: old.LiveSensorData.empty(),
        activeAlerts: [],
      );
      _fetchHealthData();
    }
  }

  List<old.SmartAlert> _computeAlerts(old.LiveSensorData live) {
    final alerts = <old.SmartAlert>[];
    final now = DateTime.now();

    if (live.heartRate != null && live.heartRate! > 100) {
      alerts.add(
        old.SmartAlert(
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
        old.SmartAlert(
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
        old.SmartAlert(
          id: 'low_sleep',
          title: 'Low Sleep Recovery',
          description:
              'Only ${live.sleep!.toStringAsFixed(1)} hrs of sleep tracked last night. Take it easy today.',
          type: 'info',
          timestamp: now,
        ),
      );
    }

    if (alerts.isEmpty) {
      alerts.add(
        old.SmartAlert(
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
    double score = 85.0;
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
        aiInsight: old.WellnessInsight(
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

      final todayStart = DateTime.now().subtract(const Duration(hours: 24));
      final recentMeetings = await isar.meetingModels
          .filter()
          .userIdEqualTo(userId)
          .findAll();

      final filteredMeetings = recentMeetings
          .where((m) => m.createdAt != null && m.createdAt!.isAfter(todayStart))
          .toList();

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

      if (filteredMeetings.isNotEmpty) {
        promptBuffer.writeln(
          '- Meetings logged today: ${filteredMeetings.length}',
        );
        for (var m in filteredMeetings) {
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
        aiInsight: old.WellnessInsight(
          coachAdvice: advice,
          bulletPoints: bullets.isNotEmpty
              ? bullets
              : old.WellnessInsight.initial().bulletPoints,
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
        aiInsight: old.WellnessInsight(
          coachAdvice: advice,
          bulletPoints: bullets,
          generatedAt: DateTime.now(),
        ),
        isLoadingInsight: false,
      );
    }
  }

  void updateSettings(old.WellnessSettings settings) {
    state = state.copyWith(wellnessSettings: settings);
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

  Future<void> connect(old.DiscoveredDevice device) async {
    state = state.copyWith(errorMessage: null);
    try {
      final type = WearableDeviceType.values.firstWhere(
        (e) => e.name == device.type.name,
        orElse: () => WearableDeviceType.genericHeartRate,
      );

      final wd = WearableDevice(
        id: device.id,
        name: device.name,
        type: type,
        rssi: device.rssi,
      );

      await _service.connect(wd);
      await _repository.saveConnectedDeviceInfo(wd);
    } catch (e) {
      state = state.copyWith(
        connectionState: old.DeviceConnectionState.disconnected,
        clearDevice: true,
        errorMessage: 'Failed to connect to ${device.name}: ${e.toString()}',
      );
    }
  }

  Future<void> disconnect() async {
    await _service.disconnect();
    await _repository.clearDeviceInfo();
    state = state.copyWith(
      connectionState: old.DeviceConnectionState.disconnected,
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
    _dataSubscription?.cancel();
    _connectionSubscription?.cancel();
    _metricsSubscription?.cancel();
    _healthRefreshTimer?.cancel();
    _simulationTimer?.cancel();
    _deviceMetrics.dispose();
    _service.dispose();
    super.dispose();
  }
}

final wearableProvider = StateNotifierProvider<WearableNotifier, WearableState>(
  (ref) => WearableNotifier(ref),
);
