import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:isar/isar.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/pdf_helper.dart';
import '../../database/isar_database.dart';
import '../../database/schemas/meeting_models.dart';
import '../../widgets/glass_card.dart';
import '../../providers/app_providers.dart';
import '../meetings/meetings_provider.dart';
import '../meetings/meeting_details_screen.dart';
import '../recording/recording_dialog.dart';
import '../recording/recording_provider.dart';
import '../settings/settings_screen.dart';
import '../settings/profile_screen.dart';
import 'dashboard_provider.dart';
import '../auth/auth_provider.dart';
import '../wearable/wearable_dashboard.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  bool _isDialogOpened = false;
  int _currentIndex = 0;

  void _showRecordingDialog(BuildContext context) {
    if (_isDialogOpened) return;
    _isDialogOpened = true;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const RecordingDialog(),
    ).then((_) {
      if (mounted) {
        setState(() {
          _isDialogOpened = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final stats = ref.watch(dashboardProvider);
    final meetingsAsync = ref.watch(meetingsListStreamProvider);
    final recordingState = ref.watch(recordingProvider);
    final emotionTest = ref.watch(emotionTestProvider);
    final user = ref.watch(authStateProvider).user;

    ref.listen<RecordingState>(recordingProvider, (previous, next) {
      if (previous?.status != next.status) {
        if (next.status == RecordingStatus.completed) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('🎉 Meeting Saved'),
              backgroundColor: AppColors.success,
              duration: Duration(seconds: 3),
            ),
          );
        } else if (next.status == RecordingStatus.error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Error: ${next.errorMessage ?? "An unknown error occurred"}'),
              backgroundColor: AppColors.error,
              duration: Duration(seconds: 4),
            ),
          );
        }
      }
    });

    return Scaffold(
      body: Stack(
        children: [
          // Background layout
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.secondary.withValues(alpha: 0.08),
              ),
            ),
          ),
          Positioned(
            top: 200,
            left: -150,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.05),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header Bar (always visible)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                  child: _buildHeader(context, user),
                ),
                // Premium sliding tab switcher
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: _buildTabSwitcher(),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: IndexedStack(
                    index: _currentIndex,
                    children: [
                      // TAB 0: Meetings/Assistant
                      RefreshIndicator(
                        onRefresh: () async {
                          ref.invalidate(meetingsListStreamProvider);
                        },
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildTestEmotionSection(context, emotionTest),
                              const SizedBox(height: 24),
                              _buildMetricsGrid(context, stats),
                              const SizedBox(height: 24),
                              _buildActivityChart(context, stats),
                              const SizedBox(height: 24),
                              _buildSpeakerLeaderboard(context),
                              const SizedBox(height: 24),
                              _buildMoodDistributionChart(context),
                              const SizedBox(height: 24),
                              _buildEmotionTrends(context),
                              const SizedBox(height: 24),
                              _buildTaskOwnershipChart(context),
                              const SizedBox(height: 24),
                              _buildAiInsightsCard(context, stats),
                              const SizedBox(height: 28),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Recent Meetings',
                                    style: Theme.of(context).textTheme.titleLarge,
                                  ),
                                  if (meetingsAsync.value?.isNotEmpty ?? false)
                                    Text(
                                      '${meetingsAsync.value!.length} total',
                                      style: const TextStyle(color: AppColors.textSecondary),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              _buildMeetingsList(context, meetingsAsync),
                              const SizedBox(height: 80),
                            ],
                          ),
                        ),
                      ),
                      // TAB 1: Wearable Wellness Dashboard
                      const WearableDashboard(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: LayoutBuilder(
        builder: (context, constraints) {
          final double screenWidth = MediaQuery.of(context).size.width;
          final bool isSmallScreen = screenWidth < 360;
          final bool isTablet = screenWidth >= 600;

          final String labelText = recordingState.status == RecordingStatus.recording
              ? '🎤 Recording...'
              : recordingState.status == RecordingStatus.paused
                  ? '⏸️ Paused'
                  : '🎤 Record Meeting';

          final IconData iconData = recordingState.status == RecordingStatus.recording
              ? Icons.stop_circle_rounded
              : Icons.mic_rounded;

          final Color buttonColor = recordingState.status == RecordingStatus.recording
              ? AppColors.error
              : recordingState.status == RecordingStatus.paused
                  ? AppColors.warning
                  : AppColors.primary;

          // Adaptive width based on device type
          final double buttonWidth = isTablet 
              ? 260.0 
              : (isSmallScreen ? screenWidth * 0.50 : screenWidth * 0.60);

          return SafeArea(
            child: Container(
              height: 54,
              width: buttonWidth,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(27),
                boxShadow: [
                  BoxShadow(
                    color: buttonColor.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: buttonColor,
                borderRadius: BorderRadius.circular(27),
                child: InkWell(
                  borderRadius: BorderRadius.circular(27),
                  onTap: () {
                    final isRecording = recordingState.status != RecordingStatus.idle &&
                                        recordingState.status != RecordingStatus.error &&
                                        recordingState.status != RecordingStatus.completed;
                    if (isRecording) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('🎤 Recording already in progress'),
                          backgroundColor: AppColors.warning,
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                    _showRecordingDialog(context);
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(iconData, color: Colors.white, size: isSmallScreen ? 20 : 24),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            labelText,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: isSmallScreen ? 12.0 : 14.0,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context, UserModel? user) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Row(
            children: [
              if (user != null) ...[
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const ProfileScreen()),
                    );
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.secondary.withValues(alpha: 0.5), width: 1.5),
                    ),
                    child: CircleAvatar(
                      radius: 22,
                      backgroundColor: AppColors.surface,
                      backgroundImage: user.photoUrl != null && user.photoUrl!.isNotEmpty
                          ? NetworkImage(user.photoUrl!)
                          : null,
                      child: user.photoUrl == null || user.photoUrl!.isEmpty
                          ? Text(
                              (user.displayName ?? 'U')[0].toUpperCase(),
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16),
                            )
                          : null,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user != null ? '👋 Welcome Back, ${user.displayName ?? "User"}' : 'MeetingMind AI',
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                            letterSpacing: 0.5,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      user != null ? (user.email ?? 'Your summary details') : 'Your summaries & action items',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          icon: const Icon(Icons.settings_outlined, color: AppColors.textPrimary, size: 26),
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            );
          },
        ),
      ],
    );
  }

  Widget _buildTabSwitcher() {
    return Container(
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.surfaceLight),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _currentIndex = 0),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: _currentIndex == 0 ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.chat_bubble_outline_rounded,
                      color: _currentIndex == 0 ? Colors.white : AppColors.textSecondary,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Meeting Intelligence',
                      style: TextStyle(
                        color: _currentIndex == 0 ? Colors.white : AppColors.textSecondary,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _currentIndex = 1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: _currentIndex == 1 ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.favorite_border_rounded,
                      color: _currentIndex == 1 ? Colors.white : AppColors.textSecondary,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Wearable Wellness',
                      style: TextStyle(
                        color: _currentIndex == 1 ? Colors.white : AppColors.textSecondary,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCardSkeleton() {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 60,
                height: 10,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
          Container(
            width: 40,
            height: 20,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsGrid(BuildContext context, DashboardData stats) {
    if (stats.isLoading) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final crossCount = constraints.maxWidth > 600 ? 4 : 2;
          return GridView.count(
            crossAxisCount: crossCount,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.4,
            children: List.generate(4, (index) => _buildStatCardSkeleton()),
          );
        },
      );
    }

    final double hours = stats.totalRecordingHours;
    final String hoursStr = hours >= 1.0 ? '${hours.toStringAsFixed(1)}h' : '${(hours * 60).toStringAsFixed(0)}m';

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossCount = constraints.maxWidth > 600 ? 4 : 2;
        return GridView.count(
          crossAxisCount: crossCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.4,
          children: [
            _buildStatCard(
              context,
              'Total Meetings',
              stats.totalMeetings.toString(),
              Icons.video_camera_back_outlined,
              AppColors.primary,
            ),
            _buildStatCard(
              context,
              'Hours Recorded',
              hoursStr,
              Icons.timer_outlined,
              AppColors.secondary,
            ),
            _buildStatCard(
              context,
              'Completed Tasks',
              stats.completedTasks.toString(),
              Icons.check_circle_outline_rounded,
              AppColors.success,
            ),
            _buildStatCard(
              context,
              'Pending Tasks',
              stats.pendingTasks.toString(),
              Icons.pending_actions_rounded,
              AppColors.warning,
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color accentColor,
  ) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
              ),
              Icon(icon, color: accentColor, size: 20),
            ],
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityChart(BuildContext context, DashboardData stats) {
    final activity = stats.weeklyActivity;
    final isAllZero = activity.every((val) => val == 0);

    if (isAllZero) {
      return GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.bar_chart_rounded, color: AppColors.secondary, size: 20),
                SizedBox(width: 8),
                Text(
                  'Weekly Activity (Minutes)',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Column(
                  children: [
                    Icon(Icons.bar_chart_outlined, color: AppColors.secondary.withValues(alpha: 0.6), size: 36),
                    const SizedBox(height: 8),
                    const Text('No Activity Registered', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 4),
                    const Text('Record or upload a meeting to see your weekly stats here.', style: TextStyle(color: AppColors.textMuted, fontSize: 11), textAlign: TextAlign.center),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Weekly Activity (Minutes)',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 160,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: activity.reduce((a, b) => a > b ? a : b) + 10.0,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => AppColors.surfaceLight,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        '${rod.toY.toStringAsFixed(0)} min',
                        const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (double value, TitleMeta meta) {
                        const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                        final idx = value.toInt();
                        if (idx >= 0 && idx < 7) {
                          return SideTitleWidget(
                            axisSide: meta.axisSide,
                            space: 8,
                            child: Text(days[idx], style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                          );
                        }
                        return const SizedBox();
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(7, (index) {
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: activity[index],
                        gradient: const LinearGradient(
                          colors: [AppColors.primary, AppColors.secondary],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                        ),
                        width: 12,
                        borderRadius: const BorderRadius.all(Radius.circular(6)),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAiInsightsCard(BuildContext context, DashboardData stats) {
    return GlassCard(
      borderColor: AppColors.secondary.withValues(alpha: 0.3),
      borderWidth: 1.0,
      gradientColors: const [AppColors.surface, AppColors.background],
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.auto_awesome_rounded, color: AppColors.secondary, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

    
                const Text(
                  'AI Productivity Insight',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 6),
                Text(
                  stats.productivityInsight,
                  style: const TextStyle(color: AppColors.textSecondary, height: 1.4, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showRenameDialog(BuildContext context, MeetingModel meeting) {
    final controller = TextEditingController(text: meeting.title);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text('Rename Meeting'),
          content: TextField(
            controller: controller,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: const InputDecoration(
              labelText: 'Meeting Title',
              labelStyle: TextStyle(color: AppColors.textSecondary),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: AppColors.textSecondary),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: AppColors.primary),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
            ),
            ElevatedButton(
              onPressed: () async {
                final newTitle = controller.text.trim();
                if (newTitle.isNotEmpty) {
                  meeting.title = newTitle;
                  await ref.read(meetingRepositoryProvider).updateMeeting(meeting);
                  if (context.mounted) Navigator.of(context).pop();
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: const Text('Save', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteConfirmationDialog(BuildContext context, MeetingModel meeting) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColors.surfaceLight),
          ),
          title: const Text('Delete Meeting'),
          content: Text('Are you sure you want to delete "${meeting.title ?? 'Untitled Meeting'}"? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                try {
                  await ref.read(meetingRepositoryProvider).deleteMeeting(meeting.id);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Meeting deleted successfully'),
                        backgroundColor: AppColors.error,
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to delete meeting: $e'),
                        backgroundColor: AppColors.error,
                        duration: const Duration(seconds: 3),
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
              child: const Text('Delete', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMeetingsList(BuildContext context, AsyncValue<List<MeetingModel>> meetingsAsync) {
    return meetingsAsync.when(
      data: (meetings) {
        if (meetings.isEmpty) {
          return GlassCard(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Center(
              child: Column(
                children: [
                  const Icon(Icons.record_voice_over_outlined, color: AppColors.textMuted, size: 48),
                  const SizedBox(height: 12),
                  const Text('No meetings recorded yet', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  const Text('Record your first meeting to see summaries.', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                ],
              ),
            ),
          );
        }

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: meetings.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final meeting = meetings[index];
            final dateStr = meeting.createdAt != null
                ? DateFormat('MMM d, y • h:mm a').format(meeting.createdAt!)
                : '';
            final double min = meeting.durationSeconds / 60.0;
            final durationStr = min >= 1.0 ? '${min.toStringAsFixed(0)} min' : '${meeting.durationSeconds.toStringAsFixed(0)} sec';

            return GlassCard(
              padding: EdgeInsets.zero,
              child: ListTile(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => MeetingDetailsScreen(meetingId: meeting.id),
                    ),
                  );
                },
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                title: Text(
                  meeting.title ?? 'Untitled Meeting',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 6.0),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 12, color: AppColors.textMuted),
                      const SizedBox(width: 4),
                      Text(dateStr, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                      const SizedBox(width: 12),
                      const Icon(Icons.timer_outlined, size: 12, color: AppColors.textMuted),
                      const SizedBox(width: 4),
                      Text(durationStr, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                    ],
                  ),
                ),
                trailing: PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: AppColors.textMuted),
                  onSelected: (value) async {
                    if (value == 'open') {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => MeetingDetailsScreen(meetingId: meeting.id),
                        ),
                      );
                    } else if (value == 'rename') {
                      _showRenameDialog(context, meeting);
                    } else if (value == 'delete') {
                      _showDeleteConfirmationDialog(context, meeting);
                    } else if (value == 'share') {
                      // Trigger loading indicator or call directly
                      await ExportHelper.shareMeetingText(meeting);
                    } else if (value == 'export_pdf') {
                      // Trigger loading indicator or call directly
                      await ExportHelper.shareMeetingPdf(meeting);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'open',
                      child: Row(
                        children: [
                          Icon(Icons.folder_open, size: 18),
                          SizedBox(width: 8),
                          Text('Open'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'rename',
                      child: Row(
                        children: [
                          Icon(Icons.edit_outlined, size: 18),
                          SizedBox(width: 8),
                          Text('Rename'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'share',
                      child: Row(
                        children: [
                          Icon(Icons.share_outlined, size: 18),
                          SizedBox(width: 8),
                          Text('Share Text'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'export_pdf',
                      child: Row(
                        children: [
                          Icon(Icons.picture_as_pdf_outlined, size: 18),
                          SizedBox(width: 8),
                          Text('Export PDF'),
                        ],
                      ),
                    ),
                    const PopupMenuDivider(),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline, color: AppColors.error, size: 18),
                          SizedBox(width: 8),
                          Text('Delete', style: TextStyle(color: AppColors.error)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 32.0),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (err, stack) => GlassCard(
        child: Center(
          child: Text('Error loading meetings: $err', style: const TextStyle(color: AppColors.error)),
        ),
      ),
    );
  }

  Widget _buildTestEmotionSection(BuildContext context, EmotionTestState state) {
    String getEmotionEmoji(String emotion) {
      switch (emotion.toLowerCase()) {
        case 'happy': return '😊';
        case 'neutral': return '😐';
        case 'stressed': return '😟';
        case 'frustrated': return '😡';
        default: return '🧠';
      }
    }

    Color getEmotionColor(String emotion) {
      switch (emotion.toLowerCase()) {
        case 'happy': return AppColors.success;
        case 'neutral': return AppColors.primary;
        case 'stressed': return AppColors.warning;
        case 'frustrated': return AppColors.error;
        default: return AppColors.textSecondary;
      }
    }

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.psychology_outlined, color: AppColors.primary, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    'Real-Time Emotion Test',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
              if (state.emotion != null || state.errorMessage != null)
                TextButton(
                  onPressed: () {
                    ref.read(emotionTestProvider.notifier).clearResult();
                  },
                  child: const Text('Clear', style: TextStyle(color: AppColors.textMuted)),
                ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Test the connection and capability of the voice tone emotion analysis service.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 16),
          if (state.emotion != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: getEmotionColor(state.emotion!).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: getEmotionColor(state.emotion!).withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Text(
                    getEmotionEmoji(state.emotion!),
                    style: const TextStyle(fontSize: 32),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Detected: ${state.emotion}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: getEmotionColor(state.emotion!),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Confidence: ${(state.confidence! * 100).toStringAsFixed(1)}%',
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          if (state.errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      state.errorMessage!,
                      style: const TextStyle(color: AppColors.error, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          ElevatedButton(
            onPressed: state.isLoading
                ? null
                : () {
                    ref.read(emotionTestProvider.notifier).runTest();
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.5),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: state.isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text(
                    'Analyze Current Voice Emotion',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpeakerLeaderboard(BuildContext context) {
    final currentUserId = ref.watch(authStateProvider).user?.uid ?? 'offline_fallback';
    final isar = IsarDatabase.instance.isar;
    final speakerProfiles = isar.speakerProfileModels.filter().userIdEqualTo(currentUserId).findAllSync();
    final allAnalytics = isar.speakerAnalyticsModels.filter().userIdEqualTo(currentUserId).findAllSync();
    for (final a in allAnalytics) {
      a.speakerProfile.loadSync();
    }
    
    final Map<int, double> speakingTimes = {};
    for (final a in allAnalytics) {
      final prof = a.speakerProfile.value;
      if (prof != null) {
        speakingTimes[prof.id] = (speakingTimes[prof.id] ?? 0.0) + a.speakingTimeSeconds;
      }
    }
    
    final sortedProfiles = List<SpeakerProfileModel>.from(speakerProfiles)
      ..sort((a, b) {
        final timeA = speakingTimes[a.id] ?? 0.0;
        final timeB = speakingTimes[b.id] ?? 0.0;
        return timeB.compareTo(timeA);
      });
      
    if (sortedProfiles.isEmpty) {
      return GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.leaderboard_rounded, color: AppColors.secondary, size: 20),
                SizedBox(width: 8),
                Text(
                  'Speaker Leaderboard',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Column(
                  children: [
                    Icon(Icons.leaderboard_outlined, color: AppColors.secondary.withValues(alpha: 0.6), size: 36),
                    const SizedBox(height: 8),
                    const Text('No Speaker Data Available', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 4),
                    const Text('Record a meeting to auto-calculate speaker contributions.', style: TextStyle(color: AppColors.textMuted, fontSize: 11), textAlign: TextAlign.center),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }
    
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.leaderboard_rounded, color: AppColors.secondary, size: 20),
              SizedBox(width: 8),
              Text(
                'Speaker Leaderboard',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...sortedProfiles.take(4).map((spk) {
            final timeSec = speakingTimes[spk.id] ?? 0.0;
            final min = (timeSec / 60).toInt();
            final sec = (timeSec % 60).toInt();
            final timeStr = min > 0 ? '${min}m ${sec}s' : '${sec}s';
            final color = Color(spk.colorValue ?? 0xFF9C27B0);
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: color.withValues(alpha: 0.15),
                    child: Text(spk.avatarEmoji ?? '👤', style: const TextStyle(fontSize: 14)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      spk.name ?? 'Speaker',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.textPrimary),
                    ),
                  ),
                  Text(
                    timeStr,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: color),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildMoodDistributionChart(BuildContext context) {
    final currentUserId = ref.watch(authStateProvider).user?.uid ?? 'offline_fallback';
    final isar = IsarDatabase.instance.isar;
    final allEmotions = isar.speakerEmotionModels.filter().userIdEqualTo(currentUserId).findAllSync();
    
    final Map<String, int> moodCounts = {};
    for (final se in allEmotions) {
      if (se.emotion != null) {
        moodCounts[se.emotion!] = (moodCounts[se.emotion!] ?? 0) + 1;
      }
    }
    
    if (moodCounts.isEmpty) {
      return GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.face_rounded, color: AppColors.secondary, size: 20),
                SizedBox(width: 8),
                Text(
                  'Mood Distribution',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Column(
                  children: [
                    Icon(Icons.sentiment_satisfied_alt_rounded, color: AppColors.secondary.withValues(alpha: 0.6), size: 36),
                    const SizedBox(height: 8),
                    const Text('No Mood Data Available', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 4),
                    const Text('Emotion insights populate automatically after audio transcription.', style: TextStyle(color: AppColors.textMuted, fontSize: 11), textAlign: TextAlign.center),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }
    
    final totalCount = moodCounts.values.fold<int>(0, (sum, val) => sum + val);
    final sortedMoods = moodCounts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    
    int colorIdx = 0;
    final List<Color> chartColors = [
      AppColors.secondary,
      AppColors.primary,
      AppColors.success,
      AppColors.warning,
      AppColors.error,
      AppColors.accent,
      Colors.indigo,
      Colors.teal,
    ];
    
    final List<PieChartSectionData> sections = [];
    final List<Widget> legends = [];
    
    for (final entry in sortedMoods.take(5)) {
      final count = entry.value;
      final percent = (count / totalCount) * 100.0;
      final color = chartColors[colorIdx % chartColors.length];
      colorIdx++;
      
      sections.add(
        PieChartSectionData(
          value: count.toDouble(),
          color: color,
          radius: 35,
          showTitle: false,
        ),
      );
      
      legends.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  entry.key,
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ),
              Text(
                '${percent.toStringAsFixed(0)}%',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
            ],
          ),
        ),
      );
    }
    
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.face_rounded, color: AppColors.secondary, size: 20),
              SizedBox(width: 8),
              Text(
                'Mood Distribution',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              SizedBox(
                width: 100,
                height: 100,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 20,
                    sections: sections,
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: legends,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmotionTrends(BuildContext context) {
    final currentUserId = ref.watch(authStateProvider).user?.uid ?? 'offline_fallback';
    final isar = IsarDatabase.instance.isar;
    final lastMeetings = isar.meetingModels
        .filter()
        .userIdEqualTo(currentUserId)
        .sortByCreatedAtDesc()
        .limit(5)
        .findAllSync();

    if (lastMeetings.isEmpty) return const SizedBox();

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.trending_up_rounded, color: AppColors.secondary, size: 20),
              SizedBox(width: 8),
              Text(
                'Emotion Trends (Last 5 Meetings)',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 60,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: lastMeetings.map((m) {
                final emotion = m.detectedEmotion ?? 'Neutral';
                final dateStr = m.createdAt != null ? DateFormat('MM/dd').format(m.createdAt!) : '';
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: getEmotionColor(emotion).withValues(alpha: 0.15),
                      child: Text(getEmotionEmoji(emotion), style: const TextStyle(fontSize: 16)),
                    ),
                    const SizedBox(height: 6),
                    Text(dateStr, style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
                  ],
                );
              }).toList().reversed.toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskOwnershipChart(BuildContext context) {
    final currentUserId = ref.watch(authStateProvider).user?.uid ?? 'offline_fallback';
    final isar = IsarDatabase.instance.isar;
    final allTasks = isar.actionItemModels.filter().userIdEqualTo(currentUserId).findAllSync();
    for (final t in allTasks) {
      t.speakerProfile.loadSync();
    }
    
    final Map<int, int> tasksPerSpeaker = {};
    final Map<int, SpeakerProfileModel> profileMap = {};
    
    for (final t in allTasks) {
      final profile = t.speakerProfile.value;
      if (profile != null) {
        tasksPerSpeaker[profile.id] = (tasksPerSpeaker[profile.id] ?? 0) + 1;
        profileMap[profile.id] = profile;
      }
    }
    
    if (tasksPerSpeaker.isEmpty) {
      return GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.task_alt_rounded, color: AppColors.secondary, size: 20),
                SizedBox(width: 8),
                Text(
                  'Task Ownership Distribution',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Column(
                  children: [
                    Icon(Icons.assignment_ind_outlined, color: AppColors.secondary.withValues(alpha: 0.6), size: 36),
                    const SizedBox(height: 8),
                    const Text('No Task Ownership Data', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 4),
                    const Text('Action items will be mapped to speakers as they are assigned.', style: TextStyle(color: AppColors.textMuted, fontSize: 11), textAlign: TextAlign.center),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }
    
    final sortedSpeakerTasks = tasksPerSpeaker.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.task_alt_rounded, color: AppColors.secondary, size: 20),
              SizedBox(width: 8),
              Text(
                'Task Ownership Distribution',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...sortedSpeakerTasks.take(4).map((entry) {
            final spkId = entry.key;
            final count = entry.value;
            final profile = profileMap[spkId]!;
            final color = Color(profile.colorValue ?? 0xFF9C27B0);
            
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text(profile.avatarEmoji ?? '👤', style: const TextStyle(fontSize: 14)),
                          const SizedBox(width: 6),
                          Text(
                            profile.name ?? 'Speaker',
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textPrimary),
                          ),
                        ],
                      ),
                      Text(
                        '$count tasks',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: color),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: math.min(1.0, count / 8.0),
                      backgroundColor: Colors.white.withValues(alpha: 0.05),
                      color: color,
                      minHeight: 8,
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  String getEmotionEmoji(String emotion) {
    switch (emotion.toLowerCase()) {
      case 'happy': return '😀';
      case 'neutral': return '😐';
      case 'stressed': return '😟';
      case 'frustrated': return '😡';
      case 'excited': return '🔥';
      case 'confident': return '💪';
      case 'calm': return '😌';
      case 'concerned': return '😟';
      case 'bored': return '😴';
      case 'nervous': return '😨';
      case 'thinking': return '🤔';
      default: return '🧠';
    }
  }

  Color getEmotionColor(String emotion) {
    switch (emotion.toLowerCase()) {
      case 'happy': case 'excited': return AppColors.secondary;
      case 'neutral': return AppColors.primary;
      case 'stressed': case 'concerned': case 'nervous': return AppColors.warning;
      case 'frustrated': return AppColors.error;
      case 'calm': return AppColors.success;
      case 'confident': return AppColors.primary;
      case 'thinking': return AppColors.accent;
      default: return AppColors.textSecondary;
    }
  }
}
