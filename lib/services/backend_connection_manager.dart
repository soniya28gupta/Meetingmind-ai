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
  int _connectionAttempts = 0;
  bool _isInitialized = false;

  dynamic _lastException;
  int? _lastStatusCode;
  DateTime? _firstAttemptTime;

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
        final isLocal = host == 'localhost' ||
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

    if (isProdOrRelease) {
      final prodUrl = _formatUrl(BackendConfig.configuredUrl);
      logDiagnostic("Production/Release mode active. Central URL candidate: $prodUrl");
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

  Future<String?> _discoverActiveEndpoint(List<String> urls, Duration timeout) async {
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
              final successState = await _checkUrlHealth(url, timeout: const Duration(seconds: 5));
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

  Future<EmotionHealthState?> _checkUrlHealth(String url, {required Duration timeout}) async {
    final startTime = DateTime.now();
    _lastException = null;
    _lastStatusCode = null;
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
          response.statusCode! < 300) {
        final data = response.data;
        String version = '1.0.0';
        String uptimeStr = 'N/A';
        
        if (data is Map) {
          version = data['version']?.toString() ?? '1.0.0';
          
          final isModelLoaded = data['model_loaded'] ?? true;
          final statusStr = data['status']?.toString().toLowerCase() ?? '';
          if (isModelLoaded == false || statusStr == 'starting') {
            logDiagnostic("Server is starting up (model not ready yet).");
            throw const FormatException("Model not ready");
          }

          final rawUptime = data['uptime'];
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
      logDiagnostic(
        "Invalid /health response from $url: ${response.statusCode} - ${response.data}",
      );
    } catch (e) {
      _lastException = e;
      if (e is DioException) {
        _lastStatusCode = e.response?.statusCode;
      }
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
      // Reset attempts if the current state is offline or we previously reached max retries.
      if (state.status == EmotionBackendStatus.offline ||
          state.status == EmotionBackendStatus.unknown ||
          _connectionAttempts >= 6) {
        _connectionAttempts = 0;
        logDiagnostic("Resetting connection attempt count to 0.");
      }

      if (_connectionAttempts == 0) {
        _firstAttemptTime = DateTime.now();
      }

      state = state.copyWith(
        status: EmotionBackendStatus.checking,
        retryAttempt: _connectionAttempts + 1,
        errorMessage: null,
      );
    }

    final isCurrentlyOnline = state.status == EmotionBackendStatus.online;
    final timeout = isCurrentlyOnline ? const Duration(seconds: 15) : const Duration(seconds: 120);

    Timer? slowCheckTimer;
    if (!isPassive && !isCurrentlyOnline) {
      slowCheckTimer = Timer(const Duration(seconds: 3), () {
        if (_isChecking && state.status == EmotionBackendStatus.checking) {
          state = state.copyWith(
            status: EmotionBackendStatus.wakingServer,
            errorMessage: "Cloud server is waking up. Please wait...",
          );
        }
      });
    }

    try {
      // 1. Generate discovery candidates
      final candidates = await _getDiscoveryCandidates();

      // If candidates list is empty, handle failure directly
      if (candidates.isEmpty) {
        logDiagnostic("No backend candidates resolved.");
        slowCheckTimer?.cancel();
        _handleFailure(isPassive, errorMsg: "No valid backend URL configured.");
        _isChecking = false;
        return;
      }

      // Check network connectivity first
      final connectivityResult = await _connectivity.checkConnectivity();
      final hasInternet = connectivityResult.any((r) => r != ConnectivityResult.none);
      if (!hasInternet) {
        logDiagnostic("No internet connection detected.");
        slowCheckTimer?.cancel();
        _handleFailure(isPassive, errorMsg: "No internet connection. Please check your Wi-Fi or mobile data.");
        _isChecking = false;
        return;
      }

      // 2. Discover active healthy endpoint
      final resolvedUrl = await _discoverActiveEndpoint(candidates, timeout);

      slowCheckTimer?.cancel();

      if (resolvedUrl != null) {
        // 3. Verify HTTP health
        final successState = await _checkUrlHealth(resolvedUrl, timeout: timeout);
        if (successState != null) {
          final timeStr = DateTime.now().toLocal().toString().split('.')[0];
          _connectionAttempts = 0;
          _firstAttemptTime = null;

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
          _isChecking = false;
          return;
        }
      }

      _handleFailure(isPassive);
    } catch (e) {
      logDiagnostic("Connection check error: $e");
      slowCheckTimer?.cancel();
      _handleFailure(isPassive);
    } finally {
      _isChecking = false;
    }
  }

  void setStatus(EmotionBackendStatus status) {
    logDiagnostic("Externally setting status: $status");
    state = state.copyWith(status: status);
  }

  void _handleFailure(bool isPassive, {String? errorMsg}) {
    if (isPassive) {
      logDiagnostic(
        "Passive background probe failed. Backend remains offline.",
      );
      return;
    }

    _connectionAttempts++;
    logDiagnostic("Connection attempt #$_connectionAttempts failed.");

    // Determine the next status and error message based on the last exception
    EmotionBackendStatus nextStatus = EmotionBackendStatus.offline;
    String displayMsg = errorMsg ?? "Unable to connect to the emotion service.";

    final e = _lastException;
    final code = _lastStatusCode;

    bool isWaking = false;

    if (e != null) {
      final parsedError = _parseException(
        state.activeUrl.isNotEmpty ? state.activeUrl : BackendConfig.configuredUrl,
        e,
      );
      displayMsg = parsedError;

      if (e is DioException) {
        if (code == 502 || code == 503 || code == 504) {
          isWaking = true;
          displayMsg = "Cloud server is waking up. Please wait...\nTemporary hosting issue (HTTP $code).";
        } else if (code == 404) {
          nextStatus = EmotionBackendStatus.offline;
          displayMsg = "HTTP 404: Health endpoint is incorrect. Please verify backend routes.";
        } else if (e.type == DioExceptionType.connectionTimeout || 
                   e.type == DioExceptionType.receiveTimeout || 
                   e.type == DioExceptionType.sendTimeout) {
          if (_connectionAttempts <= 2) {
            isWaking = true;
            displayMsg = "Cloud server is waking up. Please wait...\nConnection timeout.";
          } else {
            displayMsg = "Connection timeout: Server did not respond within 120 seconds.";
          }
        } else if (e.type == DioExceptionType.connectionError) {
          final errStr = e.error.toString().toLowerCase();
          if (errStr.contains("connection refused") || errStr.contains("111")) {
            if (_connectionAttempts <= 2) {
              isWaking = true;
              displayMsg = "Cloud server is waking up. Please wait...\nConnection refused (Server is starting up).";
            } else {
              displayMsg = "Connection refused: Server is waking up or not running on port.";
            }
          }
        }
      } else if (e is FormatException) {
        if (e.message == "Model not ready") {
          isWaking = true;
          displayMsg = "Cloud server is waking up. Please wait...\nModel loading progress in background.";
        }
      }
    }

    if (isWaking) {
      nextStatus = EmotionBackendStatus.wakingServer;
    } else {
      if (_connectionAttempts <= 4) {
        nextStatus = EmotionBackendStatus.degraded;
      } else {
        nextStatus = EmotionBackendStatus.offline;
      }
    }

    // Check maximum automatic waiting period of approximately 2 minutes (120 seconds)
    final totalElapsed = _firstAttemptTime != null 
        ? DateTime.now().difference(_firstAttemptTime!).inSeconds 
        : 0;

    if (totalElapsed >= 120) {
      logDiagnostic("Reached maximum automatic waiting period of 2 minutes ($totalElapsed seconds). Stopping automatic retries.");
      state = state.copyWith(
        status: EmotionBackendStatus.offline,
        activeUrl: '',
        retryAttempt: _connectionAttempts,
        retryCountdown: 0,
        errorMessage: displayMsg.contains("timeout") 
            ? "Connection timeout: Server did not respond within 120 seconds.\nTap Retry to reconnect."
            : "$displayMsg\nTap Retry to reconnect.",
      );
      _firstAttemptTime = null;
      return;
    }

    const delaySeconds = 5; // Retry automatically every 5 seconds per Task 8!
    logDiagnostic(
      "Scheduling automatic retry attempt #${_connectionAttempts + 1} in $delaySeconds seconds...",
    );

    state = state.copyWith(
      status: nextStatus,
      activeUrl: '',
      retryAttempt: _connectionAttempts,
      retryCountdown: delaySeconds,
      errorMessage: displayMsg,
    );

    _startCountdown(delaySeconds);
  }

  void _startCountdown(int seconds) {
    _countdownTimer?.cancel();
    int current = seconds;
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      current--;
      if (current <= 0) {
        timer.cancel();
        state = state.copyWith(retryCountdown: 0);
        checkConnection();
      } else {
        state = state.copyWith(retryCountdown: current);
      }
    });
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _passiveProbeTimer?.cancel();

    _heartbeatTimer = Timer.periodic(const Duration(seconds: 30), (
      timer,
    ) async {
      logDiagnostic("Sending heartbeat ping to ${state.activeUrl}/health...");
      final healthState = await _checkUrlHealth(state.activeUrl, timeout: const Duration(seconds: 15));
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
        _connectionAttempts = 0;
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
    final healthCheckUrl = "$url/health";
    if (e is DioException) {
      final code = e.response?.statusCode;
      final typeStr = e.type.toString().split('.').last;
      
      switch (e.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.receiveTimeout:
        case DioExceptionType.sendTimeout:
          return "Connection timeout [$typeStr] at $healthCheckUrl: Server did not respond within 120 seconds.";
        case DioExceptionType.badResponse:
          if (code == 404) {
            return "HTTP 404 Not Found at $healthCheckUrl: Health endpoint is incorrect.";
          } else if (code == 500) {
            return "Internal Server Error (HTTP 500) at $healthCheckUrl.";
          } else if (code == 502 || code == 503 || code == 504) {
            return "Temporary hosting issue (HTTP $code) at $healthCheckUrl: Server is waking up, down, or restarting.";
          }
          return "HTTP error $code (${e.response?.statusMessage ?? 'Bad Response'}) at $healthCheckUrl.";
        case DioExceptionType.connectionError:
          final errStr = e.error.toString();
          if (errStr.contains("Connection refused") || errStr.contains("111")) {
            return "Connection refused [ConnectionError] at $healthCheckUrl: Server is starting up or port is closed.";
          }
          if (errStr.contains("Failed host lookup")) {
            return "DNS lookup failure [ConnectionError] at $healthCheckUrl: Check your internet connection.";
          }
          if (errStr.contains("HandshakeException") ||
              errStr.contains("CERTIFICATE_VERIFY_FAILED")) {
            return "SSL handshake failure [ConnectionError] at $healthCheckUrl: Secure connection could not be established.";
          }
          return "Connection error ($errStr) at $healthCheckUrl.";
        default:
          return "Network error [${e.type}] at $healthCheckUrl: ${e.message}";
      }
    }
    final errStr = e.toString();
    if (errStr.contains("SocketException")) {
      if (errStr.contains("Connection refused")) {
        return "Connection refused [SocketException] at $healthCheckUrl: Server port is closed.";
      }
      return "Network socket exception [SocketException] at $healthCheckUrl: Host is unreachable.";
    }
    if (e is FormatException) {
      if (e.message == "Model not ready") {
        return "Model not ready [FormatException] at $healthCheckUrl: Cold start loading progress in background.";
      }
      return "JSON parsing error [FormatException] at $healthCheckUrl: Response was not valid JSON.";
    }
    return "Error [${e.runtimeType}] at $healthCheckUrl: $errStr";
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
