import 'package:flutter_test/flutter_test.dart';
import 'package:npd_shield/data/models/risk_marker.dart';
import 'package:npd_shield/domain/risk/risk_analyzer.dart';
import 'package:npd_shield/domain/risk/safety_index.dart';

RiskMatch match({
  String code = 'marker',
  RiskSeverity severity = RiskSeverity.low,
}) {
  return RiskMatch(
    markerCode: code,
    severity: severity,
    matchedText: 'фрагмент',
  );
}

RiskMarker marker({
  String code = 'marker',
  String pattern = 'риск',
  RiskSeverity severity = RiskSeverity.medium,
}) {
  return RiskMarker(
    code: code,
    pattern: pattern,
    severity: severity,
    description: 'Описание $code',
    example: 'Пример $code',
    suggestion: 'Безопасная формулировка $code',
  );
}

void main() {
  const calculator = SafetyIndexCalculator();

  group('SafetyIndexCalculator', () {
    test('нет рисков — индекс 100%', () {
      expect(calculator.calculate(const [], totalMarkers: 15), 100);
      expect(SafetyIndexCalculator.levelFor(100), SafetyLevel.green);
    });

    test('пустая база маркеров — индекс 100%', () {
      expect(calculator.calculate([match()], totalMarkers: 0), 100);
    });

    test('все критические риски — индекс 0%', () {
      final matches = [
        match(code: 'a', severity: RiskSeverity.critical),
        match(code: 'b', severity: RiskSeverity.critical),
        match(code: 'c', severity: RiskSeverity.critical),
      ];

      final index = calculator.calculate(matches, totalMarkers: 3);

      expect(index, 0);
      expect(SafetyIndexCalculator.levelFor(index), SafetyLevel.red);
    });

    test('смешанные риски — индекс между 0 и 100', () {
      final matches = [
        match(code: 'a', severity: RiskSeverity.critical),
        match(code: 'b', severity: RiskSeverity.medium),
        match(code: 'c', severity: RiskSeverity.low),
      ];

      final index = calculator.calculate(matches, totalMarkers: 10);

      // 100 * (1 - 3/10) - (35 + 12 + 3) = 70 - 50 = 20
      expect(index, 20);
      expect(index, inExclusiveRange(0, 100));
    });

    test('повторные срабатывания одного маркера штрафуют один раз', () {
      final once = calculator.calculate(
        [match(code: 'a', severity: RiskSeverity.medium)],
        totalMarkers: 10,
      );
      final twice = calculator.calculate(
        [
          match(code: 'a', severity: RiskSeverity.medium),
          match(code: 'a', severity: RiskSeverity.medium),
        ],
        totalMarkers: 10,
      );

      expect(twice, once);
    });

    test('критический риск снижает индекс сильнее низкого', () {
      final critical = calculator.calculate(
        [match(code: 'a', severity: RiskSeverity.critical)],
        totalMarkers: 20,
      );
      final low = calculator.calculate(
        [match(code: 'b', severity: RiskSeverity.low)],
        totalMarkers: 20,
      );

      expect(critical, lessThan(low));
      expect(low, lessThan(100));
    });

    test('не уходит ниже нуля при множестве критических рисков', () {
      final matches = List.generate(
        10,
        (i) => match(code: 'c$i', severity: RiskSeverity.critical),
      );

      expect(calculator.calculate(matches, totalMarkers: 10), 0);
    });

    test('определяет цветовые зоны индекса', () {
      expect(SafetyIndexCalculator.levelFor(100), SafetyLevel.green);
      expect(SafetyIndexCalculator.levelFor(80), SafetyLevel.green);
      expect(SafetyIndexCalculator.levelFor(79.9), SafetyLevel.yellow);
      expect(SafetyIndexCalculator.levelFor(50), SafetyLevel.yellow);
      expect(SafetyIndexCalculator.levelFor(49.9), SafetyLevel.red);
    });
  });

  group('RiskAnalyzerUseCase + SafetyIndexCalculator', () {
    test('проставляет индекс безопасности в отчёт', () async {
      final analyzer = RiskAnalyzerUseCase([
        marker(
          code: 'labor',
          pattern: 'трудовой договор',
          severity: RiskSeverity.critical,
        ),
        marker(code: 'safe', pattern: 'этого нет', severity: RiskSeverity.low),
      ]);

      final report = await analyzer.analyze('Заключён трудовой договор.');

      // Широта: 1 из 2 маркеров → 50; штраф за критический риск 35 → 15.
      expect(report.safetyIndex, 15);
    });

    test('без совпадений индекс 100', () async {
      final analyzer = RiskAnalyzerUseCase([marker(pattern: 'нет')]);

      final report = await analyzer.analyze('чистый текст без рисков');

      expect(report.safetyIndex, 100);
    });
  });
}
