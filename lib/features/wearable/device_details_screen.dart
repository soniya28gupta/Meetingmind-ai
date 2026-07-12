import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' as fbp;
import '../../core/theme/app_theme.dart';
import '../../widgets/glass_card.dart';
import 'providers/wearable_provider.dart';
import 'wearables/wearable_service.dart';
import 'wearable_models.dart' as old;

class DeviceDetailsScreen extends ConsumerStatefulWidget {
  const DeviceDetailsScreen({super.key});

  @override
  ConsumerState<DeviceDetailsScreen> createState() =>
      _DeviceDetailsScreenState();
}

class _DeviceDetailsScreenState extends ConsumerState<DeviceDetailsScreen> {
  final Map<String, String> _readValues = {};
  final Map<String, StreamSubscription<List<int>>?> _subscriptions = {};
  final List<String> _consoleLogs = [];
  bool _discovering = true;
  List<fbp.BluetoothService> _discoveredServices = [];

  @override
  void initState() {
    super.initState();
    _loadServices();
  }

  @override
  void dispose() {
    for (final sub in _subscriptions.values) {
      sub?.cancel();
    }
    super.dispose();
  }

  Future<void> _loadServices() async {
    try {
      final services = await WearableService().discoverServices();
      if (mounted) {
        setState(() {
          _discoveredServices = services;
          _discovering = false;
        });
      }
    } catch (e) {
      print('[DeviceDetailsScreen] Error discovering services: $e');
      if (mounted) {
        setState(() {
          _discovering = false;
        });
      }
    }
  }

  Future<void> _readChar(fbp.BluetoothCharacteristic char) async {
    final charUuid = char.characteristicUuid.str.toLowerCase();
    try {
      setState(() {
        _readValues[charUuid] = 'Reading...';
      });
      final val = await WearableService().readCharacteristic(
        char.serviceUuid.str,
        char.characteristicUuid.str,
      );
      final hex = val
          .map((b) => b.toRadixString(16).padLeft(2, '0'))
          .join(' ')
          .toUpperCase();
      final ascii = String.fromCharCodes(
        val,
      ).replaceAll(RegExp(r'[^\x20-\x7E]'), '.');

      if (mounted) {
        setState(() {
          _readValues[charUuid] = 'Hex: 0x$hex\nASCII: "$ascii"';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _readValues[charUuid] = 'Error: ${e.toString()}';
        });
      }
    }
  }

  Future<void> _toggleSubscription(
    fbp.BluetoothCharacteristic char,
    bool enable,
  ) async {
    final charUuid = char.characteristicUuid.str.toLowerCase();

    if (!enable) {
      // Unsubscribe
      await _subscriptions[charUuid]?.cancel();
      _subscriptions[charUuid] = null;
      setState(() {
        _consoleLogs.insert(0, '[${_timeStr()}] Unsubscribed from $charUuid');
      });
      try {
        await WearableService().subscribeCharacteristic(
          char.serviceUuid.str,
          char.characteristicUuid.str,
          false,
        );
      } catch (_) {}
      return;
    }

    // Subscribe
    try {
      setState(() {
        _consoleLogs.insert(0, '[${_timeStr()}] Subscribing to $charUuid...');
      });

      final stream = await WearableService().subscribeCharacteristic(
        char.serviceUuid.str,
        char.characteristicUuid.str,
        true,
      );

      final sub = stream.listen((value) {
        if (mounted) {
          final hex = value
              .map((b) => b.toRadixString(16).padLeft(2, '0'))
              .join(' ')
              .toUpperCase();
          setState(() {
            _consoleLogs.insert(
              0,
              '[${_timeStr()}] Char ${charUuid.substring(0, 4)}... update: 0x$hex',
            );
            if (_consoleLogs.length > 30) {
              _consoleLogs.removeLast();
            }
          });
        }
      });

      _subscriptions[charUuid] = sub;
      setState(() {
        _consoleLogs.insert(
          0,
          '[${_timeStr()}] Subscribed successfully to $charUuid',
        );
      });
    } catch (e) {
      setState(() {
        _consoleLogs.insert(
          0,
          '[${_timeStr()}] Subscription failed: ${e.toString()}',
        );
      });
    }
  }

