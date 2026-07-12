import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

@pragma('vm:entry-point')
class MeetingMindBackgroundService {
  static const notificationChannelId = 'meetingmind_recording_channel';
  static const notificationId = 888;

  static Future<void> initializeService() async {
    final service = FlutterBackgroundService();

    // Configure Local Notifications for foreground notifications
    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      notificationChannelId,
      'MeetingMind AI Foreground Service',
      description: 'Used for background recording session notification.',
      importance: Importance.low,
    );

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);

    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: false,
        isForegroundMode: true,
        notificationChannelId: notificationChannelId,
        initialNotificationTitle: 'Meeting Recording',
        initialNotificationContent: 'Recording audio in background...',
        foregroundServiceNotificationId: notificationId,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: onStart,
        onBackground: onIosBackground,
      ),
    );
  }

  @pragma('vm:entry-point')
  static Future<bool> onIosBackground(ServiceInstance service) async {
    WidgetsFlutterBinding.ensureInitialized();
    return true;
  }

  @pragma('vm:entry-point')
  static void onStart(ServiceInstance service) async {
    DartPluginRegistrant.ensureInitialized();

    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();

    // Timer to update notification details or elapsed recording time
    int seconds = 0;
    Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (service is AndroidServiceInstance) {
        if (await service.isForegroundService()) {
          final minutesStr = (seconds ~/ 60).toString().padLeft(2, '0');
          final secondsStr = (seconds % 60).toString().padLeft(2, '0');

          flutterLocalNotificationsPlugin.show(
            notificationId,
            'Recording Active • $minutesStr:$secondsStr',
            'MeetingMind AI is recording in the background.',
            const NotificationDetails(
              android: AndroidNotificationDetails(
                notificationChannelId,
                'MeetingMind AI Foreground Service',
                icon: 'ic_bg_service_small',
                ongoing: true,
                showWhen: false,
                onlyAlertOnce: true,
              ),
            ),
          );
        }
      }
      seconds++;

      // Send tick update back to the main app thread
      service.invoke('tick', {'seconds': seconds});
    });

    service.on('stopService').listen((event) {
      service.stopSelf();
    });
  }
}
