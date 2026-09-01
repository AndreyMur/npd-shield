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
  /// Ограничен горизонтом 3 месяца из соображений точности (погрешность ±15 дней).
  int? get daysRemaining {
    if (amountRemaining <= 0) return 0;
    if (averageMonthlyIncome <= 0) return null;
    final daily = averageMonthlyIncome / LimitCalculator.daysPerMonth;
    final days = (amountRemaining / daily).ceil();
    return days > LimitCalculator.forecastHorizonDays
        ? LimitCalculator.forecastHorizonDays
        : days;
  }

  /// Текстовый прогноз «до лимита осталось X руб. (Y дней)».
  String get text {
    final amount = LimitCalculator.formatAmount(amountRemaining);
    final days = daysRemaining;
    if (days == null) {
      return 'до лимита осталось $amount руб.';
    }
    return 'до лимита осталось $amount руб. ($days дней)';
  }
}

class LimitCalculator {
  static const int forecastHorizonDays = 92; // ~3 месяца
  static const double daysPerMonth = 30.44;

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
    if (ratio < 0.7) return LimitLevel.green;
    if (ratio > 0.9) return LimitLevel.red;
    return LimitLevel.yellow;
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
