import '../../core/tax/tax_calculator.dart';
import '../../data/models/transaction.dart';
import '../../data/repositories/transaction_repository.dart';
import 'business_report.dart';

/// Строит отчёт о деятельности за период по операциям пользователя.
///
/// Доход, расход и прибыль считаются за выбранный период; налог 6% — только с
/// доходов (расходы в лимит НПД и налог не входят). Показатели дополнительно
/// разбиваются по сферам деятельности и клиентам.
///
/// Период задаётся датами [from] и [to] включительно; время суток в границах
/// игнорируется, поэтому операции выбранного дня попадают в отчёт целиком.
class ReportBuilder {
  final TransactionRepository transactionRepository;
  final TaxCalculator taxCalculator;

  const ReportBuilder({
    required this.transactionRepository,
    this.taxCalculator = const TaxCalculator(),
  });

  /// Формирует отчёт за период `[from, to]`.
  ///
  /// [sphere] и [clientId] дополнительно сужают выборку — например, для отчёта
  /// по одной сфере или одному клиенту.
  Future<BusinessReport> build({
    required DateTime from,
    required DateTime to,
    TransactionSphere? sphere,
    int? clientId,
  }) async {
    final start = DateTime(from.year, from.month, from.day);
    final endInclusive = DateTime(to.year, to.month, to.day);
    if (endInclusive.isBefore(start)) {
      return BusinessReport(
        from: start,
        to: endInclusive,
        income: 0,
        expense: 0,
        tax: taxCalculator.calculate(income: 0),
      );
    }

    final transactions = await transactionRepository.getAll(
      filter: TransactionFilter(
        from: start,
        to: endInclusive.add(const Duration(days: 1)),
        sphere: sphere,
        clientId: clientId,
      ),
    );

    double income = 0;
    double expense = 0;
    final spheres = <TransactionSphere, _Totals>{};
    final clients = <String, _ClientAccumulator>{};

    for (final transaction in transactions) {
      final amount = transaction.amount;
      final isIncome = transaction.type.isIncome;
      if (isIncome) {
        income += amount;
      } else {
        expense += amount;
      }

      final sphereTotals = spheres.putIfAbsent(
        transaction.sphere,
        _Totals.new,
      );
      sphereTotals.add(amount, isIncome: isIncome);

      final key = _clientKey(transaction);
      final client = clients.putIfAbsent(
        key,
        () => _ClientAccumulator(
          clientId: transaction.clientId,
          clientName: transaction.clientName,
          clientInn: transaction.clientInn,
        ),
      );
      client.totals.add(amount, isIncome: isIncome);
    }

    final sphereRows = [
      for (final entry in spheres.entries)
        ReportSphereBreakdown(
          sphere: entry.key,
          income: entry.value.income,
          expense: entry.value.expense,
        ),
    ]..sort(_compareSpheres);

    final clientRows = [
      for (final entry in clients.values) entry.toBreakdown(),
    ]..sort(_compareClients);

    return BusinessReport(
      from: start,
      to: endInclusive,
      income: income,
      expense: expense,
      tax: taxCalculator.calculate(income: income),
      spheres: sphereRows,
      clients: clientRows,
    );
  }

  /// Ключ группировки операций по клиенту.
  ///
  /// Приоритет — привязка к карточке справочника; иначе ИНН, затем
  /// наименование. Операции без данных о клиенте попадают в группу «без
  /// клиента» только если они полностью пусты.
  static String _clientKey(Transaction transaction) {
    if (transaction.clientId != null && transaction.clientId != 0) {
      return 'id:${transaction.clientId}';
    }
    final inn = transaction.clientInn.trim();
    if (inn.isNotEmpty) return 'inn:$inn';
    return 'name:${transaction.clientName.trim().toLowerCase()}';
  }

  static int _compareSpheres(
    ReportSphereBreakdown a,
    ReportSphereBreakdown b,
  ) {
    final byIncome = b.income.compareTo(a.income);
    if (byIncome != 0) return byIncome;
    final byExpense = b.expense.compareTo(a.expense);
    if (byExpense != 0) return byExpense;
    return a.sphere.index.compareTo(b.sphere.index);
  }

  static int _compareClients(ReportClientBreakdown a, ReportClientBreakdown b) {
    final byIncome = b.income.compareTo(a.income);
    if (byIncome != 0) return byIncome;
    final byExpense = b.expense.compareTo(a.expense);
    if (byExpense != 0) return byExpense;
    return a.displayName.compareTo(b.displayName);
  }
}

/// Накопитель сумм дохода и расхода.
class _Totals {
  double income = 0;
  double expense = 0;

  void add(double amount, {required bool isIncome}) {
    if (isIncome) {
      income += amount;
    } else {
      expense += amount;
    }
  }
}

/// Накопитель показателей клиента.
class _ClientAccumulator {
  final int? clientId;
  final String clientName;
  final String clientInn;
  final _Totals totals = _Totals();

  _ClientAccumulator({
    required this.clientId,
    required this.clientName,
    required this.clientInn,
  });

  ReportClientBreakdown toBreakdown() => ReportClientBreakdown(
    clientId: clientId == 0 ? null : clientId,
    clientName: clientName,
    clientInn: clientInn,
    income: totals.income,
    expense: totals.expense,
  );
}
