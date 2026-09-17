import 'package:flutter_test/flutter_test.dart';
import 'package:npd_shield/data/models/app_notification.dart';
import 'package:npd_shield/data/models/transaction.dart';
import 'package:npd_shield/data/notifications/notification_check_runner.dart';

import 'helpers/fake_invoice_repository.dart';
import 'helpers/fake_notification_repository.dart';
import 'helpers/fake_notification_service.dart';
import 'helpers/fake_notification_settings_repository.dart';
import 'helpers/fake_transaction_repository.dart';

Transaction income(double amount, DateTime date, {int id = 0}) {
  final transaction = Transaction(
    amount: amount,
    date: date,
    sphere: TransactionSphere.it,
    clientName: 'Клиент',
    clientInn: '7700000000',
    type: TransactionType.income,
  );
  transaction.id = id;
  return transaction;
}

void main() {
  test('прогон создаёт и показывает уведомление о лимите', () async {
    final transactions = FakeTransactionRepository([
      income(2400000 * 0.9, DateTime(2026, 9, 1), id: 1),
    ]);
    final notifications = FakeNotificationRepository();
    final service = FakeNotificationService();
    final settings = FakeNotificationSettingsRepository();

    final runner = NotificationCheckRunner(
      transactionRepository: transactions,
      invoiceRepository: FakeInvoiceRepository(),
      notificationRepository: notifications,
      settingsRepository: settings,
      notificationService: service,
    );

    final created = await runner.run(now: DateTime(2026, 9, 15, 12));

    expect(created, isNotEmpty);
    expect(created.every((n) => n.type == NotificationType.limit), isTrue);
    expect(notifications.notifications, hasLength(created.length));
    expect(service.shown, hasLength(created.length));
    expect(
      service.shown.map((n) => n.dedupeKey).toSet(),
      created.map((n) => n.dedupeKey).toSet(),
    );
  });

  test('повторный прогон не создаёт дублей', () async {
    final transactions = FakeTransactionRepository([
      income(2400000 * 0.9, DateTime(2026, 9, 1), id: 1),
    ]);
    final notifications = FakeNotificationRepository();
    final service = FakeNotificationService();

    final runner = NotificationCheckRunner(
      transactionRepository: transactions,
      invoiceRepository: FakeInvoiceRepository(),
      notificationRepository: notifications,
      settingsRepository: FakeNotificationSettingsRepository(),
      notificationService: service,
    );

    final first = await runner.run(now: DateTime(2026, 9, 15, 12));
    final second = await runner.run(now: DateTime(2026, 9, 15, 13));

    expect(second, isEmpty);
    expect(notifications.notifications, hasLength(first.length));
    expect(service.shown, hasLength(first.length));
  });

  test('прогон удаляет уведомления старше 30 дней', () async {
    final old = AppNotification(
      type: NotificationType.limit,
      title: 'Старое',
      body: 'Текст',
      createdAt: DateTime(2026, 7, 1),
      dedupeKey: 'old:1',
    );
    final notifications = FakeNotificationRepository([old]);

    final runner = NotificationCheckRunner(
      transactionRepository: FakeTransactionRepository(),
      invoiceRepository: FakeInvoiceRepository(),
      notificationRepository: notifications,
      settingsRepository: FakeNotificationSettingsRepository(),
      notificationService: FakeNotificationService(),
    );

    await runner.run(now: DateTime(2026, 9, 15, 12));

    expect(notifications.notifications, isEmpty);
  });

  test('в тихие часы уведомления не показываются', () async {
    final transactions = FakeTransactionRepository([
      income(2400000 * 0.9, DateTime(2026, 9, 1), id: 1),
    ]);
    final notifications = FakeNotificationRepository();
    final service = FakeNotificationService();

    final runner = NotificationCheckRunner(
      transactionRepository: transactions,
      invoiceRepository: FakeInvoiceRepository(),
      notificationRepository: notifications,
      settingsRepository: FakeNotificationSettingsRepository(),
      notificationService: service,
    );

    final created = await runner.run(now: DateTime(2026, 9, 15, 23));

    expect(created, isEmpty);
    expect(service.shown, isEmpty);
  });
}
