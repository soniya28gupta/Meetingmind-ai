/// Wearable device type classification.
enum WearableDeviceType {
  xiaomiBand,
  xiaomiWatch,
  fitbit,
  ouraRing,
  samsungWatch,
  pixelWatch,
  genericHeartRate,
}

/// BLE / wearable connection state.
enum DeviceConnectionState { disconnected, connecting, connected, reconnecting }

/// Connectivity type from connectivity_plus.
enum NetworkType { wifi, mobile4G, mobile5G, none, unknown }

/// A discovered BLE device.
class DiscoveredDevice {
  final String id;
  final String name;
  final WearableDeviceType type;
  final int rssi;

  DiscoveredDevice({
    required this.id,
    required this.name,
    required this.type,
    required this.rssi,
  });
}

/// Live sensor data from a connected BLE wearable.
/// All health fields are nullable — null means "no real data available".
class LiveSensorData {
  final int? heartRate; // real BPM from BLE GATT; null if no wearable
  final double? stress; // from wearable if it exposes stress; null otherwise
  final int? steps; // from Health Connect; null if unavailable
  final double? sleep; // from Health Connect (hours); null if unavailable
  final int? calories; // from Health Connect; null if unavailable
  final double? distance; // from Health Connect (km); null if unavailable
  final int? spo2; // SpO₂ % from wearable GATT; null if unavailable
  final int? battery; // battery % from wearable GATT; null if unavailable
  final double? hrv; // Heart Rate Variability (ms); null if unavailable
  final double? respirationRate; // Respiration rate (breaths per minute)
  final double? bodyTemperature; // Body temperature (Celsius)
  final int? floors; // Floors climbed today
  final int? activeMinutes; // Active physical minutes today
  final double? sleepQuality; // Sleep quality score %
  final DateTime timestamp;

  LiveSensorData({
    this.heartRate,
    this.stress,
    this.steps,
    this.sleep,
    this.calories,
    this.distance,
    this.spo2,
    this.battery,
    this.hrv,
    this.respirationRate,
    this.bodyTemperature,
    this.floors,
    this.activeMinutes,
    this.sleepQuality,
    required this.timestamp,
  });

  /// Empty initial state — no fake values.
  factory LiveSensorData.empty() => LiveSensorData(timestamp: DateTime.now());

