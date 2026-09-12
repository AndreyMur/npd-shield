import 'package:flutter/services.dart';

/// Санитайзер и валидатор пользовательского ввода конструктора договоров.
///
/// Защищает генератор от подстановки собственных плейсхолдеров шаблона
/// (`{{...}}`), управляющих и невидимых символов, а также от фрагментов
/// потенциально исполняемой разметки. Значения полей подставляются в текст
/// договора как есть, поэтому небезопасный ввод может испортить документ или
/// внедрить лишние данные.
class ContractInput {
  ContractInput._();

  /// Максимальная длина одного значения поля.
  static const int maxValueLength = 2000;

  static final RegExp _controlChars = RegExp(
    r'[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]',
  );
  static final RegExp _zeroWidth = RegExp(r'[\u200B-\u200D\uFEFF]');
  static final RegExp _placeholder = RegExp(r'\{\{|\}\}');
  static final RegExp _markup = RegExp(
    r'<\s*/?\s*(script|iframe|object|embed|style)\b',
    caseSensitive: false,
  );

  /// Возвращает `true`, если значение безопасно для подстановки в договор.
  static bool isSafe(String value) => validate(value) == null;

  /// Возвращает сообщение об ошибке для небезопасного значения или `null`.
  static String? validate(String? value) {
    final text = value ?? '';
    if (_placeholder.hasMatch(text)) {
      return 'Символы {{ }} в значениях полей недопустимы';
    }
    if (_controlChars.hasMatch(text) || _zeroWidth.hasMatch(text)) {
      return 'Ввод содержит недопустимые символы';
    }
    if (_markup.hasMatch(text)) {
      return 'Ввод содержит недопустимую разметку';
    }
    if (text.length > maxValueLength) {
      return 'Значение слишком длинное (максимум $maxValueLength символов)';
    }
    return null;
  }

  /// Обезвреживает значение: удаляет управляющие и невидимые символы,
  /// нейтрализует фигурные скобки плейсхолдеров и ограничивает длину.
  static String sanitize(String value) {
    var result = value
        .replaceAll(_zeroWidth, '')
        .replaceAll(_controlChars, '')
        .replaceAll('{', '(')
        .replaceAll('}', ')');
    if (result.length > maxValueLength) {
      result = result.substring(0, maxValueLength);
    }
    return result;
  }

  /// Проверяет безопасность текста шаблона.
  ///
  /// Шаблон — доверенный ассет, но проверка защищает от повреждённых или
  /// подменённых файлов: запрещает исполняемую разметку и плейсхолдеры с
  /// недопустимыми ключами (разрешены буквы, цифры и `_`).
  static String? validateTemplate(String template) {
    if (_markup.hasMatch(template)) {
      return 'Шаблон содержит недопустимую разметку';
    }
    final placeholder = RegExp(r'\{\{([^{}]*)\}\}');
    final malformed = RegExp(r'\{\{|\}\}');
    final stripped = template.replaceAll(placeholder, '');
    if (malformed.hasMatch(stripped)) {
      return 'Шаблон содержит некорректный плейсхолдер';
    }
    for (final match in placeholder.allMatches(template)) {
      final key = match.group(1)!.trim();
      if (!RegExp(r'^[A-Za-zА-ЯЁа-яё0-9_]+$').hasMatch(key)) {
        return 'Недопустимый ключ плейсхолдера: $key';
      }
    }
    return null;
  }
}

/// Форматтер поля ввода: не даёт ввести управляющие символы, невидимые
/// символы и фигурные скобки плейсхолдеров.
class ContractInputFormatter extends TextInputFormatter {
  const ContractInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final sanitized = ContractInput.sanitize(newValue.text);
    if (sanitized == newValue.text) return newValue;
    return TextEditingValue(
      text: sanitized,
      selection: TextSelection.collapsed(offset: sanitized.length),
    );
  }
}
