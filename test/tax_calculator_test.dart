import 'package:flutter_test/flutter_test.dart';
import 'package:npd_shield/core/constants/tax_constants.dart';
import 'package:npd_shield/core/tax/tax_calculator.dart';

void main() {
  const calculator = TaxCalculator();

  group('TaxCalculator.accruedTax', () {
    test('0 дохода даёт 0 начисленного налога', () {
      final result = calculator.calculate(income: 0);
      expect(result.accruedTax, 0);
      expect(result.payableTax, 0);
      expect(result.limitExceeded, isFalse);
    });

    test('доход 100000 даёт налог ровно 6%', () {
      final result = calculator.calculate(income: 100000);
      expect(result.accruedTax, 100000 * TaxConstants.rate);
      expect(result.accruedTax, closeTo(6000, 0.001));
    });

    test('точность расчёта в пределах ±1% от расчёта ФНС', () {
      final incomes = [0.0, 1000.0, 45000.0, 600000.0, 1200000.0, 2399999.0, 2400000.0];
      for (final income in incomes) {
        final result = calculator.calculate(income: income);
        final fnsTax = income * 0.06;
        final tolerance = fnsTax * 0.01;
        expect(
          result.accruedTax,
          closeTo(fnsTax, tolerance),
          reason: 'income=$income, accrued=${result.accruedTax}, fns=$fnsTax',
        );
      }
    });
  });

  group('TaxCalculator.payableTax', () {
    test('вычитает фиксированную часть страховых взносов', () {
      final income = 1000000.0;
      final result = calculator.calculate(income: income);
      final expectedPayable = income * TaxConstants.rate - TaxConstants.fixedInsurancePremium;
      expect(result.payableTax, closeTo(expectedPayable, 0.001));
      expect(result.insuranceDeduction, TaxConstants.fixedInsurancePremium);
    });

    test('налог не бывает отрицательным при малом доходе', () {
      final result = calculator.calculate(income: 100000);
      expect(result.accruedTax, 6000);
      expect(result.payableTax, 0);
    });

    test('доход, при котором налог впервые становится положительным', () {
      final threshold = TaxConstants.fixedInsurancePremium / TaxConstants.rate;
      final below = calculator.calculate(income: threshold - 100);
      final above = calculator.calculate(income: threshold + 100);
      expect(below.payableTax, 0);
      expect(above.payableTax, greaterThan(0));
    });
  });

  group('TaxCalculator.limitExceeded', () {
    test('не превышает лимит при доходе ниже 2.4 млн', () {
      expect(calculator.calculate(income: 2399999).limitExceeded, isFalse);
      expect(calculator.calculate(income: 2400000).limitExceeded, isFalse);
    });

    test('превышает лимит при доходе выше 2.4 млн', () {
      expect(calculator.calculate(income: 2400001).limitExceeded, isTrue);
      expect(calculator.calculate(income: 3000000).limitExceeded, isTrue);
    });
  });

  group('TaxCalculator edge cases', () {
    test('граница лимита: ровно 2.4 млн не считается превышением', () {
      final result = calculator.calculate(income: TaxConstants.limit);
      expect(result.limitExceeded, isFalse);
      expect(result.accruedTax, closeTo(144000, 0.001));
    });

    test('отрицательный доход трактуется как нулевой доход', () {
      final result = calculator.calculate(income: -5000);
      expect(result.payableTax, 0);
      expect(result.accruedTax, 0);
      expect(result.limitExceeded, isFalse);
    });
  });
}
