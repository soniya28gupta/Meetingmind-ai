import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/settings/settings_provider.dart';
import '../providers/app_providers.dart';

enum OllamaConnectionStatus {
  connected,
  reconnecting,
  offline,
  waitingForOllama,
}

class OllamaConnectionState {
  final OllamaConnectionStatus status;
  final String activeUrl;
  final int responseTimeMs;
  final String? activeModel;
  final String? errorMessage;

  OllamaConnectionState({
    required this.status,
    required this.activeUrl,
    this.responseTimeMs = 0,
    this.activeModel,
    this.errorMessage,
  });

  OllamaConnectionState copyWith({
    OllamaConnectionStatus? status,
    String? activeUrl,
    int? responseTimeMs,
    String? activeModel,
    String? errorMessage,
  }) {
    return OllamaConnectionState(
      status: status ?? this.status,
      activeUrl: activeUrl ?? this.activeUrl,
      responseTimeMs: responseTimeMs ?? this.responseTimeMs,
      activeModel: activeModel ?? this.activeModel,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class OllamaConnectionManager extends StateNotifier<OllamaConnectionState> {
  final Ref _ref;
  Timer? _keepAliveTimer;
  bool _isChecking = false;
  bool _inRetryLoop = false;
  final List<int> _retryIntervals = [2, 5, 10, 20, 30];

  OllamaConnectionManager(this._ref)
    : super(
        OllamaConnectionState(
          status: OllamaConnectionStatus.offline,
          activeUrl: '',
        ),
      ) {
    // Start keeping connection alive automatically
    _startMonitoring();
  }

  void _startMonitoring() {
    _keepAliveTimer?.cancel();
    _checkConnection();
    _keepAliveTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _checkConnection();
    });
  }

  @override
  void dispose() {
    _keepAliveTimer?.cancel();
    super.dispose();
  }

  Dio get _dio => _ref.read(dioProvider);

  /// Triggers a manual instantaneous check and returns the fresh state
  Future<OllamaConnectionState> verifyHealth() async {
    await _checkConnection();
    return state;
  }

  Future<void> _checkConnection() async {
    if (_isChecking) return;
    _isChecking = true;

    final settings = _ref.read(settingsProvider);
    String targetUrl = settings.ollamaUrl;
    final targetModel = settings.ollamaModel;

    final startTime = DateTime.now();
    try {
      if (targetUrl.isEmpty) {
        state = state.copyWith(
          status: OllamaConnectionStatus.reconnecting,
          errorMessage: "No configuration found. Discovering Ollama...",
        );
        final host = await discoverPCNetworkIP();
        if (host != null) {
          targetUrl = 'http://$host:11434';
          await _ref.read(settingsProvider.notifier).saveOllamaUrl(targetUrl);
        } else {
          throw Exception("Ollama server not found on local network.");
        }
      }

      final response = await _dio.get('$targetUrl/api/tags');
      final latency = DateTime.now().difference(startTime).inMilliseconds;

      if (response.statusCode == 200) {
        final data = response.data;
        List<String> models = [];
        if (data is Map && data['models'] is List) {
          for (var m in data['models']) {
            if (m is Map && m['name'] != null) {
              models.add(m['name'].toString());
            }
          }
        }

        if (models.isEmpty) {
          state = state.copyWith(
            status: OllamaConnectionStatus.waitingForOllama,
            activeUrl: targetUrl,
            responseTimeMs: latency,
            errorMessage: "Server Running. No models loaded.",
          );
          _handleFailure("No models loaded on Ollama.");
          return;
        }

        final hasModel = models.any(
          (m) => m == targetModel || m.startsWith('$targetModel:'),
        );
        if (!hasModel) {
          state = state.copyWith(
            status: OllamaConnectionStatus.waitingForOllama,
            activeUrl: targetUrl,
            responseTimeMs: latency,
            activeModel: models.join(', '),
            errorMessage:
                "Model '$targetModel' missing. Loaded: ${models.join(', ')}",
          );
          _handleFailure("Model '$targetModel' not loaded on Ollama.");
          return;
        }

        // Connection healthy!
        _inRetryLoop = false;
        state = OllamaConnectionState(
          status: OllamaConnectionStatus.connected,
          activeUrl: targetUrl,
          responseTimeMs: latency,
          activeModel: targetModel,
        );
      } else {
        throw Exception("Server returned HTTP ${response.statusCode}");
      }
    } catch (e) {
      _handleFailure(e.toString());
    } finally {
      _isChecking = false;
    }
  }

  Future<void> _handleFailure(String error) async {
    if (_inRetryLoop) return;
    _inRetryLoop = true;

    print(
      "[OllamaConnectionManager] Connection failure detected. Starting auto-reconnect strategy...",
    );
    state = state.copyWith(
      status: OllamaConnectionStatus.reconnecting,
      errorMessage: error,
    );

    for (int i = 0; i < _retryIntervals.length; i++) {
      final delay = _retryIntervals[i];
      print(
        "[OllamaConnectionManager] Retrying in $delay seconds (attempt ${i + 1}/${_retryIntervals.length})...",
      );
      await Future.delayed(Duration(seconds: delay));

      // Attempt dynamic discovery to handle environment/IP modifications
      final discoveredHost = await discoverPCNetworkIP();
      if (discoveredHost != null) {
        final newUrl = 'http://$discoveredHost:11434';
        print(
          "[OllamaConnectionManager] Found working host: $newUrl. Updating settings...",
        );
        await _ref.read(settingsProvider.notifier).saveOllamaUrl(newUrl);
      }

      final settings = _ref.read(settingsProvider);
      final targetUrl = settings.ollamaUrl;
      final targetModel = settings.ollamaModel;
      final startTime = DateTime.now();

      try {
        final response = await _dio.get('$targetUrl/api/tags');
        final latency = DateTime.now().difference(startTime).inMilliseconds;

        if (response.statusCode == 200) {
          final data = response.data;
          List<String> models = [];
          if (data is Map && data['models'] is List) {
            for (var m in data['models']) {
              if (m is Map && m['name'] != null) {
                models.add(m['name'].toString());
              }
            }
          }

          if (models.isNotEmpty &&
              models.any(
                (m) => m == targetModel || m.startsWith('$targetModel:'),
              )) {
            // Recovered connection!
            _inRetryLoop = false;
            state = OllamaConnectionState(
              status: OllamaConnectionStatus.connected,
              activeUrl: targetUrl,
              responseTimeMs: latency,
              activeModel: targetModel,
            );
            print(
              "[OllamaConnectionManager] Reconnection established successfully!",
            );
            return;
          } else if (models.isEmpty) {
            state = state.copyWith(
              status: OllamaConnectionStatus.waitingForOllama,
              errorMessage: "Ollama starting... No models loaded yet.",
            );
          } else {
            state = state.copyWith(
              status: OllamaConnectionStatus.waitingForOllama,
              errorMessage:
                  "Ollama starting... Model '$targetModel' not loaded.",
            );
          }
        }
      } catch (_) {}
    }

    _inRetryLoop = false;
    state = state.copyWith(
      status: OllamaConnectionStatus.offline,
      errorMessage: error,
    );
    print(
      "[OllamaConnectionManager] All auto-reconnect attempts failed. State set to Offline.",
    );
  }

  /// Dynamic parallel subnet and loopback probing to locate the Ollama host
  Future<String?> discoverPCNetworkIP() async {
    try {
      final List<String> candidates = [];

      // Probing loopbacks dynamically:
      candidates.add(InternetAddress.loopbackIPv4.address);
      candidates.add(['10', '0', '2', '2'].join('.'));

      // Fetch network interfaces to scan local networks
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

            // Prioritize common gateways
            candidates.add('${prefix}1');
            candidates.add('${prefix}2');
            candidates.add('${prefix}254');

            // Add other devices in the subnet range
            for (int i = 1; i < 255; i++) {
              final val = '$prefix$i';
              if (!candidates.contains(val)) {
                candidates.add(val);
              }
            }
          }
        }
      }

      print(
        "[OllamaConnectionManager] Parallel probing ${candidates.length} connection candidates on port 11434...",
      );

      // Probe in batches of 40 to maintain speed and minimize resource usage
      const batchSize = 40;
      for (int i = 0; i < candidates.length; i += batchSize) {
        final batch = candidates.skip(i).take(batchSize);
        final results = await Future.wait(
          batch.map((ip) async {
            try {
              final socket = await Socket.connect(
                ip,
                11434,
                timeout: const Duration(milliseconds: 150),
              );
              socket.destroy();
              return ip;
            } catch (_) {
              return null;
            }
          }),
        );

        for (final res in results) {
          if (res != null) {
            print("[OllamaConnectionManager] Discovered active host: $res");
            return res;
          }
        }
      }
    } catch (e) {
      print("[OllamaConnectionManager] Host network discovery failed: $e");
    }
    return null;
  }
}

final ollamaConnectionManagerProvider =
    StateNotifierProvider<OllamaConnectionManager, OllamaConnectionState>((
      ref,
    ) {
      ref.watch(settingsProvider);
      return OllamaConnectionManager(ref);
    });
