import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/schemas/meeting_models.dart';
import '../providers/app_providers.dart';
import '../services/meeting_ai_service.dart';
import '../features/settings/settings_provider.dart';
import '../services/emotion_health_service.dart';
import '../core/config/backend_config.dart';
import 'package:dio/dio.dart';

class MeetingAIState {
  final bool isAnalyzing;
  final String? errorMessage;
  final bool isTranscribingFile;
  final double transcriptionProgress;
  final String importStatusText;

  MeetingAIState({
    this.isAnalyzing = false,
    this.errorMessage,
    this.isTranscribingFile = false,
    this.transcriptionProgress = 0.0,
    this.importStatusText = '',
  });

  MeetingAIState copyWith({
    bool? isAnalyzing,
    String? errorMessage,
    bool? isTranscribingFile,
    double? transcriptionProgress,
    String? importStatusText,
  }) {
    return MeetingAIState(
      isAnalyzing: isAnalyzing ?? this.isAnalyzing,
      errorMessage: errorMessage ?? this.errorMessage,
      isTranscribingFile: isTranscribingFile ?? this.isTranscribingFile,
      transcriptionProgress:
          transcriptionProgress ?? this.transcriptionProgress,
      importStatusText: importStatusText ?? this.importStatusText,
    );
  }
}

class MeetingAINotifier extends StateNotifier<MeetingAIState> {
  final Ref _ref;

  MeetingAINotifier(this._ref) : super(MeetingAIState());

  /// Runs the full LLM analysis (summary, decisions, actions, risks) and saves to database
  Future<void> analyzeMeeting(int meetingId) async {
    state = state.copyWith(isAnalyzing: true, errorMessage: null);

    try {
      final meetingRepo = _ref.read(meetingRepositoryProvider);
      final meeting = await meetingRepo.getMeetingById(meetingId);
      if (meeting == null) {
        throw Exception('Meeting not found.');
      }

      // Load segments
      final transcriptObj = meeting.transcript.value;
      final segments = transcriptObj != null
          ? transcriptObj.segments.toList()
          : <TranscriptSegmentModel>[];

      final String fullTranscriptText = segments
          .map((e) {
            final speakerName =
                e.speakerProfile.value?.name ?? 'Speaker ${e.speaker}';
            return '$speakerName: ${e.text}';
          })
          .join('\n');

      if (fullTranscriptText.trim().isEmpty) {
        throw Exception('Transcript is empty. Cannot generate analysis.');
      }

      final aiAnalysis = await _ref
          .read(meetingAiServiceProvider)
          .generateMeetingAnalysis(fullTranscriptText);

      await meetingRepo.saveSummaryAndActionItems(
        meeting.id,
        aiAnalysis['summary'] as SummaryModel,
        aiAnalysis['actionItems'] as List<ActionItemModel>,
        aiAnalysis['decisions'] as List<DecisionModel>,
      );
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      rethrow;
    } finally {
      state = state.copyWith(isAnalyzing: false);
    }
  }

