import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/gradient_button.dart';
import 'providers/bluetooth_provider.dart';
import 'providers/wearable_provider.dart';
import 'models/wearable_device.dart';
import 'wearable_models.dart' as old;

class ConnectWearableScreen extends ConsumerStatefulWidget {
  const ConnectWearableScreen({super.key});

  @override
  ConsumerState<ConnectWearableScreen> createState() =>
      _ConnectWearableScreenState();
}

class _ConnectWearableScreenState extends ConsumerState<ConnectWearableScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _radarController;

  @override
  void initState() {
    super.initState();
    _radarController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    // Trigger initial scan in health wearables mode
    Future.microtask(() {
      ref.read(bluetoothProvider.notifier).startScan(scanAll: false);
    });
  }

  @override
  void dispose() {
    _radarController.dispose();
    super.dispose();
  }

  String _formatManufacturerData(Map<int, List<int>> mData) {
    if (mData.isEmpty) return 'None';
    return mData.entries
        .map((e) {
          final hexVal = e.value
              .map((b) => b.toRadixString(16).padLeft(2, '0'))
              .join('')
              .toUpperCase();
          return 'ID 0x${e.key.toRadixString(16).toUpperCase()}: $hexVal';
        })
        .join(', ');
  }

  String _formatAdvertisementData(Map<String, dynamic> adv) {
    final services = adv['serviceUuids'] as List<dynamic>? ?? [];
    final tx = adv['txPowerLevel'];
    final connectable = adv['connectable'] ?? true;
    final List<String> parts = [];
    if (services.isNotEmpty) {
      parts.add(
        'Services: ${services.map((s) => s.toString().split('-')[0].toUpperCase()).toList()}',
      );
    }
    if (tx != null) {
      parts.add('TxPower: ${tx}dBm');
    }
    parts.add(connectable ? 'Connectable' : 'Non-connectable');
    return parts.join(' | ');
  }

  @override
  Widget build(BuildContext context) {
    final btState = ref.watch(bluetoothProvider);
    final wState = ref.watch(wearableProvider);

    final isScanning = btState.isScanning;
    final isHealthMode = btState.scanMode == 'health';

    // Group devices into categories (only for Health Wearables mode)
    final Map<String, List<WearableDevice>> categories = {
      'Heart Rate Monitors': [],
      'Fitness Bands': [],
      'Smart Watches': [],
      'Health Devices': [],
      'Other Health BLE Devices': [],
    };

    for (final dev in btState.discoveredDevices) {
      if (dev.type == WearableDeviceType.polarHeartRate ||
          dev.type == WearableDeviceType.garminHeartRate ||
          dev.type == WearableDeviceType.genericHeartRate) {
        categories['Heart Rate Monitors']!.add(dev);
      } else if (dev.type == WearableDeviceType.xiaomiBand ||
          dev.type == WearableDeviceType.fitbit) {
        categories['Fitness Bands']!.add(dev);
      } else if (dev.type == WearableDeviceType.samsungWatch ||
          dev.type == WearableDeviceType.pixelWatch ||
          dev.type == WearableDeviceType.xiaomiWatch) {
        categories['Smart Watches']!.add(dev);
      } else if (dev.type == WearableDeviceType.genericHealth ||
          dev.type == WearableDeviceType.ouraRing) {
        categories['Health Devices']!.add(dev);
      } else {
        categories['Other Health BLE Devices']!.add(dev);
      }
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'BLE Device Discovery',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              isScanning ? Icons.stop_rounded : Icons.refresh_rounded,
              color: Colors.white,
            ),
            tooltip: isScanning ? 'Stop scan' : 'Refresh scan',
            onPressed: () {
              if (isScanning) {
                ref.read(bluetoothProvider.notifier).stopScan();
              } else {
                ref
                    .read(bluetoothProvider.notifier)
                    .startScan(scanAll: !isHealthMode);
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Mode Selector Segment
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 20.0,
                vertical: 10.0,
              ),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          ref
                              .read(bluetoothProvider.notifier)
                              .startScan(scanAll: false);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            gradient: isHealthMode
                                ? AppColors.primaryGradient
                                : null,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            'Health Wearables',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: isHealthMode
                                  ? Colors.white
                                  : AppColors.textSecondary,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          ref
                              .read(bluetoothProvider.notifier)
                              .startScan(scanAll: true);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            gradient: !isHealthMode
                                ? AppColors.primaryGradient
                                : null,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            'All BLE Devices',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: !isHealthMode
                                  ? Colors.white
                                  : AppColors.textSecondary,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Scanning Status & Progress Indicator
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 20.0,
                vertical: 8.0,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      isScanning
                          ? 'Scanning in progress (${(btState.scanProgress * 15).round()}s remaining)...'
                          : 'Scan completed. Discoverable peripherals listed.',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  if (isScanning) ...[
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        value: btState.scanProgress,
                        strokeWidth: 3.5,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          AppColors.primary,
                        ),
                        backgroundColor: AppColors.surfaceLight,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Main Discovered Device List
            Expanded(
              child: btState.discoveredDevices.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(28.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.bluetooth_searching,
                              size: 54,
                              color: AppColors.textMuted,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              isHealthMode
                                  ? 'No standard health wearables found nearby.'
                                  : 'No Bluetooth peripherals found. Ensure pairing is enabled.',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 20),
                            // Inline Mode Switch Fallback
                            if (isHealthMode) ...[
                              ElevatedButton.icon(
                                onPressed: () {
                                  ref
                                      .read(bluetoothProvider.notifier)
                                      .startScan(scanAll: true);
                                },
                                icon: const Icon(Icons.swap_horiz),
                                label: const Text(
                                  'Scan for all BLE devices instead',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ] else ...[
                              ElevatedButton.icon(
                                onPressed: () {
                                  ref
                                      .read(bluetoothProvider.notifier)
                                      .startScan(scanAll: true);
                                },
                                icon: const Icon(Icons.refresh),
                                label: const Text(
                                  'Retry Scan',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    )
                  : isHealthMode
                  ? ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      children: categories.entries.map((entry) {
                        final label = entry.key;
                        final list = entry.value;
                        if (list.isEmpty) return const SizedBox();

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 12.0,
                              ),
                              child: Text(
                                label,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                            ...list.map(
                              (dev) => _buildDeviceRow(context, dev, wState),
                            ),
                          ],
                        );
                      }).toList(),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      itemCount: btState.discoveredDevices.length,
                      itemBuilder: (context, index) {
                        final dev = btState.discoveredDevices[index];
                        return _buildRawDeviceRow(context, dev, wState);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeviceRow(
    BuildContext context,
    WearableDevice dev,
    WearableState wState,
  ) {
    final isConnecting =
        wState.connectionState == old.DeviceConnectionState.connecting &&
        wState.connectedDevice?.id == dev.id;
    final isConnected =
        wState.connectionState == old.DeviceConnectionState.connected &&
        wState.connectedDevice?.id == dev.id;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: ListTile(
          contentPadding: EdgeInsets.zero,
          leading: CircleAvatar(
            backgroundColor: AppColors.surfaceLight,
            child: Icon(
              _getCategoryIcon(dev.type),
              color: isConnected ? AppColors.success : AppColors.textSecondary,
            ),
          ),
          title: Text(
            dev.name,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          subtitle: Text(
            'Signal: ${dev.rssi} dBm',
            style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
          ),
          trailing: isConnecting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : (isConnected
                    ? TextButton(
                        onPressed: () =>
                            ref.read(wearableProvider.notifier).disconnect(),
                        child: const Text(
                          'Disconnect',
                          style: TextStyle(
                            color: AppColors.error,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    : ElevatedButton(
                        onPressed: () async {
                          final oldDev = old.DiscoveredDevice(
                            id: dev.id,
                            name: dev.name,
                            type: old.WearableDeviceType.values.firstWhere(
                              (e) => e.name == dev.type.name,
                              orElse: () =>
                                  old.WearableDeviceType.genericHeartRate,
                            ),
                            rssi: dev.rssi,
                          );
                          await ref
                              .read(wearableProvider.notifier)
                              .connect(oldDev);
                          if (context.mounted) Navigator.pop(context);
                        },
                        child: const Text('Pair'),
                      )),
        ),
      ),
    );
  }

  Widget _buildRawDeviceRow(
    BuildContext context,
    WearableDevice dev,
    WearableState wState,
  ) {
    final isConnecting =
        wState.connectionState == old.DeviceConnectionState.connecting &&
        wState.connectedDevice?.id == dev.id;
    final isConnected =
        wState.connectionState == old.DeviceConnectionState.connected &&
        wState.connectedDevice?.id == dev.id;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: GlassCard(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    dev.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                Text(
                  '${dev.rssi} dBm',
                  style: TextStyle(
                    color: dev.rssi > -60
                        ? AppColors.success
                        : (dev.rssi > -80
                              ? AppColors.warning
                              : AppColors.error),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'MAC / ID: ${dev.id}',
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 11,
                fontFamily: 'monospace',
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Advertisement Data: ${_formatAdvertisementData(dev.advertisementData)}',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Manufacturer Data: ${_formatManufacturerData(dev.manufacturerData)}',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                isConnecting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : (isConnected
                          ? ElevatedButton(
                              onPressed: () => ref
                                  .read(wearableProvider.notifier)
                                  .disconnect(),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.error,
                              ),
                              child: const Text(
                                'Disconnect',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            )
                          : ElevatedButton(
                              onPressed: () async {
                                final oldDev = old.DiscoveredDevice(
                                  id: dev.id,
                                  name: dev.name,
                                  type: old.WearableDeviceType.values
                                      .firstWhere(
                                        (e) => e.name == dev.type.name,
                                        orElse: () => old
                                            .WearableDeviceType
                                            .genericHeartRate,
                                      ),
                                  rssi: dev.rssi,
                                );
                                await ref
                                    .read(wearableProvider.notifier)
                                    .connect(oldDev);
                                if (context.mounted) Navigator.pop(context);
                              },
                              child: const Text('Connect'),
                            )),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _getCategoryIcon(WearableDeviceType type) {
    switch (type) {
      case WearableDeviceType.polarHeartRate:
      case WearableDeviceType.garminHeartRate:
      case WearableDeviceType.genericHeartRate:
        return Icons.favorite;
      case WearableDeviceType.samsungWatch:
      case WearableDeviceType.pixelWatch:
      case WearableDeviceType.xiaomiWatch:
        return Icons.watch;
      case WearableDeviceType.ouraRing:
      case WearableDeviceType.genericHealth:
        return Icons.health_and_safety;
      default:
        return Icons.bluetooth;
    }
  }
}
