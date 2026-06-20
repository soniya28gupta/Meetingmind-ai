import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_providers.dart';

enum EmotionBackendStatus {
  connected,
  reconnecting,
  offline,
  analyzing,
  processing,
  retrying,
  fallbackActive,
}

class EmotionHealthState {
  final EmotionBackendStatus status;
  final String activeUrl;
  final int responseTimeMs;
  final int retryAttempt;
  final String? errorMessage;

  EmotionHealthState({
    required this.status,
    required this.activeUrl,
    this.responseTimeMs = 0,
    this.retryAttempt = 0,
    this.errorMessage,
  });

  EmotionHealthState copyWith({
    EmotionBackendStatus? status,
    String? activeUrl,
    int? responseTimeMs,
    int? retryAttempt,
    String? errorMessage,
  }) {
    return EmotionHealthState(
      status: status ?? this.status,
      activeUrl: activeUrl ?? this.activeUrl,
      responseTimeMs: responseTimeMs ?? this.responseTimeMs,
      retryAttempt: retryAttempt ?? this.retryAttempt,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class EmotionHealthManager extends StateNotifier<EmotionHealthState> {
  final Ref _ref;
  Timer? _healthTimer;
  bool _isChecking = false;
  bool _inRetryLoop = false;
  Process? _flaskProcess;

  EmotionHealthManager(this._ref)
      : super(EmotionHealthState(
          status: EmotionBackendStatus.offline,
          activeUrl: '',
        )) {
    _initAndStart();
  }

  void _initAndStart() async {
    if (Platform.isWindows) {
      await _startProcessOnWindows();
    }
    _startMonitoring();
  }

  Future<void> _startProcessOnWindows() async {
    try {
      final file = File('lib/services/backend/app.py');
      if (await file.exists()) {
        print('[EmotionHealthService] Spawning Python backend...');
        _flaskProcess = await Process.start(
          'python',
          ['lib/services/backend/app.py'],
          runInShell: true,
        );
        // Handle process exit to restart automatically
        _flaskProcess?.exitCode.then((code) {
          print('[EmotionHealthService] Python backend exited with code $code. Restarting...');
          if (state.status != EmotionBackendStatus.offline) {
            _startProcessOnWindows();
          }
        });
      }
    } catch (e) {
      print('[EmotionHealthService] Failed to start Python backend on Windows: $e');
    }
  }

  void _startMonitoring() {
    _healthTimer?.cancel();
    checkConnection(isPassive: false);
    _healthTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      checkConnection(isPassive: true);
    });
  }

  Dio get _dio => _ref.read(dioProvider);

  void setStatus(EmotionBackendStatus status) {
    state = state.copyWith(status: status);
  }

  Future<void> checkConnection({bool isPassive = false}) async {
    if (_isChecking) return;
    _isChecking = true;

    final startTime = DateTime.now();
    try {
      String targetUrl = state.activeUrl;
      if (targetUrl.isEmpty) {
        final host = await discoverPCNetworkIP();
        if (host != null) {
          targetUrl = 'http://$host:5000';
        } else {
          // Default fallbacks based on environment
          if (Platform.isAndroid) {
            targetUrl = 'http://10.0.2.2:5000'; // Default emulator
          } else {
            targetUrl = 'http://127.0.0.1:5000';
          }
        }
      }

      final response = await _dio.get(
        '$targetUrl/health',
        options: Options(
          connectTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 5),
        ),
      );

      final latency = DateTime.now().difference(startTime).inMilliseconds;
      if (response.statusCode == 200) {
        _inRetryLoop = false;
        state = EmotionHealthState(
          status: EmotionBackendStatus.connected,
          activeUrl: targetUrl,
          responseTimeMs: latency,
        );
      } else {
        throw Exception("Server returned HTTP ${response.statusCode}");
      }
    } catch (e) {
      if (isPassive) {
        print("[EmotionHealthService] Passive check failed: $e. No retry loop triggered.");
        // Maintain active URL but set status to fallbackActive or offline
        state = state.copyWith(
          status: EmotionBackendStatus.offline,
          errorMessage: e.toString(),
        );
      } else {
        _handleFailure(e.toString());
      }
    } finally {
      _isChecking = false;
    }
  }

