import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/gradient_button.dart';
import 'recording_provider.dart';

class RecordingDialog extends ConsumerStatefulWidget {
  const RecordingDialog({super.key});

  @override
  ConsumerState<RecordingDialog> createState() => _RecordingDialogState();
}

class _RecordingDialogState extends ConsumerState<RecordingDialog> {
  final _titleController = TextEditingController();
  final _scrollController = ScrollController();
  bool _setupPhase = true;

  @override
  void initState() {
    super.initState();
    // Default meeting name prefilled with current date
    _titleController.text = 'Meeting - ${DateFormat('MMM dd, yyyy').format(DateTime.now())}';
    
    // If a recording session is already active (not idle), skip setup phase
    final recState = ref.read(recordingProvider);
    if (recState.status != RecordingStatus.idle) {
      _setupPhase = false;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final recordingState = ref.watch(recordingProvider);

    // Auto-scroll transcript to bottom as new segments arrive
    ref.listen(recordingProvider, (previous, next) {
      if (previous?.liveSegments.length != next.liveSegments.length) {
        _scrollToBottom();
      }
    });

    final elapsedMin = (recordingState.secondsElapsed ~/ 60).toString().padLeft(2, '0');
    final elapsedSec = (recordingState.secondsElapsed % 60).toString().padLeft(2, '0');

    final double screenHeight = MediaQuery.of(context).size.height;
    final double viewInsetsBottom = MediaQuery.of(context).viewInsets.bottom;
    final double dialogHeight = (screenHeight - viewInsetsBottom) * 0.75;
    final bool showActivePanel = !_setupPhase && 
                                 recordingState.status != RecordingStatus.idle && 
                                 recordingState.status != RecordingStatus.error;

    return Container(
      height: showActivePanel ? dialogHeight : null,
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: viewInsetsBottom + 24,
      ),
      child: Column(
        mainAxisSize: showActivePanel ? MainAxisSize.max : MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle indicator
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          if (_setupPhase && recordingState.status == RecordingStatus.idle) ...[
            // SETUP PHASE SCREEN
            Text(
              'New Meeting Session',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Give your meeting a name to start continuous recording.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                hintText: 'Meeting Title',
                prefixIcon: Icon(Icons.title, color: AppColors.textMuted),
              ),
            ),
            const SizedBox(height: 24),
            GradientButton(
              onPressed: () {
                final state = ref.read(recordingProvider);
                if (state.status != RecordingStatus.idle) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('🎤 Recording already in progress'),
                      backgroundColor: AppColors.warning,
                      duration: Duration(seconds: 2),
                    ),
                  );
                  return;
                }
                setState(() => _setupPhase = false);
                ref.read(recordingProvider.notifier).startMeeting(_titleController.text.trim());
              },
              child: const Text('Start Recording'),
            ),
          ] else if (recordingState.status == RecordingStatus.finalizing) ...[
            // LOADING OR COMPILING SUMMARY STATE
            const SizedBox(height: 40),
            const Center(
              child: CircularProgressIndicator(),
            ),
            const SizedBox(height: 20),
            Text(
              recordingState.activeMeeting == null
                  ? 'Initializing Microphone & Deepgram Socket...'
                  : 'Compiling structured summary & decisions...',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 40),
          ] else if (recordingState.status == RecordingStatus.error) ...[
            // ERROR STATE
            const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 64),
            const SizedBox(height: 16),
            Text(
              'Recording Error',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.error),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              recordingState.errorMessage ?? 'An unknown error occurred.',
              style: const TextStyle(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                setState(() => _setupPhase = true);
                ref.read(recordingProvider.notifier).stopMeeting(cancel: true);
              },
              child: const Text('Go Back'),
            ),
          ] else ...[
            // ACTIVE RECORDING PANEL SCREEN
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        recordingState.activeMeeting?.title ?? 'Active Session',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: recordingState.status == RecordingStatus.recording
                                  ? AppColors.error
                                  : AppColors.warning,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            recordingState.status == RecordingStatus.recording
                                ? 'Recording live transcription...'
                                : 'Recording paused',
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Text(
                  '$elapsedMin:$elapsedSec',
                  style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Live scrolling transcripts container
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.surfaceLight),
                ),
                child: recordingState.liveSegments.isEmpty
                    ? const Center(
                        child: Text(
                          'Speak now... Real-time transcripts will appear here.',
                          style: TextStyle(color: AppColors.textMuted),
                          textAlign: TextAlign.center,
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        itemCount: recordingState.liveSegments.length,
                        itemBuilder: (context, idx) {
                          final seg = recordingState.liveSegments[idx];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: (seg.speaker ?? 0) % 2 == 0
                                        ? AppColors.primary.withValues(alpha: 0.2)
                                        : AppColors.secondary.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'S${seg.speaker}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                      color: (seg.speaker ?? 0) % 2 == 0
                                          ? AppColors.primary
                                          : AppColors.secondary,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    seg.text ?? '',
                                    style: const TextStyle(fontSize: 14, height: 1.4),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ),
            const SizedBox(height: 24),

            // Animated Visualizer wave (Simulated using dynamic bars)
            _buildVisualizer(recordingState.status == RecordingStatus.recording),
            const SizedBox(height: 24),

            // Control Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Cancel
                IconButton.filledTonal(
                  style: IconButton.styleFrom(backgroundColor: AppColors.surfaceLight),
                  onPressed: () {
                    ref.read(recordingProvider.notifier).stopMeeting(cancel: true);
                    Navigator.of(context).pop();
                  },
                  icon: const Icon(Icons.close, color: AppColors.textPrimary),
                  iconSize: 28,
                ),

                // Play / Pause
                IconButton.filled(
                  style: IconButton.styleFrom(
                    backgroundColor: recordingState.status == RecordingStatus.recording
                        ? AppColors.warning
                        : AppColors.success,
                  ),
                  onPressed: () {
                    if (recordingState.status == RecordingStatus.recording) {
                      ref.read(recordingProvider.notifier).pauseMeeting();
                    } else {
                      ref.read(recordingProvider.notifier).resumeMeeting();
                    }
                  },
                  icon: Icon(
                    recordingState.status == RecordingStatus.recording
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                    color: Colors.white,
                  ),
                  iconSize: 36,
                ),

                // Finish
                IconButton.filled(
                  style: IconButton.styleFrom(backgroundColor: AppColors.success),
                  onPressed: () async {
                    await ref.read(recordingProvider.notifier).stopMeeting();
                    if (context.mounted) Navigator.of(context).pop();
                  },
                  icon: const Icon(Icons.check, color: Colors.white),
                  iconSize: 28,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildVisualizer(bool isActive) {
    return SizedBox(
      height: 30,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(15, (index) {
          // Create a wave shape of heights
          final factor = (8 - (index - 7).abs()) / 8.0;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: 4,
            height: isActive ? (15.0 + factor * 15.0) : 4.0,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(2),
            ),
          );
        }),
      ),
    );
  }
}
