/// Текстовый файл, выбранный пользователем для проверки.
class PickedTextFile {
  /// Имя файла без пути.
  final String name;

  /// Содержимое файла в кодировке UTF-8.
  final String content;

  const PickedTextFile({required this.name, required this.content});
}

/// Источник TXT-файлов для экрана Risk Shield.
///
/// Абстракция позволяет подменять нативный диалог выбора файла в тестах.
abstract class TextFilePicker {
  /// Открывает диалог выбора файла.
  ///
  /// Возвращает выбранный файл или `null`, если пользователь отменил выбор.
  /// Бросает `ContractFileTooLargeException`, если файл превышает 100 КБ.
  Future<PickedTextFile?> pick();
}
