import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../database/schemas/meeting_models.dart';

class DeepgramService {
  WebSocketChannel? _channel;
  StreamController<TranscriptSegmentModel>? _segmentStreamController;
  bool _isConnected = false;

  Stream<TranscriptSegmentModel> get segmentStream =>
      _segmentStreamController?.stream ?? const Stream.empty();

  bool get isConnected => _isConnected;

  Future<void> connect(String apiKey) async {
    if (_isConnected) return;

    _segmentStreamController = StreamController<TranscriptSegmentModel>.broadcast();

    // Query parameters for Deepgram streaming: linear16, 16kHz, mono, diarize enabled, model nova-2, smart format, interim results
    final url = Uri.parse(
      'wss://api.deepgram.com/v1/listen'
      '?encoding=linear16'
      '&sample_rate=16000'
      '&channels=1'
      '&diarize=true'
      '&punctuate=true'
      '&model=nova-2'
      '&smart_format=true'
      '&interim_results=true',
    );

    try {
      _channel = WebSocketChannel.connect(
        url,
        protocols: ['token', apiKey],
      );

      _isConnected = true;

      _channel!.stream.listen(
        (message) {
          _handleMessage(message);
        },
        onError: (error) {
          _segmentStreamController?.addError(error);
          disconnect();
        },
        onDone: () {
          disconnect();
        },
      );
    } catch (e) {
      _isConnected = false;
      _segmentStreamController?.addError(e);
      rethrow;
    }
  }

  void sendAudioChunk(List<int> chunk) {
    if (!_isConnected || _channel == null) return;
    _channel!.sink.add(chunk);
  }

  void _handleMessage(dynamic message) {
    try {
      final data = jsonDecode(message);
      final isFinal = data['is_final'] ?? false;
      if (!isFinal) return;

      final channel = data['channel'];
      if (channel == null) return;

      final alternatives = channel['alternatives'] as List?;
      if (alternatives == null || alternatives.isEmpty) return;

      final alternative = alternatives[0];
      final transcript = alternative['transcript'] as String?;
      final words = alternative['words'] as List?;

      if (transcript == null || transcript.trim().isEmpty) return;

      // Deepgram speaker diarization check
      int speaker = 0;
      double startTime = 0.0;
      double endTime = 0.0;

      if (words != null && words.isNotEmpty) {
        speaker = (words[0]['speaker'] as int? ?? 0) + 1;
        startTime = (words[0]['start'] as num).toDouble();
        endTime = (words.last['end'] as num).toDouble();
      }

      final segment = TranscriptSegmentModel()
        ..speaker = speaker
        ..text = transcript.trim()
        ..startTime = startTime
        ..endTime = endTime;

      _segmentStreamController?.add(segment);
    } catch (e) {
      // Log parser errors or add to stream as error
    }
  }

  Future<void> disconnect() async {
    if (!_isConnected) return;
    
    _isConnected = false;
    // Send empty JSON to indicate end of stream to Deepgram
    try {
      _channel?.sink.add(jsonEncode({"type": "CloseStream"}));
    } catch (_) {}
    
    await _channel?.sink.close();
    _channel = null;
    await _segmentStreamController?.close();
    _segmentStreamController = null;
  }
}
