import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../core/config/backend_config.dart';
import 'emotion_health_service.dart';

class BackendConnectionManager {
  // Singleton instance
  static final BackendConnectionManager instance = BackendConnectionManager._();
  BackendConnectionManager._();

  final _secureStorage = const FlutterSecureStorage();
  final _connectivity = Connectivity();

  // ValueNotifier to broadcast changes to Riverpod and UI
  final ValueNotifier<EmotionHealthState> stateNotifier =
      ValueNotifier<EmotionHealthState>(
        EmotionHealthState(
          status: EmotionBackendStatus.offline,
          activeUrl: '',
          retryCountdown: 0,
        ),
      );

  EmotionHealthState get state => stateNotifier.value;
  set state(EmotionHealthState newState) => stateNotifier.value = newState;

  Dio? _dio;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  Process? _flaskProcess;

  // Timers
  Timer? _heartbeatTimer;
  Timer? _countdownTimer;
  Timer? _passiveProbeTimer;

  bool _isChecking = false;
  bool _isInitialized = false;

  // History logs
  final List<String> _diagnosticsLog = [];

  void logDiagnostic(String message) {
    final timestamp = DateTime.now().toLocal().toString().split('.')[0];
    final logEntry = "[$timestamp] $message";
    _diagnosticsLog.add(logEntry);
    if (_diagnosticsLog.length > 50) {
      _diagnosticsLog.removeAt(0);
    }
    // Update state to trigger UI update
    state = state.copyWith(
      connectionHistory: List.unmodifiable(_diagnosticsLog),
    );
    debugPrint("[BackendConnectionManager] $message");
  }

  Future<void> init(Dio dio) async {
    if (_isInitialized) return;
    _isInitialized = true;
    _dio = dio;

    logDiagnostic("Initializing BackendConnectionManager...");

    // Detect device type
    final devType = await _detectDeviceType();

    // Load cached successful endpoint
    String cachedUrl = '';
    String cachedTime = 'Never';
    try {
      cachedUrl =
          await _secureStorage.read(key: 'last_success_backend_url') ?? '';
      cachedTime =
          await _secureStorage.read(key: 'last_success_connection_time') ??
          'Never';
    } catch (e) {
      logDiagnostic("Failed to read secure storage cache: $e");
    }

    // Clear old cached local IP addresses and invalid endpoints
    if (cachedUrl.isNotEmpty) {
      final uri = Uri.tryParse(cachedUrl);
      if (uri != null) {
        final host = uri.host;
        final isLocal =
            host == 'localhost' ||
            host == '127.0.0.1' ||
            host == '10.0.2.2' ||
            host.startsWith('192.168.') ||
            host.startsWith('10.') ||
            host.startsWith('172.');
        if (isLocal) {
          try {
            await _secureStorage.delete(key: 'last_success_backend_url');
            logDiagnostic("Cleared cached local IP endpoint: $cachedUrl");
            cachedUrl = '';
          } catch (e) {
            logDiagnostic("Failed to delete cached local IP: $e");
          }
        }
      }
    }

    state = EmotionHealthState(
      status: EmotionBackendStatus.unknown,
      activeUrl: '',
      retryAttempt: 0,
      retryCountdown: 0,
      deviceType: devType,
      lastSuccessTime: cachedTime,
      serverVersion: 'Unknown',
      uptime: 'N/A',
      connectionHistory: List.unmodifiable(_diagnosticsLog),
    );

    logDiagnostic("Detected classification: $devType");
    if (cachedUrl.isNotEmpty) {
      logDiagnostic(
        "Loaded cached endpoint: $cachedUrl (last success: $cachedTime)",
      );
    }

    // Spawn local windows Flask backend if running on Windows
    if (Platform.isWindows) {
      await _startProcessOnWindows();
    }

    // Start listening to connectivity changes
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((
      result,
    ) {
      logDiagnostic("Network connectivity changed to: $result");
      if (state.status == EmotionBackendStatus.offline ||
          state.status == EmotionBackendStatus.fallbackActive) {
        logDiagnostic(
          "Network status update received. Triggering connection check...",
        );
        checkConnection();
      }
    });

    // Start initial connection attempt
    checkConnection();
  }

