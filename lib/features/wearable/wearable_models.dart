enum WearableDeviceType {
  xiaomiBand,
  xiaomiWatch,
  fitbit,
  ouraRing,
  samsungWatch,
  genericHeartRate,
  simulator,
}

enum DeviceConnectionState {
  disconnected,
  connecting,
  connected,
  reconnecting,
}

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

class LiveSensorData {
  final int heartRate;
  final double stress;
  final int steps;
  final int battery;
  final double sleep;
  final DateTime timestamp;

  LiveSensorData({
    required this.heartRate,
    required this.stress,
    required this.steps,
    required this.battery,
    required this.sleep,
    required this.timestamp,
  });

  factory LiveSensorData.initial() {
    return LiveSensorData(
      heartRate: 72,
      stress: 25.0,
      steps: 0,
      battery: 100,
      sleep: 8.0,
      timestamp: DateTime.now(),
    );
  }
}
