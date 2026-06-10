import '../settings/settings_provider.dart';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../database/schemas/meeting_models.dart';
import '../../database/isar_database.dart';
import 'package:isar/isar.dart';
import '../../providers/app_providers.dart';
import '../../services/notification_service.dart';
import '../../core/config/deepgram_debug.dart';
import '../../services/speaker_service.dart';
import '../../services/ollama_connection_manager.dart';

enum RecordingStatus { idle, recording, paused, finalizing, completed, error }

class RecordingState {
  final RecordingStatus status;
  final MeetingModel? activeMeeting;
  final List<TranscriptSegmentModel> liveSegments;
  final int secondsElapsed;
  final String? errorMessage;

  RecordingState({
    required this.status,
    this.activeMeeting,
    this.liveSegments = const [],
    this.secondsElapsed = 0,
    this.errorMessage,
  });

  RecordingState copyWith({
    RecordingStatus? status,
    MeetingModel? activeMeeting,
    List<TranscriptSegmentModel>? liveSegments,
    int? secondsElapsed,
    String? errorMessage,
  }) {
    return RecordingState(
      status: status ?? this.status,
      activeMeeting: activeMeeting ?? this.activeMeeting,
      liveSegments: liveSegments ?? this.liveSegments,
      secondsElapsed: secondsElapsed ?? this.secondsElapsed,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class RecordingNotifier extends StateNotifier<RecordingState> {
  final Ref _ref;
  StreamSubscription<List<int>>? _audioSubscription;
  StreamSubscription<TranscriptSegmentModel>? _transcriptSubscription;
  Timer? _timer;

  bool _isGeneratingLiveSummary = false;
  bool _needsNewLiveSummary = false;

  RecordingNotifier(this._ref) : super(RecordingState(status: RecordingStatus.idle));

  Future<void> startMeeting(String title) async {
    if (state.status != RecordingStatus.idle) return;
    
    state = RecordingState(status: RecordingStatus.finalizing);

    try {
      await _ref.read(settingsProvider.notifier).ensureLoaded();
      final settings = _ref.read(settingsProvider);
      final key = settings.deepgramKey;
      logDeepgramKeyDebug(key, source: 'recording_provider.startMeeting');
      if (key.isEmpty) {
        state = RecordingState(status: RecordingStatus.error, errorMessage: 'Deepgram API Key is missing. Configure it in settings.');
        return;
      }

      final meetingRepo = _ref.read(meetingRepositoryProvider);
      final meeting = await meetingRepo.createMeeting(title);

      final audioService = _ref.read(audioRecordingServiceProvider);
      await audioService.startRecording();

      final deepgramService = _ref.read(deepgramServiceProvider);
      await deepgramService.connect(key);

      state = RecordingState(
        status: RecordingStatus.recording,
        activeMeeting: meeting,
        liveSegments: [],
        secondsElapsed: 0,
      );

      _audioSubscription = audioService.audioStream.listen((chunk) {
        deepgramService.sendAudioChunk(chunk);
      });

      _transcriptSubscription = deepgramService.segmentStream.listen((segment) async {
        if (state.status == RecordingStatus.recording) {
          await meetingRepo.addTranscriptSegment(meeting.id, segment);
          
          state = state.copyWith(
            liveSegments: [...state.liveSegments, segment],
          );

          _triggerLiveSummaryGeneration(meeting.id);
        }
      });

      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        state = state.copyWith(secondsElapsed: audioService.secondsElapsed);
      });

    } catch (e) {
      await stopMeeting(cancel: true);
      state = RecordingState(status: RecordingStatus.error, errorMessage: e.toString());
    }
  }

  Future<void> pauseMeeting() async {
    if (state.status != RecordingStatus.recording) return;
    await _ref.read(audioRecordingServiceProvider).pauseRecording();
    _timer?.cancel();
    state = state.copyWith(status: RecordingStatus.paused);
  }

  Future<void> resumeMeeting() async {
    if (state.status != RecordingStatus.paused) return;
    await _ref.read(audioRecordingServiceProvider).resumeRecording();
    
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      state = state.copyWith(secondsElapsed: _ref.read(audioRecordingServiceProvider).secondsElapsed);
    });
    
