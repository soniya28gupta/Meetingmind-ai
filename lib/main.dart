import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/config/env_config.dart';
import 'core/theme/app_theme.dart';
import 'database/isar_database.dart';
import 'features/auth/splash_screen.dart';
import 'services/notification_service.dart';
import 'firebase_options.dart';

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

  // 4. Initialize Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase not configured. Error: $e');
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
    return MaterialApp(
      title: 'MeetingMind AI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const SplashScreen(),
    );
  }
}
