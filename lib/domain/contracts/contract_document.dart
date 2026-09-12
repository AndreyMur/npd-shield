import 'protective_clauses.dart';

/// Тип блока разобранного документа договора.
///
/// Используется для единообразного отображения документа: в живом
/// предпросмотре (Flutter-виджеты) и в сгенерированном PDF.
enum ContractBlockType {
  /// Заголовок договора (первая строка шапки, например «ДОГОВОР № …»).
  title,

  /// Подзаголовок шапки (вторая строка шапки, например «на разработку ПО»).
  subtitle,

  /// Заголовок раздела (например «1. ПРЕДМЕТ ДОГОВОРА»).
  heading,

  /// Обычный абзац текста.
  body,

  /// Строка реквизитов с подписью (содержит подчёркивания `_____`).
  signature,

  /// Строка «г. Город ... «дата»» с выравниванием по краям.
  meta,

  /// Защитная формулировка (ГПХ-характер) или её заголовок.
  protective,

  /// Вертикальный отступ: одна единица на каждую пустую строку шаблона.
  spacing,
}

/// Один блок разобранного документа.
class ContractBlock {
  final ContractBlockType type;

  /// Основной текст блока. Для [ContractBlockType.spacing] — пустой.
  final String text;

  /// Второй текст блока (правый край) для [ContractBlockType.meta].
  final String? secondaryText;

  /// Количество пустых строк шаблона для [ContractBlockType.spacing].
  final int spacingSteps;

  const ContractBlock(
    this.type,
    this.text, {
    this.secondaryText,
    this.spacingSteps = 1,
  });

  /// Является ли блок защитной формулировкой (маркируется значком щита).
  bool get isProtective => type == ContractBlockType.protective;
}

/// Результат разбора текста шаблона с подставленными значениями полей.
class ComposedContract {
  /// Полный текст шаблона после подстановки значений.
  final String rawText;

  /// Подставленные значения полей.
  final Map<String, String> values;

  /// Блоки документа в порядке следования.
  final List<ContractBlock> blocks;

  /// Ключи-плейсхолдеры `{{...}}`, для которых не было значения.
  final Set<String> unresolvedKeys;

  ComposedContract({
    required this.rawText,
    required this.values,
    required this.blocks,
    required this.unresolvedKeys,
  });

  /// Плейн-текст документа без пустых строк (для тестов и диагностики).
  String get plainText => blocks
      .where((b) => b.type != ContractBlockType.spacing)
      .map((b) => b.secondaryText == null || b.secondaryText!.isEmpty
          ? b.text
          : '${b.text} ${b.secondaryText}')
      .join('\n');
}

final RegExp _placeholderRegExp = RegExp(r'\{\{\s*([A-Za-zА-ЯЁа-яё0-9_]+)\s*\}\}');

/// Разбирает текст шаблона в блоки документа, заменяя плейсхолдеры `{{key}}`
/// значениями из [values].
///
/// Классификация строк:
/// * первые непустые строки до первой пустой строки — шапка договора
///   (заголовок + подзаголовок);
/// * строки вида «N. ВСЕ ЗАГЛАВНЫЕ» — заголовки разделов;
/// * строка «г. Город ... «дата»» — строка с выравниванием по краям;
/// * строки с подчёркиваниями — подписи сторон;
/// * остальные непустые строки — обычные абзацы;
/// * пустые строки превращаются в отступы.
/// [injectProtectiveClauses] включает автоматическую вставку раздела
/// защитных формулировок (ГПХ-характер) в текст договора.
ComposedContract composeContractDocument(
  String rawText,
  Map<String, String> values, {
  bool injectProtectiveClauses = true,
}) {
  final unresolved = <String>{};
  final source = injectProtectiveClauses
      ? withProtectiveClauses(rawText)
      : rawText;
  final substituted = _substitutePlaceholders(source, values, unresolved);
  final lines = substituted
      .split('\n')
      .map((line) => line.trimRight())
      .toList(growable: false);

  final blocks = <ContractBlock>[];
  var index = _skipBlanks(lines, 0);

  // Шапка договора: непустые строки до первой пустой строки.
  final headerEnd = index < lines.length
      ? _firstBlankFrom(lines, index)
      : index;
  var headerIndex = 0;
  while (index < headerEnd) {
    final blockType = headerIndex == 0
        ? ContractBlockType.title
        : ContractBlockType.subtitle;
    blocks.add(ContractBlock(blockType, lines[index].trim()));
    headerIndex++;
    index++;
  }

  while (index < lines.length) {
    final line = lines[index];
    if (line.trim().isEmpty) {
      var run = 0;
      while (index < lines.length && lines[index].trim().isEmpty) {
        run++;
        index++;
      }
      blocks.add(ContractBlock(ContractBlockType.spacing, '', spacingSteps: run));
      continue;
    }
    blocks.add(_classifyLine(line.trim()));
    index++;
  }

  return ComposedContract(
    rawText: substituted,
    values: Map.unmodifiable(values),
    blocks: blocks,
    unresolvedKeys: unresolved,
  );
}

int _skipBlanks(List<String> lines, int from) {
  var index = from;
  while (index < lines.length && lines[index].trim().isEmpty) {
    index++;
  }
  return index;
}

int _firstBlankFrom(List<String> lines, int from) {
  var index = from;
  while (index < lines.length && lines[index].trim().isNotEmpty) {
    index++;
  }
  return index;
}

/// Заменяет все плейсхолдеры `{{key}}` значениями из [values].
String _substitutePlaceholders(
  String text,
  Map<String, String> values,
  Set<String> unresolved,
) {
  return text.replaceAllMapped(_placeholderRegExp, (match) {
    final key = match.group(1)!;
    final value = values[key];
    if (value == null) {
      unresolved.add(key);
      return '';
    }
    return value;
  });
}

ContractBlock _classifyLine(String line) {
  if (_isMetaLine(line)) {
    final parts = line
        .split(RegExp(r'\s{4,}'))
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.length >= 2) {
      final left = parts.first;
      final right = parts.skip(1).join(' ');
      if (right.startsWith('«') && right.endsWith('»')) {
        return ContractBlock(ContractBlockType.meta, left, secondaryText: right);
      }
    }
    return ContractBlock(ContractBlockType.body, line);
  }
  if (isProtectiveHeading(line) || isProtectiveClause(line)) {
    return ContractBlock(ContractBlockType.protective, line);
  }
  if (_isHeading(line)) {
    return ContractBlock(ContractBlockType.heading, line);
  }
  if (line.contains('____')) {
    return ContractBlock(ContractBlockType.signature, line);
  }
  return ContractBlock(ContractBlockType.body, line);
}

/// Строка «г. Город ... «дата»»: содержит длинную серию пробелов и дату в «».
bool _isMetaLine(String line) {
  return line.startsWith('г. ') &&
      line.contains('«') &&
      line.contains('»') &&
      RegExp(r'\s{4,}').hasMatch(line);
}

/// Заголовок раздела вида «1. ВСЕ ЗАГЛАВНЫЕ БУКВЫ».
bool _isHeading(String line) {
  final match = RegExp(r'^\d{1,2}[\.\)]\s+(.+)$').firstMatch(line);
  if (match == null) return false;
  final rest = match.group(1)!;
  if (rest.isEmpty) return false;
  return rest == rest.toUpperCase() && rest.contains(RegExp(r'[А-ЯЁA-Z]'));
}
