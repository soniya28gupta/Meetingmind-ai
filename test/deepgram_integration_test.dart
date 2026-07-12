import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:meetingmind_ai/core/config/deepgram_debug.dart';
import 'package:meetingmind_ai/features/settings/settings_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Deepgram API key integration', () {
    setUpAll(() async {
      dotenv.testLoad(
        fileInput:
            'DEEPGRAM_API_KEY=6ecb2124a1a4982a3e3b1c6e5c3eee0ad25d21e1\n',
      );
    });

    test(
      'settings provider loads key from env before recording check',
      () async {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        await container.read(settingsProvider.notifier).ensureLoaded();
        final settings = container.read(settingsProvider);
        final key = settings.deepgramKey;

        logDeepgramKeyDebug(key, source: 'integration_test.settings');

        expect(settings.isLoading, isFalse);
        expect(key.isEmpty, isFalse);
        expect(key.length, 40);
        expect(settings.deepgramKeyFromEnv, isTrue);
      },
    );

    test('recording key guard would pass with loaded env key', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container.read(settingsProvider.notifier).ensureLoaded();
      final key = container.read(settingsProvider).deepgramKey;

      logDeepgramKeyDebug(key, source: 'integration_test.recording_guard');

      final missingKeyError =
          'Deepgram API Key is missing. Configure it in settings.';
      final wouldShowError = key.isEmpty;

      expect(wouldShowError, isFalse);
      expect(missingKeyError, isNotEmpty);
    });
  });
}
