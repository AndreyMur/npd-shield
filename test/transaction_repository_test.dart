import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:npd_shield/data/models/transaction.dart';
import 'package:npd_shield/data/repositories/isar_transaction_repository.dart';

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
    repository = IsarTransactionRepository(isar);
  });

  tearDown(() async {
    await isar.close(deleteFromDisk: true);
  });

  Transaction tx({
    double amount = 0,
    DateTime? date,
    TransactionSphere sphere = TransactionSphere.it,
    String clientName = 'Клиент',
    String clientInn = '1234567890',
  }) {
    return Transaction(
      amount: amount,
      date: date ?? DateTime.now(),
      sphere: sphere,
      clientName: clientName,
      clientInn: clientInn,
    );
  }

  group('TransactionRepository', () {
    test('add and getAll', () async {
      await repository.add(tx(amount: 1000));
      await repository.add(tx(amount: 2000));

      final all = await repository.getAll();
      expect(all.length, 2);
    });

    test('getAllForSphere filters by sphere', () async {
      await repository.add(tx(amount: 1000, sphere: TransactionSphere.it));
      await repository.add(
        tx(amount: 2000, sphere: TransactionSphere.logistics),
      );

      final it = await repository.getAllForSphere(TransactionSphere.it);
      final logistics =
          await repository.getAllForSphere(TransactionSphere.logistics);

      expect(it.length, 1);
      expect(it.first.amount, 1000);
      expect(logistics.length, 1);
      expect(logistics.first.amount, 2000);
    });

    group('getIncomeSummary', () {
      final now = DateTime(2026, 8, 31);

      test('sums income within current month and year (all spheres)', () async {
        await repository.add(
          tx(amount: 1000, date: DateTime(2026, 8, 5),
              sphere: TransactionSphere.it),
        );
        await repository.add(
          tx(amount: 500, date: DateTime(2026, 8, 20),
              sphere: TransactionSphere.logistics),
        );
        await repository.add(
          tx(amount: 300, date: DateTime(2026, 3, 15),
              sphere: TransactionSphere.it),
        );
        await repository.add(
          tx(amount: 900, date: DateTime(2025, 12, 10),
              sphere: TransactionSphere.logistics),
        );

        final summary = await repository.getIncomeSummary(now: now);

        expect(summary.month, 1500);
        expect(summary.year, 1800);
      });

      test('excludes transactions from previous months of same year', () async {
        await repository.add(
          tx(amount: 700, date: DateTime(2026, 7, 31),
              sphere: TransactionSphere.it),
        );

        final summary = await repository.getIncomeSummary(now: now);

        expect(summary.month, 0);
        expect(summary.year, 700);
      });

      test('filters by sphere', () async {
        await repository.add(
          tx(amount: 1000, date: DateTime(2026, 8, 5),
              sphere: TransactionSphere.it),
        );
        await repository.add(
          tx(amount: 2000, date: DateTime(2026, 8, 6),
              sphere: TransactionSphere.logistics),
        );

        final it = await repository.getIncomeSummary(
          sphere: TransactionSphere.it,
          now: now,
        );
        final logistics = await repository.getIncomeSummary(
          sphere: TransactionSphere.logistics,
          now: now,
        );

        expect(it.month, 1000);
        expect(it.year, 1000);
        expect(logistics.month, 2000);
        expect(logistics.year, 2000);
      });

      test('returns zero when no transactions', () async {
        final summary = await repository.getIncomeSummary(now: now);
        expect(summary.month, 0);
        expect(summary.year, 0);
      });
    });

    group('getAverageMonthlyIncome', () {
      final now = DateTime(2026, 8, 31);

      test('averages income over the last 3 months', () async {
        await repository.add(
          tx(amount: 3000, date: DateTime(2026, 8, 5)),
        );
        await repository.add(
          tx(amount: 3000, date: DateTime(2026, 7, 10)),
        );
        await repository.add(
          tx(amount: 3000, date: DateTime(2026, 6, 15)),
        );

        final average = await repository.getAverageMonthlyIncome(now: now);
        expect(average, 3000);
      });

      test('excludes income older than 3 months', () async {
        await repository.add(
          tx(amount: 9000, date: DateTime(2026, 8, 5)),
        );
        await repository.add(
          tx(amount: 9000, date: DateTime(2026, 2, 10)),
        );

        final average = await repository.getAverageMonthlyIncome(now: now);
        expect(average, 3000);
      });

      test('returns zero when no transactions in range', () async {
        final average = await repository.getAverageMonthlyIncome(now: now);
        expect(average, 0);
      });
    });
  });
}
