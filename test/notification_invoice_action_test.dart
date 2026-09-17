import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:npd_shield/data/models/app_notification.dart';
import 'package:npd_shield/data/models/invoice.dart';
import 'package:npd_shield/presentation/notifications/invoice_notification_action.dart';
import 'package:npd_shield/presentation/notifications/notification_center_screen.dart';

import 'helpers/fake_invoice_repository.dart';
import 'helpers/fake_notification_repository.dart';
import 'helpers/fake_notification_service.dart';

void main() {
  final now = DateTime(2026, 9, 17, 12);

  Invoice invoice({
    required int id,
    double amount = 50000,
    double paidAmount = 0,
    InvoiceStatus status = InvoiceStatus.sent,
  }) {
    return Invoice(
      number: 'INV-$id',
      amount: amount,
      issuedAt: now.subtract(const Duration(days: 5)),
      dueDate: now.add(const Duration(days: 3)),
      status: status,
      paidAmount: paidAmount,
    )..id = id;
  }

  AppNotification notification({int id = 1, String payload = 'invoice:1'}) {
    return AppNotification(
      type: NotificationType.invoice,
      title: 'Скоро срок оплаты счёта',
      body: 'Оплатите счёт',
      payload: payload,
      actionLabel: 'Отметить оплаченным',
      createdAt: now,
    )..id = id;
  }

  group('InvoiceNotificationAction', () {
    test('отмечает счёт полностью оплаченным', () async {
      final invoices = FakeInvoiceRepository([invoice(id: 1)]);
      final action = InvoiceNotificationAction(
        invoiceRepository: invoices,
        clock: () => now,
      );

      final result = await action.markPaid(notification());

      expect(result.resolved, isTrue);
      expect(result.message, 'Счёт оплачен');
      final updated = await invoices.getById(1);
      expect(updated!.isFullyPaid, isTrue);
      expect(updated.status, InvoiceStatus.paid);
      expect(updated.paidAt, now);
    });

    test('уже оплаченный счёт даёт понятное сообщение', () async {
      final invoices = FakeInvoiceRepository([
        invoice(id: 1, status: InvoiceStatus.paid, paidAmount: 50000),
      ]);
      final action = InvoiceNotificationAction(invoiceRepository: invoices);

      final result = await action.markPaid(notification());

      expect(result.resolved, isTrue);
      expect(result.message, 'Счёт уже оплачен');
    });

    test('отсутствующий счёт даёт понятное сообщение', () async {
      final action = InvoiceNotificationAction(
        invoiceRepository: FakeInvoiceRepository(),
      );

      final result = await action.markPaid(notification(payload: 'invoice:99'));

      expect(result.resolved, isTrue);
      expect(result.message, 'Счёт не найден');
    });

    test('чужой payload не выполняется и оставляет уведомление', () async {
      final action = InvoiceNotificationAction(
        invoiceRepository: FakeInvoiceRepository(),
      );

      final result = await action.markPaid(notification(payload: 'limit:80'));

      expect(result.resolved, isFalse);
      expect(result.message, isNull);
    });

    test('ошибка репозитория оставляет уведомление', () async {
      final action = InvoiceNotificationAction(
        invoiceRepository: _FailingInvoiceRepository(),
      );

      final result = await action.markPaid(notification());

      expect(result.resolved, isFalse);
      expect(result.message, 'Не удалось отметить оплату');
    });
  });

  testWidgets('кнопка действия оплачивает счёт и убирает уведомление', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1000, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final invoices = FakeInvoiceRepository([invoice(id: 1)]);
    final notifications = FakeNotificationRepository([notification()]);
    final service = FakeNotificationService();
    final action = InvoiceNotificationAction(
      invoiceRepository: invoices,
      clock: () => now,
    );
    String? message;

    await tester.pumpWidget(
      MaterialApp(
        home: NotificationCenterScreen(
          repository: notifications,
          notificationService: service,
          clock: () => now,
          onNotificationAction: (item) async {
            final result = await action.markPaid(item);
            message = result.message;
            return result.resolved;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('notification_card_1')), findsOneWidget);

    await tester.tap(find.byKey(const Key('notification_action_1')));
    await tester.pumpAndSettle();

    expect((await invoices.getById(1))!.isFullyPaid, isTrue);
    expect(await notifications.count(), 0);
    expect(find.byKey(const Key('notification_card_1')), findsNothing);
    expect(service.cancelled, contains(1));
    expect(message, 'Счёт оплачен');
  });
}

/// Репозиторий счетов, который всегда падает при обращении.
class _FailingInvoiceRepository extends FakeInvoiceRepository {
  @override
  Future<Invoice?> getById(int id) async => throw Exception('db failed');
}
