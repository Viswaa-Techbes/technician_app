import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import '../core/utils/logger.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  appLogger.i("FCM Background: Message received: ${message.messageId}");
}

class NotificationService {
  static final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    appLogger.i("NotificationService: Initializing...");

    try {
      // 1. Initialize Firebase App
      await Firebase.initializeApp();
      appLogger.i("NotificationService: Firebase App initialized.");

      // 2. Set background handler
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // 3. Request permissions
      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
      appLogger.i("NotificationService: Permission status: ${settings.authorizationStatus}");

      // 4. Get FCM token for testing and backend targeting
      final token = await messaging.getToken();
      appLogger.i("NotificationService: FCM Token: $token");

      // 5. Initialize local notifications for foreground display
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings();
      const initSettings = InitializationSettings(android: androidSettings, iOS: iosSettings);

      await _localNotificationsPlugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      // Create high-importance channel for Android
      const channel = AndroidNotificationChannel(
        'techbes_high_channel',
        'TechBes Priority Notifications',
        description: 'Channel used for critical TechBes booking updates.',
        importance: Importance.high,
      );

      await _localNotificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);

      // 6. Listen to foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        appLogger.i("FCM Foreground: Message received: ${message.notification?.title}");
        
        final notification = message.notification;
        final android = message.notification?.android;

        if (notification != null && android != null) {
          _localNotificationsPlugin.show(
            notification.hashCode,
            notification.title,
            notification.body,
            NotificationDetails(
              android: AndroidNotificationDetails(
                channel.id,
                channel.name,
                channelDescription: channel.description,
                importance: Importance.high,
                priority: Priority.high,
                icon: '@mipmap/ic_launcher',
              ),
            ),
          );
        }
      });

      // 7. Handle when app is opened via notification from terminated state
      final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
      if (initialMessage != null) {
        _handleMessageTap(initialMessage);
      }

      // 8. Handle when app is opened via notification from background state
      FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageTap);

    } catch (e) {
      appLogger.e("NotificationService: Initialization failed: $e");
    }
  }

  static void _onNotificationTapped(NotificationResponse response) {
    appLogger.i("NotificationService: Foreground local notification tapped: ${response.payload}");
  }

  static void _handleMessageTap(RemoteMessage message) {
    appLogger.i("NotificationService: App opened via notification click: ${message.data}");
  }
}
