import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:isar/isar.dart';
import '../../database/isar_database.dart';
import '../../database/schemas/meeting_models.dart';
import 'wearable_models.dart';
import 'wearable_service.dart';

class WearableRepository {
  static final WearableRepository _instance = WearableRepository._internal();
  factory WearableRepository() => _instance;
  WearableRepository._internal();

  final _wearableService = WearableService();
  StreamSubscription<LiveSensorData>? _sensorStreamSubscription;
  Timer? _syncTimer;
  Timer? _cleanupTimer;

  void initialize() {
    _wearableService.initialize();

    // Listen to live streams and save them to local Isar database
    _sensorStreamSubscription = _wearableService.liveSensorDataStream.listen((
      data,
    ) async {
      await saveSensorReading(data);
    });

    // Run sync manager every 15 seconds to sync offline data
    _syncTimer = Timer.periodic(const Duration(seconds: 15), (timer) {
      syncOfflineData();
    });

    // Run clean up routine every 24 hours to clear data older than 30 days
    _cleanupTimer = Timer.periodic(const Duration(hours: 24), (timer) {
      cleanUpOldData();
    });

    // Restore previous connection in background
    restorePreviousConnection();
  }

  int _generateId() {
    return (DateTime.now().microsecondsSinceEpoch + Random().nextInt(1000)) &
        0x7FFFFFFFFFFFFFFF;
  }

  Future<void> saveSensorReading(LiveSensorData reading) async {
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
      ..battery =
          null // battery now comes from phone metrics (battery_plus), not wearable
      ..sleep = reading.sleep
      ..isSynced = false;

    try {
      await isar.writeTxn(() async {
        await isar.sensorReadingModels.put(model);
      });

      // Update DailyMetrics aggregates locally
      await _updateDailyMetrics(reading);
    } catch (e) {
      print(
        "[WearableRepository ERROR] Failed to save local sensor reading: $e",
      );
    }
  }

  Future<void> _updateDailyMetrics(LiveSensorData reading) async {
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
            ..batteryLevel = null; // phone battery tracked separately
        } else {
          // Keep highest step count, rolling averages for HR and stress
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

  Future<void> saveConnectedDeviceInfo(DiscoveredDevice device) async {
    final isar = IsarDatabase.instance.isar;
    final info = DeviceInfoModel()
      ..id = _generateId()
      ..deviceId = device.id
      ..name = device.name
      ..type = device.type.name
      ..battery = 100
      ..connectionState = DeviceConnectionState.connected.name
      ..lastConnectedAt = DateTime.now()
      ..isAutoReconnectEnabled = true;

    try {
      await isar.writeTxn(() async {
        // Clear previous configurations to ensure single connected device
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

      final device = DiscoveredDevice(
        id: info.deviceId ?? '',
        name: info.name ?? '',
        type: deviceType,
        rssi: -60,
      );

      print(
        "[WearableRepository] Restoring previous connection to ${device.name}...",
      );
      await _wearableService.connectDevice(device);

      // Update battery and last connected timestamp
      await saveConnectedDeviceInfo(device);
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
