class SensorReading {
  final int? heartRate;
  final double? stress;
  final int? steps;
  final double? sleep;
  final int? calories;
  final double? distance;
  final int? spo2;
  final int? battery;
  final double? hrv;
  final double? respirationRate;
  final double? bodyTemperature;
  final int? floors;
  final int? activeMinutes;
  final double? sleepQuality;
  final DateTime timestamp;

  SensorReading({
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

  factory SensorReading.empty() => SensorReading(timestamp: DateTime.now());

  SensorReading copyWith({
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
    return SensorReading(
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
