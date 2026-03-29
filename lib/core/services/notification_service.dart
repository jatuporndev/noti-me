import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  GlobalKey<NavigatorState>? _navigatorKey;

  static const _androidChannel = AndroidNotificationChannel(
    'noti_me_default',
    'notiMe Notifications',
    description: 'Default channel for notiMe reminders and alerts',
    importance: Importance.high,
  );

  Future<void> initialize(GlobalKey<NavigatorState> navigatorKey) async {
    _navigatorKey = navigatorKey;

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinSettings = DarwinInitializationSettings();
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
    );

    await _plugin.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    final androidPlugin =
        _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(_androidChannel);

    FirebaseMessaging.onMessage.listen(_showForegroundNotification);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundTap);

    final initial = await FirebaseMessaging.instance.getInitialMessage();
    if (initial != null) {
      _navigateFromPayload(initial.data['route'] as String?);
    }
  }

  void _showForegroundNotification(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;

    _plugin.show(
      id: notification.hashCode,
      title: notification.title,
      body: notification.body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _androidChannel.id,
          _androidChannel.name,
          channelDescription: _androidChannel.description,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      payload: message.data['route'] as String?,
    );
  }

  void _onNotificationTap(NotificationResponse response) {
    _navigateFromPayload(response.payload);
  }

  void _handleBackgroundTap(RemoteMessage message) {
    _navigateFromPayload(message.data['route'] as String?);
  }

  void _navigateFromPayload(String? route) {
    if (route == null || _navigatorKey?.currentState == null) return;
    final nav = _navigatorKey!.currentState!;

    if (route == 'inbox') {
      nav.pushNamed('/inbox');
    } else if (route.startsWith('channel/')) {
      final channelId = route.substring('channel/'.length);
      nav.pushNamed('/channel', arguments: channelId);
    }
  }
}
