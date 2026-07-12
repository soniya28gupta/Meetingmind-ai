import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/gradient_button.dart';
import 'wearable_provider.dart';

class ConnectedDeviceScreen extends ConsumerWidget {
  const ConnectedDeviceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(wearableProvider);
    final device = state.connectedDevice;
    final liveData = state.liveData;

    if (device == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Wearable Details')),
        body: const Center(child: Text('No device connected.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Wearable Control Center',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.darkGradient),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Device Header Panel
              GlassCard(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.bluetooth_connected_rounded,
                        color: AppColors.primary,
                        size: 48,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      device.name,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.success,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Connected',
                          style: TextStyle(
                            color: AppColors.success,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Device Parameters
              Row(
                children: [
                  Expanded(
                    child: GlassCard(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Phone Battery',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(
                                Icons.battery_5_bar_rounded,
                                color: AppColors.success,
                                size: 20,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                state.phoneMetrics != null
                                    ? '${state.phoneMetrics!.batteryLevel}%'
                                    : '--',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: GlassCard(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Signal (RSSI)',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(
                                Icons.wifi_tethering,
                                color: AppColors.secondary,
                                size: 20,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '${device.rssi} dBm',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Live Telemetry Readouts
              const Padding(
                padding: EdgeInsets.only(left: 4.0, bottom: 10.0),
                child: Text(
                  'Live Telemetry Streams',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),

              GlassCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Column(
                  children: [
                    _buildTelemetryTile(
                      icon: Icons.favorite_rounded,
                      color: AppColors.error,
                      label: 'Heart Rate',
                      value: '${liveData.heartRate} bpm',
                    ),
                    const Divider(color: AppColors.surfaceLight, height: 24),
                    _buildTelemetryTile(
                      icon: Icons.flash_on_rounded,
                      color: AppColors.warning,
                      label: 'Stress Score',
                      value: '${liveData.stress}',
                    ),
                    const Divider(color: AppColors.surfaceLight, height: 24),
                    _buildTelemetryTile(
                      icon: Icons.directions_walk_rounded,
                      color: AppColors.secondary,
                      label: 'Steps',
                      value: '${liveData.steps}',
                    ),
                    const Divider(color: AppColors.surfaceLight, height: 24),
                    _buildTelemetryTile(
                      icon: Icons.bedtime_rounded,
                      color: AppColors.primary,
                      label: 'Sleep Duration',
                      value: '${liveData.sleep} hrs',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Disconnect button
              GradientButton(
                gradientColors: const [AppColors.error, Color(0xFFC0392B)],
                onPressed: () async {
                  await ref.read(wearableProvider.notifier).disconnect();
                  if (context.mounted) Navigator.of(context).pop();
                },
                child: const Text('Disconnect Device'),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Back to Dashboard'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTelemetryTile({
    required IconData icon,
    required Color color,
    required String label,
    required String value,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
            ),
          ],
        ),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
  }
}