  LiveSensorData copyWith({
    int? heartRate,
    double? stress,
    int? steps,
    double? sleep,
    int? calories,
    double? distance,
    int? spo2,
    int? battery,
    double? hrv,
    double? respirationRate,
    double? bodyTemperature,
    int? floors,
    int? activeMinutes,
    double? sleepQuality,
    DateTime? timestamp,
  }) {
    return LiveSensorData(
      heartRate: heartRate ?? this.heartRate,
      stress: stress ?? this.stress,
      steps: steps ?? this.steps,
      sleep: sleep ?? this.sleep,
      calories: calories ?? this.calories,
      distance: distance ?? this.distance,
      spo2: spo2 ?? this.spo2,
      battery: battery ?? this.battery,
      hrv: hrv ?? this.hrv,
      respirationRate: respirationRate ?? this.respirationRate,
      bodyTemperature: bodyTemperature ?? this.bodyTemperature,
      floors: floors ?? this.floors,
      activeMinutes: activeMinutes ?? this.activeMinutes,
      sleepQuality: sleepQuality ?? this.sleepQuality,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}

/// Real-time phone device metrics (battery, network, device info).
class PhoneMetrics {
  final int batteryLevel; // 0–100 %
  final bool isCharging;
  final String chargingType; // 'USB', 'AC', 'Wireless', 'Not charging'
  final NetworkType networkType;
  final String networkLabel; // 'Wi-Fi', '4G LTE', '5G', 'No Internet'
  final String deviceName; // e.g. 'Pixel 8 Pro'
  final String androidVersion; // e.g. '14'
  final DateTime timestamp;

  PhoneMetrics({
    required this.batteryLevel,
    required this.isCharging,
    required this.chargingType,
    required this.networkType,
    required this.networkLabel,
    required this.deviceName,
    required this.androidVersion,
    required this.timestamp,
  });

  factory PhoneMetrics.initial() => PhoneMetrics(
    batteryLevel: 0,
    isCharging: false,
    chargingType: 'Unknown',
    networkType: NetworkType.unknown,
    networkLabel: 'Checking...',
    deviceName: 'Android Device',
    androidVersion: '',
    timestamp: DateTime.now(),
  );
}

/// Health Connect snapshot.
class HealthSnapshot {
  final int? steps;
  final double? sleepHours;
  final int? heartRate;
  final int? calories;
  final double? distanceKm;
  final int? spo2;
  final double? hrv;
  final double? respirationRate;
  final double? bodyTemperature;
  final int? floors;
  final int? activeMinutes;
  final double? sleepQuality;
  final bool isAvailable;
  final String? errorMessage;

  HealthSnapshot({
    this.steps,
    this.sleepHours,
    this.heartRate,
    this.calories,
    this.distanceKm,
    this.spo2,
    this.hrv,
    this.respirationRate,
    this.bodyTemperature,
    this.floors,
    this.activeMinutes,
    this.sleepQuality,
    required this.isAvailable,
    this.errorMessage,
  });

  factory HealthSnapshot.unavailable(String reason) =>
      HealthSnapshot(isAvailable: false, errorMessage: reason);
}

/// Settings configuration for Wearable module
class WellnessSettings {
  final bool autoSync;
  final bool backgroundSync;
  final bool autoConnect;
  final String preferredDevice;
  final bool shareDataWithAI;
  final int syncFrequencySeconds;
  final String unitSystem; // 'metric' or 'imperial'

  WellnessSettings({
    this.autoSync = true,
    this.backgroundSync = true,
    this.autoConnect = true,
    this.preferredDevice = '',
    this.shareDataWithAI = true,
    this.syncFrequencySeconds = 30,
    this.unitSystem = 'metric',
  });

  WellnessSettings copyWith({
    bool? autoSync,
    bool? backgroundSync,
    bool? autoConnect,
    String? preferredDevice,
    bool? shareDataWithAI,
    int? syncFrequencySeconds,
    String? unitSystem,
  }) {
    return WellnessSettings(
      autoSync: autoSync ?? this.autoSync,
      backgroundSync: backgroundSync ?? this.backgroundSync,
      autoConnect: autoConnect ?? this.autoConnect,
      preferredDevice: preferredDevice ?? this.preferredDevice,
      shareDataWithAI: shareDataWithAI ?? this.shareDataWithAI,
      syncFrequencySeconds: syncFrequencySeconds ?? this.syncFrequencySeconds,
      unitSystem: unitSystem ?? this.unitSystem,
    );
  }
}

/// Real-time health alert computed dynamically
class SmartAlert {
  final String id;
  final String title;
  final String description;
  final String type; // 'warning', 'info', 'success'
  final DateTime timestamp;

  SmartAlert({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.timestamp,
  });
}

/// Personalized Coach Insight generated by AI Coach
class WellnessInsight {
  final String coachAdvice;
  final List<String> bulletPoints;
  final DateTime generatedAt;

  WellnessInsight({
    required this.coachAdvice,
    required this.bulletPoints,
    required this.generatedAt,
  });

  factory WellnessInsight.initial() => WellnessInsight(
    coachAdvice:
        'Your AI Coach is ready to analyze your data. Tap "Refresh Coach" to generate personalized health insights.',
    bulletPoints: [
      'Sync your device to analyze heart rate and stress trends.',
      'Record meetings to view cognitive stress correlation.',
      'Track daily steps and sleep to compute your recovery score.',
    ],
    generatedAt: DateTime.now(),
  );
}
