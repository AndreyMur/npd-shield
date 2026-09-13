import 'package:flutter/foundation.dart';

/// Результат генерации PDF-документа.
///
/// Общий тип для всех документов приложения (договоры, чеки, акты): байты
/// файла, число страниц, предлагаемое имя файла и время генерации.
class GeneratedPdf {
  final Uint8List bytes;

  /// Количество страниц в документе.
  final int pageCount;

  /// Предлагаемое имя файла.
  final String fileName;

  /// Время генерации (для проверки нефункциональных требований).
  final Duration generationTime;

  GeneratedPdf({
    required this.bytes,
    required this.pageCount,
    required this.fileName,
    required this.generationTime,
  });
}
