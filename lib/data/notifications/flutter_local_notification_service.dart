import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../models/app_notification.dart';
import 'notification_service.dart';

/// Сервис локальных уведомлений на базе `flutter_local_notifications`.
///
/// Реализует единый путь доставки: разрешение → показ системного уведомления
/// → отмена. Ошибки платформы (например, отсутствие разрешения или нативного
/// канала) не пробрасываются наружу, чтобы не ронять приложение.
class FlutterLocalNotificationService implements NotificationService {
  FlutterLocalNotificationService({FlutterLocalNotificationsPlugin? plugin})
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;

  bool _initialized = false;
  bool _supported = true;

  static const String _channelId = 'npd_shield_notifications';
  static const String _channelName = 'Своё дело';
  static const String _channelDescription =
      'Уведомления о лимите, счетах, аномалиях и дайджесте';

  @override
  Future<void> initialize() async {
    if (_initialized || !_supported) return;
    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
      macOS: DarwinInitializationSettings(),
      windows: WindowsInitializationSettings(
        appName: 'Своё дело',
        appUserModelId: 'com.npdshield.npdShield',
        guid: 'e0a1b2c3-4d5e-6f70-8192-a3b4c5d6e7f8',
      ),
    );
    try {
      await _plugin.initialize(settings: settings);
      _initialized = true;
    } catch (_) {
      // Платформа не поддерживает уведомления — работаем без них.
      _supported = false;
    }
  }

  @override
  Future<NotificationPermissionStatus> requestPermission() async {
    if (!_supported) return NotificationPermissionStatus.unsupported;
    await initialize();
    if (!_supported) return NotificationPermissionStatus.unsupported;
    try {
      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      if (android != null) {
        final granted = await android.requestNotificationsPermission();
        return _status(granted);
      }
      final ios = _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();
      if (ios != null) {
        final granted = await ios.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        return _status(granted);
      }
      final macos = _plugin
          .resolvePlatformSpecificImplementation<
            MacOSFlutterLocalNotificationsPlugin
          >();
      if (macos != null) {
        final granted = await macos.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        return _status(granted);
      }
      // На настольных платформах явное разрешение не требуется.
      return NotificationPermissionStatus.granted;
    } catch (_) {
      return NotificationPermissionStatus.denied;
    }
  }

  @override
  Future<void> show(AppNotification notification) async {
    if (!_supported) return;
    await initialize();
    if (!_supported) return;
    try {
      await _plugin.show(
        id: _notificationId(notification),
        title: notification.title,
        body: notification.body,
        notificationDetails: _details,
        payload: notification.payload,
      );
    } catch (error) {
      debugPrint('Не удалось показать уведомление: $error');
    }
  }

  @override
  Future<void> cancel(int id) async {
    if (!_supported) return;
    try {
      await _plugin.cancel(id: id);
    } catch (_) {
      // Игнорируем: уведомление могло быть уже удалено системой.
    }
  }

  @override
  Future<void> cancelAll() async {
    if (!_supported) return;
    try {
      await _plugin.cancelAll();
    } catch (_) {
      // Игнорируем: платформа могла не иметь активных уведомлений.
    }
  }

  /// Идентификатор системного уведомления в 32-битном диапазоне.
  int _notificationId(AppNotification notification) {
    if (notification.id != 0) return notification.id & 0x7fffffff;
    return notification.createdAt.millisecondsSinceEpoch & 0x7fffffff;
  }

  NotificationPermissionStatus _status(bool? granted) {
    return granted == true
        ? NotificationPermissionStatus.granted
        : NotificationPermissionStatus.denied;
  }

  static const NotificationDetails _details = NotificationDetails(
    android: AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.high,
      priority: Priority.high,
    ),
    iOS: DarwinNotificationDetails(),
    macOS: DarwinNotificationDetails(),
  );
}
