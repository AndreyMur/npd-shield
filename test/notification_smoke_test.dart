import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:npd_shield/data/models/app_notification.dart';
import 'package:npd_shield/data/notifications/push_notification_payload.dart';
import 'package:npd_shield/presentation/notifications/notification_center_screen.dart';

import 'helpers/fake_notification_repository.dart';
import 'helpers/fake_notification_service.dart';

/// Сквозной smoke-тест фазы 21: путь «push → сохранение → центр уведомлений».
void main() {
  testWidgets('уведомление доставляется, сохраняется и живёт в центре', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1000, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final repository = FakeNotificationRepository();
    final service = FakeNotificationService();
    final unreadValues = <int>[];
    final now = DateTime(2026, 9, 14, 12);

    // 1. Push-сообщение превращается в уведомление.
    final notification = notificationFromPushData(
      const {
        'type': 'invoice',
        'title': 'Счёт не оплачен',
        'body': 'Счёт ожидает оплаты',
        'payload': 'invoice:14/09',
        'actionLabel': 'Отметить как оплаченный',
      },
      receivedAt: now.subtract(const Duration(minutes: 10)),
    )!;
    expect(notification.type, NotificationType.invoice);

    // 2. Уведомление сохраняется в истории и показывается локально.
    await repository.save(notification);
    await service.show(notification);
    expect(service.shown, hasLength(1));

    // 3. Центр уведомлений показывает его как непрочитанное.
    await tester.pumpWidget(
      MaterialApp(
        home: NotificationCenterScreen(
          repository: repository,
          notificationService: service,
          clock: () => now,
          onUnreadCountChanged: unreadValues.add,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('notification_card_1')), findsOneWidget);
    expect(find.text('Счёт не оплачен'), findsOneWidget);
    expect(find.byKey(const Key('notification_unread_1')), findsOneWidget);
    expect(unreadValues.last, 1);

    // 4. Нажатие на кнопку действия отмечает уведомление прочитанным.
    await tester.tap(find.byKey(const Key('notification_action_1')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('notification_unread_1')), findsNothing);
    expect(service.cancelled, contains(1));
    expect(unreadValues.last, 0);
    expect(await repository.getById(1), isNotNull);
  });

  testWidgets('история центра ограничена 30 днями', (tester) async {
    tester.view.physicalSize = const Size(1000, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final now = DateTime(2026, 9, 14, 12);
    final repository = FakeNotificationRepository([
      AppNotification(
        type: NotificationType.limit,
        title: 'Старое уведомление',
        body: 'Ему больше 30 дней',
        createdAt: now.subtract(const Duration(days: 45)),
      )..id = 1,
      AppNotification(
        type: NotificationType.digest,
        title: 'Свежая сводка',
        body: 'Актуальное уведомление',
        createdAt: now.subtract(const Duration(days: 2)),
      )..id = 2,
    ]);

    await tester.pumpWidget(
      MaterialApp(
        home: NotificationCenterScreen(
          repository: repository,
          notificationService: FakeNotificationService(),
          clock: () => now,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('notification_card_1')), findsNothing);
    expect(find.byKey(const Key('notification_card_2')), findsOneWidget);
    expect(await repository.count(), 1);
  });
}
