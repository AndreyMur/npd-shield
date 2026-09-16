import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:npd_shield/data/models/transaction.dart';
import 'package:npd_shield/data/repositories/isar_transaction_repository.dart';
import 'package:npd_shield/data/repositories/transaction_repository.dart';
import 'package:npd_shield/data/security/field_encryption_service.dart';

class _PassthroughEncryption implements FieldEncryptionService {
  const _PassthroughEncryption();

  @override
  Future<String> encrypt(String plainText) async => plainText;

  @override
  Future<String> decrypt(String encryptedText) async => encryptedText;
}

void main() {
  late Isar isar;
  late IsarTransactionRepository repository;

  setUp(() async {
    final dir = await Directory.systemTemp.createTemp('npd_test');
    isar = await Isar.open(
      [TransactionSchema],
      directory: dir.path,
      name: 'test_${dir.path.hashCode}',
    );
    repository = IsarTransactionRepository(
      isar,
      encryption: const _PassthroughEncryption(),
    );
  });

  tearDown(() async {
    await isar.close(deleteFromDisk: true);
  });

  Transaction tx({
    double amount = 1000,
    DateTime? date,
    TransactionSphere sphere = TransactionSphere.it,
    TransactionType type = TransactionType.income,
    String clientName = 'Клиент',
    String clientInn = '1234567890',
    String category = '',
    String comment = '',
    int? clientId,
  }) {
    return Transaction(
      amount: amount,
      date: date ?? DateTime(2026, 8, 10),
      sphere: sphere,
      clientName: clientName,
      clientInn: clientInn,
      type: type,
      category: category,
      comment: comment,
      clientId: clientId,
    );
  }

  group('CRUD', () {
    test('add returns id and getById retrieves the operation', () async {
      final id = await repository.add(tx(amount: 1500));

      final loaded = await repository.getById(id);

      expect(loaded, isNotNull);
      expect(loaded!.amount, 1500);
      expect(loaded.type, TransactionType.income);
    });

    test('getById returns null for unknown id', () async {
      final loaded = await repository.getById(999);
      expect(loaded, isNull);
    });

    test('update persists changed fields', () async {
      final id = await repository.add(tx(amount: 1000));

      final loaded = await repository.getById(id);
      loaded!.amount = 2000;
      loaded.category = 'Материалы';
      loaded.comment = 'Закупка';
      await repository.update(loaded);

      final updated = await repository.getById(id);
      expect(updated!.amount, 2000);
      expect(updated.category, 'Материалы');
      expect(updated.comment, 'Закупка');
    });

    test('delete removes the operation and reports success', () async {
      final id = await repository.add(tx());

      final deleted = await repository.delete(id);

      expect(deleted, isTrue);
      expect(await repository.getById(id), isNull);
      expect((await repository.getAll()).length, 0);
    });

    test('delete reports false for unknown id', () async {
      expect(await repository.delete(123), isFalse);
    });

    test('count returns total and filtered counts', () async {
      await repository.add(tx(type: TransactionType.income));
      await repository.add(tx(type: TransactionType.expense));
      await repository.add(tx(type: TransactionType.expense));

      expect(await repository.count(), 3);
      expect(
        await repository.count(
          filter: const TransactionFilter(type: TransactionType.expense),
        ),
        2,
      );
      expect(
        await repository.count(
          filter: const TransactionFilter(type: TransactionType.income),
        ),
        1,
      );
    });
  });

  group('filters', () {
    setUp(() async {
      await repository.add(tx(
        amount: 1000,
        type: TransactionType.income,
        sphere: TransactionSphere.it,
        date: DateTime(2026, 8, 1),
        clientName: 'ООО Ромашка',
        clientInn: '7701234567',
        category: 'Разработка',
        comment: 'Спринт 1',
        clientId: 1,
      ));
      await repository.add(tx(
        amount: 500,
        type: TransactionType.expense,
        sphere: TransactionSphere.logistics,
        date: DateTime(2026, 8, 15),
        clientName: 'ИП Петров',
        clientInn: '500100200300',
        category: 'Топливо',
        comment: 'Заправка',
        clientId: 2,
      ));
      await repository.add(tx(
        amount: 700,
        type: TransactionType.income,
        sphere: TransactionSphere.it,
        date: DateTime(2026, 7, 31),
        clientName: 'ООО Ромашка',
        clientInn: '7701234567',
        clientId: 1,
      ));
    });

    test('filters by type', () async {
      final income = await repository.getAll(
        filter: const TransactionFilter(type: TransactionType.income),
      );
      final expense = await repository.getAll(
        filter: const TransactionFilter(type: TransactionType.expense),
      );

      expect(income.length, 2);
      expect(expense.length, 1);
      expect(expense.single.amount, 500);
    });

    test('filters by sphere', () async {
      final logistics = await repository.getAll(
        filter: const TransactionFilter(sphere: TransactionSphere.logistics),
      );

      expect(logistics.length, 1);
      expect(logistics.single.sphere, TransactionSphere.logistics);
    });

    test('filters by period with inclusive from and exclusive to', () async {
      final august = await repository.getAll(
        filter: TransactionFilter(
          from: DateTime(2026, 8, 1),
          to: DateTime(2026, 9, 1),
        ),
      );

      expect(august.length, 2);
      expect(
        august.every((t) => t.date.month == 8),
        isTrue,
      );
    });

    test('filters by client id', () async {
      final client1 = await repository.getAll(
        filter: const TransactionFilter(clientId: 1),
      );

      expect(client1.length, 2);
      expect(client1.every((t) => t.clientId == 1), isTrue);
    });

    test('search matches client name, category and comment', () async {
      final byName = await repository.getAll(
        filter: const TransactionFilter(search: 'ромашка'),
      );
      final byCategory = await repository.getAll(
        filter: const TransactionFilter(search: 'топливо'),
      );
      final byComment = await repository.getAll(
        filter: const TransactionFilter(search: 'спринт'),
      );

      expect(byName.length, 2);
      expect(byCategory.length, 1);
      expect(byComment.length, 1);
    });

    test('combines multiple filter conditions', () async {
      final result = await repository.getAll(
        filter: TransactionFilter(
          type: TransactionType.income,
          sphere: TransactionSphere.it,
          from: DateTime(2026, 8, 1),
          to: DateTime(2026, 9, 1),
          clientId: 1,
        ),
      );

      expect(result.length, 1);
      expect(result.single.amount, 1000);
    });
  });

  group('aggregate cache invalidation', () {
    final now = DateTime(2026, 8, 31);

    test('summary is recomputed after add', () async {
      expect((await repository.getIncomeSummary(now: now)).year, 0);

      await repository.add(tx(amount: 1000, date: DateTime(2026, 8, 5)));

      expect((await repository.getIncomeSummary(now: now)).year, 1000);
    });

    test('summary is recomputed after update', () async {
      final id = await repository.add(tx(amount: 1000, date: DateTime(2026, 8, 5)));
      expect((await repository.getIncomeSummary(now: now)).year, 1000);

      final loaded = await repository.getById(id);
      loaded!.amount = 2500;
      await repository.update(loaded);

      expect((await repository.getIncomeSummary(now: now)).year, 2500);
    });

    test('summary is recomputed after delete', () async {
      final id = await repository.add(tx(amount: 1000, date: DateTime(2026, 8, 5)));
      expect((await repository.getIncomeSummary(now: now)).year, 1000);

      await repository.delete(id);

      expect((await repository.getIncomeSummary(now: now)).year, 0);
    });

    test('period summary is recomputed after add', () async {
      final from = DateTime(2026, 8, 1);
      final to = DateTime(2026, 9, 1);

      expect(
        (await repository.getPeriodSummary(from: from, to: to)).income,
        0,
      );

      await repository.add(tx(amount: 1000, date: DateTime(2026, 8, 5)));

      expect(
        (await repository.getPeriodSummary(from: from, to: to)).income,
        1000,
      );
    });

    test('average and series are recomputed after add', () async {
      expect(await repository.getAverageMonthlyIncome(now: now), 0);
      expect(
        (await repository.getIncomeSeries(now: now)).every((p) => p.amount == 0),
        isTrue,
      );

      await repository.add(tx(amount: 3000, date: DateTime(2026, 8, 5)));

      expect(await repository.getAverageMonthlyIncome(now: now), 1000);
      final series = await repository.getIncomeSeries(now: now);
      expect(series.last.amount, 3000);
    });

    test('clear invalidates cached aggregates', () async {
      await repository.add(tx(amount: 1000, date: DateTime(2026, 8, 5)));
      expect((await repository.getIncomeSummary(now: now)).year, 1000);

      await repository.clear();

      expect((await repository.getIncomeSummary(now: now)).year, 0);
    });
  });
}
