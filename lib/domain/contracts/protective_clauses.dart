/// Стандартные «защитные формулировки» договора.
///
/// Доказывают гражданско-правовой (ГПХ) характер отношений между
/// Исполнителем на НПД и Заказчиком и снижают риск переквалификации
/// договора в трудовой. Вставляются автоматически в каждый шаблон,
/// чтобы 100% договоров содержали защитные положения.
class ProtectiveClause {
  /// Стабильный ключ формулировки.
  final String key;

  /// Канонический текст формулировки.
  final String text;

  /// Регулярное выражение для распознавания формулировки в тексте шаблона.
  final RegExp detector;

  const ProtectiveClause({
    required this.key,
    required this.text,
    required this.detector,
  });

  /// Проверяет, что [text] содержит данную формулировку.
  bool matches(String text) => detector.hasMatch(text);
}

/// Заголовок автоматически вставляемого раздела защитных формулировок.
const String protectiveSectionHeading = 'ЗАЩИТНЫЕ ПОЛОЖЕНИЯ';

/// Канонический набор защитных формулировок (ГПХ-характер отношений).
final List<ProtectiveClause> protectiveClauses = [
  ProtectiveClause(
    key: 'executor_determines_order',
    text:
        'Исполнитель самостоятельно определяет порядок и способы '
        'выполнения работ, распределяет рабочее время и выбирает '
        'используемые средства.',
    detector: RegExp(
      r'самостоятельно определяет порядок',
      caseSensitive: false,
    ),
  ),
  ProtectiveClause(
    key: 'executor_determines_schedule',
    text:
        'Сроки выполнения работ определяет Исполнитель; работы '
        'выполняются вне режима рабочего времени Заказчика.',
    detector: RegExp(
      r'сроки.{0,80}определяет\s+исполнитель',
      caseSensitive: false,
    ),
  ),
  ProtectiveClause(
    key: 'result_by_act',
    text: 'Результат работ передаётся Заказчику по акту приёма-передачи.',
    detector: RegExp(
      r'акт[уе]?\s+(сдачи-)?приёмки|акту\s+приёма-передачи',
      caseSensitive: false,
    ),
  ),
  ProtectiveClause(
    key: 'no_labor_relations',
    text:
        'Исполнитель не подчиняется правилам внутреннего трудового '
        'распорядка Заказчика и не состоит с ним в трудовых отношениях.',
    detector: RegExp(r'трудов', caseSensitive: false),
  ),
];

/// Возвращает `true`, если строка является заголовком раздела
/// защитных формулировок.
bool isProtectiveHeading(String line) =>
    line.trim().toUpperCase() == protectiveSectionHeading;

/// Возвращает `true`, если строка содержит защитную формулировку.
bool isProtectiveClause(String line) =>
    protectiveClauses.any((clause) => clause.matches(line));

/// Автоматически вставляет раздел защитных формулировок в [templateText].
///
/// Если раздел уже присутствует, текст возвращается без изменений
/// (идемпотентность). Раздел вставляется перед блоком реквизитов
/// («N. РЕКВИЗИТЫ…»), а если такого блока нет — в конец документа.
String withProtectiveClauses(String templateText) {
  if (templateText.contains(protectiveSectionHeading)) return templateText;

  final clauses = protectiveClauses.map((c) => c.text).join('\n\n');
  final section = '\n$protectiveSectionHeading\n\n$clauses\n';

  final requisites = RegExp(
    r'\n\d+\.\s*РЕКВИЗИТЫ',
    caseSensitive: false,
  ).firstMatch(templateText);
  if (requisites != null) {
    return templateText.replaceRange(
      requisites.start,
      requisites.start,
      section,
    );
  }
  return '$templateText$section';
}
