import 'package:npd_shield/data/models/transaction.dart';
import 'package:npd_shield/data/repositories/isar_transaction_repository.dart';
import 'package:npd_shield/data/repositories/transaction_repository.dart';

class FakeTransactionRepository implements TransactionRepository {
  final List<Transaction> transactions;
  int _nextId = 1;

  FakeTransactionRepository([List<Transaction>? transactions])
      : transactions = transactions ?? [] {
    for (final t in this.transactions) {
      if (t.id >= _nextId) _nextId = t.id + 1;
    }
  }

  @override
  Future<int> add(Transaction transaction) async {
    if (transaction.id <= 0) {
      transaction.id = _nextId++;
    } else if (transaction.id >= _nextId) {
      _nextId = transaction.id + 1;
    }
    transactions.add(transaction);
    return transaction.id;
  }

  @override
  Future<int> update(Transaction transaction) async {
    final index = transactions.indexWhere((t) => t.id == transaction.id);
    if (index >= 0) {
      transactions[index] = transaction;
    } else {
      transactions.add(transaction);
    }
    return transaction.id;
  }

  @override
  Future<Transaction?> getById(int id) async {
    for (final t in transactions) {
      if (t.id == id) return t;
    }
    return null;
  }

  @override
  Future<bool> delete(int id) async {
    final index = transactions.indexWhere((t) => t.id == id);
    if (index < 0) return false;
    transactions.removeAt(index);
    return true;
  }

  @override
  Future<int> count({TransactionFilter? filter}) async {
    if (filter == null || filter.isEmpty) return transactions.length;
    return transactions.where(filter.matches).length;
  }

  @override
  Future<List<Transaction>> getAll({TransactionFilter? filter}) async {
    if (filter == null || filter.isEmpty) return List.of(transactions);
    return transactions.where(filter.matches).toList();
  }

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
    double monthExpense = 0;
    double yearExpense = 0;
    for (final t in filtered) {
      final isIncome = t.type.isIncome;
      if (!t.date.isBefore(monthStart)) {
        if (isIncome) {
          month += t.amount;
        } else {
          monthExpense += t.amount;
        }
      }
      if (!t.date.isBefore(yearStart)) {
        if (isIncome) {
          year += t.amount;
        } else {
          yearExpense += t.amount;
        }
      }
    }
    return IncomeSummary(
      month: month,
      year: year,
      monthExpense: monthExpense,
      yearExpense: yearExpense,
    );
  }

  @override
  Future<PeriodSummary> getPeriodSummary({
    DateTime? from,
    DateTime? to,
    TransactionSphere? sphere,
    TransactionType? type,
    int? clientId,
  }) async {
    final filter = TransactionFilter(
      type: type,
      sphere: sphere,
      from: from,
      to: to,
      clientId: clientId,
    );
    double income = 0;
    double expense = 0;
    for (final t in transactions) {
      if (!filter.matches(t)) continue;
      if (t.type.isIncome) {
        income += t.amount;
      } else {
        expense += t.amount;
      }
    }
    return PeriodSummary(income: income, expense: expense);
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
      if (!t.type.isIncome) continue;
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
      if (!t.type.isIncome) continue;
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
