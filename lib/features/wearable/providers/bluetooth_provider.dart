import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../bluetooth/bluetooth_manager.dart';
import '../models/wearable_device.dart';

class BluetoothState {
  final List<WearableDevice> discoveredDevices;
  final bool isScanning;
  final BluetoothAdapterState adapterState;
  final String scanMode; // 'health' or 'all'
  final double scanProgress; // 1.0 down to 0.0

  BluetoothState({
    this.discoveredDevices = const [],
    this.isScanning = false,
    this.adapterState = BluetoothAdapterState.unknown,
    this.scanMode = 'health',
    this.scanProgress = 0.0,
  });

  BluetoothState copyWith({
    List<WearableDevice>? discoveredDevices,
    bool? isScanning,
    BluetoothAdapterState? adapterState,
    String? scanMode,
    double? scanProgress,
  }) {
    return BluetoothState(
      discoveredDevices: discoveredDevices ?? this.discoveredDevices,
      isScanning: isScanning ?? this.isScanning,
      adapterState: adapterState ?? this.adapterState,
      scanMode: scanMode ?? this.scanMode,
      scanProgress: scanProgress ?? this.scanProgress,
    );
  }
}

class BluetoothNotifier extends StateNotifier<BluetoothState> {
  final _manager = BluetoothManager();
  StreamSubscription<List<WearableDevice>>? _devicesSub;
  StreamSubscription<BluetoothAdapterState>? _adapterSub;
  StreamSubscription<bool>? _scanningSub;
  Timer? _countdownTimer;

  BluetoothNotifier() : super(BluetoothState()) {
    _manager.initialize();

    _devicesSub = _manager.discoveredDevicesStream.listen((devices) {
      state = state.copyWith(discoveredDevices: devices);
    });

    _adapterSub = _manager.adapterStateStream.listen((adapterState) {
      state = state.copyWith(adapterState: adapterState);
    });

    _scanningSub = _manager.isScanningStream.listen((isScanning) {
      state = state.copyWith(isScanning: isScanning);
      if (!isScanning) {
        _countdownTimer?.cancel();
        state = state.copyWith(scanProgress: 0.0);
      }
    });
  }

  Future<void> startScan({bool scanAll = false}) async {
    _countdownTimer?.cancel();
    state = state.copyWith(
      scanMode: scanAll ? 'all' : 'health',
      scanProgress: 1.0,
      discoveredDevices: [],
    );

    await _manager.startScanning(scanAll: scanAll);

    // 15 seconds scan duration countdown (150 steps of 100ms)
    int ticks = 0;
    const maxTicks = 150;
    _countdownTimer = Timer.periodic(const Duration(milliseconds: 100), (
      timer,
    ) {
      ticks++;
      if (ticks >= maxTicks) {
        stopScan();
      } else {
        state = state.copyWith(scanProgress: (maxTicks - ticks) / maxTicks);
      }
    });
  }

  Future<void> stopScan() async {
    _countdownTimer?.cancel();
    _countdownTimer = null;
    state = state.copyWith(scanProgress: 0.0);
    await _manager.stopScanning();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _devicesSub?.cancel();
    _adapterSub?.cancel();
    _scanningSub?.cancel();
    _manager.dispose();
    super.dispose();
  }
}

final bluetoothProvider =
    StateNotifierProvider<BluetoothNotifier, BluetoothState>((ref) {
      return BluetoothNotifier();
    });
