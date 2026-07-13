import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

enum BackendEnv { local, debug, release, production }

class ApiConfig {
  static const String emotionApiUrl = String.fromEnvironment(
    'EMOTION_API_URL',
    defaultValue: 'https://meetingmind-emotion-api.onrender.com',
  );

  static String get normalizedEmotionApiUrl => emotionApiUrl.replaceAll(
        RegExp(r'/+$'),
        '',
      );

  static String get healthUrl => '$normalizedEmotionApiUrl/health';

  static String get readinessUrl => '$normalizedEmotionApiUrl/ready';
}

class BackendConfig {
  /// Resolves the current backend environment.
  static BackendEnv get environment {
    if (kReleaseMode) {
      return BackendEnv.production;
    }

    final envStr = dotenv.env['BACKEND_ENV']?.toLowerCase() ?? '';
    switch (envStr) {
      case 'production':
        return BackendEnv.production;
      case 'release':
        return BackendEnv.release;
      case 'local':
        return BackendEnv.local;
      case 'debug':
      default:
        return BackendEnv.debug;
    }
  }

  static String get defaultProductionUrl =>
      ApiConfig.normalizedEmotionApiUrl;

  /// Resolves the backend base URL dynamically according to environment priority.
  static String get configuredUrl {
    // In release mode or production/release environments, ALWAYS use the default production URL
    if (kReleaseMode ||
        environment == BackendEnv.production ||
        environment == BackendEnv.release) {
      return defaultProductionUrl;
    }

    // Otherwise, check environment variable (highest priority)
    final envUrl = dotenv.env['EMOTION_API_URL'] ?? dotenv.env['BACKEND_URL'];
    if (envUrl != null && envUrl.trim().isNotEmpty) {
      return _normalizeUrl(envUrl);
    }

    // Otherwise, return empty to trigger dynamic local discovery (subnet ping / emulator fallbacks)
    return '';
  }

  static String _normalizeUrl(String url) {
    var cleaned = url.trim();
    // Strip surrounding quotes
    if ((cleaned.startsWith("'") && cleaned.endsWith("'")) ||
        (cleaned.startsWith('"') && cleaned.endsWith('"'))) {
      cleaned = cleaned.substring(1, cleaned.length - 1).trim();
    }
    // Remove trailing slashes
    cleaned = cleaned.replaceAll(RegExp(r'/+$'), '');

    // Validate that it starts with https:// in release mode, or for non-local addresses
    if (!cleaned.startsWith('https://')) {
      final isLocal =
          cleaned.contains('localhost') ||
          cleaned.contains('127.0.0.1') ||
          cleaned.contains('10.0.2.2') ||
          cleaned.contains('192.168.');
      if (kReleaseMode || !isLocal) {
        if (cleaned.startsWith('http://')) {
          cleaned = cleaned.replaceFirst('http://', 'https://');
        } else {
          cleaned = 'https://$cleaned';
        }
      }
    }
    return cleaned;
  }
}
