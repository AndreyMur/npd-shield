import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../models/app_notification.dart';
import 'push_notification_payload.dart';
import 'push_notification_service.dart';

/// Push-инфраструктура на базе Firebase Cloud Messaging (FCM).
///
/// На Android сообщения приходят через FCM, на iOS — через APNs, который
/// Firebase проксирует. Если Firebase не сконфигурирован на платформе
/// (например, нет `google-services.json` или сборка для Windows), сервис
/// переходит в недоступное состояние и не роняет приложение.
class FirebasePushNotificationService implements PushNotificationService {
  final StreamController<AppNotification> _messages =
      StreamController<AppNotification>.broadcast();

  bool _available = false;

  /// Доступна ли push-инфраструктура после инициализации.
  bool get isAvailable => _available;

  @override
  Stream<AppNotification> get onMessage => _messages.stream;

  @override
  Future<void> initialize() async {
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }
      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission();
      await messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
      FirebaseMessaging.onMessage.listen(_handleMessage);
      _available = true;
    } catch (error) {
      // Firebase не настроен — приложение работает без удалённых push.
      debugPrint('Push-уведомления недоступны: $error');
      _available = false;
    }
  }

  @override
  Future<String?> getToken() async {
    if (!_available) return null;
    try {
      return await FirebaseMessaging.instance.getToken();
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> subscribeToTopic(String topic) async {
    if (!_available) return;
    try {
      await FirebaseMessaging.instance.subscribeToTopic(topic);
    } catch (_) {
      // Подписка не критична для работы приложения.
    }
  }

  @override
  Future<void> unsubscribeFromTopic(String topic) async {
    if (!_available) return;
    try {
      await FirebaseMessaging.instance.unsubscribeFromTopic(topic);
    } catch (_) {
      // Отписка не критична для работы приложения.
    }
  }

  void _handleMessage(RemoteMessage message) {
    final notification = notificationFromPushData(
      message.data,
      fallbackTitle: message.notification?.title,
      fallbackBody: message.notification?.body,
    );
    if (notification != null) _messages.add(notification);
  }

  /// Закрывает поток входящих сообщений.
  Future<void> dispose() => _messages.close();
}
