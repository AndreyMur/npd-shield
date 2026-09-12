import 'package:flutter_test/flutter_test.dart';
import 'package:npd_shield/data/models/risk_marker.dart';
import 'package:npd_shield/data/risk_markers.dart';
import 'package:npd_shield/domain/risk/risk_analyzer.dart';

RiskMarker marker({
  String code = 'marker',
  String pattern = 'риск',
  RiskSeverity severity = RiskSeverity.medium,
  String suggestion = 'безопасная формулировка',
}) {
  return RiskMarker(
    code: code,
    pattern: pattern,
    severity: severity,
    description: 'Описание $code',
    example: 'Пример $code',
    suggestion: suggestion,
  );
}

void main() {
  group('RiskAnalyzerUseCase', () {
    test('находит совпадения по RegExp без учёта регистра', () async {
      final analyzer = RiskAnalyzerUseCase([
        marker(code: 'labor', pattern: r'трудовой\s+договор'),
      ]);

      final report = await analyzer.analyze(
        'Стороны заключили ТРУДОВОЙ ДОГОВОР на выполнение работ.',
      );

      expect(report.risks, hasLength(1));
      expect(report.risks.single.markerCode, 'labor');
      expect(report.risks.single.matchedText, 'ТРУДОВОЙ ДОГОВОР');
    });

    test('проставляет позиции и severity найденного совпадения', () async {
      const text = 'Договор содержит трудовой договор в тексте.';
      final analyzer = RiskAnalyzerUseCase([
        marker(
          code: 'labor',
          pattern: r'трудовой\s+договор',
          severity: RiskSeverity.critical,
        ),
      ]);

      final report = await analyzer.analyze(text);
      final match = report.risks.single;

      expect(match.severity, RiskSeverity.critical);
      expect(text.substring(match.start, match.end), 'трудовой договор');
      expect(match.description, 'Описание labor');
      expect(match.suggestion, 'безопасная формулировка');
    });

    test('параллельно анализирует все маркеры и собирает результаты', () async {
      final analyzer = RiskAnalyzerUseCase([
        marker(code: 'a', pattern: 'зарплата', severity: RiskSeverity.critical),
        marker(code: 'b', pattern: 'отпуск', severity: RiskSeverity.medium),
        marker(code: 'c', pattern: 'наличными', severity: RiskSeverity.low),
      ]);

      final report = await analyzer.analyze(
        'Зарплата, отпуск и оплата наличными указаны в договоре.',
      );

      expect(
        report.risks.map((m) => m.markerCode).toSet(),
        {'a', 'b', 'c'},
      );
    });

    test('сортирует риски: критические выше средних и низких', () async {
      final analyzer = RiskAnalyzerUseCase([
        marker(code: 'low', pattern: 'наличными', severity: RiskSeverity.low),
        marker(
          code: 'critical',
          pattern: 'трудовой договор',
          severity: RiskSeverity.critical,
        ),
        marker(code: 'medium', pattern: 'отпуск', severity: RiskSeverity.medium),
      ]);

      final report = await analyzer.analyze(
        'трудовой договор, отпуск, оплата наличными',
      );

      expect(
        report.risks.map((m) => m.markerCode).toList(),
        ['critical', 'medium', 'low'],
      );
    });

    test('находит несколько совпадений одного маркера', () async {
      final analyzer = RiskAnalyzerUseCase([
        marker(code: 'salary', pattern: 'зарплата'),
      ]);

      final report = await analyzer.analyze(
        'Зарплата в начале. Ещё раз зарплата в конце.',
      );

      expect(report.risks, hasLength(2));
    });

    test('пропускает некорректный RegExp, не ломая анализ', () async {
      final analyzer = RiskAnalyzerUseCase([
        marker(code: 'broken', pattern: '('),
        marker(code: 'ok', pattern: 'риск'),
      ]);

      final report = await analyzer.analyze('Здесь есть риск.');

      expect(report.risks, hasLength(1));
      expect(report.risks.single.markerCode, 'ok');
    });

    test('пустой текст не даёт совпадений', () async {
      final analyzer = RiskAnalyzerUseCase([
        marker(code: 'labor', pattern: r'трудовой\s+договор'),
      ]);

      final report = await analyzer.analyze('');

      expect(report.risks, isEmpty);
      expect(report.textLength, 0);
    });

    test('сохраняет имя источника и длину текста в отчёте', () async {
      final analyzer = RiskAnalyzerUseCase([marker(code: 'x', pattern: 'нет')]);

      final report = await analyzer.analyze(
        'короткий текст',
        sourceName: 'dogovor.txt',
      );

      expect(report.sourceName, 'dogovor.txt');
      expect(report.textLength, 'короткий текст'.length);
    });

    test('находит риски встроенной базой маркеров', () async {
      final analyzer = RiskAnalyzerUseCase(
        builtInRiskMarkers.map((d) => d.toMarker()).toList(),
      );

      final report = await analyzer.analyze(
        'Стороны заключают трудовой договор. Заказчик выплачивает '
        'заработную плату и предоставляет ежегодный оплачиваемый отпуск.',
      );

      expect(report.risks, isNotEmpty);
      expect(
        report.risks.any((m) => m.markerCode == 'labor_contract_term'),
        isTrue,
      );
      expect(report.risks.any((m) => m.markerCode == 'salary_term'), isTrue);
      expect(report.risks.first.severity, RiskSeverity.critical);
    });

    test('анализ текста 30 КБ быстрее 500 мс', () async {
      final analyzer = RiskAnalyzerUseCase(
        builtInRiskMarkers.map((d) => d.toMarker()).toList(),
      );
      final unit =
          'Исполнитель оказывает услуги по договору. '
          'Заказчик оплачивает результат работ по акту. ';
      final buffer = StringBuffer();
      while (buffer.length < 30 * 1024) {
        buffer.write(unit);
      }

      final stopwatch = Stopwatch()..start();
      await analyzer.analyze(buffer.toString());
      stopwatch.stop();

      expect(stopwatch.elapsedMilliseconds, lessThan(500));
    });
  });
}
