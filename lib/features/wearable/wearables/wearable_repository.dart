import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:isar/isar.dart';
import '../../../database/isar_database.dart';
import '../../../database/schemas/meeting_models.dart';
import '../models/wearable_device.dart';
import '../models/sensor_reading.dart';
import 'wearable_service.dart';

class WearableRepository {
  static final WearableRepository _instance = WearableRepository._internal();
  factory WearableRepository() => _instance;
  WearableRepository._internal();

  final _wearableService = WearableService();
  StreamSubscription<SensorReading>? _sensorStreamSubscription;
  Timer? _syncTimer;
  Timer? _cleanupTimer;

  void initialize() {
    _wearableService.initialize();

    _sensorStreamSubscription = _wearableService.telemetryStream.listen((
      data,
    ) async {
      await saveSensorReading(data);
    });

    _syncTimer = Timer.periodic(const Duration(seconds: 15), (timer) {
      syncOfflineData();
    });

    _cleanupTimer = Timer.periodic(const Duration(hours: 24), (timer) {
      cleanUpOldData();
    });

    restorePreviousConnection();
  }

  int _generateId() {
    return (DateTime.now().microsecondsSinceEpoch + Random().nextInt(1000)) &
        0x7FFFFFFFFFFFFFFF;
  }

  Future<void> saveSensorReading(SensorReading reading) async {
    final user = FirebaseAuth.instance.currentUser;
    final activeDevice = _wearableService.connectedDevice;
    if (user == null || activeDevice == null) return;

    final isar = IsarDatabase.instance.isar;
    final model = SensorReadingModel()
      ..id = _generateId()
      ..userId = user.uid
      ..deviceId = activeDevice.id
      ..timestamp = reading.timestamp
      ..heartRate = reading.heartRate
      ..stress = reading.stress
      ..steps = reading.steps
      ..battery = reading.battery
      ..sleep = reading.sleep
      ..isSynced = false;

    try {
      await isar.writeTxn(() async {
        await isar.sensorReadingModels.put(model);
      });

      await _updateDailyMetrics(reading);
    } catch (e) {
      print(
        "[WearableRepository ERROR] Failed to save local sensor reading: $e",
      );
    }
  }

  Future<void> _updateDailyMetrics(SensorReading reading) async {
    final isar = IsarDatabase.instance.isar;
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);

    try {
      await isar.writeTxn(() async {
        var daily = await isar.dailyMetricsModels
            .filter()
            .dateEqualTo(todayStart)
            .findFirst();

        if (daily == null) {
          daily = DailyMetricsModel()
            ..id = _generateId()
            ..date = todayStart
            ..totalSteps = reading.steps
            ..averageHeartRate = reading.heartRate?.toDouble()
            ..sleepHours = reading.sleep
            ..sleepScore = 80.0
            ..stressScore = reading.stress
            ..batteryLevel = reading.battery;
        } else {
          if (reading.steps != null) {
            daily.totalSteps = max(daily.totalSteps ?? 0, reading.steps!);
          }
          if (reading.heartRate != null) {
            daily.averageHeartRate =
                ((daily.averageHeartRate ?? 72.0) * 19 + reading.heartRate!) /
                20.0;
          }
          if (reading.stress != null) {
            daily.stressScore =
                ((daily.stressScore ?? 25.0) * 19 + reading.stress!) / 20.0;
          }
          if (reading.sleep != null) daily.sleepHours = reading.sleep;
          if (reading.battery != null) daily.batteryLevel = reading.battery;
        }
        await isar.dailyMetricsModels.put(daily);
      });
    } catch (e) {
      print("[WearableRepository ERROR] _updateDailyMetrics failed: $e");
    }
  }

  Future<void> syncOfflineData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final isar = IsarDatabase.instance.isar;

    try {
      final unsynced = await isar.sensorReadingModels
          .filter()
          .isSyncedEqualTo(false)
          .limit(50)
          .findAll();
      if (unsynced.isEmpty) return;

      final batch = FirebaseFirestore.instance.batch();
      for (var reading in unsynced) {
        final docRef = FirebaseFirestore.instance
            .collection('sensor_data')
            .doc(reading.id.toString());
        batch.set(docRef, {
          'userId': user.uid,
          'deviceId': reading.deviceId,
          'timestamp': reading.timestamp != null
              ? Timestamp.fromDate(reading.timestamp!)
              : FieldValue.serverTimestamp(),
          'heartRate': reading.heartRate,
          'steps': reading.steps,
          'sleep': reading.sleep,
          'stress': reading.stress,
          'battery': reading.battery,
        });
      }

      await batch.commit();

      await isar.writeTxn(() async {
        for (var reading in unsynced) {
          reading.isSynced = true;
          await isar.sensorReadingModels.put(reading);
        }
      });
      print(
        "[WearableRepository] Synced ${unsynced.length} records to Firestore.",
      );
    } catch (e) {
      print(
        "[WearableRepository ERROR] Sync failed: $e. Will retry automatically.",
      );
    }
  }

  Future<void> cleanUpOldData() async {
    final isar = IsarDatabase.instance.isar;
    final boundary = DateTime.now().subtract(const Duration(days: 30));

    try {
      await isar.writeTxn(() async {
        final count = await isar.sensorReadingModels
            .filter()
            .timestampLessThan(boundary)
            .deleteAll();
        if (count > 0) {
          print(
            "[WearableRepository] Cleaned up $count telemetry readings older than 30 days.",
          );
        }
      });
    } catch (e) {
      print("[WearableRepository ERROR] cleanUpOldData failed: $e");
    }
  }

  Future<void> saveConnectedDeviceInfo(WearableDevice device) async {
    final isar = IsarDatabase.instance.isar;
    final info = DeviceInfoModel()
      ..id = _generateId()
      ..deviceId = device.id
      ..name = device.name
      ..type = device.type.name
      ..battery = device.batteryLevel ?? 100
      ..connectionState = device.isConnected ? 'connected' : 'disconnected'
      ..lastConnectedAt = DateTime.now()
      ..isAutoReconnectEnabled = true;

    try {
      await isar.writeTxn(() async {
        await isar.deviceInfoModels.clear();
        await isar.deviceInfoModels.put(info);
      });
    } catch (e) {
      print("[WearableRepository ERROR] Failed to save device info: $e");
    }
  }

  Future<void> clearDeviceInfo() async {
    final isar = IsarDatabase.instance.isar;
    try {
      await isar.writeTxn(() async {
        await isar.deviceInfoModels.clear();
      });
    } catch (_) {}
  }

  Future<void> restorePreviousConnection() async {
    final isar = IsarDatabase.instance.isar;
    try {
      final info = await isar.deviceInfoModels
          .filter()
          .isAutoReconnectEnabledEqualTo(true)
          .findFirst();
      if (info == null) return;

      final deviceType = WearableDeviceType.values.firstWhere(
        (e) => e.name == info.type,
        orElse: () => WearableDeviceType.genericHeartRate,
      );

      final device = WearableDevice(
        id: info.deviceId ?? '',
        name: info.name ?? '',
        type: deviceType,
        rssi: -60,
        batteryLevel: info.battery,
        isConnected: false,
      );

      print(
        "[WearableRepository] Restoring previous connection to ${device.name}...",
      );
      await _wearableService.connect(device);
    } catch (e) {
      print("[WearableRepository ERROR] Auto-reconnect failed: $e");
    }
  }

  void dispose() {
    _sensorStreamSubscription?.cancel();
    _syncTimer?.cancel();
    _cleanupTimer?.cancel();
    _wearableService.dispose();
  }
}