  /// Handles audio file uploads, runs Deepgram transcribing, formatting, and analysis saving
  Future<MeetingModel> transcribeAudioFile({
    required File file,
    required String title,
  }) async {
    state = state.copyWith(
      isTranscribingFile: true,
      transcriptionProgress: 0.05,
      importStatusText: 'Initializing upload...',
      errorMessage: null,
    );

    Timer? progressTimer;

    try {
      final meetingRepo = _ref.read(meetingRepositoryProvider);
      final meeting = await meetingRepo.createMeeting(title);
      meeting.audioFilePath = file.path;
      await meetingRepo.updateMeeting(meeting);

      final dio = _ref.read(dioProvider);
      final settings = _ref.read(settingsProvider);
      final apiKey = settings.deepgramKey;
      final healthState = _ref.read(emotionHealthServiceProvider);

      String backendUrl = healthState.activeUrl;
      if (backendUrl.isEmpty) {
        backendUrl = BackendConfig.configuredUrl;
      }

      if (apiKey.isEmpty) {
        throw Exception('Deepgram API Key is empty. Configure it in settings.');
      }

      state = state.copyWith(
        transcriptionProgress: 0.1,
        importStatusText: 'Preparing audio file...',
      );
      final bool isBackendOnline =
          healthState.isOnline && healthState.activeUrl.isNotEmpty;
      Response? response;
      final List<TranscriptSegmentModel> parsedSegments = [];

      if (isBackendOnline) {
        final String url = '${healthState.activeUrl}/transcribe_file';
        final formData = FormData.fromMap({
          'audio': await MultipartFile.fromFile(
            file.path,
            filename: file.path.split('/').last,
          ),
        });

        state = state.copyWith(
          transcriptionProgress: 0.15,
          importStatusText: 'Uploading audio to server...',
        );

        int attempt = 0;
        final maxAttempts = 3;
        while (attempt < maxAttempts) {
          attempt++;
          print('[MeetingAIProvider] Uploading file to backend: ${file.path}');
          try {
            response = await dio.post(
              url,
              options: Options(
                headers: {'Authorization': 'Token $apiKey'},
                connectTimeout: const Duration(seconds: 45),
                receiveTimeout: const Duration(minutes: 6),
              ),
              data: formData,
              onSendProgress: (sent, total) {
                if (total > 0) {
                  final ratio = sent / total;
                  final double currentProgress = 0.15 + (ratio * 0.25);
                  state = state.copyWith(
                    transcriptionProgress: currentProgress,
                    importStatusText:
                        'Uploading audio file (${(ratio * 100).toStringAsFixed(0)}%)...',
                  );
                }
              },
            );
            if (response.statusCode == 200) {
              break;
            }
          } catch (e) {
            print(
              '[MeetingAIProvider] Error during backend upload attempt $attempt: $e',
            );
            if (attempt >= maxAttempts) {
              print(
                '[MeetingAIProvider] Backend failed after 3 attempts. Falling back to direct Deepgram...',
              );
              break;
            }
            formData.fields.clear();
            formData.files.clear();
            formData.files.add(
              MapEntry(
                'audio',
                await MultipartFile.fromFile(
                  file.path,
                  filename: file.path.split('/').last,
                ),
              ),
            );
            await Future.delayed(Duration(seconds: attempt * 3));
          }
        }
      }

      if (response == null || response.statusCode != 200) {
        state = state.copyWith(
          transcriptionProgress: 0.15,
          importStatusText:
              'Backend offline. Transcribing directly via Deepgram API...',
        );

        print(
          '[MeetingAIProvider] Initializing direct Deepgram transcription...',
        );

        final fileBytes = await file.readAsBytes();

        response = await dio.post(
          'https://api.deepgram.com/v1/listen?diarize=true&punctuate=true&utterances=true&model=nova-2&smart_format=true',
          data: Stream.fromIterable([fileBytes]),
          options: Options(
            headers: {
              'Authorization': 'Token $apiKey',
              'Content-Type': 'audio/wav',
            },
            connectTimeout: const Duration(seconds: 45),
            receiveTimeout: const Duration(minutes: 6),
          ),
          onSendProgress: (sent, total) {
            if (total > 0) {
              final ratio = sent / total;
              final double currentProgress = 0.15 + (ratio * 0.25);
              state = state.copyWith(
                transcriptionProgress: currentProgress,
                importStatusText:
                    'Uploading directly to Deepgram (${(ratio * 100).toStringAsFixed(0)}%)...',
              );
            }
          },
        );

        if (response.statusCode == 200 && response.data != null) {
          print(
            '[MeetingAIProvider] Direct Deepgram transcription successful. Parsing response...',
          );
          final responseData = response.data;
          final results = responseData['results'] as Map?;
          if (results != null) {
            final utterances = results['utterances'] as List?;
            if (utterances != null && utterances.isNotEmpty) {
              for (final u in utterances) {
                final text = (u['transcript'] as String? ?? '').trim();
                if (text.isEmpty) continue;
                final speaker = (u['speaker'] as int? ?? 0) + 1;
                final start = (u['start'] as num).toDouble();
                final end = (u['end'] as num).toDouble();

                parsedSegments.add(
                  TranscriptSegmentModel()
                    ..speaker = speaker
                    ..text = text
                    ..startTime = start
                    ..endTime = end,
                );
              }
            } else {
              final channels = results['channels'] as List?;
              if (channels != null && channels.isNotEmpty) {
                final alternatives = channels[0]['alternatives'] as List?;
                if (alternatives != null && alternatives.isNotEmpty) {
                  final transcriptText =
                      alternatives[0]['transcript'] as String? ?? '';
                  final words = alternatives[0]['words'] as List?;

                  if (transcriptText.isNotEmpty &&
                      words != null &&
                      words.isNotEmpty) {
                    int currentSpeaker = (words[0]['speaker'] as int? ?? 0) + 1;
                    double startT = (words[0]['start'] as num).toDouble();
                    List<String> wordsBuffer = [];

                    for (final w in words) {
                      final spk = (w['speaker'] as int? ?? 0) + 1;
                      if (spk != currentSpeaker && wordsBuffer.isNotEmpty) {
                        final endT = (w['end'] as num).toDouble();
                        parsedSegments.add(
                          TranscriptSegmentModel()
                            ..speaker = currentSpeaker
                            ..text = wordsBuffer.join(' ')
                            ..startTime = startT
                            ..endTime = endT,
                        );
                        currentSpeaker = spk;
                        startT = (w['start'] as num).toDouble();
                        wordsBuffer = [];
                      }
                      wordsBuffer.add(w['word'] as String? ?? '');
                    }

                    if (wordsBuffer.isNotEmpty) {
                      final endT = (words.last['end'] as num).toDouble();
                      parsedSegments.add(
                        TranscriptSegmentModel()
                          ..speaker = currentSpeaker
                          ..text = wordsBuffer.join(' ')
                          ..startTime = startT
                          ..endTime = endT,
                      );
                    }
                  }
                }
              }
            }
          }
        } else {
          throw Exception(
            'Direct Deepgram request failed: ${response.statusCode}',
          );
        }
      } else {
        final responseData = response.data;
        final segmentsData = responseData['segments'] as List?;
        if (segmentsData != null) {
          for (final item in segmentsData) {
            final text = (item['text'] as String? ?? '').trim();
            if (text.isEmpty) continue;

            final speaker = item['speaker'] as int? ?? 1;
            final start = (item['startTime'] as num).toDouble();
            final end = (item['endTime'] as num).toDouble();

            parsedSegments.add(
              TranscriptSegmentModel()
                ..speaker = speaker
                ..text = text
                ..startTime = start
                ..endTime = end,
            );
          }
        }
      }
      progressTimer?.cancel();

      if (parsedSegments.isEmpty) {
        throw Exception(
          'No speech detected. The audio file might be silent or lack recognizable speech.',
        );
      }

      state = state.copyWith(
        transcriptionProgress: 0.8,
        importStatusText: 'Polishing grammar & punctuation...',
      );

      // Post-process: merge, grammar-correct, and sentence-split the raw segments
      final polishedSegments = await _postProcessSegments(parsedSegments);

      state = state.copyWith(
        transcriptionProgress: 0.9,
        importStatusText: 'Saving segments to database...',
      );

      // Save polished transcript segments in order
      for (final segment in polishedSegments) {
        await meetingRepo.addTranscriptSegment(meeting.id, segment);
      }

      state = state.copyWith(
        transcriptionProgress: 0.95,
        importStatusText: 'Generating meeting intelligence summaries...',
      );

      // Automatically trigger AI summary generation
      await analyzeMeeting(meeting.id);

      state = state.copyWith(
        transcriptionProgress: 1.0,
        importStatusText: 'Completed',
        isTranscribingFile: false,
      );
      return meeting;
    } catch (e, stackTrace) {
      progressTimer?.cancel();
      print('[EmotionHealthService/Deepgram] Final failure: $e');
      print('[EmotionHealthService/Deepgram] Stack trace: $stackTrace');
      state = state.copyWith(
        isTranscribingFile: false,
        errorMessage: e.toString(),
      );
      rethrow;
    }
  }

