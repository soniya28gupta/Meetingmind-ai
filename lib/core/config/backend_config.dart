import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

enum BackendEnv { local, debug, release, production }

class ApiConfig {
  static const String productionBaseUrl = String.fromEnvironment(
    'EMOTION_API_URL',
    defaultValue: 'https://meetingmind-emotion-api.onrender.com',
  );
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

  /// Default production API endpoint.
  static String get defaultProductionUrl =>
      _normalizeUrl(ApiConfig.productionBaseUrl);

  /// Resolves the backend base URL dynamically according to environment priority.
  static String get configuredUrl {
    // 1. Check environment variable (highest priority)
    final envUrl = dotenv.env['EMOTION_API_URL'] ?? dotenv.env['BACKEND_URL'];
    if (envUrl != null && envUrl.trim().isNotEmpty) {
      return _normalizeUrl(envUrl);
    }

    // 2. Production or Release environments fall back to the production URL
    final env = environment;
    if (env == BackendEnv.production || env == BackendEnv.release) {
      return defaultProductionUrl;
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
    cleaned = cleaned.replaceAll(RegExp(r'/$'), '');
    return cleaned;
  }
}
