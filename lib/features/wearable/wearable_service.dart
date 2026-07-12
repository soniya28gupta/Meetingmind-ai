import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'wearable_models.dart';

/// Manages BLE scanning, GATT connection, and live sensor data streaming.
/// ZERO fake data — only real BLE sensor readings are emitted.
class WearableService {
  static final WearableService _instance = WearableService._internal();
  factory WearableService() => _instance;
  WearableService._internal();

  StreamSubscription<List<ScanResult>>? _scanSubscription;
  StreamController<List<DiscoveredDevice>>? _discoveryController;
  StreamController<LiveSensorData>? _liveSensorController;
  StreamController<DeviceConnectionState>? _connectionStateController;

  DiscoveredDevice? _connectedDevice;
  DeviceConnectionState _connectionState = DeviceConnectionState.disconnected;

  // GATT subscriptions for auto-reconnect
  StreamSubscription<BluetoothConnectionState>? _bleConnectionSub;
  BluetoothDevice? _activeBluetoothDevice;

  // Cached values read dynamically
  String firmwareVersion = 'v1.0.0';
  int? lastRssi;

  Stream<List<DiscoveredDevice>> get discoveredDevicesStream =>
      _discoveryController?.stream ?? const Stream.empty();

  Stream<LiveSensorData> get liveSensorDataStream =>
      _liveSensorController?.stream ?? const Stream.empty();

  Stream<DeviceConnectionState> get connectionStateStream =>
      _connectionStateController?.stream ?? const Stream.empty();

  DiscoveredDevice? get connectedDevice => _connectedDevice;
  DeviceConnectionState get connectionState => _connectionState;

  void initialize() {
    _discoveryController = StreamController<List<DiscoveredDevice>>.broadcast();
    _liveSensorController = StreamController<LiveSensorData>.broadcast();
    _connectionStateController =
        StreamController<DeviceConnectionState>.broadcast();
  }

  Future<bool> requestPermissions() async {
    final permissions = [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ];
    final statuses = await permissions.request();
    return statuses.values.every((s) => s.isGranted);
  }

  Future<bool> isBluetoothEnabled() async {
    return await FlutterBluePlus.isSupported &&
        await FlutterBluePlus.adapterState.first == BluetoothAdapterState.on;
  }

