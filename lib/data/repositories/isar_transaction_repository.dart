import 'package:isar/isar.dart';

import '../models/transaction.dart';
import 'transaction_repository.dart';

class IsarTransactionRepository implements TransactionRepository {
  final Isar isar;

  IsarTransactionRepository(this.isar);

  @override
  Future<int> add(Transaction transaction) {
    return isar.writeTxn(() => isar.transactions.put(transaction));
  }

  @override
  Future<List<Transaction>> getAll() {
    return isar.transactions.where().findAll();
  }

  @override
  Future<List<Transaction>> getAllForSphere(TransactionSphere sphere) {
    return isar.transactions.where().sphereEqualTo(sphere).findAll();
  }

  @override
  Future<IncomeSummary> getIncomeSummary({
    TransactionSphere? sphere,
    DateTime? now,
  }) {
    final today = now ?? DateTime.now();
    final monthStart = DateTime(today.year, today.month);
    final yearStart = DateTime(today.year);

    return isar.txn(() async {
      final all = sphere != null
          ? await isar.transactions.where().sphereEqualTo(sphere).findAll()
          : await isar.transactions.where().findAll();

      double month = 0;
      double year = 0;
      for (final t in all) {
        if (!t.date.isBefore(monthStart)) {
          month += t.amount;
        }
        if (!t.date.isBefore(yearStart)) {
          year += t.amount;
        }
      }
      return IncomeSummary(month: month, year: year);
    });
  }

  @override
  Future<double> getAverageMonthlyIncome({
    TransactionSphere? sphere,
    DateTime? now,
  }) {
    final today = now ?? DateTime.now();
    final start = DateTime(today.year, today.month - 2);
    final end = DateTime(today.year, today.month + 1);

    return isar.txn(() async {
      final all = sphere != null
          ? await isar.transactions.where().sphereEqualTo(sphere).findAll()
          : await isar.transactions.where().findAll();

      double total = 0;
      for (final t in all) {
        if (!t.date.isBefore(start) && t.date.isBefore(end)) {
          total += t.amount;
        }
      }
      return total / 3;
    });
  }

  @override
  Future<List<IncomePoint>> getIncomeSeries({
    SeriesPeriod period = SeriesPeriod.month,
    TransactionSphere? sphere,
    DateTime? now,
  }) {
    final today = now ?? DateTime.now();
    final lastBucketStart = startOfBucket(period, today);
    final starts = [
      for (var i = period.bucketCount - 1; i >= 0; i--)
        subtractBuckets(period, lastBucketStart, i),
    ];
    final amounts = List<double>.filled(starts.length, 0);

    return isar.txn(() async {
      final all = sphere != null
          ? await isar.transactions.where().sphereEqualTo(sphere).findAll()
          : await isar.transactions.where().findAll();

      final firstIndex = bucketIndex(period, starts.first);
      for (final t in all) {
        final index =
            bucketIndex(period, startOfBucket(period, t.date)) - firstIndex;
        if (index >= 0 && index < starts.length) {
          amounts[index] += t.amount;
        }
      }
      return [
        for (var i = 0; i < starts.length; i++)
          IncomePoint(start: starts[i], amount: amounts[i]),
      ];
    });
  }

  @override
  Future<void> clear() {
    return isar.writeTxn(() => isar.transactions.clear());
  }
}

DateTime startOfBucket(SeriesPeriod period, DateTime date) {
  return switch (period) {
    SeriesPeriod.week =>
      DateTime(date.year, date.month, date.day)
          .subtract(Duration(days: date.weekday - 1)),
    SeriesPeriod.month => DateTime(date.year, date.month),
    SeriesPeriod.quarter =>
      DateTime(date.year, ((date.month - 1) ~/ 3) * 3 + 1),
    SeriesPeriod.year => DateTime(date.year),
  };
}

DateTime subtractBuckets(SeriesPeriod period, DateTime start, int count) {
  return switch (period) {
    SeriesPeriod.week => start.subtract(Duration(days: 7 * count)),
    SeriesPeriod.month => DateTime(start.year, start.month - count, start.day),
    SeriesPeriod.quarter =>
      DateTime(start.year, start.month - 3 * count, start.day),
    SeriesPeriod.year => DateTime(start.year - count, start.month, start.day),
  };
}

int bucketIndex(SeriesPeriod period, DateTime bucketStart) {
  return switch (period) {
    SeriesPeriod.week =>
      DateTime.utc(
        bucketStart.year,
        bucketStart.month,
        bucketStart.day,
      ).millisecondsSinceEpoch ~/
          (7 * Duration.millisecondsPerDay),
    SeriesPeriod.month => bucketStart.year * 12 + bucketStart.month,
    SeriesPeriod.quarter => (bucketStart.year * 12 + bucketStart.month) ~/ 3,
    SeriesPeriod.year => bucketStart.year,
  };
}