  /// Post-processes raw Deepgram segments:
  /// 1. Groups consecutive segments by speaker.
  /// 2. Merges each group's text and sends it through Ollama grammar correction.
  /// 3. Sentence-splits the corrected text and distributes timestamps proportionally.
  /// 4. Returns the final polished segments ready for saving.
  Future<List<TranscriptSegmentModel>> _postProcessSegments(
    List<TranscriptSegmentModel> rawSegments,
  ) async {
    if (rawSegments.isEmpty) return rawSegments;

    final openAiService = _ref.read(openAIServiceProvider);
    final List<TranscriptSegmentModel> result = [];

    // --- 1. Group consecutive segments by same speaker ---
    final List<List<TranscriptSegmentModel>> groups = [];
    List<TranscriptSegmentModel> currentGroup = [rawSegments.first];
    for (int i = 1; i < rawSegments.length; i++) {
      final seg = rawSegments[i];
      final prev = rawSegments[i - 1];
      if (seg.speaker == prev.speaker) {
        currentGroup.add(seg);
      } else {
        groups.add(currentGroup);
        currentGroup = [seg];
      }
    }
    groups.add(currentGroup);

    // --- 2. For each group: merge, correct grammar, split into sentences ---
    for (final group in groups) {
      final speaker = group.first.speaker ?? 1;
      final groupStart = group.first.startTime;
      final groupEnd = group.last.endTime;
      final groupDuration = groupEnd - groupStart;

      // Merge raw text
      final rawText = group.map((s) => (s.text ?? '').trim()).join(' ');

      // Ollama grammar correction (with silent fallback)
      final correctedText = await openAiService.correctTranscriptGrammar(
        rawText,
      );

      // --- 3. Split corrected text into natural sentences ---
      final sentences = _splitIntoSentences(correctedText);

      if (sentences.isEmpty) {
        // Fallback: keep original group as a single segment
        final seg = TranscriptSegmentModel()
          ..speaker = speaker
          ..text = correctedText.isEmpty ? rawText : correctedText
          ..startTime = groupStart
          ..endTime = groupEnd;
        result.add(seg);
        continue;
      }

      // --- 4. Distribute timestamps proportionally by character length ---
      final totalChars = sentences.fold<int>(0, (sum, s) => sum + s.length);
      double cursor = groupStart;
      for (final sentence in sentences) {
        final fraction = totalChars > 0
            ? sentence.length / totalChars
            : 1.0 / sentences.length;
        final duration = groupDuration * fraction;
        final sentStart = cursor;
        final sentEnd = cursor + duration;
        cursor = sentEnd;

        final seg = TranscriptSegmentModel()
          ..speaker = speaker
          ..text = sentence.trim()
          ..startTime = sentStart
          ..endTime = sentEnd;
        result.add(seg);
      }
    }

    return result;
  }

  /// Splits a paragraph of text into sentences using standard punctuation delimiters.
  List<String> _splitIntoSentences(String text) {
    if (text.trim().isEmpty) return [];
    // Split on sentence-ending punctuation followed by whitespace or end-of-string
    final parts = text.split(RegExp(r'(?<=[.!?])\s+'));
    return parts.where((s) => s.trim().isNotEmpty).toList();
  }

  String _getMimeType(String filePath) {
    final ext = filePath.split('.').last.toLowerCase();
    switch (ext) {
      case 'mp3':
        return 'audio/mpeg';
      case 'm4a':
        return 'audio/mp4';
      case 'aac':
        return 'audio/aac';
      case 'ogg':
        return 'audio/ogg';
      case 'wav':
        return 'audio/wav';
      default:
        return 'application/octet-stream';
    }
  }
}

final meetingAiProvider =
    StateNotifierProvider<MeetingAINotifier, MeetingAIState>((ref) {
      return MeetingAINotifier(ref);
    });
