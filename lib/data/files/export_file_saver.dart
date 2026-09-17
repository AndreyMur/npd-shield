import 'dart:typed_data';

/// Сохраняет готовый файл экспорта на устройство пользователя.
///
/// Абстракция позволяет подменять нативный диалог сохранения в тестах.
abstract class ExportFileSaver {
  /// Открывает диалог сохранения и записывает [bytes] под именем [fileName].
  ///
  /// Возвращает путь сохранённого файла или `null`, если пользователь
  /// отменил сохранение.
  Future<String?> save({required String fileName, required Uint8List bytes});
}
