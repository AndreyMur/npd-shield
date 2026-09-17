import 'package:flutter_test/flutter_test.dart';
import 'package:npd_shield/data/models/invoice.dart';
import 'package:npd_shield/domain/notifications/invoice_reminder_rule.dart';
import 'package:npd_shield/domain/notifications/notification_check_context.dart';
import 'package:npd_shield/domain/notifications/notification_settings.dart';

Invoice invoice({
  required int id,
  required DateTime dueDate,
  InvoiceStatus status = InvoiceStatus.sent,
  double amount = 100000,
  double paidAmount = 0,
  String number = 'СЧ-1',
}) {
  final result = Invoice(
    number: number,
    amount: amount,
    issuedAt: DateTime(2026, 8, 1),
    dueDate: dueDate,
    status: status,
    paidAmount: paidAmount,
  );
  result.id = id;
  return result;
}

NotificationCheckContext contextWith(
  List<Invoice> invoices,
  DateTime now, {
  NotificationSettings settings = NotificationSettings.defaults,
}) {
  return NotificationCheckContext(
    now: now,
    transactions: const [],
    invoices: invoices,
    settings: settings,
  );
}

Set<String> keysOf(List drafts) =>
    drafts.map((draft) => draft.dedupeKey as String).toSet();

void main() {
  const rule = InvoiceReminderRule();
  final now = DateTime(2026, 9, 15, 12);

  test('напоминание за 14 дней', () {
    final drafts = rule.evaluate(
      contextWith([invoice(id: 1, dueDate: DateTime(2026, 9, 29))], now),
    );
    expect(keysOf(drafts), contains('invoice:1:reminder:14'));
    expect(drafts.single.actionLabel, InvoiceReminderRule.actionLabel);
    expect(drafts.single.payload, 'invoice:1');
  });

  test('напоминание за 7 дней', () {
    final drafts = rule.evaluate(
      contextWith([invoice(id: 2, dueDate: DateTime(2026, 9, 22))], now),
    );
    expect(keysOf(drafts), contains('invoice:2:reminder:7'));
  });

  test('напоминание за 3 дня', () {
    final drafts = rule.evaluate(
      contextWith([invoice(id: 3, dueDate: DateTime(2026, 9, 18))], now),
    );
    expect(keysOf(drafts), contains('invoice:3:reminder:3'));
  });

  test('вне контрольных сроков напоминания нет', () {
    final drafts = rule.evaluate(
      contextWith([invoice(id: 4, dueDate: DateTime(2026, 9, 20))], now),
    );
    expect(drafts, isEmpty);
  });

  test('просроченный счёт даёт отдельное уведомление', () {
    final drafts = rule.evaluate(
      contextWith([invoice(id: 5, dueDate: DateTime(2026, 9, 13))], now),
    );
    expect(keysOf(drafts), contains('invoice:5:overdue'));
    final draft = drafts.single;
    expect(draft.title, 'Счёт просрочен');
    expect(draft.body, contains('просрочен на 2 дня'));
  });

  test('оплаченные, отменённые и черновики игнорируются', () {
    final drafts = rule.evaluate(
      contextWith([
        invoice(
          id: 6,
          dueDate: DateTime(2026, 9, 18),
          status: InvoiceStatus.paid,
        ),
        invoice(
          id: 7,
          dueDate: DateTime(2026, 9, 18),
          status: InvoiceStatus.cancelled,
        ),
        invoice(
          id: 8,
          dueDate: DateTime(2026, 9, 18),
          status: InvoiceStatus.draft,
        ),
      ], now),
    );
    expect(drafts, isEmpty);
  });

  test('счёт без остатка не напоминает', () {
    final drafts = rule.evaluate(
      contextWith([
        invoice(
          id: 9,
          dueDate: DateTime(2026, 9, 18),
          amount: 100000,
          paidAmount: 100000,
        ),
      ], now),
    );
    expect(drafts, isEmpty);
  });

  test('сроки напоминаний берутся из настроек', () {
    final drafts = rule.evaluate(
      contextWith(
        [invoice(id: 10, dueDate: DateTime(2026, 9, 20))],
        now,
        settings: const NotificationSettings(invoiceReminderDays: {5}),
      ),
    );
    expect(keysOf(drafts), contains('invoice:10:reminder:5'));
  });
}
