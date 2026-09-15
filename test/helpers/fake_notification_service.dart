import 'package:npd_shield/data/models/app_notification.dart';
import 'package:npd_shield/data/notifications/notification_service.dart';

/// Фейковый сервис уведомлений, записывающий вызовы.
class FakeNotificationService implements NotificationService {
  final List<AppNotification> shown = [];
  final List<int> cancelled = [];
  int cancelAllCount = 0;
  NotificationPermissionStatus permission =
      NotificationPermissionStatus.granted;

  @override
  Future<void> initialize() async {}

  @override
  Future<NotificationPermissionStatus> requestPermission() async => permission;

  @override
  Future<void> show(AppNotification notification) async {
    shown.add(notification);
  }

  @override
  Future<void> cancel(int id) async {
    cancelled.add(id);
  }

  @override
  Future<void> cancelAll() async {
    cancelAllCount++;
  }
}
