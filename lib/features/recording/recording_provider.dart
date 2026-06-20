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
import '../../services/emotion_health_service.dart';
import '../wearable/wearable_provider.dart';
import '../wearable/wearable_service.dart';
import '../wearable/wearable_models.dart';

enum RecordingStatus { idle, connecting, recording, paused, stopped, processing, completed, error }

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
  Timer? _keepAliveTimer;

  bool _isGeneratingLiveSummary = false;
  bool _needsNewLiveSummary = false;

  List<int> _meetingHeartRates = [];
  List<double> _meetingStressScores = [];
  StreamSubscription<LiveSensorData>? _meetingSensorSubscription;

  RecordingNotifier(this._ref) : super(RecordingState(status: RecordingStatus.idle));

  void reset() {
    _timer?.cancel();
    _timer = null;
    _keepAliveTimer?.cancel();
    _keepAliveTimer = null;
    state = RecordingState(status: RecordingStatus.idle);
  }

  Future<void> startMeeting(String title) async {
    if (state.status == RecordingStatus.recording ||
        state.status == RecordingStatus.paused ||
        state.status == RecordingStatus.connecting ||
        state.status == RecordingStatus.processing) {
      return;
    }
    
    state = RecordingState(status: RecordingStatus.connecting);

    try {
      await _ref.read(settingsProvider.notifier).ensureLoaded();
      final settings = _ref.read(settingsProvider);
      final key = settings.deepgramKey;
      logDeepgramKeyDebug(key, source: 'recording_provider.startMeeting');
      if (key.isEmpty) {
        state = RecordingState(status: RecordingStatus.error, errorMessage: 'Deepgram API Key is missing. Configure it in settings.');
        return;
      }

      final deepgramService = _ref.read(deepgramServiceProvider);
      // Connect to Deepgram first and verify handshake (ready) success
      await deepgramService.connect(key);

      final audioService = _ref.read(audioRecordingServiceProvider);
      await audioService.startRecording();

      final meetingRepo = _ref.read(meetingRepositoryProvider);
      final meeting = await meetingRepo.createMeeting(title);

      state = RecordingState(
        status: RecordingStatus.recording,
        activeMeeting: meeting,
        liveSegments: [],
        secondsElapsed: 0,
      );

      // Wearable Biometric Streaming Sync
      _meetingHeartRates.clear();
      _meetingStressScores.clear();
      _meetingSensorSubscription?.cancel();
      final wearableState = _ref.read(wearableProvider);
      if (wearableState.connectionState == DeviceConnectionState.connected) {
        _meetingSensorSubscription = WearableService().liveSensorDataStream.listen((data) {
          _meetingHeartRates.add(data.heartRate);
          _meetingStressScores.add(data.stress);
        });
      }

      _audioSubscription = audioService.audioStream.listen(
        (chunk) {
          deepgramService.sendAudioChunk(chunk);
        },
        onError: (err) {
          print("[RecordingNotifier] Microphone stream error: $err");
          state = RecordingState(status: RecordingStatus.error, errorMessage: 'Microphone stream error: $err');
          stopMeeting(cancel: true);
        },
      );

      _transcriptSubscription = deepgramService.segmentStream.listen(
        (segment) async {
          if (state.status == RecordingStatus.recording) {
            await meetingRepo.addTranscriptSegment(meeting.id, segment);
            
            state = state.copyWith(
              liveSegments: [...state.liveSegments, segment],
            );

            _triggerLiveSummaryGeneration(meeting.id);
          }
        },
        onError: (err) {
          print("[RecordingNotifier] Deepgram stream error: $err");
          state = RecordingState(status: RecordingStatus.error, errorMessage: 'Deepgram connection error: $err');
          stopMeeting(cancel: true);
        },
        onDone: () {
          print("[RecordingNotifier] Deepgram stream done");
          if (state.status == RecordingStatus.recording) {
            state = RecordingState(status: RecordingStatus.error, errorMessage: 'Deepgram connection closed unexpectedly.');
            stopMeeting(cancel: true);
          }
        },
      );

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
    _timer = null;

    // Send keep-alive every 5 seconds to prevent Deepgram WebSocket from timing out during pause
    _keepAliveTimer?.cancel();
    _keepAliveTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _ref.read(deepgramServiceProvider).sendKeepAlive();
    });

    state = state.copyWith(status: RecordingStatus.paused);
  }

  Future<void> resumeMeeting() async {
    if (state.status != RecordingStatus.paused) return;
    _keepAliveTimer?.cancel();
    _keepAliveTimer = null;

    await _ref.read(audioRecordingServiceProvider).resumeRecording();
    
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      state = state.copyWith(secondsElapsed: _ref.read(audioRecordingServiceProvider).secondsElapsed);
    });
    
    state = state.copyWith(status: RecordingStatus.recording);
  }

  Future<void> stopMeeting({bool cancel = false}) async {
    if (state.status == RecordingStatus.idle) return;

    final meeting = state.activeMeeting;
    
    _timer?.cancel();
    _timer = null;
    _keepAliveTimer?.cancel();
    _keepAliveTimer = null;
    await _audioSubscription?.cancel();
    _audioSubscription = null;
    await _transcriptSubscription?.cancel();
    _transcriptSubscription = null;
    _meetingSensorSubscription?.cancel();
    _meetingSensorSubscription = null;

    final finalAudioPath = await _ref.read(audioRecordingServiceProvider).stopRecording();
    await _ref.read(deepgramServiceProvider).disconnect();

    final hasError = state.status == RecordingStatus.error;
    final savedError = hasError ? state.errorMessage : null;

    if (cancel || meeting == null) {
      if (meeting != null) {
        await _ref.read(meetingRepositoryProvider).deleteMeeting(meeting.id);
      }
      state = RecordingState(
        status: hasError ? RecordingStatus.error : RecordingStatus.idle,
        errorMessage: savedError,
      );
      return;
    }

    state = state.copyWith(status: RecordingStatus.processing);

    try {
      final meetingRepo = _ref.read(meetingRepositoryProvider);
      
      // Calculate Biometrics Averages if data exists
      double? hrAvg;
      double? hrPeak;
      double? stressAvg;
      double? sleepScoreVal;
      double? engagementVal;
      double? energyVal;
      
      if (_meetingHeartRates.isNotEmpty) {
        hrAvg = _meetingHeartRates.reduce((a, b) => a + b) / _meetingHeartRates.length;
        hrPeak = _meetingHeartRates.map((e) => e.toDouble()).reduce((a, b) => a > b ? a : b);
      }
      if (_meetingStressScores.isNotEmpty) {
        stressAvg = _meetingStressScores.reduce((a, b) => a + b) / _meetingStressScores.length;
      }

      if (hrAvg != null && stressAvg != null) {
        sleepScoreVal = 82.0; // Benchmark sleep baseline
        engagementVal = (100.0 - (stressAvg * 0.5) - (hrAvg - 70).abs().clamp(0.0, 30.0));
        energyVal = (state.secondsElapsed / 60.0) * (hrAvg / 70.0) * 1.5;
      }

      meeting.audioFilePath = finalAudioPath;
      meeting.durationSeconds = state.secondsElapsed.toDouble();
      meeting.isRecording = false;
      meeting.heartRateAverage = hrAvg;
      meeting.heartRatePeak = hrPeak;
      meeting.stressAverage = stressAvg;
      meeting.sleepScore = sleepScoreVal;
      meeting.engagementScore = engagementVal;
      meeting.energyDrain = energyVal;

      await meetingRepo.updateMeeting(meeting);

      // Run Speaker Intelligence first to extract identities and emotions
      await _runSpeakerIntelligenceFlow(meeting.id, finalAudioPath);

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

        // Generate Biometric Analyses if wearable telemetry is active
        if (hrAvg != null && stressAvg != null && hrPeak != null) {
          final bioAnalysis = await openAiService.generateBiometricAnalysis(
            heartRateAverage: hrAvg,
            heartRatePeak: hrPeak,
            stressAverage: stressAvg,
            transcript: fullTranscriptText,
          );
          
          meeting.stressAnalysis = bioAnalysis['stressAnalysis'];
          meeting.engagementAnalysis = bioAnalysis['engagementAnalysis'];
          meeting.focusAnalysis = bioAnalysis['focusAnalysis'];
          meeting.energyAnalysis = bioAnalysis['energyAnalysis'];
          meeting.wellnessInsightText = 'Stress: ${meeting.stressAnalysis}\nEngagement: ${meeting.engagementAnalysis}';
          
          await meetingRepo.updateMeeting(meeting);
        }

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

      // 0. Re-run speaker intelligence / emotion analysis
      await _runSpeakerIntelligenceFlow(meeting.id, meeting.audioFilePath);

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
  Future<void> _runSpeakerIntelligenceFlow(int meetingId, String? audioFilePath) async {
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

    bool isLocalEstimation = false;
    Map<String, dynamic> dspResult;

    try {
      _ref.read(emotionHealthServiceProvider.notifier).setStatus(EmotionBackendStatus.processing);

      await isar.writeTxn(() async {
        await isar.speakerEmotionModels.filter().meeting((m) => m.idEqualTo(meetingId)).deleteAll();
        await isar.speakerAnalyticsModels.filter().meeting((m) => m.idEqualTo(meetingId)).deleteAll();
      });

      try {
        if (audioFilePath == null || audioFilePath.isEmpty) {
          throw Exception("Audio file is missing. Bypassing backend DSP processing.");
        }
        dspResult = await _ref.read(emotionServiceProvider).analyzeAudio(
          audioFilePath: audioFilePath,
          segments: segments,
        );
        _ref.read(emotionHealthServiceProvider.notifier).setStatus(EmotionBackendStatus.connected);
      } catch (e) {
        print("[Speaker Intelligence Flow ERROR] Flask backend failed: $e. Running local fallback.");
        isLocalEstimation = true;
        _ref.read(emotionHealthServiceProvider.notifier).setStatus(EmotionBackendStatus.fallbackActive);

        final speakerIndexes = segments.map((s) => s.speaker ?? 0).toSet().toList();
        final fullTranscriptText = segments.map((e) {
          final speakerName = e.speakerProfile.value?.name ?? 'Speaker ${e.speaker}';
          return '$speakerName: ${e.text}';
        }).join('\n');

        final estimation = await _ref.read(openAIServiceProvider).estimateEmotions(
          fullTranscript: fullTranscriptText,
          speakerIndexes: speakerIndexes,
        );

        final Map<String, dynamic> mockedResult = {
          'speakers': [],
          'meetingTimeline': [
            {
              'startTime': 0.0,
              'endTime': meeting.durationSeconds,
              'emotion': estimation['overallEmotion'] ?? 'Neutral',
            }
          ],
        };

        final List<dynamic> estimatedSpeakers = estimation['speakers'] as List? ?? [];
        for (final spk in estimatedSpeakers) {
          if (spk is Map) {
            final speakerIndex = spk['speakerIndex'] as int;
            final emotion = spk['emotion']?.toString() ?? 'Neutral';
            final confidence = (spk['confidence'] as num?)?.toDouble() ?? 0.85;

            double speakingTime = 0.0;
            int wordCount = 0;
            int turns = 0;
            for (final seg in segments) {
              if (seg.speaker == speakerIndex) {
                speakingTime += ((seg.endTime - seg.startTime).clamp(0.0, double.infinity)).toDouble();
                wordCount += (seg.text ?? '').split(' ').length.toInt();
                turns += 1;
              }
            }

            mockedResult['speakers'].add({
              'speakerIndex': speakerIndex,
              'voiceEmbedding': <double>[],
              'primaryMood': emotion,
              'moodConfidence': confidence,
              'analytics': {
                'speakingTimeSeconds': speakingTime,
                'wordCount': wordCount,
                'participationPercentage': meeting.durationSeconds > 0 ? speakingTime / meeting.durationSeconds : 0.0,
                'interactionScore': turns * 5.0,
              }
            });
          }
        }
        dspResult = mockedResult;
      }
      
      final dspSpeakers = dspResult['speakers'] as List? ?? [];
      final dspTimeline = dspResult['meetingTimeline'] as List? ?? [];
      
      final Map<int, SpeakerProfileModel> indexToProfile = {};
      
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
      
      for (final segment in segments) {
        final spkIdx = segment.speaker ?? 0;
        if (!indexToProfile.containsKey(spkIdx)) {
          final profile = await speakerService.getOrCreateSpeakerProfileByName('Speaker $spkIdx');
          indexToProfile[spkIdx] = profile;
        }
      }
      
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
      
      final actionItems = meeting.actionItems.toList();
      if (actionItems.isNotEmpty) {
        await isar.writeTxn(() async {
          for (final item in actionItems) {
            final assignee = item.assignedTo?.trim().toLowerCase() ?? '';
            if (assignee.isNotEmpty) {
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

      if (dspTimeline.isNotEmpty) {
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
      meeting.isLocalEstimation = isLocalEstimation;
      await meetingRepo.updateMeeting(meeting);
      
    } catch (e) {
      print("[Speaker Intelligence Flow ERROR] Failed: $e");
      for (final segment in segments) {
        final spkIdx = segment.speaker ?? 0;
        final profile = await speakerService.getOrCreateSpeakerProfileByName('Speaker $spkIdx');
        await isar.writeTxn(() async {
          segment.speakerProfile.value = profile;
          await isar.transcriptSegmentModels.put(segment);
          await segment.speakerProfile.save();
        });
      }
      meeting.detectedEmotion = 'Neutral';
      meeting.emotionConfidence = 0.50;
      meeting.isLocalEstimation = true;
      await meetingRepo.updateMeeting(meeting);
    }
  }
}


final recordingProvider = StateNotifierProvider<RecordingNotifier, RecordingState>((ref) {
  return RecordingNotifier(ref);
});