  Future<void> _startProcessOnWindows() async {
    try {
      File file = File('lib/services/backend/app.py');
      if (!await file.exists()) {
        file = File('backend/app.py');
      }

      if (await file.exists()) {
        logDiagnostic("Spawning Python backend from: ${file.path}...");
        _flaskProcess = await Process.start('python', [
          file.path,
        ], runInShell: true);

        _flaskProcess!.stdout.transform(utf8.decoder).listen((data) {
          debugPrint('[Flask Backend Stdout] ${data.trim()}');
        });

        _flaskProcess!.stderr.transform(utf8.decoder).listen((data) {
          debugPrint('[Flask Backend Stderr] ${data.trim()}');
        });

        _flaskProcess?.exitCode.then((code) {
          logDiagnostic("Python backend exited with code $code.");
          if (state.status != EmotionBackendStatus.offline) {
            logDiagnostic("Attempting to restart Python backend...");
            _startProcessOnWindows();
          }
        });
      } else {
        logDiagnostic(
          "Local app.py not found at standard paths. Skipping local Windows startup.",
        );
      }
    } catch (e) {
      logDiagnostic("Failed to start Python backend on Windows: $e");
    }
  }

  Future<String> _detectDeviceType() async {
    if (kIsWeb) return 'Web Browser';
    if (Platform.isWindows) return 'Windows Desktop';
    if (Platform.isMacOS) return 'macOS Desktop';
    if (Platform.isLinux) return 'Linux Desktop';

    final deviceInfo = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      try {
        final androidInfo = await deviceInfo.androidInfo;
        final isEmulator = !androidInfo.isPhysicalDevice;
        return isEmulator
            ? 'Android Emulator'
            : 'Physical Android Device (${androidInfo.model})';
      } catch (_) {
        return 'Android Device';
      }
    }
    if (Platform.isIOS) {
      try {
        final iosInfo = await deviceInfo.iosInfo;
        final isSimulator = !iosInfo.isPhysicalDevice;
        return isSimulator ? 'iOS Simulator' : 'Physical iOS Device';
      } catch (_) {
        return 'iOS Device';
      }
    }
    return 'Unknown Device';
  }

  Future<List<String>> _getDiscoveryCandidates() async {
    final env = BackendConfig.environment;
    final isProdOrRelease =
        env == BackendEnv.production ||
        env == BackendEnv.release ||
        kReleaseMode;

    // Detect if running on a physical Android/iOS device
    bool isPhysicalDevice = true;
    if (!kIsWeb) {
      final deviceInfo = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        try {
          final androidInfo = await deviceInfo.androidInfo;
          isPhysicalDevice = androidInfo.isPhysicalDevice;
        } catch (_) {}
      } else if (Platform.isIOS) {
        try {
          final iosInfo = await deviceInfo.iosInfo;
          isPhysicalDevice = iosInfo.isPhysicalDevice;
        } catch (_) {}
      }
    }

    if (isProdOrRelease || isPhysicalDevice) {
      final prodUrl = _formatUrl(
        BackendConfig.configuredUrl.isNotEmpty
            ? BackendConfig.configuredUrl
            : BackendConfig.defaultProductionUrl,
      );
      logDiagnostic(
        "Production/Release mode or Physical Device active. Central URL candidate: $prodUrl",
      );
      return [prodUrl];
    }

    final List<String> candidates = [];

    // 1. Manually configured custom URL (highest priority)
    try {
      final customUrl = await _secureStorage.read(key: 'custom_backend_url');
      if (customUrl != null && customUrl.trim().isNotEmpty) {
        final formatted = _formatUrl(customUrl.trim());
        if (!candidates.contains(formatted)) {
          candidates.add(formatted);
          logDiagnostic(
            "Added custom configured endpoint candidate: $formatted",
          );
        }
      }
    } catch (_) {}

    // 2. Firebase Remote Config endpoint
    final remoteConfigUrl = await _getRemoteConfigEndpoint();
    if (remoteConfigUrl != null && remoteConfigUrl.isNotEmpty) {
      final formatted = _formatUrl(remoteConfigUrl);
      if (!candidates.contains(formatted)) {
        candidates.add(formatted);
        logDiagnostic("Added Remote Config endpoint candidate: $formatted");
      }
    }

    // 3. Cached successful endpoint
    try {
      final cachedUrl = await _secureStorage.read(
        key: 'last_success_backend_url',
      );
      if (cachedUrl != null && cachedUrl.isNotEmpty) {
        final formatted = _formatUrl(cachedUrl);
        if (!candidates.contains(formatted)) {
          candidates.add(formatted);
          logDiagnostic(
            "Added cached successful endpoint candidate: $formatted",
          );
        }
      }
    } catch (_) {}

    // 4. Environment configured endpoint
    final envUrl = BackendConfig.configuredUrl;
    if (envUrl.isNotEmpty) {
      final formatted = _formatUrl(envUrl);
      if (!candidates.contains(formatted)) {
        candidates.add(formatted);
        logDiagnostic("Added Env/Config endpoint candidate: $formatted");
      }
    } else {
      // If configuredUrl is empty (e.g. in debug mode), still add defaultProductionUrl as a candidate
      final defaultUrl = _formatUrl(BackendConfig.defaultProductionUrl);
      if (defaultUrl.isNotEmpty && !candidates.contains(defaultUrl)) {
        candidates.add(defaultUrl);
        logDiagnostic("Added Default Production URL candidate: $defaultUrl");
      }
    }

    // 5. Standard endpoints: localhost, 127.0.0.1, 10.0.2.2, host.docker.internal
    final stdUrls = [
      'http://localhost:5000',
      'http://127.0.0.1:5000',
      'http://10.0.2.2:5000',
      'http://host.docker.internal:5000',
    ];
    for (final url in stdUrls) {
      if (!candidates.contains(url)) {
        candidates.add(url);
      }
    }

    // 6. Subnet scanning candidate IPs (high priority first)
    final subnetIps = await _discoverSubnetIps();
    for (final ip in subnetIps) {
      final url = 'http://$ip:5000';
      if (!candidates.contains(url)) {
        candidates.add(url);
      }
    }

    return candidates;
  }

  String _formatUrl(String url) {
    var formatted = url.trim();
    if (!formatted.startsWith('http://') && !formatted.startsWith('https://')) {
      formatted = 'http://$formatted';
    }
    if (formatted.endsWith('/')) {
      formatted = formatted.substring(0, formatted.length - 1);
    }
    return formatted;
  }

  Future<String?> _getRemoteConfigEndpoint() async {
    try {
      final remoteConfig = FirebaseRemoteConfig.instance;
      await remoteConfig.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 1), // Fast 1-second timeout
          minimumFetchInterval: Duration.zero,
        ),
      );
      await remoteConfig.fetchAndActivate();
      final url = remoteConfig.getString('emotion_backend_url');
      if (url.isNotEmpty) {
        return url;
      }
    } catch (e) {
      logDiagnostic("Firebase Remote Config fetch skipped/failed: $e");
    }
    return null;
  }

  Future<List<String>> _discoverSubnetIps() async {
    final List<String> ips = [];
    try {
      final List<NetworkInterface> interfaces = await NetworkInterface.list(
        includeLoopback: false,
        type: InternetAddressType.IPv4,
      );

      final List<String> subnets = [];
      for (final interface in interfaces) {
        for (final addr in interface.addresses) {
          final ip = addr.address;
          final parts = ip.split('.');
          if (parts.length == 4) {
            final subnetPrefix = '${parts[0]}.${parts[1]}.${parts[2]}.';
            if (!subnets.contains(subnetPrefix)) {
              subnets.add(subnetPrefix);
            }
          }
        }
      }

      // High-priority targets: host 1, 2, 254
      for (final subnet in subnets) {
        for (final host in [1, 2, 254]) {
          ips.add('$subnet$host');
        }
      }

      // Low priority targets: rest of subnet hosts
      for (final subnet in subnets) {
        for (int i = 3; i < 254; i++) {
          if (i != 254) {
            ips.add('$subnet$i');
          }
        }
      }
    } catch (e) {
      logDiagnostic("Subnet enumeration failed: $e");
    }
    return ips;
  }

  Future<String?> _discoverActiveEndpoint(
    List<String> urls,
    Duration timeout,
  ) async {
    logDiagnostic("Probing ${urls.length} discovery candidates for health...");

    const batchSize = 10;
    for (int i = 0; i < urls.length; i += batchSize) {
      final end = (i + batchSize < urls.length) ? i + batchSize : urls.length;
      final batch = urls.sublist(i, end);

      final results = await Future.wait(
        batch.map((url) async {
          try {
            final uri = Uri.parse(url);
            final host = uri.host;
            final isLocalIp =
                host == 'localhost' ||
                host == '127.0.0.1' ||
                host == '10.0.2.2' ||
                host.startsWith('192.168.') ||
                host.startsWith('10.') ||
                host.startsWith('172.');

            if (!isLocalIp || uri.scheme == 'https') {
              // Bypass TCP probe for public/HTTPS URLs, run HTTP /health check directly
              logDiagnostic(
                "Bypassing TCP probe for public domain/HTTPS candidate: $url",
              );
              final successState = await _checkUrlHealth(url, timeout: timeout);
              if (successState != null) {
                return url;
              }
            } else {
              // Fast TCP probe (300ms timeout) for local IP discovery candidates
              final port = uri.port != 0 ? uri.port : 5000;
              final socket = await Socket.connect(
                host,
                port,
                timeout: const Duration(milliseconds: 300),
              );
              socket.destroy();

              // HTTP health check immediately if TCP probe succeeded
              final successState = await _checkUrlHealth(
                url,
                timeout: const Duration(seconds: 5),
              );
              if (successState != null) {
                return url;
              }
            }
          } catch (_) {}
          return null;
        }),
      );

      for (final foundUrl in results) {
        if (foundUrl != null) {
          logDiagnostic("Discovered active healthy endpoint: $foundUrl");
          return foundUrl;
        }
      }
    }
    return null;
  }

  Future<EmotionHealthState?> _checkUrlHealth(
    String url, {
    required Duration timeout,
  }) async {
    final startTime = DateTime.now();
    try {
      logDiagnostic("Verifying HTTP /health at $url...");
      final response = await _dio!.get(
        '$url/health',
        options: Options(
          connectTimeout: timeout,
          receiveTimeout: timeout,
          sendTimeout: timeout,
        ),
      );

      final latency = DateTime.now().difference(startTime).inMilliseconds;
      if (response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300 &&
          response.data != null) {
        final data = response.data;
        if (data is Map) {
          final isModelLoaded = data['model_loaded'] ?? true;
          final statusStr = data['status']?.toString().toLowerCase() ?? '';
          if (isModelLoaded == false || statusStr == 'starting') {
            logDiagnostic("Server is starting up (model not ready yet).");
            throw const FormatException("Model not ready");
          }
          if ((data['status'] == 'healthy' || data['status'] == 'online') &&
              data['service'] == 'MeetingMind Emotion API') {
            final version = data['version']?.toString() ?? '1.0.0';

            // Format uptime nicely if it is a number of seconds
            final rawUptime = data['uptime'];
            String uptimeStr = 'Unknown';
            if (rawUptime != null) {
              if (rawUptime is num) {
                final totalSeconds = rawUptime.toInt();
                final hours = totalSeconds ~/ 3600;
                final minutes = (totalSeconds % 3600) ~/ 60;
                final seconds = totalSeconds % 60;
                if (hours > 0) {
                  uptimeStr = '${hours}h ${minutes}m ${seconds}s';
                } else if (minutes > 0) {
                  uptimeStr = '${minutes}m ${seconds}s';
                } else {
                  uptimeStr = '${seconds}s';
                }
              } else {
                uptimeStr = rawUptime.toString();
              }
            }

            return EmotionHealthState(
              status: EmotionBackendStatus.online,
              activeUrl: url,
              responseTimeMs: latency,
              retryAttempt: 0,
              retryCountdown: 0,
              errorMessage: null,
              serverVersion: version,
              deviceType: state.deviceType,
              lastSuccessTime: state.lastSuccessTime,
              uptime: uptimeStr,
              connectionHistory: List.unmodifiable(_diagnosticsLog),
            );
          }
        }
      }
      logDiagnostic(
        "Invalid /health response from $url: ${response.statusCode} - ${response.data}",
      );
    } catch (e) {
      logDiagnostic(
        "HTTP /health check failed for $url: ${_parseException(url, e)}",
      );
    }
    return null;
  }

  Future<void> checkConnection({bool isPassive = false}) async {
    if (_isChecking) return;
    _isChecking = true;

    _heartbeatTimer?.cancel();
    _countdownTimer?.cancel();
    _passiveProbeTimer?.cancel();

    logDiagnostic("Starting connection check (passive: $isPassive)...");

    if (!isPassive) {
      state = state.copyWith(
        status: EmotionBackendStatus.checking,
        retryAttempt: 1,
        errorMessage: null,
      );
    }

    try {
      final maxAttempts = isPassive ? 1 : 12; // 12 attempts
      final backoffDelays = [
        3,
        5,
        7,
        15,
        30,
      ]; // Delay BEFORE Attempt 2, 3, 4, 5, 6 is delays[attempt-1]

      for (int attempt = 1; attempt <= maxAttempts; attempt++) {
        if (!isPassive) {
          state = state.copyWith(
            status: EmotionBackendStatus.checking,
            retryAttempt: attempt,
            retryCountdown: 0,
          );
        }

        // Check network connectivity first
        final connectivityResult = await _connectivity.checkConnectivity();
        final hasInternet = connectivityResult.any(
          (r) => r != ConnectivityResult.none,
        );
        if (!hasInternet) {
          logDiagnostic("No internet connection detected.");
          if (!isPassive) {
            state = state.copyWith(
              status: EmotionBackendStatus.noInternet,
              retryAttempt: attempt,
              errorMessage:
                  "No internet connection. Please check your Wi-Fi or mobile data.",
            );
          }
          if (attempt < maxAttempts) {
            // Determine delay for next attempt
            int baseDelay = 60;
            if (attempt <= backoffDelays.length) {
              baseDelay = backoffDelays[attempt - 1];
            }
            final jitter = Random().nextInt(4); // 0 to 3 seconds
            final delay = baseDelay + jitter;

            logDiagnostic(
              "No Internet. Retrying attempt #${attempt + 1} in $delay seconds (jitter: $jitter)...",
            );

            for (int c = delay; c > 0; c--) {
              if (!isPassive) {
                state = state.copyWith(retryCountdown: c);
              }
              await Future.delayed(const Duration(seconds: 1));
            }
            continue;
          } else {
            break;
          }
        }

        final candidates = await _getDiscoveryCandidates();
        if (candidates.isEmpty) {
          logDiagnostic("No backend candidates resolved.");
          if (!isPassive) {
            state = state.copyWith(
              status: EmotionBackendStatus.offline,
              retryAttempt: attempt,
              errorMessage: "No valid backend URL configured.",
            );
          }
          break;
        }

        String? resolvedUrl;
        EmotionHealthState? successState;
        String? lastErrorMsg;
        bool isWaking = false;
        bool is404 = false;

        try {
          resolvedUrl = await _discoverActiveEndpoint(
            candidates,
            const Duration(seconds: 20),
          );
          if (resolvedUrl != null) {
            successState = await _checkUrlHealth(
              resolvedUrl,
              timeout: const Duration(seconds: 20),
            );
          }
        } catch (e) {
          logDiagnostic("Endpoint discovery error: $e");
        }

        if (successState != null && resolvedUrl != null) {
          final timeStr = DateTime.now().toLocal().toString().split('.')[0];

          await _secureStorage.write(
            key: 'last_success_backend_url',
            value: resolvedUrl,
          );
          await _secureStorage.write(
            key: 'last_success_connection_time',
            value: timeStr,
          );

          state = successState.copyWith(
            lastSuccessTime: timeStr,
            status: EmotionBackendStatus.online,
          );

          logDiagnostic(
            "Backend ONLINE at $resolvedUrl (Latency: ${state.responseTimeMs}ms, Version: ${state.serverVersion})",
          );

          _startHeartbeat();
          return;
        }

        // Failure logic: classify error for primary candidate
        final primaryUrl = candidates.first;
        try {
          final response = await _dio!.get(
            '$primaryUrl/health',
            options: Options(
              connectTimeout: const Duration(seconds: 20),
              receiveTimeout: const Duration(seconds: 20),
              sendTimeout: const Duration(seconds: 20),
            ),
          );
          lastErrorMsg =
              "Server returned ${response.statusCode} with invalid body.";
        } catch (e) {
          lastErrorMsg = _parseException(primaryUrl, e);
          if (e is DioException) {
            final code = e.response?.statusCode;
            if (code == 502 || code == 503 || code == 504) {
              isWaking = true;
            } else if (code == 404) {
              is404 = true;
            } else if (e.type == DioExceptionType.connectionTimeout ||
                e.type == DioExceptionType.receiveTimeout ||
                e.type == DioExceptionType.sendTimeout) {
              isWaking = true;
            }
          } else if (e is FormatException && e.message == "Model not ready") {
            isWaking = true;
          }
        }

        // Calculate backoff delay with jitter
        int baseDelay = 60;
        if (attempt <= backoffDelays.length) {
          baseDelay = backoffDelays[attempt - 1];
        }
        final jitter = Random().nextInt(4); // 0 to 3 seconds
        final currentDelay = baseDelay + jitter;

        if (!isPassive) {
          EmotionBackendStatus nextStatus;
          String displayMsg;
          if (isWaking) {
            nextStatus = EmotionBackendStatus.wakingServer;
            displayMsg = "Cloud server is starting. Retrying automatically...";
          } else if (is404) {
            nextStatus = EmotionBackendStatus.offline;
            displayMsg =
                "/health endpoint not found. Verify backend configuration.";
          } else {
            nextStatus = EmotionBackendStatus.offline;
            displayMsg = lastErrorMsg;
          }

          state = state.copyWith(
            status: nextStatus,
            retryAttempt: attempt,
            retryCountdown: attempt < maxAttempts ? currentDelay : 0,
            errorMessage: displayMsg,
          );
        }

        if (attempt < maxAttempts) {
          logDiagnostic(
            "Attempt #$attempt failed. Retrying in $currentDelay seconds...",
          );
          for (int c = currentDelay; c > 0; c--) {
            if (!isPassive) {
              state = state.copyWith(retryCountdown: c);
            }
            await Future.delayed(const Duration(seconds: 1));
          }
          if (!isPassive) {
            state = state.copyWith(retryCountdown: 0);
          }
        }
      }

      if (!isPassive && state.status != EmotionBackendStatus.online) {
        state = state.copyWith(
          status: EmotionBackendStatus.offline,
          retryCountdown: 0,
          errorMessage:
              state.errorMessage ?? "Unable to connect to the emotion service.",
        );
      }
    } catch (e) {
      logDiagnostic("Connection check loop error: $e");
    } finally {
      _isChecking = false;
    }
  }

  void setStatus(EmotionBackendStatus status) {
    logDiagnostic("Externally setting status: $status");
    state = state.copyWith(status: status);
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _passiveProbeTimer?.cancel();

    _heartbeatTimer = Timer.periodic(const Duration(seconds: 30), (
      timer,
    ) async {
      logDiagnostic("Sending heartbeat ping to ${state.activeUrl}/health...");
      final healthState = await _checkUrlHealth(
        state.activeUrl,
        timeout: const Duration(seconds: 15),
      );
      if (healthState != null) {
        state = state.copyWith(
          status: EmotionBackendStatus.online,
          responseTimeMs: healthState.responseTimeMs,
          uptime: healthState.uptime,
          serverVersion: healthState.serverVersion,
        );
        logDiagnostic(
          "Heartbeat response OK (Latency: ${state.responseTimeMs}ms)",
        );
      } else {
        logDiagnostic("Heartbeat failed. Backend went offline.");
        timer.cancel();
        state = state.copyWith(
          status: EmotionBackendStatus.degraded,
          activeUrl: '',
        );
        checkConnection();
      }
    });
  }

  void handleAppPaused() {
    logDiagnostic("App paused. Suspending active timers...");
    _heartbeatTimer?.cancel();
    _countdownTimer?.cancel();
    _passiveProbeTimer?.cancel();
  }

  void handleAppResumed() {
    logDiagnostic("App resumed. Restarting connection check...");
    checkConnection();
  }

  String _parseException(String url, dynamic e) {
    if (e is DioException) {
      final code = e.response?.statusCode;
      switch (e.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.receiveTimeout:
        case DioExceptionType.sendTimeout:
          return "Connection timeout: Server did not respond within 20 seconds.";
        case DioExceptionType.badResponse:
          if (code == 404) {
            return "HTTP 404 Route mismatch: Verify backend endpoints.";
          } else if (code == 500) {
            return "Internal Server Error (HTTP 500) at $url.";
          } else if (code == 502 || code == 503 || code == 504) {
            return "Temporary hosting issue (HTTP $code): Server is down or restarting.";
          }
          return "HTTP error $code: ${e.response?.statusMessage ?? 'Invalid response'}.";
        case DioExceptionType.connectionError:
          final errStr = e.error.toString();
          if (errStr.contains("Connection refused") || errStr.contains("111")) {
            return "Connection refused: Server is waking up or not running on port.";
          }
          if (errStr.contains("Failed host lookup")) {
            return "DNS lookup failure: Check your network connectivity.";
          }
          if (errStr.contains("HandshakeException") ||
              errStr.contains("CERTIFICATE_VERIFY_FAILED")) {
            return "SSL handshake failure: Secure connection failed.";
          }
          return "Connection error: $errStr";
        default:
          return "Network error: ${e.message}";
      }
    }
    final errStr = e.toString();
    if (errStr.contains("SocketException")) {
      if (errStr.contains("Connection refused")) {
        return "Connection refused: Server port is closed.";
      }
      return "Network socket exception: Host unreachable.";
    }
    if (e is FormatException) {
      if (e.message == "Model not ready") {
        return "Model not ready: Cold start loading progress in background.";
      }
      return "JSON parsing error: Response was not valid JSON.";
    }
    return "Error: $errStr";
  }

  void dispose() {
    _connectivitySubscription?.cancel();
    _heartbeatTimer?.cancel();
    _countdownTimer?.cancel();
    _passiveProbeTimer?.cancel();
    _flaskProcess?.kill();
    stateNotifier.dispose();
  }
}
