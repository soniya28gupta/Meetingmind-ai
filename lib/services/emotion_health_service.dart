import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:device_info_plus/device_info_plus.dart';
import '../providers/app_providers.dart';
import '../features/settings/settings_provider.dart';
import '../core/config/backend_config.dart';
import 'backend_connection_manager.dart';

enum EmotionBackendStatus {
  connected, // ONLINE
  offline, // OFFLINE
  connecting, // CONNECTING
  reconnecting, // RECONNECTING
  retrying, // RECONNECTING fallback
  fallbackActive, // OFFLINE fallback
  processing, // Compatibility: Backend processing request
  analyzing, // Compatibility: Backend analyzing request
}

class EmotionHealthState {
  final EmotionBackendStatus status;
  final String activeUrl;
  final int responseTimeMs;
  final int retryAttempt;
  final String? errorMessage;
  final String serverVersion;
  final int retryCountdown;
  final String deviceType;
  final String lastSuccessTime;
  final String uptime;
  final List<String> connectionHistory;

  EmotionHealthState({
    required this.status,
    required this.activeUrl,
    this.responseTimeMs = 0,
    this.retryAttempt = 0,
    this.errorMessage,
    this.serverVersion = 'Unknown',
    this.retryCountdown = 2,
    this.deviceType = 'Detecting...',
    this.lastSuccessTime = 'Never',
    this.uptime = 'N/A',
    this.connectionHistory = const [],
  });

  bool get isOnline =>
      status == EmotionBackendStatus.connected ||
      status == EmotionBackendStatus.processing ||
      status == EmotionBackendStatus.analyzing;

  bool get isOffline =>
      status == EmotionBackendStatus.offline ||
      status == EmotionBackendStatus.fallbackActive;

  bool get isConnecting => status == EmotionBackendStatus.connecting;

  bool get isReconnecting =>
      status == EmotionBackendStatus.reconnecting ||
      status == EmotionBackendStatus.retrying;

  EmotionHealthState copyWith({
    EmotionBackendStatus? status,
    String? activeUrl,
    int? responseTimeMs,
    int? retryAttempt,
    String? errorMessage,
    String? serverVersion,
    int? retryCountdown,
    String? deviceType,
    String? lastSuccessTime,
    String? uptime,
    List<String>? connectionHistory,
  }) {
    return EmotionHealthState(
      status: status ?? this.status,
      activeUrl: activeUrl ?? this.activeUrl,
      responseTimeMs: responseTimeMs ?? this.responseTimeMs,
      retryAttempt: retryAttempt ?? this.retryAttempt,
      errorMessage: errorMessage ?? this.errorMessage,
      serverVersion: serverVersion ?? this.serverVersion,
      retryCountdown: retryCountdown ?? this.retryCountdown,
      deviceType: deviceType ?? this.deviceType,
      lastSuccessTime: lastSuccessTime ?? this.lastSuccessTime,
      uptime: uptime ?? this.uptime,
      connectionHistory: connectionHistory ?? this.connectionHistory,
    );
  }
}

class EmotionHealthManager extends StateNotifier<EmotionHealthState> {
  final Ref _ref;
  late final VoidCallback _listener;

  EmotionHealthManager(this._ref)
    : super(BackendConnectionManager.instance.state) {
    _listener = () {
      if (mounted) {
        state = BackendConnectionManager.instance.state;
      }
    };
    BackendConnectionManager.instance.stateNotifier.addListener(_listener);

    // Initialize the singleton connection manager
    BackendConnectionManager.instance.init(_ref.read(dioProvider));
  }

  Future<void> checkConnection({bool isPassive = false}) async {
    await BackendConnectionManager.instance.checkConnection(
      isPassive: isPassive,
    );
  }

  void setStatus(EmotionBackendStatus status) {
    BackendConnectionManager.instance.setStatus(status);
  }

  @override
  void dispose() {
    BackendConnectionManager.instance.stateNotifier.removeListener(_listener);
    super.dispose();
  }
}

final emotionHealthServiceProvider =
    StateNotifierProvider<EmotionHealthManager, EmotionHealthState>((ref) {
      return EmotionHealthManager(ref);
    });
