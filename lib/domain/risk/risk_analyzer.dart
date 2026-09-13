import '../../data/models/risk_marker.dart';
import 'risk_analysis_thresholds.dart';
import 'safety_index.dart';

/// Доменный use case проверки текста договора на маркеры риска.
///
/// Поиск по всем маркерам запускается параллельно: каждый маркер
/// обрабатывается отдельной задачей, а результаты собираются в один отчёт.
class RiskAnalyzerUseCase {
  /// База маркеров, по которой выполняется поиск.
  final List<RiskMarker> markers;

  /// Калькулятор индекса безопасности по найденным рискам.
  final SafetyIndexCalculator indexCalculator;

  /// Пороги чувствительности: длина совпадения и окно отрицаний.
  final RiskAnalysisThresholds thresholds;

  const RiskAnalyzerUseCase(
    this.markers, {
    this.indexCalculator = const SafetyIndexCalculator(),
    this.thresholds = const RiskAnalysisThresholds(),
  });

  /// Ищет все совпадения маркеров в [text] и возвращает отчёт.
  ///
  /// [sourceName] — имя проверенного файла, сохраняется в отчёте.
  Future<RiskReport> analyze(String text, {String sourceName = ''}) async {
    final compiled = <_CompiledMarker>[];
    for (final marker in markers) {
      final regexp = _tryCompile(marker.pattern);
      if (regexp != null) {
        compiled.add(_CompiledMarker(marker, regexp));
      }
    }

    final results = await Future.wait(
      compiled.map((entry) => Future(() => _findMatches(entry, text))),
    );

    final matches = <RiskMatch>[];
    for (final group in results) {
      matches.addAll(group);
    }
    matches.sort((a, b) {
      final bySeverity = a.severity.index.compareTo(b.severity.index);
      return bySeverity != 0 ? bySeverity : a.start.compareTo(b.start);
    });

    return RiskReport(
      sourceName: sourceName,
      textLength: text.length,
      risks: matches,
      safetyIndex: indexCalculator.calculate(
        matches,
        totalMarkers: markers.length,
      ),
    );
  }

  List<RiskMatch> _findMatches(_CompiledMarker entry, String text) {
    final matches = <RiskMatch>[];
    for (final match in entry.regexp.allMatches(text)) {
      final matchedText = match.group(0) ?? '';
      if (!thresholds.acceptsMatch(matchedText)) continue;
      if (thresholds.isNegated(text, match.start)) continue;
      matches.add(
        RiskMatch(
          markerCode: entry.marker.code,
          severity: entry.marker.severity,
          matchedText: matchedText,
          start: match.start,
          end: match.end,
          description: entry.marker.description,
          example: entry.marker.example,
          suggestion: entry.marker.suggestion,
        ),
      );
    }
    return matches;
  }

  /// Компилирует паттерн; некорректные шаблоны пропускаются, не ломая анализ.
  RegExp? _tryCompile(String pattern) {
    try {
      return RegExp(
        pattern,
        caseSensitive: false,
        multiLine: true,
        dotAll: true,
        unicode: true,
      );
    } catch (_) {
      return null;
    }
  }
}

class _CompiledMarker {
  final RiskMarker marker;
  final RegExp regexp;

  const _CompiledMarker(this.marker, this.regexp);
}
