import '../../core/constants/tax_constants.dart';

/// Уровень исчерпания лимита для цветовой кодировки.
enum LimitLevel { green, yellow, red }

/// Результат расчёта лимита и прогноза исчерпания.
class LimitResult {
  final double limit;
  final double usedAmount;
  final double ratio;
  final LimitLevel level;
  final double averageMonthlyIncome;

  LimitResult({
    required this.limit,
    required this.usedAmount,
    required this.ratio,
    required this.level,
    required this.averageMonthlyIncome,
  });

  /// Сколько рублей осталось до лимита (может быть отрицательным при превышении).
  double get amountRemaining => limit - usedAmount;

  /// Прогноз количества дней до исчерпания лимита при текущем темпе.
  ///
  /// Возвращает `null`, если прогноз недоступен (нет дохода за последние 3 месяца).
  /// Не ограничивается горизонтом — для проверки выхода за горизонт см. [isBeyondHorizon].
  int? get daysRemaining {
    if (amountRemaining <= 0) return 0;
    if (averageMonthlyIncome <= 0) return null;
    final daily = averageMonthlyIncome / LimitCalculator.daysPerMonth;
    return (amountRemaining / daily).ceil();
  }

  /// Истинно, когда прогноз [daysRemaining] выходит за горизонт прогнозирования.
  bool get isBeyondHorizon {
    final days = daysRemaining;
    return days != null && days > LimitCalculator.forecastHorizonDays;
  }

  /// Текстовый прогноз «до лимита осталось X руб. (Y дней)».
  String get text {
    final amount = LimitCalculator.formatAmount(amountRemaining);
    final days = daysRemaining;
    if (days == null) {
      return 'до лимита осталось $amount руб.';
    }
    if (isBeyondHorizon) {
      return 'до лимита осталось $amount руб. (более 3 месяцев)';
    }
    return 'до лимита осталось $amount руб. (${LimitCalculator.pluralDays(days)})';
  }
}

class LimitCalculator {
  static const int forecastHorizonDays = 92; // ~3 месяца
  static const double daysPerMonth = 30.44;
  static const double yellowThreshold = 0.7;
  static const double redThreshold = 0.9;

  final double limit;

  const LimitCalculator({double? limit}) : limit = limit ?? TaxConstants.limit;

  /// Расчёт текущего значения относительно лимита.
  ///
  /// [usedAmount] — доход с начала года (limit — годовой лимит).
  /// [averageMonthlyIncome] — средний доход за последние 3 месяца.
  LimitResult calculate({
    required double usedAmount,
    required double averageMonthlyIncome,
  }) {
    final ratio = limit > 0 ? usedAmount / limit : 0.0;
    return LimitResult(
      limit: limit,
      usedAmount: usedAmount,
      ratio: ratio,
      level: levelFor(ratio),
      averageMonthlyIncome: averageMonthlyIncome,
    );
  }

  /// Цветовая кодировка: зелёный < 70%, жёлтый 70–90%, красный > 90%.
  static LimitLevel levelFor(double ratio) {
    if (ratio < yellowThreshold) return LimitLevel.green;
    if (ratio > redThreshold) return LimitLevel.red;
    return LimitLevel.yellow;
  }

  /// Русское склонение слова «день» по количеству.
  static String pluralDays(int days) {
    final n = days % 100;
    if (n >= 11 && n <= 14) return '$days дней';
    switch (days % 10) {
      case 1:
        return '$days день';
      case 2:
      case 3:
      case 4:
        return '$days дня';
      default:
        return '$days дней';
    }
  }

  static String formatAmount(double value) {
    final fixed = value.toStringAsFixed(0);
    final digits = fixed.replaceFirst('-', '');
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(' ');
      buffer.write(digits[i]);
    }
    return '${value < 0 ? '-' : ''}$buffer';
  }
}
