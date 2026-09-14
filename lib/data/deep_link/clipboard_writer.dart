import 'package:flutter/services.dart';

/// Записывает текст в системный буфер обмена.
///
/// Абстракция нужна для fallback-сценария deep link и для подмены в тестах.
abstract class ClipboardWriter {
  /// Копирует [text] в буфер обмена.
  Future<void> write(String text);
}

/// Реализация [ClipboardWriter] через системный буфер обмена Flutter.
class SystemClipboardWriter implements ClipboardWriter {
  const SystemClipboardWriter();

  @override
  Future<void> write(String text) =>
      Clipboard.setData(ClipboardData(text: text));
}
