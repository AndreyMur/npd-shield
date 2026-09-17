import '../../domain/reports/report_format.dart';

/// Предустановленный период отчёта.
enum ReportPeriodPreset {
  month('Месяц'),
  quarter('Квартал'),
  year('Год'),
  custom('Период');

  const ReportPeriodPreset(this.label);

  /// Подпись для интерфейса.
  final String label;

  /// Вычисляет границы периода относительно даты [now].
  ///
  /// Для [ReportPeriodPreset.custom] границы задаёт пользователь, поэтому
  /// возвращается `null`.
  ReportPeriod? range(DateTime now) {
    switch (this) {
      case ReportPeriodPreset.month:
        return ReportPeriod(
          from: DateTime(now.year, now.month, 1),
          to: DateTime(now.year, now.month + 1, 0),
        );
      case ReportPeriodPreset.quarter:
        final startMonth = ((now.month - 1) ~/ 3) * 3 + 1;
        return ReportPeriod(
          from: DateTime(now.year, startMonth, 1),
          to: DateTime(now.year, startMonth + 3, 0),
        );
      case ReportPeriodPreset.year:
        return ReportPeriod(
          from: DateTime(now.year, 1, 1),
          to: DateTime(now.year, 12, 31),
        );
      case ReportPeriodPreset.custom:
        return null;
    }
  }
}

/// Период отчёта с границами включительно.
class ReportPeriod {
  /// Начало периода (включительно).
  final DateTime from;

  /// Конец периода (включительно).
  final DateTime to;

  const ReportPeriod({required this.from, required this.to});

  /// Подпись периода для интерфейса: `дд.мм.гггг — дд.мм.гггг`.
  String get label => '${formatReportDate(from)} — ${formatReportDate(to)}';
}
