import 'package:flutter_test/flutter_test.dart';
import 'package:npd_shield/data/models/risk_marker.dart';
import 'package:npd_shield/data/risk_markers.dart';
import 'package:npd_shield/domain/risk/risk_analyzer.dart';
import 'package:npd_shield/domain/risk/safety_index.dart';

import 'fixtures/risk_contract_corpus.dart';

RiskMatch _match(RiskSeverity severity, String code) => RiskMatch(
  markerCode: code,
  severity: severity,
  matchedText: code,
  description: 'Описание',
  suggestion: 'Альтернатива',
);

/// Консолидированная проверка критериев готовности PRD модуля Risk Shield.
///
/// Каждый тест соответствует пункту «Критерии готовности» в
/// `docs/prd-risk-shield.md`. Отдельные аспекты покрыты профильными тестами
/// (`risk_marker_base_test`, `risk_accuracy_test`, `risk_analyzer_test`,
/// `safety_index_test`, `risk_report_repository_test`,
/// `risk_shield_screen_test`); здесь критерии собраны в одном месте, чтобы
/// фазу можно было подтвердить одним прогоном.
void main() {
  final analyzer = RiskAnalyzerUseCase(
    builtInRiskMarkers.map((d) => d.toMarker()).toList(),
  );

  group('Критерии готовности PRD Risk Shield', () {
    test('1. База содержит минимум 50 маркеров риска', () {
      expect(builtInRiskMarkers.length, greaterThanOrEqualTo(50));
    });

    test('2. Точность обнаружения > 90% на тестовой базе', () async {
      var expected = 0;
      var found = 0;
      for (final doc in unsafeRiskCorpus) {
        final report = await analyzer.analyze(doc.text);
        final codes = report.risks.map((r) => r.markerCode).toSet();
        for (final code in doc.expectedMarkerCodes) {
          expected++;
          if (codes.contains(code)) found++;
        }
      }
      expect(found / expected, greaterThan(0.9));
    });

    test('3. Ложноположительные срабатывания < 5%', () async {
      var flagged = 0;
      for (final doc in safeRiskCorpus) {
        final report = await analyzer.analyze(doc.text);
        if (report.risks.isNotEmpty) flagged++;
      }
      expect(flagged / safeRiskCorpus.length, lessThan(0.05));
    });

    test('4. Время анализа договора 30 КБ < 500 мс', () async {
      final buffer = StringBuffer();
      const unit =
          'Исполнитель оказывает услуги по договору. '
          'Заказчик оплачивает результат работ по акту. ';
      while (buffer.length < 30 * 1024) {
        buffer.write(unit);
      }

      final stopwatch = Stopwatch()..start();
      await analyzer.analyze(buffer.toString());
      stopwatch.stop();

      expect(stopwatch.elapsedMilliseconds, lessThan(500));
    });

    test('5. Индекс безопасности корректен для всех сценариев', () {
      const calculator = SafetyIndexCalculator();

      expect(calculator.calculate(const [], totalMarkers: 50), 100);
      expect(
        calculator.calculate([
          _match(RiskSeverity.critical, 'a'),
          _match(RiskSeverity.critical, 'b'),
          _match(RiskSeverity.critical, 'c'),
        ], totalMarkers: 3),
        0,
      );
      final mixed = calculator.calculate([
        _match(RiskSeverity.medium, 'b'),
        _match(RiskSeverity.low, 'c'),
      ], totalMarkers: 50);
      expect(mixed, inInclusiveRange(0, 100));
      expect(mixed, lessThan(100));

      // Повторные срабатывания одного маркера штрафуют один раз.
      final repeated = calculator.calculate([
        _match(RiskSeverity.critical, 'a'),
        _match(RiskSeverity.critical, 'a'),
      ], totalMarkers: 50);
      final once = calculator.calculate([
        _match(RiskSeverity.critical, 'a'),
      ], totalMarkers: 50);
      expect(repeated, once);
    });

    test('6. Альтернативы предлагаются для 100% найденных рисков', () async {
      for (final doc in unsafeRiskCorpus) {
        final report = await analyzer.analyze(doc.text);
        for (final risk in report.risks) {
          expect(risk.suggestion, isNotEmpty, reason: risk.markerCode);
          expect(risk.description, isNotEmpty, reason: risk.markerCode);
          expect(risk.matchedText, isNotEmpty, reason: risk.markerCode);
        }
      }
    });

    test('7. Отчёт проверки пригоден для истории (индекс и число рисков)', () async {
      final report = await analyzer.analyze(
        unsafeRiskCorpus.first.text,
        sourceName: 'dogovor.txt',
      );

      expect(report.sourceName, 'dogovor.txt');
      expect(report.createdAt, isNotNull);
      expect(report.safetyIndex, inInclusiveRange(0, 100));
      expect(report.riskCount, report.risks.length);
    });

    test('8. Уровни риска сопровождаются текстовыми метками', () {
      for (final severity in RiskSeverity.values) {
        expect(severity.label, isNotEmpty);
        expect(severity.pluralLabel, isNotEmpty);
      }
      expect(SafetyLevel.green.label, isNotEmpty);
      expect(SafetyLevel.yellow.label, isNotEmpty);
      expect(SafetyLevel.red.label, isNotEmpty);
    });
  });
}
