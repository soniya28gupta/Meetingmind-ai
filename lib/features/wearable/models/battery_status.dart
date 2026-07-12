class BatteryStatus {
  final int level;
  final bool isCharging;
  final DateTime timestamp;

  BatteryStatus({
    required this.level,
    required this.isCharging,
    required this.timestamp,
  });
}
