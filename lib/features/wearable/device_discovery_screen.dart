import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/glass_card.dart';
import 'wearable_models.dart';
import 'wearable_provider.dart';
import 'connected_device_screen.dart';

class DeviceDiscoveryScreen extends ConsumerStatefulWidget {
  const DeviceDiscoveryScreen({super.key});

  @override
  ConsumerState<DeviceDiscoveryScreen> createState() => _DeviceDiscoveryScreenState();
}

class _DeviceDiscoveryScreenState extends ConsumerState<DeviceDiscoveryScreen> {
  @override
  void initState() {
    super.initState();
    // Auto start scan on screen load
    Future.microtask(() {
      ref.read(wearableProvider.notifier).startScan();
    });
  }

  @override
  void dispose() {
    // Stop scanning on exit
    Future.microtask(() {
      ref.read(wearableProvider.notifier).stopScan();
    });
    super.dispose();
  }

  IconData _getDeviceIcon(WearableDeviceType type) {
    switch (type) {
      case WearableDeviceType.ouraRing:
        return Icons.circle_outlined;
      case WearableDeviceType.fitbit:
      case WearableDeviceType.xiaomiBand:
        return Icons.watch_outlined;
      case WearableDeviceType.xiaomiWatch:
      case WearableDeviceType.samsungWatch:
        return Icons.watch;
      case WearableDeviceType.genericHeartRate:
        return Icons.favorite_border_rounded;
      case WearableDeviceType.simulator:
        return Icons.auto_awesome;
    }
  }

  String _getDeviceTypeName(WearableDeviceType type) {
    switch (type) {
      case WearableDeviceType.ouraRing:
        return 'Smart Ring';
      case WearableDeviceType.fitbit:
        return 'Fitbit Tracker';
      case WearableDeviceType.xiaomiBand:
        return 'Fitness Band';
      case WearableDeviceType.xiaomiWatch:
        return 'Xiaomi Watch';
      case WearableDeviceType.samsungWatch:
        return 'Galaxy Watch';
      case WearableDeviceType.genericHeartRate:
        return 'GATT Heart Rate Strap';
      case WearableDeviceType.simulator:
        return 'Developer Simulation';
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(wearableProvider);

    // If connected, automatically push to details screen or pop back
    ref.listen<WearableState>(wearableProvider, (previous, next) {
      if (next.connectionState == DeviceConnectionState.connected &&
          previous?.connectionState != DeviceConnectionState.connected) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const ConnectedDeviceScreen()),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pair Wearable Sensor', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(state.isScanning ? Icons.stop_rounded : Icons.refresh_rounded),
            onPressed: () {
              if (state.isScanning) {
                ref.read(wearableProvider.notifier).stopScan();
              } else {
                ref.read(wearableProvider.notifier).startScan();
              }
            },
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.darkGradient,
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (state.isScanning) ...[
                const SizedBox(height: 20),
                Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Pulsating BLE rings
                      _buildScanRipple(100.0, 0.2),
                      _buildScanRipple(140.0, 0.1),
                      Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: AppColors.primaryGradient,
                        ),
                        child: const Icon(Icons.bluetooth_searching_rounded, color: Colors.white, size: 36),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Scanning for nearby BLE signals...',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 30),
              ] else ...[
                const SizedBox(height: 10),
                const Text(
                  'Scan inactive. Refresh to search.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textMuted),
                ),
                const SizedBox(height: 20),
              ],

              if (state.errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    state.errorMessage!,
                    style: const TextStyle(color: AppColors.error, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 16),
              ],

              Expanded(
                child: state.discoveredDevices.isEmpty
                    ? Center(
                        child: Text(
                          'No devices found yet.\nVerify Bluetooth and Location services are enabled.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.textMuted, height: 1.5),
                        ),
                      )
                    : ListView.separated(
                        itemCount: state.discoveredDevices.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final device = state.discoveredDevices[index];
                          final isConnecting = state.connectionState == DeviceConnectionState.connecting &&
                                               state.connectedDevice?.id == device.id;

                          return GlassCard(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            borderColor: device.type == WearableDeviceType.simulator
                                ? AppColors.secondary.withValues(alpha: 0.4)
                                : AppColors.surfaceLight,
                            child: ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: (device.type == WearableDeviceType.simulator
                                          ? AppColors.secondary
                                          : AppColors.primary)
                                      .withValues(alpha: 0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  _getDeviceIcon(device.type),
                                  color: device.type == WearableDeviceType.simulator
                                      ? AppColors.secondary
                                      : AppColors.primary,
                                ),
                              ),
                              title: Text(
                                device.name,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Row(
                                  children: [
                                    Text(
                                      _getDeviceTypeName(device.type),
                                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                                    ),
                                    const SizedBox(width: 10),
                                    Icon(Icons.wifi_tethering, size: 12, color: _getRssiColor(device.rssi)),
                                    const SizedBox(width: 4),
                                    Text('${device.rssi} dBm', style: TextStyle(color: _getRssiColor(device.rssi), fontSize: 11)),
                                  ],
                                ),
                              ),
                              trailing: isConnecting
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(strokeWidth: 2.5),
                                    )
                                  : Icon(Icons.chevron_right, color: AppColors.textMuted),
                              onTap: isConnecting
                                  ? null
                                  : () {
                                      ref.read(wearableProvider.notifier).connect(device);
                                    },
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScanRipple(double size, double opacity) {
    return AnimatedContainer(
      duration: const Duration(seconds: 1),
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.primary.withValues(alpha: opacity),
      ),
    );
  }

  Color _getRssiColor(int rssi) {
    if (rssi >= -60) return AppColors.success;
    if (rssi >= -80) return AppColors.warning;
    return AppColors.error;
  }
}
