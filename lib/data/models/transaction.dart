import 'package:isar/isar.dart';

part 'transaction.g.dart';

/// Тип операции: доход или расход.
enum TransactionType {
  income,
  expense;

  /// Человекочитаемое название типа для интерфейса.
  String get label => switch (this) {
    TransactionType.income => 'Доход',
    TransactionType.expense => 'Расход',
  };

  bool get isIncome => this == TransactionType.income;

  bool get isExpense => this == TransactionType.expense;
}

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

  /// Тип операции. По умолчанию — доход (совместимо со старыми записями).
  @Index()
  @enumerated
  TransactionType type;

  /// Категория операции (свободный текст), например «Материалы».
  String category;

  String clientName;

  String clientInn;

  /// Ссылка на карточку клиента из справочника (если выбрана).
  @Index()
  int? clientId;

  /// Произвольный комментарий пользователя к операции.
  String comment;

  Transaction({
    required this.amount,
    required this.date,
    required this.sphere,
    required this.clientName,
    required this.clientInn,
    this.type = TransactionType.income,
    this.category = '',
    this.clientId,
    this.comment = '',
  });
}
