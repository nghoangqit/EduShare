import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../models/app_notification.dart';
import 'firebase_data_service.dart';

class NotificationSystemService {
  NotificationSystemService._();

  static final NotificationSystemService instance =
      NotificationSystemService._();

  static const AndroidNotificationChannel _androidChannel =
      AndroidNotificationChannel(
        'edushare_updates',
        'EduShare updates',
        description: 'Thong bao don hang, tin nhan va vi EduShare.',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      );

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseDataService _dataService = FirebaseDataService.instance;
  final Set<String> _knownNotificationIds = <String>{};

  StreamSubscription<List<AppNotification>>? _notificationSubscription;
  StreamSubscription<RemoteMessage>? _foregroundMessageSubscription;
  StreamSubscription<String>? _tokenRefreshSubscription;
  bool _initialized = false;
  bool _hasSeenInitialSnapshot = false;

  Future<void> initialize() async {
    if (_initialized || kIsWeb) return;
    _initialized = true;

    const initializationSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    );

    await _localNotifications.initialize(settings: initializationSettings);
    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(_androidChannel);

    await requestPermissions();

    _foregroundMessageSubscription = FirebaseMessaging.onMessage.listen(
      showRemoteMessage,
    );
    _tokenRefreshSubscription = _messaging.onTokenRefresh.listen(
      _saveMessagingToken,
    );
  }

  Future<void> requestPermissions() async {
    if (kIsWeb) return;

    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
    await _localNotifications
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  Future<void> startForCurrentUser() async {
    if (kIsWeb) return;
    await initialize();
    await _saveCurrentMessagingToken();

    await _notificationSubscription?.cancel();
    _knownNotificationIds.clear();
    _hasSeenInitialSnapshot = false;

    _notificationSubscription = _dataService.watchNotifications().listen(
      _handleNotificationSnapshot,
    );
  }

  Future<void> stopForCurrentUser() async {
    await _notificationSubscription?.cancel();
    _notificationSubscription = null;
    _knownNotificationIds.clear();
    _hasSeenInitialSnapshot = false;
  }

  Future<void> dispose() async {
    await stopForCurrentUser();
    await _foregroundMessageSubscription?.cancel();
    await _tokenRefreshSubscription?.cancel();
  }

  Future<void> showRemoteMessage(RemoteMessage message) async {
    final title =
        message.notification?.title ?? message.data['title']?.toString();
    final body = message.notification?.body ?? message.data['body']?.toString();
    if ((title == null || title.trim().isEmpty) &&
        (body == null || body.trim().isEmpty)) {
      return;
    }

    await _showSystemNotification(
      id: message.messageId?.hashCode ?? DateTime.now().millisecondsSinceEpoch,
      title: title?.trim().isEmpty ?? true ? 'EduShare' : title!.trim(),
      body: body?.trim() ?? '',
      payload: message.data['notificationId']?.toString(),
    );
  }

  void _handleNotificationSnapshot(List<AppNotification> notifications) {
    final unreadNotifications = notifications
        .where((item) => !item.isRead && item.id.trim().isNotEmpty)
        .toList();

    if (!_hasSeenInitialSnapshot) {
      _knownNotificationIds.addAll(unreadNotifications.map((item) => item.id));
      _hasSeenInitialSnapshot = true;
      return;
    }

    for (final notification in unreadNotifications.reversed) {
      if (!_knownNotificationIds.add(notification.id)) continue;
      _showSystemNotification(
        id: notification.id.hashCode,
        title: notification.title.trim().isEmpty
            ? 'Thong bao EduShare'
            : notification.title.trim(),
        body: notification.body.trim(),
        payload: notification.id,
      );
    }
  }

  Future<void> _showSystemNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    if (kIsWeb) return;

    await _localNotifications.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _androidChannel.id,
          _androidChannel.name,
          channelDescription: _androidChannel.description,
          importance: Importance.high,
          priority: Priority.high,
          category: AndroidNotificationCategory.message,
          ticker: title,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: payload,
    );
  }

  Future<void> _saveCurrentMessagingToken() async {
    try {
      final token = await _messaging.getToken();
      if (token != null && token.trim().isNotEmpty) {
        await _saveMessagingToken(token);
      }
    } catch (_) {
      // Token can be unavailable on emulators or platforms without messaging.
    }
  }

  Future<void> _saveMessagingToken(String token) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || token.trim().isEmpty) return;

    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'fcmToken': token,
        'fcmTokens': FieldValue.arrayUnion([token]),
        'fcmTokenUpdatedAt': DateTime.now().toIso8601String(),
      }, SetOptions(merge: true));
    } on FirebaseException catch (error) {
      if (error.code != 'permission-denied') rethrow;
    }
  }
}