  Future<void> startScanning() async {
    await requestPermissions();
    final isEnabled = await isBluetoothEnabled();

    if (!isEnabled) {
      print('[WearableService] Bluetooth not enabled. No devices to scan.');
      _discoveryController?.add([]); // empty list — no fake devices
      return;
    }

    List<DiscoveredDevice> devicesList = [];

    try {
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 15));
      _scanSubscription = FlutterBluePlus.scanResults.listen((results) {
        for (var r in results) {
          final name = r.device.platformName.trim();
          if (name.isEmpty) continue;
          if (devicesList.any((d) => d.id == r.device.remoteId.str)) continue;

          final type = _determineDeviceType(name);
          devicesList.add(
            DiscoveredDevice(
              id: r.device.remoteId.str,
              name: name,
              type: type,
              rssi: r.rssi,
            ),
          );
        }
        _discoveryController?.add(List.from(devicesList));
      });
    } catch (e) {
      print('[WearableService ERROR] startScan failed: $e');
    }
  }

  Future<void> stopScanning() async {
    try {
      await FlutterBluePlus.stopScan();
    } catch (_) {}
    _scanSubscription?.cancel();
    _scanSubscription = null;
  }

  WearableDeviceType _determineDeviceType(String name) {
    final lowerName = name.toLowerCase();
    if (lowerName.contains('oura')) return WearableDeviceType.ouraRing;
    if (lowerName.contains('fitbit')) return WearableDeviceType.fitbit;
    if (lowerName.contains('xiaomi') || lowerName.contains('mi band'))
      return WearableDeviceType.xiaomiBand;
    if (lowerName.contains('galaxy') ||
        lowerName.contains('samsung') ||
        lowerName.contains('gear')) {
      return WearableDeviceType.samsungWatch;
    }
    if (lowerName.contains('pixel watch')) return WearableDeviceType.pixelWatch;
    if (lowerName.contains('watch')) return WearableDeviceType.xiaomiWatch;
    return WearableDeviceType.genericHeartRate;
  }

  Future<void> connectDevice(DiscoveredDevice device) async {
    await disconnectDevice();

    _connectedDevice = device;
    lastRssi = device.rssi;
    _updateConnectionState(DeviceConnectionState.connecting);

    try {
      final bleDevice = BluetoothDevice(remoteId: DeviceIdentifier(device.id));
      _activeBluetoothDevice = bleDevice;

      await bleDevice.connect(
        timeout: const Duration(seconds: 10),
        autoConnect: false,
      );
      _updateConnectionState(DeviceConnectionState.connected);

      // Monitor connection state for auto-reconnect
      _bleConnectionSub = bleDevice.connectionState.listen((state) {
        if (state == BluetoothConnectionState.disconnected) {
          print(
            '[WearableService] Device disconnected. Attempting reconnect...',
          );
          _updateConnectionState(DeviceConnectionState.reconnecting);
          _attemptReconnect(bleDevice, device);
        }
      });

      // Discover GATT services and subscribe to standard health characteristics
      final services = await bleDevice.discoverServices();
      _subscribeToHealthCharacteristics(services);
    } catch (e) {
      print('[WearableService ERROR] Connection to ${device.name} failed: $e');
      _updateConnectionState(DeviceConnectionState.disconnected);
      _connectedDevice = null;
      rethrow;
    }
  }

  void _subscribeToHealthCharacteristics(List<BluetoothService> services) {
    for (final s in services) {
      final uuid = s.serviceUuid.str.toLowerCase();

      // Heart Rate Service (0x180D)
      if (uuid.contains('180d')) {
        for (final c in s.characteristics) {
          if (c.characteristicUuid.str.toLowerCase().contains('2a37')) {
            () async {
              try {
                await c.setNotifyValue(true);
                c.lastValueStream.listen((value) {
                  if (value.isNotEmpty) {
                    // HR Measurement format: byte[0] = flags, byte[1] = HR value
                    final hr = value.length > 1 ? value[1] : value[0];
                    final data = LiveSensorData(
                      heartRate: hr,
                      timestamp: DateTime.now(),
                    );
                    _liveSensorController?.add(data);
                  }
                });
              } catch (e) {
                print('[WearableService] HR notify error: $e');
              }
            }();
          }
        }
      }

      // Battery Service (0x180F)
      if (uuid.contains('180f')) {
        for (final c in s.characteristics) {
          if (c.characteristicUuid.str.toLowerCase().contains('2a19')) {
            () async {
              try {
                await c.read();
                await c.setNotifyValue(true);
              } catch (_) {}
            }();
          }
        }
      }

      // SpO₂ / Blood Oxygen (0x1822 or 0x2A5F)
      if (uuid.contains('1822') || uuid.contains('2a5f')) {
        for (final c in s.characteristics) {
          () async {
            try {
              await c.setNotifyValue(true);
              c.lastValueStream.listen((value) {
                if (value.isNotEmpty && value[0] > 50 && value[0] <= 100) {
                  final existing = LiveSensorData(
                    spo2: value[0],
                    timestamp: DateTime.now(),
                  );
                  _liveSensorController?.add(existing);
                }
              });
            } catch (_) {}
          }();
        }
      }

      // Device Information Service (0x180A)
      if (uuid.contains('180a')) {
        for (final c in s.characteristics) {
          if (c.characteristicUuid.str.toLowerCase().contains('2a26')) {
            () async {
              try {
                final val = await c.read();
                if (val.isNotEmpty) {
                  firmwareVersion = String.fromCharCodes(val).trim();
                  print(
                    '[WearableService] Read Firmware Version: $firmwareVersion',
                  );
                }
              } catch (_) {}
            }();
          }
        }
      }
    }
  }

  Future<void> _attemptReconnect(
    BluetoothDevice bleDevice,
    DiscoveredDevice device,
  ) async {
    await Future.delayed(const Duration(seconds: 3));
    if (_connectionState == DeviceConnectionState.reconnecting) {
      try {
        await bleDevice.connect(
          timeout: const Duration(seconds: 10),
          autoConnect: false,
        );
        _updateConnectionState(DeviceConnectionState.connected);
        final services = await bleDevice.discoverServices();
        _subscribeToHealthCharacteristics(services);
        print('[WearableService] Reconnected to ${device.name}');
      } catch (e) {
        print('[WearableService] Reconnect failed: $e');
        _updateConnectionState(DeviceConnectionState.disconnected);
        _connectedDevice = null;
      }
    }
  }

  Future<void> disconnectDevice() async {
    _bleConnectionSub?.cancel();
    _bleConnectionSub = null;

    if (_activeBluetoothDevice != null) {
      try {
        await _activeBluetoothDevice!.disconnect();
      } catch (_) {}
      _activeBluetoothDevice = null;
    }

    _connectedDevice = null;
    _updateConnectionState(DeviceConnectionState.disconnected);
  }

  void _updateConnectionState(DeviceConnectionState state) {
    _connectionState = state;
    _connectionStateController?.add(state);
  }

  void dispose() {
    stopScanning();
    disconnectDevice();
    _discoveryController?.close();
    _liveSensorController?.close();
    _connectionStateController?.close();
  }
}
