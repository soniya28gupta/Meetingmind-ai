import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/config/env_config.dart';
import 'core/theme/app_theme.dart';
import 'database/isar_database.dart';
import 'features/auth/auth_provider.dart';
import 'features/auth/login_screen.dart';
import 'features/dashboard/dashboard_screen.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 0. Load environment variables from .env
  await EnvConfig.load();

  // 1. Initialize Isar Database
  try {
    await IsarDatabase.initialize();
  } catch (e) {
    // Log database initialization error locally
    debugPrint('Isar initialization error: $e');
  }

  // 2. Initialize Notification service
  try {
    final notificationService = NotificationService();
    await notificationService.initialize();
    await notificationService.requestPermissions();
  } catch (e) {
    debugPrint('Notification Service error: $e');
  }

  // 3. Initialize Background Service for Android/iOS audio recording
  try {
    /*await MeetingMindBackgroundService.initializeService();*/
  } catch (e) {
    debugPrint('Background Service error: $e');
  }

  // 4. Initialize Firebase (Gracefully catches failures if config file is not checked in yet)
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('Firebase not configured. Running in Local Offline Fallback Mode. Error: $e');
  }

  runApp(
    const ProviderScope(
      child: MeetingMindApp(),
    ),
  );
}

class MeetingMindApp extends ConsumerWidget {
  const MeetingMindApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return MaterialApp(
      title: 'MeetingMind AI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: _getHomeScreen(authState),
    );
  }

  Widget _getHomeScreen(AuthState authState) {
    switch (authState.status) {
      case AuthStatus.initial:
        return const Scaffold(
          body: Center(
            child: CircularProgressIndicator(
              color: AppColors.secondary,
            ),
          ),
        );
      case AuthStatus.authenticated:
        return const DashboardScreen();
      case AuthStatus.loading:
      case AuthStatus.unauthenticated:
      case AuthStatus.error:
        return const LoginScreen();
    }
  }
}
