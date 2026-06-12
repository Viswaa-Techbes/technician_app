import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'api_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PushNotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  final Ref _ref;

  PushNotificationService(this._ref);

  Future<void> initialize() async {
    // Request permissions for iOS/Android 13+
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('[PushNotificationService] User granted permission');
    }

    // Initialize Local Notifications for Foreground
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings();
    const InitializationSettings initSettings =
        InitializationSettings(android: androidSettings, iOS: iosSettings);

    await _localNotifications.initialize(initSettings);

    // Get FCM Token
    String? token = await _fcm.getToken();
    if (token != null) {
      debugPrint('[PushNotificationService] FCM Token: $token');
      await _saveTokenToBackend(token);
    }

    // Listen to token refresh
    _fcm.onTokenRefresh.listen(_saveTokenToBackend);

    // Handle Foreground Messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('[PushNotificationService] Foreground Message: ${message.notification?.title}');
      _showLocalNotification(message);
    });

    // Handle Background/Terminated Click
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('[PushNotificationService] Background Message Clicked: ${message.data}');
      // TODO: Navigate to specific screen based on data
    });
  }

  Future<void> _saveTokenToBackend(String token) async {
    try {
      final api = _ref.read(apiServiceProvider);
      await api.updateFcmToken(token);
      debugPrint('[PushNotificationService] Token saved to backend');
    } catch (e) {
      debugPrint('[PushNotificationService] Error saving token: $e');
    }
  }

  void _showLocalNotification(RemoteMessage message) {
    RemoteNotification? notification = message.notification;

    if (notification != null && !kIsWeb) {
      showLocalNotification(
        id: notification.hashCode,
        title: notification.title ?? '',
        body: notification.body ?? '',
      );
    }
  }

  Future<void> showLocalNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    if (kIsWeb) return;
    await _localNotifications.show(
      id,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'high_importance_channel',
          'High Importance Notifications',
          importance: Importance.max,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }
}

final pushNotificationServiceProvider = Provider<PushNotificationService>((ref) {
  return PushNotificationService(ref);
});
