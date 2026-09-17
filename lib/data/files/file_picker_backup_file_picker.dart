import 'package:file_picker/file_picker.dart';

import 'backup_file_picker.dart';

/// Выбор файла резервной копии через нативный диалог `file_picker`.
class FilePickerBackupFilePicker implements BackupFilePicker {
  const FilePickerBackupFilePicker();

  @override
  Future<PickedBinaryFile?> pick() async {
    final file = await FilePicker.pickFile(
      dialogTitle: 'Выберите файл резервной копии',
      type: FileType.custom,
      allowedExtensions: const ['json'],
    );
    if (file == null) return null;
    return PickedBinaryFile(name: file.name, bytes: await file.readAsBytes());
  }
}
