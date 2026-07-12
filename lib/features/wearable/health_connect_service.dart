import 'package:health/health.dart';
import 'wearable_models.dart';

/// Reads health data from Google Health Connect.
/// Returns null fields when Health Connect is not installed or not authorized.
class HealthConnectService {
  static final HealthConnectService _instance =
      HealthConnectService._internal();
  factory HealthConnectService() => _instance;
  HealthConnectService._internal();

  final _health = Health();

  static const _types = [
    HealthDataType.STEPS,
    HealthDataType.HEART_RATE,
    HealthDataType.SLEEP_ASLEEP,
    HealthDataType.SLEEP_IN_BED,
    HealthDataType.ACTIVE_ENERGY_BURNED,
    HealthDataType.DISTANCE_WALKING_RUNNING,
    HealthDataType.BLOOD_OXYGEN,
  ];

  bool _authorized = false;

  /// Requests Health Connect permissions. Returns true if granted.
  Future<bool> requestPermissions() async {
    try {
      // Configure for Health Connect (Android)
      _health.configure();
      final permissions = _types.map((t) => HealthDataAccess.READ).toList();
      _authorized = await _health.requestAuthorization(
        _types,
        permissions: permissions,
      );
      print('[HealthConnect] Authorization result: $_authorized');
      return _authorized;
    } catch (e) {
      print('[HealthConnect] Permission request failed: $e');
      return false;
    }
  }

  /// Fetches a snapshot of today's health data.
  Future<HealthSnapshot> fetchSnapshot() async {
    if (!_authorized) {
      final granted = await requestPermissions();
      if (!granted) {
        return HealthSnapshot.unavailable(
          'Health Connect permission not granted',
        );
      }
    }

    try {
      final now = DateTime.now();
      final midnightToday = DateTime(now.year, now.month, now.day);
      final yesterday = midnightToday.subtract(
        const Duration(hours: 8),
      ); // for sleep

      // Fetch all types
      final data = await _health.getHealthDataFromTypes(
        types: _types,
        startTime: yesterday,
        endTime: now,
      );

      // Steps (sum today)
      int? steps;
      int stepSum = 0;
      for (final d in data) {
        if (d.type == HealthDataType.STEPS &&
            d.dateFrom.isAfter(midnightToday)) {
          final v = (d.value as NumericHealthValue).numericValue;
          stepSum += v.toInt();
        }
      }
      if (stepSum > 0) steps = stepSum;

      // Heart Rate (most recent)
      int? heartRate;
      final hrPoints = data
          .where((d) => d.type == HealthDataType.HEART_RATE)
          .toList();
      if (hrPoints.isNotEmpty) {
        hrPoints.sort((a, b) => b.dateFrom.compareTo(a.dateFrom));
        heartRate = (hrPoints.first.value as NumericHealthValue).numericValue
            .toInt();
      }

      // Calories (sum today)
      int? calories;
      double calSum = 0;
      for (final d in data) {
        if (d.type == HealthDataType.ACTIVE_ENERGY_BURNED &&
            d.dateFrom.isAfter(midnightToday)) {
          final v = (d.value as NumericHealthValue).numericValue;
          calSum += v;
        }
      }
      if (calSum > 0) calories = calSum.toInt();

      // Distance (sum today, in km)
      double? distanceKm;
      double distSum = 0;
      for (final d in data) {
        if (d.type == HealthDataType.DISTANCE_WALKING_RUNNING &&
            d.dateFrom.isAfter(midnightToday)) {
          final v = (d.value as NumericHealthValue).numericValue;
          distSum += v;
        }
      }
      if (distSum > 0) distanceKm = distSum / 1000; // meters → km

      // Sleep (total hours from yesterday midnight)
      double? sleepHours;
      double sleepMinutes = 0;
      for (final d in data) {
        if (d.type == HealthDataType.SLEEP_ASLEEP ||
            d.type == HealthDataType.SLEEP_IN_BED) {
          final durationMins = d.dateTo.difference(d.dateFrom).inMinutes;
          sleepMinutes += durationMins;
        }
      }
      if (sleepMinutes > 0) sleepHours = sleepMinutes / 60;

      // SpO₂ (most recent)
      int? spo2;
      final spo2Points = data
          .where((d) => d.type == HealthDataType.BLOOD_OXYGEN)
          .toList();
      if (spo2Points.isNotEmpty) {
        spo2Points.sort((a, b) => b.dateFrom.compareTo(a.dateFrom));
        spo2 = (spo2Points.first.value as NumericHealthValue).numericValue
            .toInt();
      }

      return HealthSnapshot(
        isAvailable: true,
        steps: steps,
        heartRate: heartRate,
        sleepHours: sleepHours,
        calories: calories,
        distanceKm: distanceKm,
        spo2: spo2,
      );
    } catch (e) {
      print('[HealthConnect] Fetch error: $e');
      return HealthSnapshot.unavailable('Failed to read Health Connect: $e');
    }
  }

  /// Checks if Health Connect is available on this device.
  Future<bool> isAvailable() async {
    try {
      final status = await _health.getHealthConnectSdkStatus();
      return status == HealthConnectSdkStatus.sdkAvailable;
    } catch (_) {
      return false;
    }
  }
}
