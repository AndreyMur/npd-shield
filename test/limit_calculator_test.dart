import 'package:flutter_test/flutter_test.dart';
import 'package:npd_shield/core/constants/tax_constants.dart';
import 'package:npd_shield/domain/limit/limit_calculator.dart';

void main() {
  group('LimitCalculator.levelFor — цветовая кодировка', () {
    test('зелёный < 70%', () {
      expect(LimitCalculator().calculate(usedAmount: 0, averageMonthlyIncome: 0).level,
          LimitLevel.green);
      expect(LimitCalculator().calculate(usedAmount: 100, averageMonthlyIncome: 0).level,
          LimitLevel.green);
    });

    test('жёлтый 70–90%', () {
      final yellow = LimitCalculator().calculate(
        usedAmount: TaxConstants.limit * 0.7,
        averageMonthlyIncome: 0,
      );
      expect(yellow.level, LimitLevel.yellow);

      final at70 = LimitCalculator().calculate(
        usedAmount: TaxConstants.limit * 0.7,
        averageMonthlyIncome: 0,
      );
      expect(at70.level, LimitLevel.yellow);

      final at90 = LimitCalculator().calculate(
        usedAmount: TaxConstants.limit * 0.9,
        averageMonthlyIncome: 0,
      );
      expect(at90.level, LimitLevel.yellow);
    });

    test('красный > 90%', () {
      final red = LimitCalculator().calculate(
        usedAmount: TaxConstants.limit * 0.91,
        averageMonthlyIncome: 0,
      );
      expect(red.level, LimitLevel.red);

      final over = LimitCalculator().calculate(
        usedAmount: TaxConstants.limit * 1.2,
        averageMonthlyIncome: 0,
      );
      expect(over.level, LimitLevel.red);
    });
  });

  group('LimitCalculator.calculate — расчёт относительно лимита', () {
    test('граничное значение 0%', () {
      final result = LimitCalculator().calculate(usedAmount: 0, averageMonthlyIncome: 0);
      expect(result.ratio, 0);
      expect(result.amountRemaining, TaxConstants.limit);
    });

    test('граничное значение 100%', () {
      final result = LimitCalculator().calculate(
        usedAmount: TaxConstants.limit,
        averageMonthlyIncome: 0,
      );
      expect(result.ratio, 1.0);
      expect(result.amountRemaining, 0);
      expect(result.daysRemaining, 0);
    });

    test('превышение лимита — отрицательный остаток', () {
      final result = LimitCalculator().calculate(
        usedAmount: TaxConstants.limit * 1.1,
        averageMonthlyIncome: 0,
      );
      expect(result.amountRemaining, lessThan(0));
      expect(result.daysRemaining, 0);
    });
  });

  group('LimitCalculator — прогноз исчерпания', () {
    test('прогноз на основе среднего дохода за 3 месяца', () {
      // Средний доход 100 000₽/мес, остаток 1 200 000₽.
      final result = LimitCalculator().calculate(
        usedAmount: TaxConstants.limit / 2,
        averageMonthlyIncome: 100000,
      );
      expect(result.amountRemaining, closeTo(1200000, 0.001));
      // ~1200000 / (100000 / 30.44) ≈ 365 дней — выходит за горизонт 3 месяцев.
      expect(result.daysRemaining, greaterThan(LimitCalculator.forecastHorizonDays));
      expect(result.isBeyondHorizon, isTrue);
    });

    test('прогноз без дохода недоступен (null)', () {
      final result = LimitCalculator().calculate(usedAmount: 100, averageMonthlyIncome: 0);
      expect(result.daysRemaining, isNull);
      expect(result.isBeyondHorizon, isFalse);
      expect(result.text, contains('до лимита осталось'));
    });

    test('прогноз в пределах горизонта 3 месяцев', () {
      final result = LimitCalculator().calculate(
        usedAmount: TaxConstants.limit - 100000,
        averageMonthlyIncome: 100000,
      );
      final days = result.daysRemaining!;
      expect(days, greaterThan(0));
      expect(days, lessThanOrEqualTo(LimitCalculator.forecastHorizonDays));
      expect(result.isBeyondHorizon, isFalse);
    });

    test('граничное значение остатка ровно на границе горизонта', () {
      // До исчерпания ровно 92 дня (горизонт).
      final monthly = 100000.0;
      final used = TaxConstants.limit - (monthly / LimitCalculator.daysPerMonth) * 92;
      final result = LimitCalculator().calculate(
        usedAmount: used,
        averageMonthlyIncome: monthly,
      );
      expect(result.daysRemaining, 92);
      expect(result.isBeyondHorizon, isFalse);
    });

    test('текстовый прогноз «до лимита осталось X руб. (Y дней)»', () {
      final result = LimitCalculator().calculate(
        usedAmount: TaxConstants.limit - 100000,
        averageMonthlyIncome: 100000,
      );
      expect(result.daysRemaining, isNotNull);
      expect(result.isBeyondHorizon, isFalse);
      expect(result.text, startsWith('до лимита осталось 100 000 руб. ('));
      expect(result.text, endsWith(')'));
    });

    test('текст за пределами горизонта — «более 3 месяцев»', () {
      final result = LimitCalculator().calculate(
        usedAmount: TaxConstants.limit / 2,
        averageMonthlyIncome: 100000,
      );
      expect(result.text, contains('более 3 месяцев'));
    });
  });

  group('LimitCalculator.pluralDays — склонение слова «день»', () {
    test('правильное склонение', () {
      expect(LimitCalculator.pluralDays(1), '1 день');
      expect(LimitCalculator.pluralDays(2), '2 дня');
      expect(LimitCalculator.pluralDays(4), '4 дня');
      expect(LimitCalculator.pluralDays(5), '5 дней');
      expect(LimitCalculator.pluralDays(11), '11 дней');
      expect(LimitCalculator.pluralDays(21), '21 день');
      expect(LimitCalculator.pluralDays(22), '22 дня');
      expect(LimitCalculator.pluralDays(25), '25 дней');
    });
  });
}
