import '../models/transaction.dart';

class IncomeSummary {
  final double month;
  final double year;

  const IncomeSummary({required this.month, required this.year});
}

/// Тип периода агрегации доходов для графика.
enum SeriesPeriod {
  week,
  month,
  quarter,
  year;

  /// Число точек на графике для данного периода.
  int get bucketCount => switch (this) {
        SeriesPeriod.week => 12,
        SeriesPeriod.month => 12,
        SeriesPeriod.quarter => 8,
        SeriesPeriod.year => 5,
      };

  String get label => switch (this) {
        SeriesPeriod.week => 'Неделя',
        SeriesPeriod.month => 'Месяц',
        SeriesPeriod.quarter => 'Квартал',
        SeriesPeriod.year => 'Год',
      };
}

/// Точка графика: начало периода и суммарный доход в нём.
class IncomePoint {
  final DateTime start;
  final double amount;

  const IncomePoint({required this.start, required this.amount});
}

abstract class TransactionRepository {
  Future<int> add(Transaction transaction);

  Future<List<Transaction>> getAll();

  Future<List<Transaction>> getAllForSphere(TransactionSphere sphere);

  Future<IncomeSummary> getIncomeSummary({TransactionSphere? sphere, DateTime? now});

  /// Средний доход за последние 3 месяца (включая текущий).
  Future<double> getAverageMonthlyIncome({TransactionSphere? sphere, DateTime? now});

  /// Доход по периодам для графика. Возвращает [SeriesPeriod.bucketCount]
  /// точек с конца, агрегированных по выбранному периоду и сфере.
  Future<List<IncomePoint>> getIncomeSeries({
    SeriesPeriod period = SeriesPeriod.month,
    TransactionSphere? sphere,
    DateTime? now,
  });

  Future<void> clear();
}
