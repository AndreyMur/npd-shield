import '../../core/tax/tax_calculator.dart';
import '../../data/models/transaction.dart';

/// Отчёт о результатах деятельности за период.
///
/// Содержит итоговые суммы (доход, расход, прибыль), рассчитанный налог и
/// разбивку показателей по сферам деятельности и клиентам. Формируется
/// [ReportBuilder] из операций за выбранный период; налог считается только
/// с доходов — расходы в лимит НПД и налог не входят.
class BusinessReport {
  /// Начало периода (включительно), нормализовано к началу дня.
  final DateTime from;

  /// Конец периода (включительно), нормализовано к началу дня.
  final DateTime to;

  /// Суммарный доход за период.
  final double income;

  /// Суммарный расход за период.
  final double expense;

  /// Расчёт налога 6% с вычетом взносов по доходу за период.
  final TaxCalculation tax;

  /// Разбивка показателей по сферам деятельности.
  final List<ReportSphereBreakdown> spheres;

  /// Разбивка показателей по клиентам.
  final List<ReportClientBreakdown> clients;

  const BusinessReport({
    required this.from,
    required this.to,
    required this.income,
    required this.expense,
    required this.tax,
    this.spheres = const [],
    this.clients = const [],
  });

  /// Прибыль за период: доход минус расход.
  double get profit => income - expense;

  /// Налог к уплате по расчёту [tax].
  double get taxAmount => tax.payableTax;

  /// Есть ли в отчёте хотя бы одна операция.
  bool get isEmpty =>
      income == 0 && expense == 0 && spheres.isEmpty && clients.isEmpty;
}

/// Показатели одной сферы деятельности в отчёте.
class ReportSphereBreakdown {
  final TransactionSphere sphere;

  /// Доход по сфере за период.
  final double income;

  /// Расход по сфере за период.
  final double expense;

  const ReportSphereBreakdown({
    required this.sphere,
    required this.income,
    required this.expense,
  });

  /// Прибыль по сфере: доход минус расход.
  double get profit => income - expense;
}

/// Показатели одного клиента в отчёте.
///
/// Группировка выполняется по привязке к карточке клиента ([clientId]), а при
/// её отсутствии — по ИНН, затем по наименованию, чтобы операции без карточки
/// не сливались с разными контрагентами.
class ReportClientBreakdown {
  /// Идентификатор клиента из справочника. `null` — операция без привязки.
  final int? clientId;

  /// Наименование контрагента (на момент последней операции).
  final String clientName;

  /// ИНН контрагента.
  final String clientInn;

  /// Доход от клиента за период.
  final double income;

  /// Расход по клиенту за период.
  final double expense;

  const ReportClientBreakdown({
    this.clientId,
    this.clientName = '',
    this.clientInn = '',
    required this.income,
    required this.expense,
  });

  /// Прибыль по клиенту: доход минус расход.
  double get profit => income - expense;

  /// Подпись клиента для интерфейса и файлов.
  String get displayName {
    if (clientName.trim().isNotEmpty) return clientName.trim();
    if (clientInn.trim().isNotEmpty) return 'ИНН ${clientInn.trim()}';
    return 'Без клиента';
  }
}
