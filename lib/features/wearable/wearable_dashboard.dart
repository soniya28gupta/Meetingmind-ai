import 'dart:async';
import 'dart:math';
import 'package:isar/isar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/gradient_button.dart';
import '../../database/isar_database.dart';
import '../../database/schemas/meeting_models.dart';
import '../../providers/app_providers.dart';
import 'wearable_models.dart';
import 'providers/wearable_provider.dart';
import 'providers/bluetooth_provider.dart';
import 'wearables/wearable_service.dart';
import 'wearable_settings_sheet.dart';
import 'connect_wearable_screen.dart';
import 'device_details_screen.dart';

// ─── Main Dashboard Widget ────────────────────────────────────────────────────

class WearableDashboard extends ConsumerStatefulWidget {
  const WearableDashboard({super.key});

  @override
  ConsumerState<WearableDashboard> createState() => _WearableDashboardState();
}

class _WearableDashboardState extends ConsumerState<WearableDashboard>
    with TickerProviderStateMixin {
  late AnimationController _heartController;
  late Animation<double> _heartScale;
  late AnimationController _radarController;
  List<MeetingModel> _meetingsToday = [];

  @override
  void initState() {
    super.initState();
    // Heart pulse animation
    _heartController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    )..repeat(reverse: true);
    _heartScale = Tween<double>(begin: 1.0, end: 1.22).animate(
      CurvedAnimation(parent: _heartController, curve: Curves.easeInOut),
    );

    // Radar scan animation
    _radarController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    // Load today's meetings for correlation
    _loadMeetingsToday();
  }

  Future<void> _loadMeetingsToday() async {
    try {
      final isar = IsarDatabase.instance.isar;
      final userId =
          ref.read(authRepositoryProvider).currentUser?.uid ??
          'offline_fallback';
      final todayStart = DateTime.now().subtract(const Duration(hours: 24));

      final meetings = await isar.meetingModels
          .filter()
          .userIdEqualTo(userId)
          .findAll();
      final filteredMeetings = meetings
          .where((m) => m.createdAt != null && m.createdAt!.isAfter(todayStart))
          .toList();

      if (mounted) {
        setState(() {
          _meetingsToday = filteredMeetings;
        });
      }
    } catch (e) {
      print('[WearableDashboard] Error loading meetings: $e');
    }
  }

  @override
  void dispose() {
    _heartController.dispose();
    _radarController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(wearableProvider);
    final isConnected =
        state.connectionState == DeviceConnectionState.connected;
    final isSyncing = state.isSyncing;

    // Trigger meeting reload on rebuild to stay fresh
    _loadMeetingsToday();

    // Dynamic Wellness Score based on actual data
    final wellnessScore = ref
        .read(wearableProvider.notifier)
        .getWellnessScore(_meetingsToday);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(
              Icons.favorite_rounded,
              color: AppColors.primary,
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              'Wearable Wellness',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (isConnected) ...[
            IconButton(
              icon: isSyncing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white70,
                      ),
                    )
                  : const Icon(Icons.sync_rounded, color: Colors.white70),
              tooltip: 'Sync data now',
              onPressed: () => ref.read(wearableProvider.notifier).syncNow(),
            ),
          ],
          IconButton(
            icon: const Icon(Icons.settings_rounded, color: Colors.white70),
            tooltip: 'Settings',
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => const WearableSettingsSheet(),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(wearableProvider.notifier).syncNow();
          await _loadMeetingsToday();
        },
        color: AppColors.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              GlassCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: const [
                        Icon(
                          Icons.developer_mode,
                          color: AppColors.primary,
                          size: 18,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Simulation Mode (Developer)',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    Switch(
                      value: state.isSimulationMode,
                      onChanged: (val) {
                        ref
                            .read(wearableProvider.notifier)
                            .toggleSimulationMode(val);
                      },
                      activeColor: AppColors.primary,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (!isConnected &&
                  state.connectionState != DeviceConnectionState.connecting &&
                  state.connectionState !=
                      DeviceConnectionState.reconnecting) ...[
                // Phase 15: Beautiful Empty State
                _buildPremiumEmptyState(context, state),
              ] else ...[
                // Smart Alerts Carousel (Phase 10)
                if (state.activeAlerts.isNotEmpty) ...[
                  _buildAlertsCarousel(state.activeAlerts),
                  const SizedBox(height: 20),
                ],

                // Wellness Radial Score Banner (Phase 8)
                _buildWellnessScoreHeader(wellnessScore),
                const SizedBox(height: 20),

                // BLE Device Connection card (Phase 2)
                _buildDeviceCard(context, state),
                const SizedBox(height: 20),

                // Telemetry health cards grid (Phase 4 & 5)
                _buildHealthCardsGrid(state),
                const SizedBox(height: 20),

                // AI Coach advice block (Phase 7)
                _buildAICoachCard(state),
                const SizedBox(height: 20),

                // Interactive fl_chart visualizer (Phase 6)
                _buildInteractiveCharts(state),
                const SizedBox(height: 20),

                // Meeting health correlation log (Phase 9)
                _buildMeetingCorrelationSection(),
                const SizedBox(height: 20),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ─── Phase 15: Premium Empty State ──────────────────────────────────────────
  Widget _buildPremiumEmptyState(BuildContext context, WearableState state) {
    return Column(
      children: [
        const SizedBox(height: 30),
        Center(
          child: Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.2),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Icon(
              Icons.bluetooth_searching_rounded,
              size: 70,
              color: AppColors.accentLight,
            ),
          ),
        ),
        const SizedBox(height: 30),
        const Text(
          'Connect Wearable to Unlock AI Insights',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            'Monitor cognitive stress, heart rate variability, sleep quality, and calories correlated with meetings in real-time.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ),
        const SizedBox(height: 32),

        // Value Props Grid
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 1.35,
          children: [
            _buildPropCard(
              Icons.favorite_rounded,
              'Realtime heart rate',
              'Live BPM stream',
            ),
            _buildPropCard(
              Icons.psychology_rounded,
              'Cognitive stress',
              'Meeting stress correlation',
            ),
            _buildPropCard(
              Icons.bedtime_rounded,
              'Sleep analytics',
              'Track recovery scores',
            ),
            _buildPropCard(
              Icons.auto_awesome_rounded,
              'AI wellness coach',
              'Personalized recommendations',
            ),
          ],
        ),
        const SizedBox(height: 40),

        GradientButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ConnectWearableScreen()),
            );
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.bluetooth_searching_rounded, size: 20),
              SizedBox(width: 8),
              Text(
                'Scan & Pair Devices',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildPropCard(IconData icon, String title, String subtitle) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary, size: 24),
          const Spacer(),
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            subtitle,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
          ),
        ],
      ),
    );
  }

  // ─── Phase 8: Wellness Score Radial Banner ──────────────────────────────────
  Widget _buildWellnessScoreHeader(int score) {
    Color scoreColor = AppColors.success;
    String rating = 'Optimal';
    if (score < 60) {
      scoreColor = AppColors.error;
      rating = 'Restricted';
    } else if (score < 80) {
      scoreColor = AppColors.warning;
      rating = 'Moderate';
    }

    return GlassCard(
      padding: const EdgeInsets.all(22),
      child: Row(
        children: [
          // Radial Progress Indicator
          SizedBox(
            width: 90,
            height: 90,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: score / 100.0,
                  strokeWidth: 10,
                  backgroundColor: AppColors.surfaceLight,
                  color: scoreColor,
                ),
                Text(
                  '$score',
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Wellness Score: $score/100',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: scoreColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    rating,
                    style: TextStyle(
                      color: scoreColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Your score tracks resting heart rate, sleep restoration, active steps, and meeting stress today.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Phase 2: Wearable Connection Card ──────────────────────────────────────
  Widget _buildDeviceCard(BuildContext context, WearableState state) {
    final isConnected =
        state.connectionState == DeviceConnectionState.connected;
    final isSyncing =
        state.connectionState == DeviceConnectionState.connecting ||
        state.connectionState == DeviceConnectionState.reconnecting;

    final device = state.connectedDevice;
    final battery = state.liveData.battery ?? 88;
    final rssi = device?.rssi ?? -55;
    final firmware =
        WearableService().connectedDevice?.firmwareVersion ?? 'v1.0.0';

    Color stateColor = AppColors.error;
    String stateLabel = 'Disconnected';
    if (isConnected) {
      stateColor = AppColors.success;
      stateLabel = 'Connected';
    } else if (isSyncing) {
      stateColor = AppColors.warning;
      stateLabel = 'Syncing...';
    }

    return GestureDetector(
      onTap: isConnected
          ? () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DeviceDetailsScreen()),
              );
            }
          : null,
      child: GlassCard(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: stateColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  stateLabel,
                  style: TextStyle(
                    color: stateColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const Spacer(),
                Text(
                  'Last Sync: ${DateFormat.jm().format(DateTime.now())}',
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  isConnected ? Icons.watch_rounded : Icons.watch_off_rounded,
                  size: 38,
                  color: isConnected ? AppColors.primary : AppColors.textMuted,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isConnected
                            ? (device?.name ?? 'Connected Smartwatch')
                            : 'No Device Paired',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isConnected
                            ? 'Firmware: $firmware | Battery: $battery%'
                            : 'Pair a BLE device to track biometrics',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.bluetooth_audio_rounded,
                    color: AppColors.primary,
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ConnectWearableScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
            if (isConnected) ...[
              const SizedBox(height: 16),
              const Divider(color: AppColors.border, height: 1),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatIcon(
                    Icons.wifi_tethering,
                    '${rssi} dBm',
                    'BLE Signal',
                  ),
                  _buildStatIcon(Icons.bolt, 'Excellent', 'Quality'),
                  _buildStatIcon(
                    Icons.battery_5_bar_rounded,
                    '$battery%',
                    'Battery',
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatIcon(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: AppColors.textSecondary, size: 18),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: AppColors.textMuted, fontSize: 10),
        ),
      ],
    );
  }

  // ─── Phase 10: Smart Alerts Carousel ────────────────────────────────────────
  Widget _buildAlertsCarousel(List<SmartAlert> alerts) {
    return GlassCard(
      borderColor: AppColors.warning.withValues(alpha: 0.3),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        children: alerts.map((alert) {
          Color typeColor = AppColors.warning;
          IconData icon = Icons.warning_amber_rounded;
          if (alert.type == 'success') {
            typeColor = AppColors.success;
            icon = Icons.check_circle_outline_rounded;
          } else if (alert.type == 'info') {
            typeColor = AppColors.primary;
            icon = Icons.info_outline_rounded;
          }

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Row(
              children: [
                Icon(icon, color: typeColor, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        alert.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        alert.description,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ─── Phase 4 & 5: Health Cards Grid ─────────────────────────────────────────
  Widget _buildHealthCardsGrid(WearableState state) {
    final live = state.liveData;

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 14,
      crossAxisSpacing: 14,
      childAspectRatio: 1.25,
      children: [
        _buildMetricCard(
          title: 'Heart Rate',
          value: live.heartRate != null ? '${live.heartRate}' : '--',
          unit: ' BPM',
          icon: Icons.favorite_rounded,
          color: AppColors.error,
          status: live.heartRate != null
              ? (live.heartRate! > 90 ? 'Elevated' : 'Normal')
              : 'No data',
          sparkline: [62, 65, 72, 70, 78, live.heartRate?.toDouble() ?? 74.0],
        ),
        _buildMetricCard(
          title: 'Stress Score',
          value: live.stress != null ? '${live.stress!.round()}%' : '--',
          unit: '',
          icon: Icons.psychology_rounded,
          color: AppColors.warning,
          status: live.stress != null
              ? (live.stress! > 50 ? 'High' : 'Low')
              : 'No data',
          sparkline: [22, 28, 30, 24, 38, live.stress ?? 28.0],
        ),
        _buildMetricCard(
          title: 'Daily Steps',
          value: live.steps != null ? '${live.steps}' : '--',
          unit: '',
          icon: Icons.directions_walk_rounded,
          color: AppColors.secondary,
          status: live.steps != null
              ? '${(live.steps! / 10000 * 100).round()}%'
              : 'Goal: 10k',
          sparkline: [
            1200,
            2400,
            4800,
            6000,
            7800,
            live.steps?.toDouble() ?? 8200.0,
          ],
        ),
        _buildMetricCard(
          title: 'Sleep Duration',
          value: live.sleep != null ? live.sleep!.toStringAsFixed(1) : '--',
          unit: ' hrs',
          icon: Icons.bedtime_rounded,
          color: AppColors.primary,
          status: live.sleep != null
              ? (live.sleep! > 7.0 ? 'Excellent' : 'Good')
              : 'No data',
          sparkline: [6.8, 7.2, 7.0, 7.8, 7.5, live.sleep ?? 7.4],
        ),
        _buildMetricCard(
          title: 'Blood Oxygen',
          value: live.spo2 != null ? '${live.spo2}%' : '--',
          unit: '',
          icon: Icons.air_rounded,
          color: Colors.cyan,
          status: live.spo2 != null ? 'Normal' : 'No data',
          sparkline: [98, 97, 98, 99, 98, live.spo2?.toDouble() ?? 98.0],
        ),
        _buildMetricCard(
          title: 'HRV',
          value: live.hrv != null ? '${live.hrv!.round()}' : '--',
          unit: ' ms',
          icon: Icons.graphic_eq_rounded,
          color: Colors.tealAccent,
          status: live.hrv != null ? 'Optimal' : 'No data',
          sparkline: [52, 54, 58, 62, 58, live.hrv ?? 56.0],
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String unit,
    required IconData icon,
    required Color color,
    required String status,
    required List<double> sparkline,
  }) {
    final heartAnimated = icon == Icons.favorite_rounded && value != '--';

    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 11,
                ),
              ),
              heartAnimated
                  ? AnimatedBuilder(
                      animation: _heartScale,
                      builder: (_, __) => Transform.scale(
                        scale: _heartScale.value,
                        child: Icon(icon, color: color, size: 16),
                      ),
                    )
                  : Icon(icon, color: color, size: 16),
            ],
          ),
          const Spacer(),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontFamily: 'monospace',
                ),
              ),
              Text(
                unit,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color: color,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              // Mini Graph representation
              SizedBox(
                width: 45,
                height: 18,
                child: LineChart(
                  LineChartData(
                    gridData: const FlGridData(show: false),
                    titlesData: const FlTitlesData(show: false),
                    borderData: FlBorderData(show: false),
                    minX: 0,
                    maxX: (sparkline.length - 1).toDouble(),
                    minY: sparkline.reduce(min) - 1,
                    maxY: sparkline.reduce(max) + 1,
                    lineBarsData: [
                      LineChartBarData(
                        spots: sparkline
                            .asMap()
                            .entries
                            .map((e) => FlSpot(e.key.toDouble(), e.value))
                            .toList(),
                        isCurved: true,
                        color: color,
                        barWidth: 1.8,
                        isStrokeCapRound: true,
                        dotData: const FlDotData(show: false),
                        belowBarData: BarAreaData(show: false),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Phase 7: AI Wellness Coach ─────────────────────────────────────────────
  Widget _buildAICoachCard(WearableState state) {
    final insight = state.aiInsight;
    final isLoading = state.isLoadingInsight;

    return GlassCard(
      borderColor: AppColors.primary.withValues(alpha: 0.25),
      borderWidth: 1.0,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(
                Icons.auto_awesome_rounded,
                color: AppColors.primary,
                size: 24,
              ),
              const SizedBox(width: 10),
              const Text(
                'AI Wellness Coach',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primary,
                        ),
                      )
                    : const Icon(
                        Icons.refresh_rounded,
                        color: AppColors.primary,
                        size: 20,
                      ),
                onPressed: isLoading
                    ? null
                    : () => ref
                          .read(wearableProvider.notifier)
                          .generateAICoachInsight(),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            insight.coachAdvice,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 14),
          ...insight.bulletPoints.map(
            (point) => Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 4.0, right: 8.0),
                    child: Icon(Icons.lens, size: 6, color: AppColors.accent),
                  ),
                  Expanded(
                    child: Text(
                      point,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.bottomRight,
            child: Text(
              'Coached by MeetingMind AI',
              style: TextStyle(
                color: AppColors.textMuted.withValues(alpha: 0.7),
                fontSize: 10,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Phase 6: Interactive Multi-Timeframe Charts ───────────────────────────
  Widget _buildInteractiveCharts(WearableState state) {
    final currentMetric = state.selectedMetricType;
    final currentFilter = state.timeframeFilter;

    // Static bezier coordinate calculation for illustration
    List<FlSpot> spots = [];
    if (currentFilter == 'today') {
      spots = const [
        FlSpot(0, 68),
        FlSpot(2, 70),
        FlSpot(4, 65),
        FlSpot(6, 74),
        FlSpot(8, 80),
        FlSpot(10, 85),
        FlSpot(12, 75),
        FlSpot(14, 88),
        FlSpot(16, 72),
        FlSpot(18, 76),
        FlSpot(20, 66),
        FlSpot(22, 68),
        FlSpot(24, 70),
      ];
    } else if (currentFilter == 'week') {
      spots = const [
        FlSpot(1, 72),
        FlSpot(2, 75),
        FlSpot(3, 71),
        FlSpot(4, 78),
        FlSpot(5, 82),
        FlSpot(6, 68),
        FlSpot(7, 72),
      ];
    } else {
      spots = const [
        FlSpot(1, 70),
        FlSpot(5, 75),
        FlSpot(10, 68),
        FlSpot(15, 82),
        FlSpot(20, 74),
        FlSpot(25, 70),
        FlSpot(30, 78),
      ];
    }

    // Multiply coordinates relative to the metric select type
    if (currentMetric == 'steps') {
      spots = spots.map((s) => FlSpot(s.x, s.y * 100.0)).toList();
    } else if (currentMetric == 'stress') {
      spots = spots.map((s) => FlSpot(s.x, s.y / 2.0)).toList();
    } else if (currentMetric == 'sleep') {
      spots = spots.map((s) => FlSpot(s.x, s.y / 10.0)).toList();
    }

    Color metricColor = AppColors.primary;
    if (currentMetric == 'stress') metricColor = AppColors.warning;
    if (currentMetric == 'steps') metricColor = AppColors.secondary;
    if (currentMetric == 'sleep') metricColor = AppColors.success;

    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Biometrics Analysis',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Row(
                children: [
                  _buildTimeframeChip('Today', 'today', currentFilter),
                  const SizedBox(width: 6),
                  _buildTimeframeChip('Week', 'week', currentFilter),
                  const SizedBox(width: 6),
                  _buildTimeframeChip('Month', 'month', currentFilter),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMetricTypeButton('Heart Rate', 'hr', currentMetric),
              _buildMetricTypeButton('Stress', 'stress', currentMetric),
              _buildMetricTypeButton('Steps', 'steps', currentMetric),
              _buildMetricTypeButton('Sleep', 'sleep', currentMetric),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 180,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) =>
                      const FlLine(color: AppColors.border, strokeWidth: 0.5),
                ),
                titlesData: FlTitlesData(
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      getTitlesWidget: (val, _) => Text(
                        val.round().toString(),
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (val, _) {
                        String label = '';
                        if (currentFilter == 'today') {
                          if (val % 6 == 0) label = '${val.round()}h';
                        } else if (currentFilter == 'week') {
                          final days = [
                            'Mon',
                            'Tue',
                            'Wed',
                            'Thu',
                            'Fri',
                            'Sat',
                            'Sun',
                          ];
                          final idx = val.round() - 1;
                          if (idx >= 0 && idx < days.length) label = days[idx];
                        } else {
                          if (val % 10 == 0) label = 'd${val.round()}';
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            label,
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 10,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: metricColor,
                    barWidth: 3.0,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          metricColor.withValues(alpha: 0.35),
                          metricColor.withValues(alpha: 0.0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeframeChip(String label, String value, String current) {
    final isSelected = value == current;
    return GestureDetector(
      onTap: () =>
          ref.read(wearableProvider.notifier).setTimeframeFilter(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildMetricTypeButton(String label, String type, String current) {
    final isSelected = type == current;
    return GestureDetector(
      onTap: () =>
          ref.read(wearableProvider.notifier).setSelectedMetricType(type),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.transparent,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isSelected ? AppColors.accentLight : AppColors.textMuted,
          ),
        ),
      ),
    );
  }

  // ─── Phase 9: Meeting Correlation Log ──────────────────────────────────────
  Widget _buildMeetingCorrelationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4.0, bottom: 12.0),
          child: Text(
            'Meeting-Health Correlations',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        _meetingsToday.isEmpty
            ? GlassCard(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: const [
                    Icon(
                      Icons.mic_none_rounded,
                      color: AppColors.textMuted,
                      size: 24,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'No meetings recorded today. Correlation logs will load after your next meeting.',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            : Column(
                children: _meetingsToday.map((meeting) {
                  final hr = meeting.heartRateAverage?.round() ?? 76;
                  final stress = meeting.stressAverage?.round() ?? 28;
                  final focus = meeting.engagementScore?.round() ?? 90;
                  final mood = meeting.detectedEmotion ?? 'Positive';

                  Color stressColor = AppColors.success;
                  if (stress > 60) {
                    stressColor = AppColors.error;
                  } else if (stress > 35) {
                    stressColor = AppColors.warning;
                  }

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: GlassCard(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.play_circle_fill_rounded,
                                color: AppColors.primary,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  meeting.title ?? 'Recorded Meeting',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: Colors.white,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                '${(meeting.durationSeconds / 60).round()} mins',
                                style: const TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Divider(color: AppColors.border, height: 1),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildCorrelationItem(
                                'Avg HR',
                                '$hr BPM',
                                Icons.favorite_rounded,
                                AppColors.error,
                              ),
                              _buildCorrelationItem(
                                'Stress',
                                '$stress%',
                                Icons.psychology_rounded,
                                stressColor,
                              ),
                              _buildCorrelationItem(
                                'Focus',
                                '$focus%',
                                Icons.visibility_rounded,
                                AppColors.secondary,
                              ),
                              _buildCorrelationItem(
                                'Mood',
                                mood,
                                Icons.emoji_emotions_rounded,
                                Colors.orangeAccent,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
      ],
    );
  }

  Widget _buildCorrelationItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 12),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 10),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}
