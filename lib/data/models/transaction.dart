import 'package:isar/isar.dart';

part 'transaction.g.dart';

enum TransactionSphere {
  it,
  logistics;

  /// Человекочитаемое название сферы для интерфейса.
  String get label => switch (this) {
    TransactionSphere.it => 'IT',
    TransactionSphere.logistics => 'Логистика',
  };
}

@collection
class Transaction {
  Id id = Isar.autoIncrement;

  double amount;

  @Index()
  DateTime date;

  @Index()
  @enumerated
  TransactionSphere sphere;

  String clientName;

  String clientInn;

  Transaction({
    required this.amount,
    required this.date,
    required this.sphere,
    required this.clientName,
    required this.clientInn,
  });
}
