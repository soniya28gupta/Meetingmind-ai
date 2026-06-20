import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'wearable_models.dart';
import 'wearable_service.dart';
import 'wearable_repository.dart';

class WearableState {
  final DeviceConnectionState connectionState;
  final DiscoveredDevice? connectedDevice;
  final List<DiscoveredDevice> discoveredDevices;
  final bool isScanning;
  final LiveSensorData liveData;
  final String? errorMessage;

  WearableState({
    required this.connectionState,
    this.connectedDevice,
    this.discoveredDevices = const [],
    this.isScanning = false,
    required this.liveData,
    this.errorMessage,
  });

  WearableState copyWith({
    DeviceConnectionState? connectionState,
    DiscoveredDevice? connectedDevice,
    List<DiscoveredDevice>? discoveredDevices,
    bool? isScanning,
    LiveSensorData? liveData,
    String? errorMessage,
  }) {
    return WearableState(
      connectionState: connectionState ?? this.connectionState,
      connectedDevice: connectedDevice ?? this.connectedDevice, // Note: can be null
      discoveredDevices: discoveredDevices ?? this.discoveredDevices,
      isScanning: isScanning ?? this.isScanning,
      liveData: liveData ?? this.liveData,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class WearableNotifier extends StateNotifier<WearableState> {
  final _service = WearableService();
  final _repository = WearableRepository();

  StreamSubscription<List<DiscoveredDevice>>? _devicesSubscription;
  StreamSubscription<DeviceConnectionState>? _connectionSubscription;
  StreamSubscription<LiveSensorData>? _dataSubscription;

  WearableNotifier()
      : super(WearableState(
          connectionState: DeviceConnectionState.disconnected,
          liveData: LiveSensorData.initial(),
        )) {
    // Start background sync manager and auto-reconnect flows in repository
    _repository.initialize();
    
    // Subscribe to WearableService updates
    _connectionSubscription = _service.connectionStateStream.listen((state) {
      _updateConnectionState(state);
    });

    _dataSubscription = _service.liveSensorDataStream.listen((data) {
      state = state.copyWith(liveData: data);
    });

    _devicesSubscription = _service.discoveredDevicesStream.listen((devices) {
      state = state.copyWith(discoveredDevices: devices);
    });
  }

  void _updateConnectionState(DeviceConnectionState connState) {
    state = state.copyWith(
      connectionState: connState,
      connectedDevice: connState == DeviceConnectionState.disconnected ? null : _service.connectedDevice,
    );
  }

  Future<void> startScan() async {
    state = state.copyWith(isScanning: true, discoveredDevices: []);
    await _service.startScanning();
  }

  Future<void> stopScan() async {
    await _service.stopScanning();
    state = state.copyWith(isScanning: false);
  }

  Future<void> connect(DiscoveredDevice device) async {
    state = state.copyWith(errorMessage: null);
    try {
      await _service.connectDevice(device);
      await _repository.saveConnectedDeviceInfo(device);
    } catch (e) {
      state = state.copyWith(
        connectionState: DeviceConnectionState.disconnected,
        errorMessage: 'Failed to connect to ${device.name}: ${e.toString()}',
      );
    }
  }

  Future<void> disconnect() async {
    await _service.disconnectDevice();
    await _repository.clearDeviceInfo();
  }

  Future<bool> requestPermissions() async {
    return await _service.requestPermissions();
  }

  @override
  void dispose() {
    _devicesSubscription?.cancel();
    _connectionSubscription?.cancel();
    _dataSubscription?.cancel();
    super.dispose();
  }
}

final wearableProvider = StateNotifierProvider<WearableNotifier, WearableState>((ref) {
  return WearableNotifier();
});
