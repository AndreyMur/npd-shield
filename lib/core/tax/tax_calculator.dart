import '../constants/tax_constants.dart';

/// Результат расчёта налога для заданного дохода.
class TaxCalculation {
  /// Доход, для которого выполнен расчёт (в рублях).
  final double income;

  /// Начисленный налог 6% от дохода (в рублях).
  final double accruedTax;

  /// Фиксированная часть страховых взносов ИП, вычтенная из налога.
  final double insuranceDeduction;

  /// Сумма налога к уплате после вычета взносов (в рублях), не может быть < 0.
  final double payableTax;

  /// Признак превышения лимита годового дохода для режима НПД.
  final bool limitExceeded;

  const TaxCalculation({
    required this.income,
    required this.accruedTax,
    required this.insuranceDeduction,
    required this.payableTax,
    required this.limitExceeded,
  });
}

/// Рассчитывает налог 6% от дохода с вычетом фиксированной части
/// страховых взносов ИП в соответствии с константами [TaxConstants].
///
/// Отрицательный доход трактуется как нулевой.
///
/// Формула:
/// - accrued = max(0, income) * rate
/// - payable = max(0, accrued - fixedInsurancePremium)
class TaxCalculator {
  const TaxCalculator();

  TaxCalculation calculate({required double income}) {
    final effectiveIncome = income < 0 ? 0.0 : income;
    final accruedTax = effectiveIncome * TaxConstants.rate;
    final deduction = TaxConstants.fixedInsurancePremium;
    final payableTax =
        (accruedTax - deduction) < 0 ? 0.0 : accruedTax - deduction;

    return TaxCalculation(
      income: effectiveIncome,
      accruedTax: accruedTax,
      insuranceDeduction: deduction,
      payableTax: payableTax,
      limitExceeded: effectiveIncome > TaxConstants.limit,
    );
  }
}