    state = state.copyWith(status: RecordingStatus.recording);
  }

  Future<void> stopMeeting({bool cancel = false}) async {
    if (state.status != RecordingStatus.recording && state.status != RecordingStatus.paused) return;

    final meeting = state.activeMeeting;
    
    _timer?.cancel();
    _timer = null;
    await _audioSubscription?.cancel();
    _audioSubscription = null;
    await _transcriptSubscription?.cancel();
    _transcriptSubscription = null;

    final finalAudioPath = await _ref.read(audioRecordingServiceProvider).stopRecording();
    await _ref.read(deepgramServiceProvider).disconnect();

    if (cancel || meeting == null) {
      if (meeting != null) {
        await _ref.read(meetingRepositoryProvider).deleteMeeting(meeting.id);
      }
      state = RecordingState(status: RecordingStatus.idle);
      return;
    }

    state = state.copyWith(status: RecordingStatus.finalizing);

    try {
      final meetingRepo = _ref.read(meetingRepositoryProvider);
      
      meeting.audioFilePath = finalAudioPath;
      meeting.durationSeconds = state.secondsElapsed.toDouble();
      meeting.isRecording = false;

      await meetingRepo.updateMeeting(meeting);

      // Run Speaker Intelligence first to extract identities and emotions
      if (finalAudioPath != null) {
        await _runSpeakerIntelligenceFlow(meeting.id, finalAudioPath);
      }

      final updatedMeeting = await meetingRepo.getMeetingById(meeting.id);
      final transcriptObj = updatedMeeting?.transcript.value;
      final segments = transcriptObj != null ? transcriptObj.segments.toList() : <TranscriptSegmentModel>[];
      
      final fullTranscriptText = segments.map((e) {
        final speakerName = e.speakerProfile.value?.name ?? 'Speaker ${e.speaker}';
        return '$speakerName: ${e.text}';
      }).join('\n');

      if (fullTranscriptText.trim().isNotEmpty) {
        final openAiService = _ref.read(openAIServiceProvider);

        final analysis = await openAiService.generateMeetingAnalysis(
          fullTranscript: fullTranscriptText,
        );

        await meetingRepo.saveSummaryAndActionItems(
          meeting.id,
          analysis['summary'] as SummaryModel,
          analysis['actionItems'] as List<ActionItemModel>,
          analysis['decisions'] as List<DecisionModel>,
        );

        await NotificationService().showNotification(
          id: meeting.id,
          title: 'Meeting Summary Ready',
          body: '"${meeting.title}" analysis completed. Tasks and summary generated!',
        );
      }

      state = state.copyWith(status: RecordingStatus.completed);
    } catch (e) {
      state = state.copyWith(
        status: RecordingStatus.completed,
        errorMessage: 'Meeting saved. Summary generation failed: $e',
      );
    }
  }

  void _triggerLiveSummaryGeneration(int meetingId) async {
    if (_isGeneratingLiveSummary) {
      _needsNewLiveSummary = true;
      return;
    }
    _isGeneratingLiveSummary = true;
    _needsNewLiveSummary = false;

    // Debounce to collect multiple rapid segments
    await Future.delayed(const Duration(seconds: 10));

    while (true) {
      try {
        final meetingRepo = _ref.read(meetingRepositoryProvider);
        final meeting = await meetingRepo.getMeetingById(meetingId);
        if (meeting == null) break;

        final transcript = meeting.transcript.value;
        if (transcript == null) break;

        final fullTranscriptText = transcript.segments.toList()
            .map((e) => 'Speaker ${e.speaker}: ${e.text}')
            .join('\n');

        if (fullTranscriptText.trim().isEmpty) break;

        final openAiService = _ref.read(openAIServiceProvider);
        final analysis = await openAiService.generateMeetingAnalysis(
          fullTranscript: fullTranscriptText,
        );

        await meetingRepo.saveSummaryAndActionItems(
          meeting.id,
          analysis['summary'] as SummaryModel,
          analysis['actionItems'] as List<ActionItemModel>,
          analysis['decisions'] as List<DecisionModel>,
        );
      } catch (e) {
        print("Live summary generation failed: $e");
      }

      if (!_needsNewLiveSummary) {
        break;
      }
      _needsNewLiveSummary = false;
      // Wait 15 seconds before processing subsequent runs to avoid hammering Ollama
      await Future.delayed(const Duration(seconds: 15));
    }
    _isGeneratingLiveSummary = false;
  }

  Future<void> regenerateSummary(int meetingId) async {
    print("[AI Summary flow] regenerateSummary started for meeting ID: $meetingId");
    try {
      final meetingRepo = _ref.read(meetingRepositoryProvider);
      final meeting = await meetingRepo.getMeetingById(meetingId);
      if (meeting == null) {
        print("[AI Summary flow ERROR] Meeting not found in database for ID: $meetingId");
        throw Exception('Meeting not found in database.');
      }

      // 0. Re-run speaker intelligence if audio file exists
      if (meeting.audioFilePath != null && meeting.audioFilePath!.isNotEmpty) {
        await _runSpeakerIntelligenceFlow(meeting.id, meeting.audioFilePath!);
      }

      // 1. Get transcript text with speaker names
      final transcript = meeting.transcript.value;
      final segments = transcript != null ? transcript.segments.toList() : <TranscriptSegmentModel>[];
      final fullTranscriptText = segments.map((e) {
        final speakerName = e.speakerProfile.value?.name ?? 'Speaker ${e.speaker}';
        return '$speakerName: ${e.text}';
      }).join('\n');
      print("[AI Summary flow] Transcript text length: ${fullTranscriptText.length}");

      // 2. Verify transcript is not empty
      if (fullTranscriptText.trim().isEmpty) {
        print("[AI Summary flow ERROR] Transcript is empty. Cannot generate summary.");
        throw Exception('Transcript is empty. Speak or import audio to generate a transcript first.');
      }

      // 3. Verify Ollama connectivity
      print("[AI Summary flow] Checking Ollama health connectivity...");
      final connState = await _ref.read(ollamaConnectionManagerProvider.notifier).verifyHealth();
      print("[AI Summary flow] Ollama connection state: ${connState.status}");
      if (connState.status == OllamaConnectionStatus.offline) {
        throw Exception('Ollama Offline (connection refused)\nDetails: ${connState.errorMessage ?? 'Connection refused.'}');
      } else if (connState.status == OllamaConnectionStatus.waitingForOllama) {
        throw Exception('Ollama Waiting (model missing)\nDetails: ${connState.errorMessage ?? 'Model missing.'}');
      }

      // 5. Generate analysis via OpenAIService
      print("[AI Summary flow] Generating analysis (summary, tasks, decisions) from Ollama...");
      final openAiService = _ref.read(openAIServiceProvider);
      final analysis = await openAiService.generateMeetingAnalysis(
        fullTranscript: fullTranscriptText,
      );
      print("[AI Summary flow] Analysis generation completed successfully.");

      // 6. Save summary, action items and decisions
      print("[AI Summary flow] Saving analysis results to database...");
      try {
        await meetingRepo.saveSummaryAndActionItems(
          meeting.id,
          analysis['summary'] as SummaryModel,
          analysis['actionItems'] as List<ActionItemModel>,
          analysis['decisions'] as List<DecisionModel>,
        );
        print("[AI Summary flow] Database save completed successfully.");
      } catch (dbError, stack) {
        print("[AI Summary flow ERROR] Database save failed: $dbError");
        print(stack);
        throw Exception('Failed to save summary to database: $dbError');
      }
    } catch (e, stack) {
      print("[AI Summary flow ERROR] regenerateSummary failed: $e");
      print(stack);
      rethrow;
    }
  }

  /// Runs the Advanced Speaker Intelligence pipeline.
  Future<void> _runSpeakerIntelligenceFlow(int meetingId, String audioFilePath) async {
    print("[Speaker Intelligence Flow] Running for meeting: $meetingId, audio: $audioFilePath");
    final isar = IsarDatabase.instance.isar;
    final meetingRepo = _ref.read(meetingRepositoryProvider);
    final speakerService = _ref.read(speakerServiceProvider);
    
    final meeting = await meetingRepo.getMeetingById(meetingId);
    if (meeting == null) return;
    
    final transcript = meeting.transcript.value;
    if (transcript == null) return;
    
    final segments = transcript.segments.toList();
    if (segments.isEmpty) return;
    
    try {
      // Clean previous speaker details to prevent clutter
      await isar.writeTxn(() async {
        await isar.speakerEmotionModels.filter().meeting((m) => m.idEqualTo(meetingId)).deleteAll();
        await isar.speakerAnalyticsModels.filter().meeting((m) => m.idEqualTo(meetingId)).deleteAll();
      });

      // 1. Call DSP backend for feature extraction and speaker fingerprinting
      final dspResult = await _ref.read(emotionServiceProvider).analyzeAudio(
        audioFilePath: audioFilePath,
        segments: segments,
      );
      
      final dspSpeakers = dspResult['speakers'] as List? ?? [];
      final dspTimeline = dspResult['meetingTimeline'] as List? ?? [];
      
      // Keep track of mapped speaker profiles
      final Map<int, SpeakerProfileModel> indexToProfile = {};
      
      // 2. Map and fingerprint speakers
      for (final spkObj in dspSpeakers) {
        if (spkObj is Map) {
          final speakerIndex = spkObj['speakerIndex'] as int;
          final embedding = (spkObj['voiceEmbedding'] as List?)?.map((e) => (e as num).toDouble()).toList() ?? [];
          final primaryMood = spkObj['primaryMood']?.toString() ?? 'Neutral';
          final moodConfidence = (spkObj['moodConfidence'] as num?)?.toDouble() ?? 0.85;
          final analytics = spkObj['analytics'] as Map?;
          
          SpeakerProfileModel profile;
          if (embedding.isNotEmpty) {
            profile = await speakerService.getOrCreateSpeakerProfileForVoice(
              voiceEmbedding: embedding,
              defaultName: 'Speaker $speakerIndex',
            );
          } else {
            profile = await speakerService.getOrCreateSpeakerProfileByName('Speaker $speakerIndex');
          }
          
          indexToProfile[speakerIndex] = profile;
          
          // Save SpeakerAnalytics
          if (analytics != null) {
            final spkAnalytics = SpeakerAnalyticsModel()
              ..speakingTimeSeconds = (analytics['speakingTimeSeconds'] as num?)?.toDouble() ?? 0.0
              ..wordCount = (analytics['wordCount'] as num?)?.toInt() ?? 0
              ..participationPercentage = (analytics['participationPercentage'] as num?)?.toDouble() ?? 0.0
              ..interactionScore = (analytics['interactionScore'] as num?)?.toDouble() ?? 0.0;
            
            await isar.writeTxn(() async {
              spkAnalytics.speakerProfile.value = profile;
              spkAnalytics.meeting.value = meeting;
              await isar.speakerAnalyticsModels.put(spkAnalytics);
              await spkAnalytics.speakerProfile.save();
              await spkAnalytics.meeting.save();
            });
          }
          
          // Save SpeakerEmotion summary details in Isar
          final spkEmotion = SpeakerEmotionModel()
            ..emotion = primaryMood
            ..confidence = moodConfidence
            ..startTime = 0.0
            ..endTime = meeting.durationSeconds;
            
          await isar.writeTxn(() async {
            spkEmotion.speakerProfile.value = profile;
            spkEmotion.meeting.value = meeting;
            await isar.speakerEmotionModels.put(spkEmotion);
            await spkEmotion.speakerProfile.save();
            await spkEmotion.meeting.save();
          });
        }
      }
      
      // 3. Fallback map for any segments whose speaker was not in DSP speakers list
      for (final segment in segments) {
        final spkIdx = segment.speaker ?? 0;
        if (!indexToProfile.containsKey(spkIdx)) {
          final profile = await speakerService.getOrCreateSpeakerProfileByName('Speaker $spkIdx');
          indexToProfile[spkIdx] = profile;
        }
      }
      
      // 4. Update segment relations in Isar to link the speaker profile
      await isar.writeTxn(() async {
        for (final segment in segments) {
          final profile = indexToProfile[segment.speaker ?? 0];
          if (profile != null) {
            segment.speakerProfile.value = profile;
            await isar.transcriptSegmentModels.put(segment);
            await segment.speakerProfile.save();
          }
        }
      });
      
      // 5. Link SpeakerProfile in action items/tasks if assignee matches speaker profile name
      final actionItems = meeting.actionItems.toList();
      if (actionItems.isNotEmpty) {
        await isar.writeTxn(() async {
          for (final item in actionItems) {
            final assignee = item.assignedTo?.trim().toLowerCase() ?? '';
            if (assignee.isNotEmpty) {
              // Try to find matching profile
              for (final profile in indexToProfile.values) {
                final profName = profile.name?.trim().toLowerCase() ?? '';
                if (profName == assignee || assignee.contains(profName) || profName.contains(assignee)) {
                  item.speakerProfile.value = profile;
                  await isar.actionItemModels.put(item);
                  await item.speakerProfile.save();
                  break;
                }
              }
            }
          }
        });
      }

      // 6. Set overall meeting emotion from timeline
      if (dspTimeline.isNotEmpty) {
        // Find most frequent overall emotion
        final emotionsList = dspTimeline.map((e) => e['emotion']?.toString() ?? 'Neutral').toList();
        final mostFreq = emotionsList.fold<Map<String, int>>({}, (map, element) {
          map[element] = (map[element] ?? 0) + 1;
          return map;
        });
        final sorted = mostFreq.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
        meeting.detectedEmotion = sorted.first.key;
        meeting.emotionConfidence = 0.85;
      } else {
        meeting.detectedEmotion = 'Neutral';
        meeting.emotionConfidence = 0.90;
      }
      await meetingRepo.updateMeeting(meeting);
      
    } catch (e) {
      print("[Speaker Intelligence Flow ERROR] Failed: $e");
      // Fallback: Create profiles by index names only
      for (final segment in segments) {
        final spkIdx = segment.speaker ?? 0;
        final profile = await speakerService.getOrCreateSpeakerProfileByName('Speaker $spkIdx');
        await isar.writeTxn(() async {
          segment.speakerProfile.value = profile;
          await isar.transcriptSegmentModels.put(segment);
          await segment.speakerProfile.save();
        });
      }
      meeting.detectedEmotion = 'Feature unavailable';
      meeting.emotionConfidence = 0.0;
      await meetingRepo.updateMeeting(meeting);
    }
  }
}

final recordingProvider = StateNotifierProvider<RecordingNotifier, RecordingState>((ref) {
  return RecordingNotifier(ref);
});