import 'package:npd_shield/data/models/transaction.dart';
import 'package:npd_shield/data/repositories/isar_transaction_repository.dart';
import 'package:npd_shield/data/repositories/transaction_repository.dart';

class FakeTransactionRepository implements TransactionRepository {
  final List<Transaction> transactions;

  FakeTransactionRepository([List<Transaction>? transactions])
      : transactions = transactions ?? [];

  @override
  Future<int> add(Transaction transaction) async {
    transactions.add(transaction);
    return transactions.length;
  }

  @override
  Future<List<Transaction>> getAll() async => List.of(transactions);

  @override
  Future<List<Transaction>> getAllForSphere(TransactionSphere sphere) async {
    return transactions.where((t) => t.sphere == sphere).toList();
  }

  @override
  Future<IncomeSummary> getIncomeSummary({
    TransactionSphere? sphere,
    DateTime? now,
  }) async {
    final today = now ?? DateTime.now();
    final monthStart = DateTime(today.year, today.month);
    final yearStart = DateTime(today.year);

    final filtered =
        sphere == null ? transactions : transactions.where((t) => t.sphere == sphere);

    double month = 0;
    double year = 0;
    for (final t in filtered) {
      if (!t.date.isBefore(monthStart)) month += t.amount;
      if (!t.date.isBefore(yearStart)) year += t.amount;
    }
    return IncomeSummary(month: month, year: year);
  }

  @override
  Future<double> getAverageMonthlyIncome({
    TransactionSphere? sphere,
    DateTime? now,
  }) async {
    final today = now ?? DateTime.now();
    final start = DateTime(today.year, today.month - 2);
    final end = DateTime(today.year, today.month + 1);
    final filtered =
        sphere == null ? transactions : transactions.where((t) => t.sphere == sphere);
    double total = 0;
    for (final t in filtered) {
      if (!t.date.isBefore(start) && t.date.isBefore(end)) total += t.amount;
    }
    return total / 3;
  }

  @override
  Future<List<IncomePoint>> getIncomeSeries({
    SeriesPeriod period = SeriesPeriod.month,
    TransactionSphere? sphere,
    DateTime? now,
  }) async {
    final today = now ?? DateTime.now();
    final lastBucketStart = startOfBucket(period, today);
    final starts = [
      for (var i = period.bucketCount - 1; i >= 0; i--)
        subtractBuckets(period, lastBucketStart, i),
    ];
    final amounts = List<double>.filled(starts.length, 0);
    final filtered =
        sphere == null ? transactions : transactions.where((t) => t.sphere == sphere);
    final firstIndex = bucketIndex(period, starts.first);
    for (final t in filtered) {
      final index = bucketIndex(period, startOfBucket(period, t.date)) - firstIndex;
      if (index >= 0 && index < starts.length) {
        amounts[index] += t.amount;
      }
    }
    return [
      for (var i = 0; i < starts.length; i++)
        IncomePoint(start: starts[i], amount: amounts[i]),
    ];
  }

  @override
  Future<void> clear() async => transactions.clear();
}