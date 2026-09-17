import '../../data/models/invoice.dart';
import '../../data/models/transaction.dart';
import 'notification_settings.dart';

/// Данные одной проверки условий уведомлений.
///
/// Контекст передаётся всем правилам и содержит всё, что нужно для их
/// вычисления: текущее время, операции, счета и настройки. Правила не ходят в
/// базу сами — это делает движок, поэтому правила остаются чистыми и
/// тестируемыми.
class NotificationCheckContext {
  /// Момент проверки.
  final DateTime now;

  /// Все операции (доходы и расходы).
  final List<Transaction> transactions;

  /// Все счета.
  final List<Invoice> invoices;

  /// Настройки уведомлений.
  final NotificationSettings settings;

  const NotificationCheckContext({
    required this.now,
    required this.transactions,
    required this.invoices,
    required this.settings,
  });

  /// Только доходы: расходы в лимит НПД и налог не входят.
  Iterable<Transaction> get incomes =>
      transactions.where((transaction) => transaction.type.isIncome);

  /// Суммарный доход за указанный год.
  double incomeForYear(int year) {
    var total = 0.0;
    for (final transaction in incomes) {
      if (transaction.date.year == year) total += transaction.amount;
    }
    return total;
  }

  /// Суммарный доход за период: [from] включительно, [to] исключительно.
  double incomeInRange(DateTime from, DateTime to) {
    var total = 0.0;
    for (final transaction in incomes) {
      if (transaction.date.isBefore(from)) continue;
      if (!transaction.date.isBefore(to)) continue;
      total += transaction.amount;
    }
    return total;
  }

  /// Средний месячный доход за последние три месяца (включая текущий).
  double get averageMonthlyIncome {
    final start = DateTime(now.year, now.month - 2);
    final end = DateTime(now.year, now.month + 1);
    return incomeInRange(start, end) / 3;
  }

  /// Все операции, кроме указанной (для сравнения с историей).
  ///
  /// Исключение идёт по идентификатору, а для несохранённых операций (id == 0)
  /// — по ссылке на объект.
  List<Transaction> transactionsExcept(Transaction excluded) {
    return transactions
        .where(
          (transaction) =>
              !identical(transaction, excluded) &&
              (excluded.id == 0 || transaction.id != excluded.id),
        )
        .toList(growable: false);
  }
}
