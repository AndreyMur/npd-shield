import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:npd_shield/core/constants/tax_constants.dart';
import 'package:npd_shield/core/tax/tax_calculator.dart';
import 'package:npd_shield/data/models/transaction.dart';
import 'package:npd_shield/data/repositories/isar_transaction_repository.dart';
import 'package:npd_shield/data/security/field_encryption_service.dart';
import 'package:npd_shield/domain/limit/limit_calculator.dart';

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
    required double amount,
    required TransactionType type,
    DateTime? date,
    TransactionSphere sphere = TransactionSphere.it,
    int? clientId,
  }) {
    return Transaction(
      amount: amount,
      date: date ?? DateTime(2026, 8, 10),
      sphere: sphere,
      clientName: 'Клиент',
      clientInn: '1234567890',
      type: type,
      clientId: clientId,
    );
  }

  group('getIncomeSummary', () {
    final now = DateTime(2026, 8, 31);

    test('separates income and expense, profit = income - expense', () async {
      await repository.add(
        tx(amount: 10000, type: TransactionType.income, date: DateTime(2026, 8, 5)),
      );
      await repository.add(
        tx(amount: 4000, type: TransactionType.expense, date: DateTime(2026, 8, 6)),
      );
      await repository.add(
        tx(amount: 2000, type: TransactionType.income, date: DateTime(2026, 3, 1)),
      );
      await repository.add(
        tx(amount: 1000, type: TransactionType.expense, date: DateTime(2026, 3, 2)),
      );

      final summary = await repository.getIncomeSummary(now: now);

      expect(summary.month, 10000);
      expect(summary.monthExpense, 4000);
      expect(summary.monthProfit, 6000);
      expect(summary.year, 12000);
      expect(summary.yearExpense, 5000);
      expect(summary.yearProfit, 7000);
    });

    test('income used for limit and tax excludes expenses', () async {
      await repository.add(
        tx(amount: 1000000, type: TransactionType.income, date: DateTime(2026, 8, 5)),
      );
      await repository.add(
        tx(amount: 900000, type: TransactionType.expense, date: DateTime(2026, 8, 6)),
      );

      final summary = await repository.getIncomeSummary(now: now);

      final limit = LimitCalculator().calculate(
        usedAmount: summary.year,
        averageMonthlyIncome: 0,
      );
      final tax = const TaxCalculator().calculate(income: summary.year);

      expect(limit.usedAmount, 1000000);
      expect(tax.income, 1000000);
      expect(tax.accruedTax, 1000000 * TaxConstants.rate);
      expect(summary.year, isNot(1900000));
    });

    test('is zero when there are no operations', () async {
      final summary = await repository.getIncomeSummary(now: now);

      expect(summary.month, 0);
      expect(summary.monthExpense, 0);
      expect(summary.monthProfit, 0);
      expect(summary.year, 0);
      expect(summary.yearExpense, 0);
      expect(summary.yearProfit, 0);
    });
  });

  group('getPeriodSummary', () {
    test('computes income, expense and profit for a period', () async {
      await repository.add(
        tx(amount: 5000, type: TransactionType.income, date: DateTime(2026, 8, 3)),
      );
      await repository.add(
        tx(amount: 1500, type: TransactionType.expense, date: DateTime(2026, 8, 4)),
      );
      await repository.add(
        tx(amount: 9000, type: TransactionType.income, date: DateTime(2026, 6, 1)),
      );

      final summary = await repository.getPeriodSummary(
        from: DateTime(2026, 8, 1),
        to: DateTime(2026, 9, 1),
      );

      expect(summary.income, 5000);
      expect(summary.expense, 1500);
      expect(summary.profit, 3500);
    });

    test('filters by sphere, type and client', () async {
      await repository.add(
        tx(
          amount: 5000,
          type: TransactionType.income,
          sphere: TransactionSphere.it,
          clientId: 1,
          date: DateTime(2026, 8, 3),
        ),
      );
      await repository.add(
        tx(
          amount: 7000,
          type: TransactionType.income,
          sphere: TransactionSphere.logistics,
          clientId: 2,
          date: DateTime(2026, 8, 4),
        ),
      );

      final bySphere = await repository.getPeriodSummary(
        sphere: TransactionSphere.logistics,
      );
      final byClient = await repository.getPeriodSummary(clientId: 1);
      final byType = await repository.getPeriodSummary(
        type: TransactionType.expense,
      );

      expect(bySphere.income, 7000);
      expect(byClient.income, 5000);
      expect(byType.income, 0);
      expect(byType.expense, 0);
    });

    test('is zero when there are no operations', () async {
      final summary = await repository.getPeriodSummary();

      expect(summary.income, 0);
      expect(summary.expense, 0);
      expect(summary.profit, 0);
    });
  });

  group('other aggregates ignore expenses', () {
    final now = DateTime(2026, 8, 31);

    test('average monthly income counts only income', () async {
      await repository.add(
        tx(amount: 3000, type: TransactionType.income, date: DateTime(2026, 8, 5)),
      );
      await repository.add(
        tx(amount: 6000, type: TransactionType.expense, date: DateTime(2026, 8, 6)),
      );

      expect(await repository.getAverageMonthlyIncome(now: now), 1000);
    });

    test('income series counts only income', () async {
      await repository.add(
        tx(amount: 1000, type: TransactionType.income, date: DateTime(2026, 8, 5)),
      );
      await repository.add(
        tx(amount: 5000, type: TransactionType.expense, date: DateTime(2026, 8, 6)),
      );

      final series = await repository.getIncomeSeries(now: now);

      expect(series.last.amount, 1000);
      expect(series.every((p) => p.amount >= 0), isTrue);
    });

    test('income series is zero-filled when there are no operations', () async {
      final series = await repository.getIncomeSeries(now: now);

      expect(series.length, 12);
      expect(series.every((p) => p.amount == 0), isTrue);
    });
  });
}
