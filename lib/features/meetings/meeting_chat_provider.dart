import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../database/schemas/meeting_models.dart';
import '../../providers/app_providers.dart';
import '../../services/chat_service.dart';
import '../../services/ollama_connection_manager.dart';

class MeetingChatNotifier
    extends StateNotifier<AsyncValue<List<ChatMessageModel>>> {
  final Ref _ref;
  final int _meetingId;

  MeetingChatNotifier(this._ref, this._meetingId)
    : super(const AsyncValue.loading()) {
    _loadChatHistory();
  }

  Future<void> _loadChatHistory() async {
    state = const AsyncValue.loading();
    try {
      final meetingRepo = _ref.read(meetingRepositoryProvider);
      final meeting = await meetingRepo.getMeetingById(_meetingId);
      if (meeting == null) {
        state = AsyncValue.error('Meeting not found', StackTrace.current);
        return;
      }
      state = AsyncValue.data(meeting.chatMessages.toList());
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> sendMessage(String text) async {
    final currentMessages = state.value ?? [];

    // 1. Create and save user message
    final userMessage = ChatMessageModel()
      ..message = text
      ..isUser = true
      ..timestamp = DateTime.now();

    final meetingRepo = _ref.read(meetingRepositoryProvider);
    await meetingRepo.addChatMessage(_meetingId, userMessage);

    // Update local state temporarily
    state = AsyncValue.data([...currentMessages, userMessage]);

    // 2. Fetch API keys and meeting context

    // Set loading indicator
    state = AsyncValue.data([
      ...state.value!,
      ChatMessageModel()
        ..message = '🤖 Thinking...'
        ..isUser = false
        ..timestamp = DateTime.now(),
    ]);

    try {
      final meeting = await meetingRepo.getMeetingById(_meetingId);
      final transcript = meeting?.transcript.value;

      final String fullTranscriptText = transcript != null
          ? transcript.segments
                .toList()
                .map((e) => 'Speaker ${e.speaker}: ${e.text}')
                .join('\n')
          : '';

      if (fullTranscriptText.trim().isEmpty) {
        // Remove placeholder
        final cleanList = state.value!.sublist(0, state.value!.length - 1);
        final emptyBotMessage = ChatMessageModel()
          ..message =
              'There is no transcript available for this meeting to analyze.'
          ..isUser = false
          ..timestamp = DateTime.now();
        state = AsyncValue.data([...cleanList, emptyBotMessage]);
        return;
      }

      // Call ChatService RAG API with context
      final chatService = _ref.read(chatServiceProvider);

      // Verify Ollama connectivity before sending chat request
      final connState = await _ref
          .read(ollamaConnectionManagerProvider.notifier)
          .verifyHealth();
      if (connState.status == OllamaConnectionStatus.offline) {
        throw Exception(
          'Ollama Offline (connection refused)\nDetails: ${connState.errorMessage ?? 'Connection refused.'}',
        );
      } else if (connState.status == OllamaConnectionStatus.waitingForOllama) {
        throw Exception(
          'Ollama Waiting (model missing)\nDetails: ${connState.errorMessage ?? 'Model missing.'}',
        );
      }

      final responseText = await chatService.askAboutMeeting(
        meetingId: _meetingId,
        question: text,
        chatHistory: currentMessages,
      );
      final botMessage = ChatMessageModel()
        ..message = responseText
        ..isUser = false
        ..timestamp = DateTime.now();

      // Save bot reply to database
      await meetingRepo.addChatMessage(_meetingId, botMessage);

      // Reload entire history from database to align states correctly
      await _loadChatHistory();
    } catch (e) {
      // Remove placeholder
      final cleanList = state.value!.sublist(0, state.value!.length - 1);
      String displayError = '⚠️ Ollama unavailable';
      final errStr = e.toString().toLowerCase();
      if (errStr.contains('timeout') || errStr.contains('deadline')) {
        displayError = '⚠️ Timeout';
      } else if (errStr.contains('connection refused') ||
          errStr.contains('refused')) {
        displayError = '⚠️ Connection Refused';
      } else if (errStr.contains('no model loaded') ||
          errStr.contains('model missing') ||
          errStr.contains('waiting') ||
          errStr.contains('missing')) {
        displayError = '⚠️ Model Missing';
      } else if (errStr.contains('invalid url') || errStr.contains('format')) {
        displayError = '⚠️ Invalid URL';
      } else if (errStr.contains('server not running') ||
          errStr.contains('unreachable') ||
          errStr.contains('offline')) {
        displayError = '⚠️ Server Not Running';
      }
      final errorBotMessage = ChatMessageModel()
        ..message = '$displayError\nDetails: $e'
        ..isUser = false
        ..timestamp = DateTime.now();
      state = AsyncValue.data([...cleanList, errorBotMessage]);
    }
  }

  Future<void> retryLastMessage(String originalText) async {
    final currentMessages = state.value ?? [];
    // Remove the error message from state
    List<ChatMessageModel> cleanList = [];
    if (currentMessages.isNotEmpty && !currentMessages.last.isUser) {
      cleanList = currentMessages.sublist(0, currentMessages.length - 1);
      state = AsyncValue.data(cleanList);
    } else {
      cleanList = currentMessages;
    }

    // Set loading indicator
    state = AsyncValue.data([
      ...cleanList,
      ChatMessageModel()
        ..message = '🤖 Thinking...'
        ..isUser = false
        ..timestamp = DateTime.now(),
    ]);

    try {
      final meetingRepo = _ref.read(meetingRepositoryProvider);
      final meeting = await meetingRepo.getMeetingById(_meetingId);
      final transcript = meeting?.transcript.value;

      final String fullTranscriptText = transcript != null
          ? transcript.segments
                .toList()
                .map((e) => 'Speaker ${e.speaker}: ${e.text}')
                .join('\n')
          : '';

      if (fullTranscriptText.trim().isEmpty) {
        final cleanList = state.value!.sublist(0, state.value!.length - 1);
        final emptyBotMessage = ChatMessageModel()
          ..message =
              'There is no transcript available for this meeting to analyze.'
          ..isUser = false
          ..timestamp = DateTime.now();
        state = AsyncValue.data([...cleanList, emptyBotMessage]);
        return;
      }

      // Call ChatService RAG API with context
      final chatService = _ref.read(chatServiceProvider);

      // Verify Ollama connectivity before sending chat request
      final connState = await _ref
          .read(ollamaConnectionManagerProvider.notifier)
          .verifyHealth();
      if (connState.status == OllamaConnectionStatus.offline) {
        throw Exception(
          'Ollama Offline (connection refused)\nDetails: ${connState.errorMessage ?? 'Connection refused.'}',
        );
      } else if (connState.status == OllamaConnectionStatus.waitingForOllama) {
        throw Exception(
          'Ollama Waiting (model missing)\nDetails: ${connState.errorMessage ?? 'Model missing.'}',
        );
      }

      final responseText = await chatService.askAboutMeeting(
        meetingId: _meetingId,
        question: originalText,
        chatHistory: cleanList,
      );
      final botMessage = ChatMessageModel()
        ..message = responseText
        ..isUser = false
        ..timestamp = DateTime.now();

      // Save bot reply to database
      await meetingRepo.addChatMessage(_meetingId, botMessage);

      // Reload entire history from database to align states correctly
      await _loadChatHistory();
    } catch (e) {
      // Remove placeholder
      final cleanList = state.value!.sublist(0, state.value!.length - 1);
      String displayError = '⚠️ Ollama unavailable';
      final errStr = e.toString().toLowerCase();
      if (errStr.contains('timeout') || errStr.contains('deadline')) {
        displayError = '⚠️ Timeout';
      } else if (errStr.contains('connection refused') ||
          errStr.contains('refused')) {
        displayError = '⚠️ Connection Refused';
      } else if (errStr.contains('no model loaded') ||
          errStr.contains('model missing') ||
          errStr.contains('waiting') ||
          errStr.contains('missing')) {
        displayError = '⚠️ Model Missing';
      } else if (errStr.contains('invalid url') || errStr.contains('format')) {
        displayError = '⚠️ Invalid URL';
      } else if (errStr.contains('server not running') ||
          errStr.contains('unreachable') ||
          errStr.contains('offline')) {
        displayError = '⚠️ Server Not Running';
      }
      final errorBotMessage = ChatMessageModel()
        ..message = '$displayError\nDetails: $e'
        ..isUser = false
        ..timestamp = DateTime.now();
      state = AsyncValue.data([...cleanList, errorBotMessage]);
    }
  }

  Future<void> clearChat() async {
    state = const AsyncValue.loading();
    try {
      final meeting = await _ref
          .read(meetingRepositoryProvider)
          .getMeetingById(_meetingId);
      if (meeting != null) {
        final isar = _ref.read(isarProvider);
        await isar.writeTxn(() async {
          for (final chat in meeting.chatMessages) {
            await isar.chatMessageModels.delete(chat.id);
          }
          meeting.chatMessages.clear();
        });
        await _loadChatHistory();
      }
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

final meetingChatProvider =
    StateNotifierProvider.family<
      MeetingChatNotifier,
      AsyncValue<List<ChatMessageModel>>,
      int
    >((ref, meetingId) {
      return MeetingChatNotifier(ref, meetingId);
    });
