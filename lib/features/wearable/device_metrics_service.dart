import 'dart:async';
import 'package:battery_plus/battery_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'wearable_models.dart';

/// Reads real-time phone metrics: battery %, charging state, network type,
/// and device info. Updates every second via stream.
class DeviceMetricsService {
  static final DeviceMetricsService _instance =
      DeviceMetricsService._internal();
  factory DeviceMetricsService() => _instance;
  DeviceMetricsService._internal();

  final _battery = Battery();
  final _connectivity = Connectivity();
  final _deviceInfo = DeviceInfoPlugin();

  StreamController<PhoneMetrics>? _metricsController;
  Timer? _refreshTimer;

  // Cached device info (read once)
  String _deviceName = 'Android Device';
  String _androidVersion = '';
  bool _deviceInfoLoaded = false;

  Stream<PhoneMetrics> get metricsStream =>
      _metricsController?.stream ?? const Stream.empty();

  Future<void> initialize() async {
    _metricsController?.close();
    _metricsController = StreamController<PhoneMetrics>.broadcast();

    // Load device info once
    if (!_deviceInfoLoaded) {
      try {
        final info = await _deviceInfo.androidInfo;
        _deviceName = info.model;
        _androidVersion = info.version.release;
        _deviceInfoLoaded = true;
      } catch (e) {
        print('[DeviceMetrics] device_info_plus failed: $e');
      }
    }

    // Initial push
    await _refreshAndPush();

    // Refresh every second
    _refreshTimer = Timer.periodic(const Duration(seconds: 1), (_) async {
      await _refreshAndPush();
    });
  }

  Future<void> _refreshAndPush() async {
    try {
      final batteryLevel = await _battery.batteryLevel;
      final batteryState = await _battery.batteryState;
      final isCharging =
          batteryState == BatteryState.charging ||
          batteryState == BatteryState.full;

      String chargingType = 'Not charging';
      if (batteryState == BatteryState.charging) chargingType = 'Charging';
      if (batteryState == BatteryState.full) chargingType = 'Full ✓';

      final connectivityResults = await _connectivity.checkConnectivity();
      final networkType = _resolveNetworkType(connectivityResults);
      final networkLabel = _networkLabel(networkType, connectivityResults);

      _metricsController?.add(
        PhoneMetrics(
          batteryLevel: batteryLevel,
          isCharging: isCharging,
          chargingType: chargingType,
          networkType: networkType,
          networkLabel: networkLabel,
          deviceName: _deviceName,
          androidVersion: _androidVersion,
          timestamp: DateTime.now(),
        ),
      );
    } catch (e) {
      print('[DeviceMetrics] Error refreshing metrics: $e');
    }
  }

  NetworkType _resolveNetworkType(List<ConnectivityResult> results) {
    if (results.contains(ConnectivityResult.wifi)) return NetworkType.wifi;
    if (results.contains(ConnectivityResult.mobile)) {
      // connectivity_plus doesn't differentiate 4G vs 5G — we default to mobile4G
      // A precise check would require a platform channel call
      return NetworkType.mobile4G;
    }
    if (results.contains(ConnectivityResult.none) || results.isEmpty)
      return NetworkType.none;
    return NetworkType.unknown;
  }

  String _networkLabel(NetworkType type, List<ConnectivityResult> results) {
    switch (type) {
      case NetworkType.wifi:
        return 'Wi-Fi';
      case NetworkType.mobile4G:
        return '4G/LTE';
      case NetworkType.mobile5G:
        return '5G';
      case NetworkType.none:
        return 'No Internet';
      case NetworkType.unknown:
        return results.isEmpty ? 'No Internet' : results.first.name;
    }
  }

  void dispose() {
    _refreshTimer?.cancel();
    _metricsController?.close();
    _refreshTimer = null;
    _metricsController = null;
  }
}