  String _timeStr() {
    return DateTime.now().toString().split(' ')[1].substring(0, 8);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(wearableProvider);
    final isConnected =
        state.connectionState == old.DeviceConnectionState.connected;
    final device = WearableService().connectedDevice;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'GATT Explorer',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (device == null) ...[
                const GlassCard(
                  padding: EdgeInsets.all(20),
                  child: Center(
                    child: Text(
                      'No device currently connected.',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                ),
              ] else ...[
                // Device Profile Header
                Center(
                  child: Column(
                    children: [
                      const Icon(
                        Icons.developer_board,
                        size: 64,
                        color: AppColors.primary,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        device.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isConnected ? 'Connected' : 'Disconnected',
                        style: TextStyle(
                          color: isConnected
                              ? AppColors.success
                              : AppColors.error,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Core details cards
                const Text(
                  'Hardware Specifications',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 10),
                GlassCard(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    children: [
                      _buildRow('Manufacturer', device.manufacturer),
                      const Divider(color: AppColors.border, height: 16),
                      _buildRow('Model Number', device.modelNumber),
                      const Divider(color: AppColors.border, height: 16),
                      _buildRow('Firmware Revision', device.firmwareVersion),
                      const Divider(color: AppColors.border, height: 16),
                      _buildRow('RSSI Signal Strength', '${device.rssi} dBm'),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Console Logs if subscriptions exist
                if (_consoleLogs.isNotEmpty) ...[
                  const Text(
                    'Live Notification Console',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    height: 140,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black45,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: ListView.builder(
                      itemCount: _consoleLogs.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 4.0),
                          child: Text(
                            _consoleLogs[index],
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 11,
                              color: Colors.green,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Discovered Services GATT Tree representation
                const Text(
                  'GATT Service Explorer',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 10),

                if (_discovering) ...[
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(28.0),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                ] else if (_discoveredServices.isEmpty) ...[
                  const GlassCard(
                    padding: EdgeInsets.all(16),
                    child: Center(
                      child: Text(
                        'No GATT services found or device disconnected.',
                        style: TextStyle(color: AppColors.textMuted),
                      ),
                    ),
                  ),
                ] else ...[
                  ..._discoveredServices.map((service) {
                    final sUuid = service.serviceUuid.str.toUpperCase().split(
                      '-',
                    )[0];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: Theme(
                        data: Theme.of(
                          context,
                        ).copyWith(dividerColor: Colors.transparent),
                        child: GlassCard(
                          padding: EdgeInsets.zero,
                          child: ExpansionTile(
                            leading: const Icon(
                              Icons.dns,
                              color: AppColors.primary,
                            ),
                            iconColor: Colors.white,
                            collapsedIconColor: Colors.white70,
                            title: Text(
                              'Service: 0x$sUuid',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            subtitle: Text(
                              service.serviceUuid.str,
                              style: const TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 10,
                                fontFamily: 'monospace',
                              ),
                            ),
                            children: service.characteristics.map((char) {
                              final cUuid = char.characteristicUuid.str
                                  .toUpperCase()
                                  .split('-')[0];
                              final charFullUuid = char.characteristicUuid.str
                                  .toLowerCase();
                              final props = char.properties;

                              final isReadable = props.read;
                              final isNotifiable =
                                  props.notify || props.indicate;
                              final hasSubscription =
                                  _subscriptions[charFullUuid] != null;
                              final readVal = _readValues[charFullUuid];

                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16.0,
                                  vertical: 10.0,
                                ),
                                decoration: const BoxDecoration(
                                  border: Border(
                                    top: BorderSide(
                                      color: AppColors.border,
                                      width: 0.5,
                                    ),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.adjust_rounded,
                                          size: 12,
                                          color: AppColors.accent,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            'Characteristic: 0x$cUuid',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        left: 20.0,
                                        top: 2.0,
                                      ),
                                      child: Text(
                                        char.characteristicUuid.str,
                                        style: const TextStyle(
                                          color: AppColors.textMuted,
                                          fontSize: 9,
                                          fontFamily: 'monospace',
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 6),

                                    // Display Properties/Capabilities
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        left: 20.0,
                                      ),
                                      child: Wrap(
                                        spacing: 6,
                                        children: [
                                          _buildPropBadge('Read', isReadable),
                                          _buildPropBadge(
                                            'Write',
                                            props.write ||
                                                props.writeWithoutResponse,
                                          ),
                                          _buildPropBadge(
                                            'Notify',
                                            props.notify,
                                          ),
                                          _buildPropBadge(
                                            'Indicate',
                                            props.indicate,
                                          ),
                                        ],
                                      ),
                                    ),

                                    // Interactions Section
                                    if (isReadable || isNotifiable) ...[
                                      const SizedBox(height: 10),
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          left: 20.0,
                                        ),
                                        child: Row(
                                          children: [
                                            if (isReadable) ...[
                                              ElevatedButton.icon(
                                                style: ElevatedButton.styleFrom(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 10,
                                                        vertical: 6,
                                                      ),
                                                  minimumSize: Size.zero,
                                                ),
                                                onPressed: () =>
                                                    _readChar(char),
                                                icon: const Icon(
                                                  Icons.download,
                                                  size: 12,
                                                ),
                                                label: const Text(
                                                  'Read',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 10),
                                            ],
                                            if (isNotifiable) ...[
                                              Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  const Text(
                                                    'Notify: ',
                                                    style: TextStyle(
                                                      color: AppColors
                                                          .textSecondary,
                                                      fontSize: 11,
                                                    ),
                                                  ),
                                                  Switch(
                                                    value: hasSubscription,
                                                    activeColor:
                                                        AppColors.primary,
                                                    onChanged: (val) =>
                                                        _toggleSubscription(
                                                          char,
                                                          val,
                                                        ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ],

                                    // Read value display box
                                    if (readVal != null) ...[
                                      const SizedBox(height: 8),
                                      Container(
                                        margin: const EdgeInsets.only(
                                          left: 20.0,
                                        ),
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.black26,
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                          border: Border.all(
                                            color: AppColors.border,
                                            width: 0.5,
                                          ),
                                        ),
                                        child: Text(
                                          readVal,
                                          style: const TextStyle(
                                            fontFamily: 'monospace',
                                            fontSize: 10,
                                            color: Colors.white70,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ],
                const SizedBox(height: 24),

                ElevatedButton.icon(
                  onPressed: () async {
                    await ref.read(wearableProvider.notifier).disconnect();
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.link_off),
                  label: const Text(
                    'Forget & Disconnect Device',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPropBadge(String label, bool active) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: active
            ? AppColors.primary.withValues(alpha: 0.2)
            : Colors.white10,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: active ? AppColors.primary : Colors.transparent,
          width: 0.5,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: active ? Colors.white : AppColors.textMuted,
          fontSize: 8,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}
