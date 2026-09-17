import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

import 'export_file_saver.dart';

/// Сохранение файла через нативный диалог `file_picker`.
class FilePickerExportFileSaver implements ExportFileSaver {
  const FilePickerExportFileSaver();

  @override
  Future<String?> save({
    required String fileName,
    required Uint8List bytes,
  }) async {
    final uri = await FilePicker.saveFile(
      fileName: fileName,
      bytes: bytes,
      dialogTitle: 'Сохранить файл',
    );
    if (uri == null) return null;
    return uri.scheme == 'file' ? uri.toFilePath() : uri.toString();
  }
}
