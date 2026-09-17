import 'package:flutter_test/flutter_test.dart';
import 'package:npd_shield/data/models/transaction.dart';
import 'package:npd_shield/domain/notifications/limit_monitor.dart';
import 'package:npd_shield/domain/notifications/notification_check_context.dart';
import 'package:npd_shield/domain/notifications/notification_draft.dart';
import 'package:npd_shield/domain/notifications/notification_settings.dart';

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

NotificationCheckContext contextWith({
  required List<Transaction> transactions,
  required DateTime now,
  NotificationSettings settings = NotificationSettings.defaults,
}) {
  return NotificationCheckContext(
    now: now,
    transactions: transactions,
    invoices: const [],
    settings: settings,
  );
}

Set<String> keysOf(List<NotificationDraft> drafts) =>
    drafts.map((draft) => draft.dedupeKey).toSet();

void main() {
  const monitor = LimitMonitor();
  final now = DateTime(2026, 9, 15, 12);

  test('порог 80% формирует уведомление', () {
    final context = contextWith(
      now: now,
      transactions: [income(2400000 * 0.8, DateTime(2026, 9, 1))],
    );
    final drafts = monitor.evaluate(context);
    expect(keysOf(drafts), contains('limit:threshold:80:2026'));
    final draft = drafts.firstWhere(
      (d) => d.dedupeKey == 'limit:threshold:80:2026',
    );
    expect(draft.body, contains('до лимита осталось'));
  });

  test('порог 90% формирует уведомление', () {
    final context = contextWith(
      now: now,
      transactions: [income(2400000 * 0.9, DateTime(2026, 9, 1))],
    );
    expect(
      keysOf(monitor.evaluate(context)),
      contains('limit:threshold:90:2026'),
    );
  });

  test('порог 95% формирует уведомление', () {
    final context = contextWith(
      now: now,
      transactions: [income(2400000 * 0.95, DateTime(2026, 9, 1))],
    );
    expect(
      keysOf(monitor.evaluate(context)),
      contains('limit:threshold:95:2026'),
    );
  });

  test('порог 100% формирует уведомление об исчерпании', () {
    final context = contextWith(
      now: now,
      transactions: [income(2400000, DateTime(2026, 9, 1))],
    );
    final drafts = monitor.evaluate(context);
    expect(keysOf(drafts), contains('limit:threshold:100:2026'));
    final draft = drafts.firstWhere(
      (d) => d.dedupeKey == 'limit:threshold:100:2026',
    );
    expect(draft.title, 'Лимит НПД исчерпан');
  });

  test('при скачке через несколько порогов берётся самый высокий', () {
    final context = contextWith(
      now: now,
      transactions: [income(2400000 * 0.97, DateTime(2026, 9, 1))],
    );
    final keys = keysOf(monitor.evaluate(context));
    expect(keys, contains('limit:threshold:95:2026'));
    expect(keys, isNot(contains('limit:threshold:80:2026')));
    expect(keys, isNot(contains('limit:threshold:90:2026')));
  });

  test('ниже 80% уведомления о порогах нет', () {
    final context = contextWith(
      now: now,
      transactions: [income(2400000 * 0.5, DateTime(2026, 9, 1))],
    );
    final keys = keysOf(monitor.evaluate(context));
    expect(keys.where((key) => key.startsWith('limit:threshold')), isEmpty);
  });

  test('контрольный срок 60 дней', () {
    // Доход трёх последних месяцев задаёт средний темп; остаток — около 45 дней.
    final monthly = 535000.0;
    final context = contextWith(
      now: now,
      transactions: [
        income(monthly, DateTime(2026, 7, 1)),
        income(monthly, DateTime(2026, 8, 1)),
        income(monthly, DateTime(2026, 9, 1)),
      ],
    );
    final keys = keysOf(monitor.evaluate(context));
    expect(keys, contains('limit:days:60:2026'));
    expect(keys, isNot(contains('limit:days:30:2026')));
  });

  test('контрольный срок 30 дней', () {
    final monthly = 650000.0;
    final context = contextWith(
      now: now,
      transactions: [
        income(monthly, DateTime(2026, 7, 1)),
        income(monthly, DateTime(2026, 8, 1)),
        income(monthly, DateTime(2026, 9, 1)),
      ],
    );
    final keys = keysOf(monitor.evaluate(context));
    expect(keys, contains('limit:days:30:2026'));
    expect(keys, isNot(contains('limit:days:60:2026')));
  });

  test('расходы не влияют на лимит', () {
    final expense = Transaction(
      amount: 2400000,
      date: DateTime(2026, 9, 1),
      sphere: TransactionSphere.it,
      clientName: 'Клиент',
      clientInn: '7700000000',
      type: TransactionType.expense,
    );
    final context = contextWith(now: now, transactions: [expense]);
    expect(keysOf(monitor.evaluate(context)), isEmpty);
  });
}
