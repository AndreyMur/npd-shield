import 'dart:typed_data';

/// Двоичный файл, выбранный пользователем (например, резервная копия).
class PickedBinaryFile {
  /// Имя файла без пути.
  final String name;

  /// Содержимое файла.
  final Uint8List bytes;

  const PickedBinaryFile({required this.name, required this.bytes});
}

/// Источник двоичных файлов для импорта резервной копии.
///
/// Абстракция позволяет подменять нативный диалог выбора файла в тестах.
abstract class BackupFilePicker {
  /// Открывает диалог выбора файла.
  ///
  /// Возвращает выбранный файл или `null`, если пользователь отменил выбор.
  Future<PickedBinaryFile?> pick();
}
