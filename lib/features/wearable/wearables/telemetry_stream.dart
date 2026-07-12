import 'dart:async';
import '../models/sensor_reading.dart';

class TelemetryStream {
  static final TelemetryStream _instance = TelemetryStream._internal();
  factory TelemetryStream() => _instance;
  TelemetryStream._internal();

  final StreamController<SensorReading> _controller =
      StreamController<SensorReading>.broadcast();

  Stream<SensorReading> get stream => _controller.stream;

  void addReading(SensorReading reading) {
    _controller.add(reading);
  }

  void dispose() {
    _controller.close();
  }
}
