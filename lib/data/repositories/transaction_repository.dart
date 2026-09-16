import '../models/transaction.dart';

/// Сводка доходов за текущий месяц и год.
///
/// [month]/[year] учитывают только доходы (расходы в лимит НПД и налог не входят),
/// [monthExpense]/[yearExpense] — расходы за те же периоды.
class IncomeSummary {
  final double month;
  final double year;
  final double monthExpense;
  final double yearExpense;

  const IncomeSummary({
    required this.month,
    required this.year,
    this.monthExpense = 0,
    this.yearExpense = 0,
  });

  /// Прибыль за текущий месяц: доход минус расход.
  double get monthProfit => month - monthExpense;

  /// Прибыль за текущий год: доход минус расход.
  double get yearProfit => year - yearExpense;
}

/// Агрегаты за произвольный период.
class PeriodSummary {
  /// Сумма доходов за период.
  final double income;

  /// Сумма расходов за период.
  final double expense;

  const PeriodSummary({required this.income, required this.expense});

  /// Прибыль за период: доход минус расход.
  double get profit => income - expense;
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

/// Фильтр выборки операций.
///
/// [from] — включительно, [to] — исключительно. [search] ищет подстроку
/// (без учёта регистра) по клиенту, ИНН, категории и комментарию.
class TransactionFilter {
  final TransactionType? type;
  final TransactionSphere? sphere;
  final DateTime? from;
  final DateTime? to;
  final int? clientId;
  final String? search;

  const TransactionFilter({
    this.type,
    this.sphere,
    this.from,
    this.to,
    this.clientId,
    this.search,
  });

  bool get isEmpty =>
      type == null &&
      sphere == null &&
      from == null &&
      to == null &&
      clientId == null &&
      (search == null || search!.trim().isEmpty);

  bool matches(Transaction transaction) {
    if (type != null && transaction.type != type) return false;
    if (sphere != null && transaction.sphere != sphere) return false;
    if (from != null && transaction.date.isBefore(from!)) return false;
    if (to != null && !transaction.date.isBefore(to!)) return false;
    if (clientId != null && transaction.clientId != clientId) return false;

    final query = search?.trim().toLowerCase();
    if (query != null && query.isNotEmpty) {
      final haystack = [
        transaction.clientName,
        transaction.clientInn,
        transaction.category,
        transaction.comment,
      ].join(' ').toLowerCase();
      if (!haystack.contains(query)) return false;
    }
    return true;
  }
}

abstract class TransactionRepository {
  Future<int> add(Transaction transaction);

  Future<Transaction?> getById(int id);

  Future<int> update(Transaction transaction);

  Future<bool> delete(int id);

  Future<int> count({TransactionFilter? filter});

  Future<List<Transaction>> getAll({TransactionFilter? filter});

  Future<List<Transaction>> getAllForSphere(TransactionSphere sphere);

  /// Агрегаты за текущий месяц и год: доходы (для лимита и налога) и расходы.
  Future<IncomeSummary> getIncomeSummary({TransactionSphere? sphere, DateTime? now});

  /// Агрегаты (доход, расход, прибыль) за произвольный период.
  Future<PeriodSummary> getPeriodSummary({
    DateTime? from,
    DateTime? to,
    TransactionSphere? sphere,
    TransactionType? type,
    int? clientId,
  });

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
