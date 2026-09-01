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
  Future<void> clear() {
    return isar.writeTxn(() => isar.transactions.clear());
  }
}
