import 'package:flutter_dotenv/flutter_dotenv.dart';

class EnvConfig {
  static bool _loaded = false;

  static Future<void> load() async {
  if (_loaded) return;

  try {
    await dotenv.load(fileName: '.env');



print("DEEPGRAM KEY LENGTH: ${dotenv.env['DEEPGRAM_API_KEY']?.length ?? 0}");
print("OPENAI KEY LENGTH: ${dotenv.env['OPENAI_API_KEY']?.length ?? 0}");
print("GOOGLE CLIENT ID LENGTH: ${dotenv.env['GOOGLE_WEB_CLIENT_ID']?.length ?? 0}");
    _loaded = true;
  } catch (e) {
    print('Failed to load .env file: $e');
  }
}

  static String get deepgramApiKey {
    return dotenv.env['DEEPGRAM_API_KEY']?.trim() ?? '';
  }

  static String get openAiApiKey {
    return dotenv.env['OPENAI_API_KEY']?.trim() ?? '';
  }

  static String get googleWebClientId {
    return dotenv.env['GOOGLE_WEB_CLIENT_ID']?.trim() ?? '';
  }

}
