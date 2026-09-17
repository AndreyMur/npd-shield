import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:npd_shield/data/models/app_notification.dart';
import 'package:npd_shield/presentation/notifications/notification_center_screen.dart';

import 'helpers/fake_notification_repository.dart';
import 'helpers/fake_notification_service.dart';

void main() {
  final now = DateTime(2026, 9, 14, 12);

  AppNotification note({
    required int id,
    NotificationType type = NotificationType.limit,
    NotificationStatus status = NotificationStatus.unread,
    String title = 'Заголовок',
    String body = 'Текст уведомления',
    String actionLabel = '',
    DateTime? createdAt,
  }) {
    final notification = AppNotification(
      type: type,
      status: status,
      title: title,
      body: body,
      actionLabel: actionLabel,
      createdAt: createdAt ?? now.subtract(const Duration(hours: 1)),
    );
    notification.id = id;
    return notification;
  }

  Future<void> pumpCenter(
    WidgetTester tester,
    FakeNotificationRepository repository, {
    FakeNotificationService? service,
    Future<bool> Function(AppNotification)? onAction,
    ValueChanged<int>? onUnread,
    DateTime? clock,
  }) async {
    tester.view.physicalSize = const Size(1000, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: NotificationCenterScreen(
          repository: repository,
          notificationService: service ?? FakeNotificationService(),
          clock: () => clock ?? now,
          onNotificationAction: onAction,
          onUnreadCountChanged: onUnread,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('показывает уведомления с группировкой по дате и иконками типов', (
    tester,
  ) async {
    await pumpCenter(
      tester,
      FakeNotificationRepository([
        note(id: 1, type: NotificationType.limit),
        note(
          id: 2,
          type: NotificationType.invoice,
          createdAt: now.subtract(const Duration(days: 1)),
        ),
        note(
          id: 3,
          type: NotificationType.anomaly,
          createdAt: now.subtract(const Duration(days: 10)),
        ),
      ]),
    );

    expect(find.byKey(const Key('notification_card_1')), findsOneWidget);
    expect(find.byKey(const Key('notification_card_2')), findsOneWidget);
    expect(find.byKey(const Key('notification_card_3')), findsOneWidget);

    expect(find.byKey(const Key('notification_group_today')), findsOneWidget);
    expect(
      find.byKey(const Key('notification_group_yesterday')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('notification_group_earlier')), findsOneWidget);

    expect(find.byIcon(Icons.speed_outlined), findsOneWidget);
    expect(find.byIcon(Icons.request_quote_outlined), findsOneWidget);
    expect(find.byIcon(Icons.warning_amber_outlined), findsOneWidget);
  });

  testWidgets('группировку можно отключить', (tester) async {
    await pumpCenter(
      tester,
      FakeNotificationRepository([note(id: 1)]),
    );

    expect(find.byKey(const Key('notification_group_today')), findsOneWidget);

    await tester.tap(find.byKey(const Key('notification_group_toggle')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('notification_group_today')), findsNothing);
    expect(find.byKey(const Key('notification_card_1')), findsOneWidget);
  });

  testWidgets('фильтр по типу скрывает остальные уведомления', (tester) async {
    await pumpCenter(
      tester,
      FakeNotificationRepository([
        note(id: 1, type: NotificationType.limit),
        note(id: 2, type: NotificationType.anomaly),
      ]),
    );

    await tester.tap(find.byKey(const Key('notification_type_filter_anomaly')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('notification_card_1')), findsNothing);
    expect(find.byKey(const Key('notification_card_2')), findsOneWidget);
  });

  testWidgets('фильтр по статусу показывает только непрочитанные', (
    tester,
  ) async {
    await pumpCenter(
      tester,
      FakeNotificationRepository([
        note(id: 1),
        note(id: 2, status: NotificationStatus.read),
      ]),
    );

    await tester.tap(
      find.byKey(const Key('notification_status_filter_unread')),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('notification_card_1')), findsOneWidget);
    expect(find.byKey(const Key('notification_card_2')), findsNothing);
  });

  testWidgets('фильтр по дате показывает только сегодняшние уведомления', (
    tester,
  ) async {
    await pumpCenter(
      tester,
      FakeNotificationRepository([
        note(id: 1),
        note(id: 2, createdAt: now.subtract(const Duration(days: 10))),
      ]),
    );

    await tester.tap(find.byKey(const Key('notification_date_filter_today')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('notification_card_1')), findsOneWidget);
    expect(find.byKey(const Key('notification_card_2')), findsNothing);
  });

  testWidgets('нажатие на карточку отмечает прочитанным и отменяет системное', (
    tester,
  ) async {
    final service = FakeNotificationService();
    final unreadValues = <int>[];
    await pumpCenter(
      tester,
      FakeNotificationRepository([
        note(id: 1),
        note(id: 2, status: NotificationStatus.read),
      ]),
      service: service,
      onUnread: unreadValues.add,
    );

    expect(find.byKey(const Key('notification_unread_1')), findsOneWidget);

    await tester.tap(find.byKey(const Key('notification_card_1')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('notification_unread_1')), findsNothing);
    expect(service.cancelled, contains(1));
    expect(unreadValues.last, 0);
  });

  testWidgets('кнопка действия отмечает прочитанным и вызывает callback', (
    tester,
  ) async {
    AppNotification? actioned;
    final service = FakeNotificationService();
    await pumpCenter(
      tester,
      FakeNotificationRepository([
        note(id: 1, actionLabel: 'Отметить как оплаченный'),
      ]),
      service: service,
      onAction: (notification) async {
        actioned = notification;
        return false;
      },
    );

    expect(find.text('Отметить как оплаченный'), findsOneWidget);

    await tester.tap(find.byKey(const Key('notification_action_1')));
    await tester.pumpAndSettle();

    expect(actioned?.id, 1);
    expect(find.byKey(const Key('notification_unread_1')), findsNothing);
    expect(service.cancelled, contains(1));
    expect(find.byKey(const Key('notification_card_1')), findsOneWidget);
  });

  testWidgets('выполненное действие убирает уведомление из центра', (
    tester,
  ) async {
    final service = FakeNotificationService();
    await pumpCenter(
      tester,
      FakeNotificationRepository([
        note(id: 1, actionLabel: 'Отметить оплаченным'),
        note(id: 2),
      ]),
      service: service,
      onAction: (_) async => true,
    );

    await tester.tap(find.byKey(const Key('notification_action_1')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('notification_card_1')), findsNothing);
    expect(find.byKey(const Key('notification_card_2')), findsOneWidget);
    expect(service.cancelled, contains(1));
  });

  testWidgets('меню позволяет отметить уведомление непрочитанным', (
    tester,
  ) async {
    await pumpCenter(
      tester,
      FakeNotificationRepository([note(id: 1, status: NotificationStatus.read)]),
    );

    await tester.tap(find.byKey(const Key('notification_menu_1')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Отметить непрочитанным'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('notification_unread_1')), findsOneWidget);
  });

  testWidgets('удаление уведомления можно отменить', (tester) async {
    final service = FakeNotificationService();
    await pumpCenter(
      tester,
      FakeNotificationRepository([note(id: 1), note(id: 2)]),
      service: service,
    );

    await tester.tap(find.byKey(const Key('notification_menu_1')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Удалить'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('notification_card_1')), findsNothing);
    expect(service.cancelled, contains(1));
    expect(find.text('Уведомление удалено'), findsOneWidget);

    await tester.tap(find.text('Отменить'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('notification_card_1')), findsOneWidget);
  });

  testWidgets('«Прочитать все» снимает непрочитанные и отменяет системные', (
    tester,
  ) async {
    final service = FakeNotificationService();
    await pumpCenter(
      tester,
      FakeNotificationRepository([note(id: 1), note(id: 2)]),
      service: service,
    );

    await tester.tap(find.byKey(const Key('notification_mark_all_read')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('notification_unread_1')), findsNothing);
    expect(find.byKey(const Key('notification_unread_2')), findsNothing);
    expect(service.cancelAllCount, 1);
  });

  testWidgets('пустое состояние', (tester) async {
    await pumpCenter(tester, FakeNotificationRepository());

    expect(find.byKey(const Key('notification_center_empty')), findsOneWidget);
    expect(find.text('Уведомлений пока нет'), findsOneWidget);
  });

  testWidgets('ошибка загрузки показывает повтор', (tester) async {
    await pumpCenter(tester, FakeNotificationRepository.failing());

    expect(find.text('Не удалось загрузить уведомления'), findsOneWidget);
    expect(find.byKey(const Key('notification_center_retry')), findsOneWidget);
  });

  testWidgets('при загрузке вычищает уведомления старше 30 дней', (
    tester,
  ) async {
    final repository = FakeNotificationRepository([
      note(id: 1, createdAt: now.subtract(const Duration(days: 40))),
      note(id: 2),
    ]);

    await pumpCenter(tester, repository);

    expect(repository.notifications.map((n) => n.id), [2]);
    expect(find.byKey(const Key('notification_card_1')), findsNothing);
    expect(find.byKey(const Key('notification_card_2')), findsOneWidget);
  });

  testWidgets('карточки доступны скринридеру', (tester) async {
    final handle = tester.ensureSemantics();

    await pumpCenter(
      tester,
      FakeNotificationRepository([
        note(
          id: 1,
          type: NotificationType.invoice,
          title: 'Счёт не оплачен',
          body: 'Проверьте оплату',
        ),
      ]),
    );

    expect(
      find.bySemanticsLabel(RegExp('Счёт. Счёт не оплачен')),
      findsOneWidget,
    );
    expect(find.byTooltip('Действия с уведомлением'), findsOneWidget);

    handle.dispose();
  });
}
