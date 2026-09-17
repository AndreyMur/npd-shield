import 'package:flutter_test/flutter_test.dart';
import 'package:npd_shield/data/models/transaction.dart';
import 'package:npd_shield/domain/notifications/notification_check_context.dart';
import 'package:npd_shield/domain/notifications/notification_settings.dart';
import 'package:npd_shield/domain/notifications/weekly_digest_rule.dart';

Transaction income(double amount, DateTime date) {
  return Transaction(
    amount: amount,
    date: date,
    sphere: TransactionSphere.it,
    clientName: 'Клиент',
    clientInn: '7700000000',
    type: TransactionType.income,
  );
}

NotificationCheckContext contextWith(
  List<Transaction> transactions,
  DateTime now,
) {
  return NotificationCheckContext(
    now: now,
    transactions: transactions,
    invoices: const [],
    settings: NotificationSettings.defaults,
  );
}

void main() {
  const rule = WeeklyDigestRule();

  test('воскресенье после 10:00 формирует дайджест', () {
    final sunday = DateTime(2026, 9, 20, 10);
    expect(sunday.weekday, DateTime.sunday);

    final drafts = rule.evaluate(
      contextWith([income(100000, DateTime(2026, 9, 16))], sunday),
    );

    expect(drafts, hasLength(1));
    final draft = drafts.single;
    expect(draft.dedupeKey, 'digest:2026-09-20');
    expect(draft.title, 'Еженедельный дайджест');
    expect(draft.body, contains('доход 100 000 руб.'));
    expect(draft.body, contains('налог 6 000 руб.'));
    expect(draft.body, contains('сделок: 1'));
    expect(draft.body, contains('До лимита осталось 2 300 000 руб.'));
    expect(draft.actionLabel, 'Подробнее');
  });

  test('воскресенье до 10:00 дайджест не формируется', () {
    final sunday = DateTime(2026, 9, 20, 9);
    expect(
      rule.evaluate(contextWith(const [], sunday)),
      isEmpty,
    );
  });

  test('в понедельник дайджест не формируется', () {
    final monday = DateTime(2026, 9, 21, 10);
    expect(monday.weekday, DateTime.monday);
    expect(rule.evaluate(contextWith(const [], monday)), isEmpty);
  });

  test('в дайджест попадают только операции недели', () {
    final sunday = DateTime(2026, 9, 20, 10);
    final drafts = rule.evaluate(
      contextWith([
        income(50000, DateTime(2026, 9, 14)),
        income(25000, DateTime(2026, 9, 20)),
        income(999999, DateTime(2026, 9, 1)),
      ], sunday),
    );

    expect(drafts.single.body, contains('доход 75 000 руб.'));
    expect(drafts.single.body, contains('сделок: 2'));
  });

  test('исчерпанный лимит отражается в дайджесте', () {
    final sunday = DateTime(2026, 9, 20, 10);
    final drafts = rule.evaluate(
      contextWith([income(2500000, DateTime(2026, 9, 16))], sunday),
    );
    expect(drafts.single.body, contains('лимит исчерпан'));
  });
}
