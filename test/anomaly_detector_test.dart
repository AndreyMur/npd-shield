import 'package:flutter_test/flutter_test.dart';
import 'package:npd_shield/data/models/transaction.dart';
import 'package:npd_shield/domain/notifications/anomaly_detector.dart';
import 'package:npd_shield/domain/notifications/notification_check_context.dart';
import 'package:npd_shield/domain/notifications/notification_draft.dart';
import 'package:npd_shield/domain/notifications/notification_settings.dart';

Transaction tx({
  required int id,
  required double amount,
  required DateTime date,
  String name = 'Клиент',
  String inn = '7700000000',
  TransactionType type = TransactionType.income,
}) {
  final transaction = Transaction(
    amount: amount,
    date: date,
    sphere: TransactionSphere.it,
    clientName: name,
    clientInn: inn,
    type: type,
  );
  transaction.id = id;
  return transaction;
}

Set<String> keysOf(List<NotificationDraft> drafts) =>
    drafts.map((draft) => draft.dedupeKey).toSet();

void main() {
  const detector = AnomalyDetector();
  final now = DateTime(2026, 9, 15, 12);

  test('сумма в 3+ раза выше средней', () {
    final history = [
      for (var i = 0; i < 6; i++)
        tx(id: i + 1, amount: 1000, date: DateTime(2026, 9, 10, 10)),
    ];
    final spike = tx(id: 99, amount: 5000, date: DateTime(2026, 9, 15, 10));

    final drafts = detector.evaluate(
      NotificationCheckContext(
        now: now,
        transactions: [...history, spike],
        invoices: const [],
        settings: NotificationSettings.defaults,
      ),
    );

    expect(keysOf(drafts), contains('anomaly:tx:99:amount'));
  });

  test('сумма ниже трёх средних не считается аномалией', () {
    final history = [
      for (var i = 0; i < 6; i++)
        tx(id: i + 1, amount: 1000, date: DateTime(2026, 9, 10, 10)),
    ];
    final normal = tx(id: 99, amount: 2500, date: DateTime(2026, 9, 15, 10));

    final drafts = detector.evaluate(
      NotificationCheckContext(
        now: now,
        transactions: [...history, normal],
        invoices: const [],
        settings: NotificationSettings.defaults,
      ),
    );

    expect(keysOf(drafts), isNot(contains('anomaly:tx:99:amount')));
  });

  test('новый контрагент с крупной суммой', () {
    final history = [
      tx(id: 1, amount: 1000, date: DateTime(2026, 9, 10, 10), inn: '1111111111'),
    ];
    final newcomer = tx(
      id: 99,
      amount: 200000,
      date: DateTime(2026, 9, 15, 10),
      name: 'Новый партнёр',
      inn: '2222222222',
    );

    final drafts = detector.evaluate(
      NotificationCheckContext(
        now: now,
        transactions: [...history, newcomer],
        invoices: const [],
        settings: NotificationSettings.defaults,
      ),
    );

    expect(keysOf(drafts), contains('anomaly:tx:99:counterparty'));
  });

  test('известный контрагент с крупной суммой не аномалия', () {
    final history = [
      tx(id: 1, amount: 1000, date: DateTime(2026, 9, 10, 10), inn: '2222222222'),
    ];
    final repeat = tx(
      id: 99,
      amount: 200000,
      date: DateTime(2026, 9, 15, 10),
      inn: '2222222222',
    );

    final drafts = detector.evaluate(
      NotificationCheckContext(
        now: now,
        transactions: [...history, repeat],
        invoices: const [],
        settings: NotificationSettings.defaults,
      ),
    );

    expect(keysOf(drafts), isNot(contains('anomaly:tx:99:counterparty')));
  });

  test('операция в необычное время', () {
    final night = tx(id: 99, amount: 1000, date: DateTime(2026, 9, 15, 3, 30));

    final drafts = detector.evaluate(
      NotificationCheckContext(
        now: now,
        transactions: [night],
        invoices: const [],
        settings: NotificationSettings.defaults,
      ),
    );

    expect(keysOf(drafts), contains('anomaly:tx:99:time'));
  });

  test('операция без времени (00:00) не считается ночной', () {
    final midnight = tx(id: 99, amount: 1000, date: DateTime(2026, 9, 15));

    final drafts = detector.evaluate(
      NotificationCheckContext(
        now: now,
        transactions: [midnight],
        invoices: const [],
        settings: NotificationSettings.defaults,
      ),
    );

    expect(keysOf(drafts), isNot(contains('anomaly:tx:99:time')));
  });

  test('старые операции вне окна анализа игнорируются', () {
    final old = tx(id: 99, amount: 500000, date: DateTime(2026, 9, 1, 3));

    final drafts = detector.evaluate(
      NotificationCheckContext(
        now: now,
        transactions: [old],
        invoices: const [],
        settings: NotificationSettings.defaults,
      ),
    );

    expect(drafts, isEmpty);
  });
}
