import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import 'wearable_provider.dart';

class WearableSettingsSheet extends ConsumerWidget {
  const WearableSettingsSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(wearableProvider);
    final settings = state.wellnessSettings;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Wellness Settings',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Auto-Sync Switch
              _buildSwitchTile(
                title: 'Auto Sync Data',
                subtitle: 'Automatically sync data every refresh interval.',
                value: settings.autoSync,
                onChanged: (val) {
                  ref
                      .read(wearableProvider.notifier)
                      .updateSettings(settings.copyWith(autoSync: val));
                },
              ),
              const Divider(color: AppColors.border, height: 24),

              // Background Sync Switch
              _buildSwitchTile(
                title: 'Background Tracking',
                subtitle: 'Collect telemetry while the app is in background.',
                value: settings.backgroundSync,
                onChanged: (val) {
                  ref
                      .read(wearableProvider.notifier)
                      .updateSettings(settings.copyWith(backgroundSync: val));
                },
              ),
              const Divider(color: AppColors.border, height: 24),

              // Auto-Connect Switch
              _buildSwitchTile(
                title: 'Auto Reconnect BLE',
                subtitle: 'Reconnect to preferred device automatically.',
                value: settings.autoConnect,
                onChanged: (val) {
                  ref
                      .read(wearableProvider.notifier)
                      .updateSettings(settings.copyWith(autoConnect: val));
                },
              ),
              const Divider(color: AppColors.border, height: 24),

              // AI Data Sharing Switch
              _buildSwitchTile(
                title: 'AI Coach Analysis',
                subtitle: 'Share biometric logs with AI wellness engine.',
                value: settings.shareDataWithAI,
                onChanged: (val) {
                  ref
                      .read(wearableProvider.notifier)
                      .updateSettings(settings.copyWith(shareDataWithAI: val));
                },
              ),
              const Divider(color: AppColors.border, height: 24),

              // Sync Frequency Dropdown
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Sync Frequency',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Interval between data retrievals.',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  DropdownButton<int>(
                    value: settings.syncFrequencySeconds,
                    dropdownColor: AppColors.surface,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    underline: const SizedBox(),
                    items: const [
                      DropdownMenuItem(value: 15, child: Text('15s')),
                      DropdownMenuItem(value: 30, child: Text('30s')),
                      DropdownMenuItem(value: 60, child: Text('1 min')),
                      DropdownMenuItem(value: 300, child: Text('5 min')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        ref
                            .read(wearableProvider.notifier)
                            .updateSettings(
                              settings.copyWith(syncFrequencySeconds: val),
                            );
                      }
                    },
                  ),
                ],
              ),
              const Divider(color: AppColors.border, height: 24),

              // Units Choice
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Measurement System',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Display system for health logs.',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      ChoiceChip(
                        label: const Text('Metric'),
                        selected: settings.unitSystem == 'metric',
                        selectedColor: AppColors.primary,
                        backgroundColor: AppColors.surface,
                        labelStyle: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                        onSelected: (selected) {
                          if (selected) {
                            ref
                                .read(wearableProvider.notifier)
                                .updateSettings(
                                  settings.copyWith(unitSystem: 'metric'),
                                );
                          }
                        },
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('Imperial'),
                        selected: settings.unitSystem == 'imperial',
                        selectedColor: AppColors.primary,
                        backgroundColor: AppColors.surface,
                        labelStyle: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                        onSelected: (selected) {
                          if (selected) {
                            ref
                                .read(wearableProvider.notifier)
                                .updateSettings(
                                  settings.copyWith(unitSystem: 'imperial'),
                                );
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: AppColors.primary,
          activeTrackColor: AppColors.primary.withValues(alpha: 0.3),
          inactiveThumbColor: Colors.grey,
          inactiveTrackColor: AppColors.surface,
        ),
      ],
    );
  }
}
