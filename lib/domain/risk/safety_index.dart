import '../../data/models/risk_marker.dart';

/// Цветовая зона индекса безопасности договора.
enum SafetyLevel {
  /// Безопасно — индекс 80% и выше (зелёный).
  green,

  /// Средний риск — индекс 50–79% (жёлтый).
  yellow,

  /// Высокий риск — индекс ниже 50% (красный).
  red;

  /// Человекочитаемая метка для интерфейса и скринридеров.
  String get label => switch (this) {
    SafetyLevel.green => 'Высокая безопасность',
    SafetyLevel.yellow => 'Средний риск',
    SafetyLevel.red => 'Высокий риск',
  };
}

/// Расчёт индекса безопасности договора (0–100%).
///
/// Индекс учитывает два фактора:
/// * **широту** — какую долю базы маркеров нашли в договоре;
/// * **тяжесть** — штраф за каждый найденный маркер по его уровню.
///
/// Формула: `index = 100 × (1 − сработавшие / всего) − Σ штрафов`, результат
/// ограничен диапазоном 0–100. Если база пуста или рисков нет, индекс равен
/// 100%. Повторные срабатывания одного маркера штрафуют один раз.
class SafetyIndexCalculator {
  /// Штраф за найденный критический маркер.
  static const double criticalPenalty = 35;

  /// Штраф за найденный маркер среднего уровня.
  static const double mediumPenalty = 12;

  /// Штраф за найденный маркер низкого уровня.
  static const double lowPenalty = 3;

  /// Нижняя граница зелёной зоны (безопасно).
  static const double greenThreshold = 80;

  /// Нижняя граница жёлтой зоны (средний риск).
  static const double yellowThreshold = 50;

  const SafetyIndexCalculator();

  /// Считает индекс безопасности по найденным [matches].
  ///
  /// [totalMarkers] — общее число маркеров в базе проверки.
  double calculate(List<RiskMatch> matches, {required int totalMarkers}) {
    if (totalMarkers <= 0 || matches.isEmpty) return 100;

    final severityByCode = <String, RiskSeverity>{};
    for (final match in matches) {
      severityByCode.putIfAbsent(match.markerCode, () => match.severity);
    }

    final coverage = severityByCode.length / totalMarkers;
    final coverageScore = 100 * (1 - coverage);

    var penalty = 0.0;
    for (final severity in severityByCode.values) {
      penalty += switch (severity) {
        RiskSeverity.critical => criticalPenalty,
        RiskSeverity.medium => mediumPenalty,
        RiskSeverity.low => lowPenalty,
      };
    }

    return (coverageScore - penalty).clamp(0, 100).toDouble();
  }

  /// Определяет цветовую зону индекса безопасности.
  static SafetyLevel levelFor(double index) {
    if (index >= greenThreshold) return SafetyLevel.green;
    if (index >= yellowThreshold) return SafetyLevel.yellow;
    return SafetyLevel.red;
  }
}