  Future<void> _handleFailure(String error) async {
    if (_inRetryLoop) return;
    _inRetryLoop = true;

    print("[EmotionHealthService] Connection failure. Retrying with exponential backoff. Root cause: $error");
    
    // retry intervals: 1s, 2s, 4s
    final List<int> retryIntervals = [1, 2, 4];
    
    for (int i = 0; i < retryIntervals.length; i++) {
      final delay = retryIntervals[i];
      state = state.copyWith(
        status: EmotionBackendStatus.retrying,
        retryAttempt: i + 1,
        errorMessage: "Reconnecting (Attempt ${i + 1}/3) in $delay seconds...",
      );
      
      await Future.delayed(Duration(seconds: delay));
      
      // Probe dynamically again
      final host = await discoverPCNetworkIP();
      final targetUrl = host != null ? 'http://$host:5000' : state.activeUrl;

      try {
        final startTime = DateTime.now();
        final response = await _dio.get(
          '$targetUrl/health',
          options: Options(
            connectTimeout: const Duration(seconds: 5),
            receiveTimeout: const Duration(seconds: 5),
          ),
        );
        if (response.statusCode == 200) {
          final latency = DateTime.now().difference(startTime).inMilliseconds;
          _inRetryLoop = false;
          state = EmotionHealthState(
            status: EmotionBackendStatus.connected,
            activeUrl: targetUrl,
            responseTimeMs: latency,
          );
          print("[EmotionHealthService] Reconnected successfully!");
          return;
        }
      } catch (_) {}
    }

    _inRetryLoop = false;
    state = state.copyWith(
      status: EmotionBackendStatus.fallbackActive,
      errorMessage: "All 3 reconnect attempts failed. Root cause error: $error",
    );
    print("[EmotionHealthService] All 3 reconnect attempts failed. Offline/Fallback mode active. Error: $error");
  }

  Future<String?> discoverPCNetworkIP() async {
    try {
      final List<String> candidates = [];
      candidates.add('127.0.0.1');
      candidates.add('10.0.2.2'); // Standard Android Emulator
      candidates.add('10.0.3.2'); // Genymotion

      // List interfaces
      final List<NetworkInterface> interfaces = await NetworkInterface.list(
        includeLoopback: false,
        type: InternetAddressType.IPv4,
      );

      for (final interface in interfaces) {
        for (final addr in interface.addresses) {
          final ip = addr.address;
          final parts = ip.split('.');
          if (parts.length == 4) {
            final prefix = '${parts[0]}.${parts[1]}.${parts[2]}.';
            // Prioritize standard gateway/host addresses
            if (!candidates.contains('${prefix}1')) candidates.add('${prefix}1');
            if (!candidates.contains('${prefix}2')) candidates.add('${prefix}2');
            if (!candidates.contains('${prefix}254')) candidates.add('${prefix}254');
          }
        }
      }

      print("[EmotionHealthService] Probing ${candidates.length} candidates on port 5000: $candidates");

      // Parallel batch probing with robust 1000ms timeout
      final results = await Future.wait(candidates.map((ip) async {
        try {
          final socket = await Socket.connect(
            ip,
            5000,
            timeout: const Duration(milliseconds: 1000),
          );
          socket.destroy();
          return ip;
        } catch (_) {
          return null;
        }
      }));

      for (final res in results) {
        if (res != null) {
          print("[EmotionHealthService] Discovered Flask host IP: $res");
          return res;
        }
      }
    } catch (e) {
      print("[EmotionHealthService] Subnet discovery failed: $e");
    }
    return null;
  }

  @override
  void dispose() {
    _healthTimer?.cancel();
    _flaskProcess?.kill();
    super.dispose();
  }
}

final emotionHealthServiceProvider = StateNotifierProvider<EmotionHealthManager, EmotionHealthState>((ref) {
  return EmotionHealthManager(ref);
});
