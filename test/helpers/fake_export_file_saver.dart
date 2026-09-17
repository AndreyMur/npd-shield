import 'dart:typed_data';

import 'package:npd_shield/data/files/export_file_saver.dart';

/// Сохранённый файл в фейковом сервисе.
class SavedFile {
  final String fileName;
  final Uint8List bytes;

  const SavedFile(this.fileName, this.bytes);
}

/// Фейковое сохранение файлов для виджет-тестов.
class FakeExportFileSaver implements ExportFileSaver {
  final List<SavedFile> saved = [];

  /// Путь, возвращаемый после сохранения. `null` имитирует отмену.
  String? resultPath;

  FakeExportFileSaver({this.resultPath});

  @override
  Future<String?> save({
    required String fileName,
    required Uint8List bytes,
  }) async {
    saved.add(SavedFile(fileName, bytes));
    return resultPath ?? 'C:\\exports\\$fileName';
  }
}
