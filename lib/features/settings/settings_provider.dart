import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/config/env_config.dart';
import '../../core/config/deepgram_debug.dart';
import '../../services/backend_connection_manager.dart';

class SettingsState {
  final String deepgramKey;
  final String ollamaUrl;
  final String ollamaModel;
  final String customBackendUrl;
  final bool isBackgroundRecordingEnabled;
  final bool isLoading;
  final bool deepgramKeyFromEnv;

  SettingsState({
    required this.deepgramKey,
    required this.ollamaUrl,
    required this.ollamaModel,
    this.customBackendUrl = '',
    this.isBackgroundRecordingEnabled = true,
    this.isLoading = false,
    this.deepgramKeyFromEnv = false,
  });

  SettingsState copyWith({
    String? deepgramKey,
    String? ollamaUrl,
    String? ollamaModel,
    String? customBackendUrl,
    bool? isBackgroundRecordingEnabled,
    bool? isLoading,
    bool? deepgramKeyFromEnv,
  }) {
    return SettingsState(
      deepgramKey: deepgramKey ?? this.deepgramKey,
      ollamaUrl: ollamaUrl ?? this.ollamaUrl,
      ollamaModel: ollamaModel ?? this.ollamaModel,
      customBackendUrl: customBackendUrl ?? this.customBackendUrl,
      isBackgroundRecordingEnabled:
          isBackgroundRecordingEnabled ?? this.isBackgroundRecordingEnabled,
      isLoading: isLoading ?? this.isLoading,
      deepgramKeyFromEnv: deepgramKeyFromEnv ?? this.deepgramKeyFromEnv,
    );
  }
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  final _secureStorage = const FlutterSecureStorage();
  late final Future<void> _loadFuture;

  SettingsNotifier(Ref ref)
    : super(
        SettingsState(
          deepgramKey: '',
          ollamaUrl: '',
          ollamaModel: 'qwen2.5:7b',
          customBackendUrl: '',
          isLoading: true,
        ),
      ) {
    _loadFuture = _loadSettings();
  }

  Future<void> ensureLoaded() => _loadFuture;

  Future<String> _readSecureKey(String storageKey) async {
    try {
      return (await _secureStorage.read(key: storageKey))?.trim() ?? '';
    } catch (e) {
      print('Secure storage read failed for $storageKey: $e');
      return '';
    }
  }

  Future<void> _loadSettings() async {
    final envDeepgramKey = EnvConfig.deepgramApiKey;
    final storedDgKey = await _readSecureKey('deepgram_key');
    final dgKey = envDeepgramKey.isNotEmpty ? envDeepgramKey : storedDgKey;

    final storedOllamaUrl = await _readSecureKey('ollama_url');
    final ollamaUrl = storedOllamaUrl;

    final storedOllamaModel = await _readSecureKey('ollama_model');
    final ollamaModel = storedOllamaModel.isNotEmpty
        ? storedOllamaModel
        : 'qwen2.5:7b';

    final storedBackendUrl = await _readSecureKey('custom_backend_url');
    final customBackendUrl = storedBackendUrl;

    print("DEEPGRAM KEY LENGTH: ${dgKey.length}");
    print("OLLAMA URL: $ollamaUrl");
    print("OLLAMA MODEL: $ollamaModel");
    print("CUSTOM BACKEND URL: $customBackendUrl");

    logDeepgramKeyDebug(dgKey, source: 'settings_provider._loadSettings');

    state = SettingsState(
      deepgramKey: dgKey,
      ollamaUrl: ollamaUrl,
      ollamaModel: ollamaModel,
      customBackendUrl: customBackendUrl,
      isLoading: false,
      deepgramKeyFromEnv: envDeepgramKey.isNotEmpty,
    );
  }

  Future<void> saveDeepgramKey(String key) async {
    if (state.deepgramKeyFromEnv) return;
    await _secureStorage.write(key: 'deepgram_key', value: key);
    state = state.copyWith(deepgramKey: key);
  }

  Future<void> saveOllamaUrl(String url) async {
    await _secureStorage.write(key: 'ollama_url', value: url);
    state = state.copyWith(ollamaUrl: url);
  }

  Future<void> saveOllamaModel(String model) async {
    await _secureStorage.write(key: 'ollama_model', value: model);
    state = state.copyWith(ollamaModel: model);
  }

  Future<void> saveCustomBackendUrl(String url) async {
    await _secureStorage.write(key: 'custom_backend_url', value: url.trim());
    state = state.copyWith(customBackendUrl: url.trim());
    BackendConnectionManager.instance.checkConnection(isPassive: false);
  }

  void toggleBackgroundRecording(bool enabled) {
    state = state.copyWith(isBackgroundRecordingEnabled: enabled);
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>(
  (ref) {
    return SettingsNotifier(ref);
  },
);
