import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'apiClient.dart';

/// Top-level background handler required by firebase_messaging
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

typedef DeepLinkCallback = Future<void> Function(String plantId, String actionType);

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
  FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _careChannel = AndroidNotificationChannel(
    'plant_care_alerts',
    'Plant Care & Recovery Alerts',
    description: 'Watering, nutrition, checkup, and relocation alerts per plant.',
    importance: Importance.max,
  );

  DeepLinkCallback? _onDeepLink;

  Future<void> initialize({required DeepLinkCallback onDeepLink}) async {
    _onDeepLink = onDeepLink;
    tz.initializeTimeZones();

    // 1. Request OS notification permissions
    await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // 2. Initialize flutter_local_notifications
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    await _localNotifications.initialize(
      settings: const InitializationSettings(android: androidInit, iOS: iosInit),
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        if (response.payload != null && response.payload!.isNotEmpty) {
          final data = jsonDecode(response.payload!) as Map<String, dynamic>;
          _dispatchRoute(data);
        }
      },
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_careChannel);

    // 3. Foreground FCM -> show local heads-up banner
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final notification = message.notification;
      if (notification == null) return;

      _localNotifications.show(
        id: notification.hashCode,
        title: notification.title,
        body: notification.body,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            _careChannel.id,
            _careChannel.name,
            channelDescription: _careChannel.description,
            importance: Importance.max,
            priority: Priority.high,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentSound: true,
          ),
        ),
        payload: jsonEncode(message.data),
      );
    });

    // 4. Background tap -> deep-link
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _dispatchRoute(message.data);
    });

    // 5. Terminated state tap -> deep-link
    final initialMessage = await _fcm.getInitialMessage();
    if (initialMessage != null) {
      _dispatchRoute(initialMessage.data);
    }

    // 6. Keep backend synced whenever Firebase rotates the device token
    _fcm.onTokenRefresh.listen((newToken) async {
      try {
        await ApiClient().registerFcmToken(newToken);
      } catch (e) {
        debugPrint('FCM token refresh sync error: $e');
      }
    });
  }

  /// Call immediately after POST /auth/login succeeds
  /// Call immediately after POST /auth/login succeeds
  Future<void> syncTokenAfterLogin() async {
    final token = await _fcm.getToken();
    debugPrint('FCM Device Token: $token'); // Temporary: remove before production release
    if (token != null && token.isNotEmpty) {
      await ApiClient().registerFcmToken(token);
    }
  }

  void _dispatchRoute(Map<String, dynamic> data) {
    final plantId = data['plant_id']?.toString();
    final actionType = data['action_type']?.toString().toUpperCase();
    if (plantId == null || actionType == null || _onDeepLink == null) return;
    _onDeepLink!(plantId, actionType);
  }

  /// Deterministic per-plant local fallback alarms (prevents ID collisions)
  Future<void> schedulePlantFallbackAlarms(PlantScheduleData plant) async {
    final int baseId = plant.plantId.hashCode.abs() % 100000;

    // Cancel stale alarms for this plant before rescheduling
    await _localNotifications.cancel(id: baseId + 1);
    await _localNotifications.cancel(id: baseId + 2);
    await _localNotifications.cancel(id: baseId + 3);

    await _scheduleSingle(
      id: baseId + 1,
      when: plant.nextWaterDate,
      title: 'Watering Due: ${plant.name}',
      body: 'Time to hydrate ${plant.name}. Tap to view watering instructions.',
      plantId: plant.plantId,
      actionType: 'WATER',
    );

    await _scheduleSingle(
      id: baseId + 2,
      when: plant.nextNutritionDate,
      title: 'Nutrition Due: ${plant.name}',
      body: 'Recommended fertilizer cycle is due for ${plant.name}.',
      plantId: plant.plantId,
      actionType: 'NUTRITION',
    );

    await _scheduleSingle(
      id: baseId + 3,
      when: plant.nextCheckupDate,
      title: plant.healthStatus == 'Recovering'
          ? 'Recovery Checkup: ${plant.name}'
          : 'Health Checkup: ${plant.name}',
      body: 'Snap a quick leaf photo so AI can track ${plant.name}\'s health.',
      plantId: plant.plantId,
      actionType: 'CHECKUP',
    );
  }

  Future<void> _scheduleSingle({
    required int id,
    required DateTime? when,
    required String title,
    required String body,
    required String plantId,
    required String actionType,
  }) async {
    if (when == null || when.isBefore(DateTime.now())) return;

    await _localNotifications.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: tz.TZDateTime.from(when, tz.local),
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _careChannel.id,
          _careChannel.name,
          channelDescription: _careChannel.description,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: jsonEncode({'plant_id': plantId, 'action_type': actionType}),
    );
  }
}