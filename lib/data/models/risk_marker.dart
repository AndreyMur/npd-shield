import 'package:isar/isar.dart';

part 'risk_marker.g.dart';

/// Уровень риска переквалификации договора в трудовой.
///
/// Порядок объявления задаёт «вес» уровня: [critical] опаснее [medium],
/// а [medium] — [low]. На него опирается сортировка найденных рисков.
enum RiskSeverity {
  /// Прямое указание на трудовые отношения (красный уровень).
  critical,

  /// Косвенный признак подчинённости (жёлтый уровень).
  medium,

  /// Незначительный или формальный риск (зелёный уровень).
  low;

  /// Человекочитаемая метка уровня для интерфейса и скринридеров.
  String get label => switch (this) {
    RiskSeverity.critical => 'Критический',
    RiskSeverity.medium => 'Средний',
    RiskSeverity.low => 'Низкий',
  };
}

/// Маркер риска — правило поиска опасной формулировки в тексте договора.
///
/// [pattern] — RegExp-шаблон (без учёта регистра), [description] — суть риска,
/// [example] — пример небезопасной формулировки, [suggestion] — безопасная
/// альтернатива, которую можно скопировать в договор. [code] — стабильный
/// строковый идентификатор, переживающий пересоздание базы данных.
@collection
class RiskMarker {
  Id id = Isar.autoIncrement;

  @Index()
  late String code;

  /// RegExp-шаблон поиска риска в тексте договора.
  late String pattern;

  @Index()
  @enumerated
  late RiskSeverity severity;

  /// Описание риска простым языком.
  late String description;

  /// Пример небезопасной формулировки.
  late String example;

  /// Безопасная альтернатива формулировки.
  late String suggestion;

  RiskMarker({
    required this.code,
    required this.pattern,
    required this.severity,
    required this.description,
    required this.example,
    required this.suggestion,
  });
}

/// Найденное в тексте совпадение с маркером риска.
///
/// Встраивается в [RiskReport], чтобы результат проверки хранился целиком
/// и не зависел от текущей версии базы маркеров.
@embedded
class RiskMatch {
  /// Код маркера ([RiskMarker.code]), по которому найдено совпадение.
  String markerCode = '';

  @enumerated
  RiskSeverity severity = RiskSeverity.low;

  /// Фрагмент текста договора, в котором сработал маркер.
  String matchedText = '';

  /// Позиция начала совпадения в тексте договора.
  int start = 0;

  /// Позиция конца совпадения в тексте договора.
  int end = 0;

  String description = '';

  String example = '';

  String suggestion = '';

  RiskMatch({
    this.markerCode = '',
    this.severity = RiskSeverity.low,
    this.matchedText = '',
    this.start = 0,
    this.end = 0,
    this.description = '',
    this.example = '',
    this.suggestion = '',
  });
}

/// Результат проверки договора на риски.
///
/// [risks] — все найденные совпадения, [safetyIndex] — индекс безопасности
/// (0–100%), рассчитываемый по найденным рискам.
@collection
class RiskReport {
  Id id = Isar.autoIncrement;

  @Index()
  DateTime createdAt = DateTime.now();

  /// Имя проверенного файла (без пути).
  late String sourceName;

  /// Длина проверенного текста в символах.
  late int textLength;

  List<RiskMatch> risks = [];

  double safetyIndex = 0;

  RiskReport({
    required this.sourceName,
    required this.textLength,
    this.risks = const [],
    this.safetyIndex = 0,
  });
}
