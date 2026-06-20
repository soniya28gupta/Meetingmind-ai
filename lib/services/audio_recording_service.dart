import 'dart:async';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import '../core/utils/audio_helper.dart';

class AudioRecordingService {
  final AudioRecorder _recorder = AudioRecorder();
  
  bool _isRecording = false;
  bool _isPaused = false;
  int _secondsElapsed = 0;
  Timer? _timer;
  
  String? _tempPcmPath;
  String? _finalWavPath;
  IOSink? _fileSink;
  
  StreamController<List<int>>? _audioStreamController;
  StreamSubscription<List<int>>? _recorderSubscription;

  bool get isRecording => _isRecording;
  bool get isPaused => _isPaused;
  int get secondsElapsed => _secondsElapsed;
  String? get finalWavPath => _finalWavPath;

  // Streams PCM bytes for real-time transcription
  Stream<List<int>> get audioStream => _audioStreamController?.stream ?? const Stream.empty();

  Future<bool> hasPermission() async {
    return await _recorder.hasPermission();
  }

  Future<void> startRecording() async {
    if (_isRecording) return;

    if (!await _recorder.hasPermission()) {
      throw Exception('Microphone permission not granted');
    }

    final tempDir = await getTemporaryDirectory();
    final docDir = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    
    _tempPcmPath = '${tempDir.path}/rec_$timestamp.raw';
    _finalWavPath = '${docDir.path}/meeting_$timestamp.wav';
    
    final pcmFile = File(_tempPcmPath!);
    _fileSink = pcmFile.openWrite();

    _audioStreamController = StreamController<List<int>>.broadcast();

    // Configure recorder for PCM 16-bit, 16kHz, mono (ideal for Deepgram)
    const config = RecordConfig(
      encoder: AudioEncoder.pcm16bits,
      sampleRate: 16000,
      numChannels: 1,
    );

    final recordStream = await _recorder.startStream(config);
    _isRecording = true;
    _isPaused = false;
    _secondsElapsed = 0;

    _startTimer();

    _recorderSubscription = recordStream.listen(
      (chunk) {
        if (!_isPaused) {
          // Write raw PCM bytes to local file
          _fileSink?.add(chunk);
          // Pipe bytes to the audio stream controller for WebSocket streaming
          _audioStreamController?.add(chunk);
        }
      },
      onError: (err) {
        stopRecording();
      },
    );
  }

  Future<void> pauseRecording() async {
    if (!_isRecording || _isPaused) return;
    try {
      await _recorder.pause();
    } catch (e) {
      print("[AudioRecordingService] Error pausing recorder: $e");
    }
    _isPaused = true;
    _timer?.cancel();
  }

  Future<void> resumeRecording() async {
    if (!_isRecording || !_isPaused) return;
    try {
      await _recorder.resume();
    } catch (e) {
      print("[AudioRecordingService] Error resuming recorder: $e");
    }
    _isPaused = false;
    _startTimer();
  }

  Future<String?> stopRecording() async {
    if (!_isRecording) return null;

    _timer?.cancel();
    _timer = null;
    
    await _recorderSubscription?.cancel();
    _recorderSubscription = null;
    
    try {
      await _recorder.stop();
    } catch (e) {
      print("[AudioRecordingService] Error stopping recorder: $e");
    }
    await _fileSink?.close();
    _fileSink = null;
    
    await _audioStreamController?.close();
    _audioStreamController = null;

    _isRecording = false;
    _isPaused = false;

    // Convert raw PCM to standard playable WAV file
    if (_tempPcmPath != null && _finalWavPath != null) {
      await AudioHelper.convertPcmToWav(_tempPcmPath!, _finalWavPath!, 16000);
      return _finalWavPath;
    }
    
    return null;
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _secondsElapsed++;
    });
  }

  void dispose() {
    _timer?.cancel();
    _recorderSubscription?.cancel();
    _recorder.dispose();
  }
}
