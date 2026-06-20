import 'dart:async';
import 'dart:math';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'wearable_models.dart';

class WearableService {
  static final WearableService _instance = WearableService._internal();
  factory WearableService() => _instance;
  WearableService._internal();

  StreamSubscription<List<ScanResult>>? _scanSubscription;
  StreamController<List<DiscoveredDevice>>? _discoveryController;
  StreamController<LiveSensorData>? _liveSensorController;
  StreamController<DeviceConnectionState>? _connectionStateController;

  Timer? _simulatorTimer;
  DiscoveredDevice? _connectedDevice;
  DeviceConnectionState _connectionState = DeviceConnectionState.disconnected;

  // Streams exposed to UI/Providers
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
    _connectionStateController = StreamController<DeviceConnectionState>.broadcast();
  }

  Future<bool> requestPermissions() async {
    // BLE scanning and connection permissions + location (needed for scanning on older OS versions)
    final permissions = [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ];

    Map<Permission, PermissionStatus> statuses = await permissions.request();
    return statuses.values.every((status) => status.isGranted);
  }

  Future<bool> isBluetoothEnabled() async {
    return await FlutterBluePlus.isSupported && await FlutterBluePlus.adapterState.first == BluetoothAdapterState.on;
  }

  Future<void> startScanning() async {
    await requestPermissions();
    final isEnabled = await isBluetoothEnabled();
    
    List<DiscoveredDevice> devicesList = [];
    
    // Always include a simulator device for high-fidelity testing
    devicesList.add(DiscoveredDevice(
      id: 'SIMULATOR_DEVICE',
      name: 'MeetingMind Wearable Simulator',
      type: WearableDeviceType.simulator,
      rssi: -45,
    ));
    _discoveryController?.add(devicesList);

    if (!isEnabled) {
      print("[WearableService] Bluetooth is not enabled. Scanning BLE will be bypassed, simulator is active.");
      return;
    }

    try {
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 15));
      _scanSubscription = FlutterBluePlus.scanResults.listen((results) {
        for (var r in results) {
          final name = r.device.platformName.trim();
          if (name.isEmpty) continue;

          // Check if already in list
          if (devicesList.any((d) => d.id == r.device.remoteId.str)) continue;

          final type = _determineDeviceType(name);
          devicesList.add(DiscoveredDevice(
            id: r.device.remoteId.str,
            name: name,
            type: type,
            rssi: r.rssi,
          ));
        }
        _discoveryController?.add(List.from(devicesList));
      });
    } catch (e) {
      print("[WearableService ERROR] startScan failed: $e");
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
    if (lowerName.contains('xiaomi') || lowerName.contains('mi band')) return WearableDeviceType.xiaomiBand;
    if (lowerName.contains('galaxy') || lowerName.contains('samsung') || lowerName.contains('gear')) return WearableDeviceType.samsungWatch;
    if (lowerName.contains('watch')) return WearableDeviceType.xiaomiWatch;
    return WearableDeviceType.genericHeartRate;
  }

  Future<void> connectDevice(DiscoveredDevice device) async {
    await disconnectDevice();
    
    _connectedDevice = device;
    _updateConnectionState(DeviceConnectionState.connecting);

    if (device.type == WearableDeviceType.simulator) {
      // Setup simulator connection
      await Future.delayed(const Duration(milliseconds: 800));
      _updateConnectionState(DeviceConnectionState.connected);
      _startSimulatorStream();
      return;
    }

    // GATT Connection Flow
    try {
      final bleDevice = BluetoothDevice(remoteId: DeviceIdentifier(device.id));
      await bleDevice.connect(timeout: const Duration(seconds: 10), autoConnect: false);
      
      _updateConnectionState(DeviceConnectionState.connected);
      
      // Discover services & subscribe to Heart Rate if generic BLE device
      List<BluetoothService> services = await bleDevice.discoverServices();
      for (var s in services) {
        if (s.serviceUuid.str.toLowerCase().contains('180d')) { // Heart Rate Service
          for (var c in s.characteristics) {
            if (c.characteristicUuid.str.toLowerCase().contains('2a37')) { // HR Measurement
              await c.setNotifyValue(true);
              c.lastValueStream.listen((value) {
                if (value.isNotEmpty) {
                  // Standard Heart Rate Measurement format: byte 1 contains flags, byte 2 contains HR
                  int hr = value.length > 1 ? value[1] : 70;
                  _liveSensorController?.add(LiveSensorData(
                    heartRate: hr,
                    stress: _calculateStressFromHR(hr),
                    steps: 0, // Heart Rate standard BLE doesn't include steps
                    battery: 90,
                    sleep: 7.5,
                    timestamp: DateTime.now(),
                  ));
                }
              });
            }
          }
        }
      }
    } catch (e) {
      print("[WearableService ERROR] Connection to ${device.name} failed: $e");
      _updateConnectionState(DeviceConnectionState.disconnected);
      _connectedDevice = null;
      rethrow;
    }
  }

  Future<void> disconnectDevice() async {
    _simulatorTimer?.cancel();
    _simulatorTimer = null;

    if (_connectedDevice != null && _connectedDevice!.type != WearableDeviceType.simulator) {
      try {
        final bleDevice = BluetoothDevice(remoteId: DeviceIdentifier(_connectedDevice!.id));
        await bleDevice.disconnect();
      } catch (_) {}
    }

    _connectedDevice = null;
    _updateConnectionState(DeviceConnectionState.disconnected);
  }

  void _updateConnectionState(DeviceConnectionState state) {
    _connectionState = state;
    _connectionStateController?.add(state);
  }

  double _calculateStressFromHR(int hr) {
    // Heuristics mapping Heart Rate to stress level
    if (hr < 60) return 15.0; // relaxed
    if (hr < 75) return 28.0; // low stress
    if (hr < 90) return 48.0; // moderate stress
    if (hr < 110) return 72.0; // high stress
    return 89.0; // extreme stress
  }

  void _startSimulatorStream() {
    _simulatorTimer?.cancel();
    final random = Random();
    int currentSteps = 4250;
    int currentHR = 72;
    int batteryLevel = 88;

    _simulatorTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_connectionState != DeviceConnectionState.connected) {
        timer.cancel();
        return;
      }

      // Small natural fluctuations
      currentHR += random.nextInt(5) - 2;
      currentHR = currentHR.clamp(60, 115);
      
      currentSteps += random.nextInt(3); // increments steps slowly
      
      if (random.nextDouble() < 0.01) {
        batteryLevel -= 1;
        batteryLevel = batteryLevel.clamp(0, 100);
      }

      final stress = _calculateStressFromHR(currentHR) + (random.nextDouble() * 4 - 2);
      final sleep = 7.35 + (random.nextDouble() * 0.1);

      _liveSensorController?.add(LiveSensorData(
        heartRate: currentHR,
        stress: double.parse(stress.toStringAsFixed(1)),
        steps: currentSteps,
        battery: batteryLevel,
        sleep: double.parse(sleep.toStringAsFixed(1)),
        timestamp: DateTime.now(),
      ));
    });
  }

  void dispose() {
    stopScanning();
    disconnectDevice();
    _discoveryController?.close();
    _liveSensorController?.close();
    _connectionStateController?.close();
  }
}
