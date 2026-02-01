import 'dart:developer' as developer;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:myapp/main.dart';
import 'package:myapp/screens/order_tracking_loader_screen.dart';
import 'package:myapp/services/woocommerce_service.dart';

class NotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final WooCommerceService _wooCommerceService = WooCommerceService();

  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  Future<void> initialize() async {
    // Request permissions for iOS and Android 13+
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      developer.log('NotificationService: User granted permission');
    } else if (settings.authorizationStatus ==
        AuthorizationStatus.provisional) {
      developer.log('NotificationService: User granted provisional permission');
    } else {
      developer.log(
        'NotificationService: User declined or has not accepted permission: ${settings.authorizationStatus}',
      );
    }

    // Configure local notifications for foreground
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsDarwin,
        );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse details) {
        developer.log('Notification clicked: ${details.payload}');
      },
    );

    // Create a high importance channel for Android
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel',
      'High Importance Notifications',
      description: 'This channel is used for important notifications.',
      importance: Importance.high,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);

    // Setup iOS foreground notification presentation options
    await _fcm.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // Listen for foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      developer.log('Got a message whilst in the foreground!');
      developer.log('Message data: ${message.data}');

      if (message.notification != null) {
        developer.log(
          'Message also contained a notification: ${message.notification}',
        );
        _showLocalNotification(message, channel);
      }
    });

    // Handle background/terminated message click
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      developer.log('A new onMessageOpenedApp event was published!');
      _handleMessage(message);
    });

    // Check if the app was opened from a terminated state via a notification
    _fcm.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        developer.log('App opened from terminated state via notification');
        _handleMessage(message);
      }
    });
  }

  void _handleMessage(RemoteMessage message) {
    developer.log('Handling Message Click: ${message.data}');
    final String? orderIdStr = message.data['order_id'];

    if (orderIdStr != null) {
      final int? orderId = int.tryParse(orderIdStr);
      if (orderId != null) {
        developer.log('Navigating to Order Tracking for ID: $orderId');
        // Use Global Navigator Key
        MyApp.navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (context) => OrderTrackingLoaderScreen(orderId: orderId),
          ),
        );
      }
    }
  }

  Future<void> _showLocalNotification(
    RemoteMessage message,
    AndroidNotificationChannel channel,
  ) async {
    RemoteNotification? notification = message.notification;

    if (notification != null) {
      _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            channel.id,
            channel.name,
            channelDescription: channel.description,
            importance: channel.importance,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher', // Use default icon
          ),
        ),
      );
    }
  }

  Future<String?> getToken() async {
    return await _fcm.getToken();
  }

  Future<void> updateTokenOnServer(int customerId) async {
    String? token = await getToken();
    if (token != null) {
      developer.log('Updating FCM Token on server (Direct): $token');
      bool success = await _wooCommerceService.updateFcmToken(
        customerId,
        token,
      );
      if (success) {
        developer.log('FCM Token successfully synced with server.');
      } else {
        developer.log('FCM Token sync FAILED.');
      }
    }
  }
}
