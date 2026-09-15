import 'package:flutter_test/flutter_test.dart';
import 'package:npd_shield/data/models/app_notification.dart';
import 'package:npd_shield/data/notifications/notification_background_scheduler.dart';
import 'package:npd_shield/data/notifications/notification_service.dart';

void main() {
  test('NoopNotificationBackgroundScheduler не планирует задачи', () async {
    const scheduler = NoopNotificationBackgroundScheduler();
    await scheduler.initialize();
    await scheduler.schedulePeriodicCheck(
      frequency: const Duration(minutes: 15),
    );
    await scheduler.cancel();
  });

  test('NoopNotificationService не показывает уведомления', () async {
    const service = NoopNotificationService();

    await service.initialize();
    expect(
      await service.requestPermission(),
      NotificationPermissionStatus.unsupported,
    );

    final notification = AppNotification(
      type: NotificationType.limit,
      title: 'Заголовок',
      body: 'Текст',
      createdAt: DateTime(2026, 9, 14),
    );
    await service.show(notification);
    await service.cancel(1);
    await service.cancelAll();
  });
}
