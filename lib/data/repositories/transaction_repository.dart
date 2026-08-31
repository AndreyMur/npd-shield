import '../models/transaction.dart';

class IncomeSummary {
  final double month;
  final double year;

  const IncomeSummary({required this.month, required this.year});
}

abstract class TransactionRepository {
  Future<int> add(Transaction transaction);

  Future<List<Transaction>> getAll();

  Future<List<Transaction>> getAllForSphere(TransactionSphere sphere);

  Future<IncomeSummary> getIncomeSummary({TransactionSphere? sphere, DateTime? now});

  Future<void> clear();
}
