import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../models/wearable_device.dart';
import '../models/sensor_reading.dart';
import '../wearable_models.dart' as old;

class WearableService {
  static final WearableService _instance = WearableService._internal();
  factory WearableService() => _instance;
  WearableService._internal();

  BluetoothDevice? _connectedBleDevice;
  WearableDevice? _connectedDevice;

  final StreamController<SensorReading> _telemetryController =
      StreamController<SensorReading>.broadcast();
  final StreamController<WearableDevice?> _connectionController =
      StreamController<WearableDevice?>.broadcast();

  StreamSubscription<BluetoothConnectionState>? _stateSub;
  StreamSubscription<int>? _rssiSub;

  Stream<SensorReading> get telemetryStream => _telemetryController.stream;

  Stream<old.LiveSensorData> get liveSensorDataStream => telemetryStream.map(
    (r) => old.LiveSensorData(
      heartRate: r.heartRate,
      stress: r.stress,
      steps: r.steps,
      sleep: r.sleep,
      calories: r.calories,
      distance: r.distance,
      spo2: r.spo2,
      battery: r.battery,
      hrv: r.hrv,
      respirationRate: r.respirationRate,
      bodyTemperature: r.bodyTemperature,
      floors: r.floors,
      activeMinutes: r.activeMinutes,
      sleepQuality: r.sleepQuality,
      timestamp: r.timestamp,
    ),
  );

  Stream<WearableDevice?> get connectionStream => _connectionController.stream;

  WearableDevice? get connectedDevice => _connectedDevice;

  SensorReading _currentReading = SensorReading.empty();

  void initialize() {
    print('[WearableService] Initialized Wearable service');
  }

  Future<void> connect(WearableDevice device) async {
    await disconnect();

    _connectedDevice = device.copyWith(isConnected: false);
    _connectionController.add(_connectedDevice);

    try {
      final bleDevice = BluetoothDevice(remoteId: DeviceIdentifier(device.id));
      _connectedBleDevice = bleDevice;

      print(
        '[WearableService] Connecting to device: ${device.name} (${device.id})',
      );
      await bleDevice.connect(
        timeout: const Duration(seconds: 10),
        autoConnect: false,
      );

      _connectedDevice = _connectedDevice?.copyWith(isConnected: true);
      _connectionController.add(_connectedDevice);

      _stateSub = bleDevice.connectionState.listen((state) {
        print('[WearableService] Connection status updated: $state');
        if (state == BluetoothConnectionState.disconnected) {
          _handleDisconnect();
        } else if (state == BluetoothConnectionState.connected) {
          _connectedDevice = _connectedDevice?.copyWith(isConnected: true);
          _connectionController.add(_connectedDevice);
        }
      });

      _startRssiMonitoring(bleDevice);

      final services = await bleDevice.discoverServices();
      await _subscribeToServices(services);
    } catch (e) {
      print('[WearableService ERROR] Connection to ${device.name} failed: $e');
      _handleDisconnect();
      // Do not rethrow — callers are not required to handle Bluetooth errors
    }
  }

  void _startRssiMonitoring(BluetoothDevice device) {
    _rssiSub?.cancel();
    _rssiSub = Stream.periodic(const Duration(seconds: 5))
        .asyncMap((_) async {
          try {
            if (_connectedDevice?.isConnected == true) {
              return await device.readRssi();
            }
          } catch (_) {}
          return -90;
        })
        .listen((rssi) {
          if (_connectedDevice != null && rssi != null) {
            _connectedDevice = _connectedDevice!.copyWith(rssi: rssi);
            _connectionController.add(_connectedDevice);

            _currentReading = _currentReading.copyWith(
              timestamp: DateTime.now(),
            );
            _telemetryController.add(_currentReading);
          }
        });
  }

