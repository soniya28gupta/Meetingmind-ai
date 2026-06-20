import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/glass_card.dart';
import 'wearable_models.dart';
import 'wearable_provider.dart';
import 'device_discovery_screen.dart';
import 'connected_device_screen.dart';

class WearableDashboard extends ConsumerStatefulWidget {
  const WearableDashboard({super.key});

  @override
  ConsumerState<WearableDashboard> createState() => _WearableDashboardState();
}

class _WearableDashboardState extends ConsumerState<WearableDashboard> {
  String _chartViewType = 'weekly'; // 'daily', 'weekly', 'monthly'

  // Heart pulse animation controller
  double _heartScale = 1.0;
  Timer? _pulseTimer;

  @override
  void initState() {
    super.initState();
    _startHeartPulse();
  }

  @override
  void dispose() {
    _pulseTimer?.cancel();
    super.dispose();
  }

  void _startHeartPulse() {
    _pulseTimer = Timer.periodic(const Duration(milliseconds: 800), (timer) {
      if (mounted) {
        setState(() {
          _heartScale = _heartScale == 1.0 ? 1.2 : 1.0;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(wearableProvider);
    final liveData = state.liveData;
    final isConnected = state.connectionState == DeviceConnectionState.connected;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Wearable Device Connector Row
          _buildDeviceStatusCard(context, state),
          const SizedBox(height: 20),

          // Core Metrics Grid
          LayoutBuilder(
            builder: (context, constraints) {
              final double cardWidth = (constraints.maxWidth - 16) / 2;
              return Column(
                children: [
                  Row(
                    children: [
                      SizedBox(
                        width: cardWidth,
                        child: _buildMetricCard(
                          title: 'Heart Rate',
                          value: isConnected ? '${liveData.heartRate}' : '--',
                          unit: 'bpm',
                          icon: Icons.favorite_rounded,
                          iconColor: AppColors.error,
                          subtitle: isConnected ? 'Live Pulse' : 'Disconnected',
                          isLive: isConnected,
                        ),
                      ),
                      const SizedBox(width: 16),
                      SizedBox(
                        width: cardWidth,
                        child: _buildMetricCard(
                          title: 'Daily Steps',
                          value: isConnected ? '${liveData.steps}' : '4,250',
                          unit: '',
                          icon: Icons.directions_walk_rounded,
                          iconColor: AppColors.secondary,
                          subtitle: 'Goal: 10,000 steps',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      SizedBox(
                        width: cardWidth,
                        child: _buildMetricCard(
                          title: 'Sleep Duration',
                          value: isConnected ? '${liveData.sleep}' : '7.2',
                          unit: 'hrs',
                          icon: Icons.bedtime_rounded,
                          iconColor: AppColors.primary,
                          subtitle: 'Sleep Score: 82',
                        ),
                      ),
                      const SizedBox(width: 16),
                      SizedBox(
                        width: cardWidth,
                        child: _buildMetricCard(
                          title: 'Stress Score',
                          value: isConnected ? '${liveData.stress.toStringAsFixed(0)}' : '35',
                          unit: '/100',
                          icon: Icons.flash_on_rounded,
                          iconColor: AppColors.warning,
                          subtitle: isConnected ? _getStressLabel(liveData.stress) : 'Calm',
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),

          // Historical Telemetry Charts Section
          GlassCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Stress & HR Trends',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    _buildChartToggleButtons(),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 200,
                  child: LineChart(
                    _getChartData(),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildLegendItem(AppColors.primary, 'Stress Level'),
                    const SizedBox(width: 24),
                    _buildLegendItem(AppColors.secondary, 'Heart Rate (bpm)'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Static AI Wellness Insight
          GlassCard(
            borderColor: AppColors.primary.withValues(alpha: 0.3),
            borderWidth: 1.0,
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.auto_awesome_rounded, color: AppColors.primary, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Circadian Stress Analysis',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Your average stress levels peak during late-afternoon team sync meetings. Consider scheduling complex decision-making meetings before 1:00 PM when your focus levels are historically highest.',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildDeviceStatusCard(BuildContext context, WearableState state) {
    final isConnected = state.connectionState == DeviceConnectionState.connected;
    final device = state.connectedDevice;

    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                isConnected ? Icons.bluetooth_connected_rounded : Icons.bluetooth_disabled_rounded,
                color: isConnected ? AppColors.success : AppColors.textMuted,
                size: 28,
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isConnected ? (device?.name ?? 'Connected Wearable') : 'No Wearable Connected',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isConnected ? 'Battery: ${state.liveData.battery}% | Live Sync Active' : 'Enable BLE sensors for wellness metrics',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => isConnected
                      ? const ConnectedDeviceScreen()
                      : const DeviceDiscoveryScreen(),
                ),
              );
            },
            child: Text(isConnected ? 'Manage' : 'Connect'),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String unit,
    required IconData icon,
    required Color iconColor,
    required String subtitle,
    bool isLive = false,
  }) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w500)),
              AnimatedScale(
                scale: (isLive && title == 'Heart Rate') ? _heartScale : 1.0,
                duration: const Duration(milliseconds: 250),
                child: Icon(icon, color: iconColor, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            textBaseline: TextBaseline.alphabetic,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            children: [
              Text(
                value,
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              if (unit.isNotEmpty) ...[
                const SizedBox(width: 4),
                Text(unit, style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Text(subtitle, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
        ],
      ),
    );
  }

  String _getStressLabel(double stress) {
    if (stress < 30) return 'Relaxed & Calm';
    if (stress < 50) return 'Low Focus Stress';
    if (stress < 70) return 'Moderate Strain';
    return 'Elevated Stress';
  }

  Widget _buildChartToggleButtons() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildToggleItem('daily', 'D'),
          _buildToggleItem('weekly', 'W'),
          _buildToggleItem('monthly', 'M'),
        ],
      ),
    );
  }

  Widget _buildToggleItem(String value, String label) {
    final bool isSelected = _chartViewType == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _chartViewType = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.textSecondary,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
      ],
    );
  }

  LineChartData _getChartData() {
    // Generate mock datasets based on toggle values for visual richness,
    // in real deployments these queries are calculated from SensorReadingModel & DailyMetricsModel
    List<FlSpot> stressSpots = [];
    List<FlSpot> hrSpots = [];

    if (_chartViewType == 'daily') {
      // Hour intervals
      stressSpots = const [
        FlSpot(0, 15), FlSpot(4, 18), FlSpot(8, 48), FlSpot(12, 35),
        FlSpot(16, 75), FlSpot(20, 22), FlSpot(24, 15)
      ];
      hrSpots = const [
        FlSpot(0, 62), FlSpot(4, 58), FlSpot(8, 85), FlSpot(12, 72),
        FlSpot(16, 105), FlSpot(20, 68), FlSpot(24, 60)
      ];
    } else if (_chartViewType == 'weekly') {
      // Days: Mon-Sun
      stressSpots = const [
        FlSpot(1, 35), FlSpot(2, 48), FlSpot(3, 22), FlSpot(4, 52),
        FlSpot(5, 78), FlSpot(6, 18), FlSpot(7, 15)
      ];
      hrSpots = const [
        FlSpot(1, 72), FlSpot(2, 85), FlSpot(3, 68), FlSpot(4, 88),
        FlSpot(5, 108), FlSpot(6, 62), FlSpot(7, 60)
      ];
    } else {
      // Weeks of month
      stressSpots = const [
        FlSpot(1, 42), FlSpot(2, 38), FlSpot(3, 56), FlSpot(4, 45)
      ];
      hrSpots = const [
        FlSpot(1, 78), FlSpot(2, 75), FlSpot(3, 90), FlSpot(4, 81)
      ];
    }

    return LineChartData(
      gridData: const FlGridData(show: false),
      titlesData: FlTitlesData(
        show: true,
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (value, meta) {
              if (_chartViewType == 'daily') {
                if (value.toInt() % 4 == 0) return Text('${value.toInt()}h', style: const TextStyle(color: AppColors.textMuted, fontSize: 10));
              } else if (_chartViewType == 'weekly') {
                const days = ['', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                if (value.toInt() >= 1 && value.toInt() <= 7) {
                  return Text(days[value.toInt()], style: const TextStyle(color: AppColors.textMuted, fontSize: 10));
                }
              } else {
                return Text('Wk ${value.toInt()}', style: const TextStyle(color: AppColors.textMuted, fontSize: 10));
              }
              return const SizedBox();
            },
          ),
        ),
        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      borderData: FlBorderData(show: false),
      lineBarsData: [
        // Stress Line
        LineChartBarData(
          spots: stressSpots,
          isCurved: true,
          color: AppColors.primary,
          barWidth: 3.5,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(
            show: true,
            color: AppColors.primary.withValues(alpha: 0.15),
          ),
        ),
        // Heart Rate Line
        LineChartBarData(
          spots: hrSpots,
          isCurved: true,
          color: AppColors.secondary,
          barWidth: 3.5,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(
            show: true,
            color: AppColors.secondary.withValues(alpha: 0.10),
          ),
        ),
      ],
    );
  }
}