  Future<void> _subscribeToServices(List<BluetoothService> services) async {
    final List<String> supportedSensors = [];
    final List<String> supportedServices = [];

    String manufacturer = 'Unknown';
    String model = 'Unknown';
    String firmware = 'v1.0.0';

    for (final s in services) {
      final uuid = s.serviceUuid.str.toLowerCase();
      supportedServices.add(uuid);

      // Heart Rate Service (0x180D)
      if (uuid.contains('180d')) {
        supportedSensors.add('Heart Rate');
        for (final c in s.characteristics) {
          if (c.characteristicUuid.str.toLowerCase().contains('2a37')) {
            try {
              await c.setNotifyValue(true);
              c.lastValueStream.listen((value) {
                if (value.isNotEmpty) {
                  final hr = value.length > 1 ? value[1] : value[0];
                  _currentReading = _currentReading.copyWith(
                    heartRate: hr,
                    timestamp: DateTime.now(),
                  );
                  _telemetryController.add(_currentReading);
                }
              });
              print(
                '[WearableService] Subscribed to Heart Rate notifications successfully.',
              );
            } catch (e) {
              print(
                '[WearableService ERROR] Subscribing to HR notifications failed: $e',
              );
            }
          }
        }
      }

      // Battery Service (0x180F)
      if (uuid.contains('180f')) {
        supportedSensors.add('Battery');
        for (final c in s.characteristics) {
          if (c.characteristicUuid.str.toLowerCase().contains('2a19')) {
            try {
              await c.read();
              await c.setNotifyValue(true);
              c.lastValueStream.listen((value) {
                if (value.isNotEmpty) {
                  final batt = value[0];
                  _connectedDevice = _connectedDevice?.copyWith(
                    batteryLevel: batt,
                  );
                  _connectionController.add(_connectedDevice);

                  _currentReading = _currentReading.copyWith(
                    battery: batt,
                    timestamp: DateTime.now(),
                  );
                  _telemetryController.add(_currentReading);
                  print('[WearableService] Battery level updated: $batt%');
                }
              });
            } catch (_) {}
          }
        }
      }

      // Device Information Service (0x180A)
      if (uuid.contains('180a')) {
        for (final c in s.characteristics) {
          final cUuid = c.characteristicUuid.str.toLowerCase();
          if (cUuid.contains('2a29')) {
            try {
              final val = await c.read();
              manufacturer = String.fromCharCodes(val).trim();
            } catch (_) {}
          }
          if (cUuid.contains('2a24')) {
            try {
              final val = await c.read();
              model = String.fromCharCodes(val).trim();
            } catch (_) {}
          }
          if (cUuid.contains('2a26')) {
            try {
              final val = await c.read();
              firmware = String.fromCharCodes(val).trim();
            } catch (_) {}
          }
        }
      }
    }

    _connectedDevice = _connectedDevice?.copyWith(
      manufacturer: manufacturer,
      modelNumber: model,
      firmwareVersion: firmware,
      supportedSensors: supportedSensors,
      supportedServices: supportedServices,
    );
    _connectionController.add(_connectedDevice);
  }

  void _handleDisconnect() {
    print('[WearableService] Device disconnected.');
    _connectedDevice = _connectedDevice?.copyWith(isConnected: false);
    _connectionController.add(_connectedDevice);

    if (_connectedDevice != null) {
      print('[WearableService] Attempting automatic reconnection in 5s...');
      Future.delayed(const Duration(seconds: 5), () {
        if (_connectedDevice != null &&
            _connectedDevice?.isConnected == false) {
          connect(_connectedDevice!).catchError((e) {
            print('[WearableService] Auto-reconnect failed: $e');
          });
        }
      });
    }
  }

  Future<void> disconnect() async {
    _rssiSub?.cancel();
    _rssiSub = null;
    _stateSub?.cancel();
    _stateSub = null;

    if (_connectedBleDevice != null) {
      try {
        await _connectedBleDevice!.disconnect();
      } catch (_) {}
      _connectedBleDevice = null;
    }

    _connectedDevice = null;
    _connectionController.add(null);
  }

  Future<List<int>> readCharacteristic(
    String serviceUuid,
    String characteristicUuid,
  ) async {
    final dev = _connectedBleDevice;
    if (dev == null) throw Exception('No device connected');

    final services = await dev.discoverServices();
    for (final s in services) {
      if (s.serviceUuid.str.toLowerCase() == serviceUuid.toLowerCase()) {
        for (final c in s.characteristics) {
          if (c.characteristicUuid.str.toLowerCase() ==
              characteristicUuid.toLowerCase()) {
            return await c.read();
          }
        }
      }
    }
    throw Exception('Characteristic not found');
  }

  Future<Stream<List<int>>> subscribeCharacteristic(
    String serviceUuid,
    String characteristicUuid,
    bool enable,
  ) async {
    final dev = _connectedBleDevice;
    if (dev == null) throw Exception('No device connected');

    final services = await dev.discoverServices();
    for (final s in services) {
      if (s.serviceUuid.str.toLowerCase() == serviceUuid.toLowerCase()) {
        for (final c in s.characteristics) {
          if (c.characteristicUuid.str.toLowerCase() ==
              characteristicUuid.toLowerCase()) {
            await c.setNotifyValue(enable);
            return c.lastValueStream;
          }
        }
      }
    }
    throw Exception('Characteristic not found');
  }

  Future<List<BluetoothService>> discoverServices() async {
    final dev = _connectedBleDevice;
    if (dev == null) return [];
    return await dev.discoverServices();
  }

  void dispose() {
    disconnect();
    _telemetryController.close();
    _connectionController.close();
  }
}
