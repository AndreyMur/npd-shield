import 'package:npd_shield/data/files/backup_file_picker.dart';

/// Фейковый выбор файла резервной копии для виджет-тестов.
class FakeBackupFilePicker implements BackupFilePicker {
  PickedBinaryFile? file;
  int calls = 0;

  FakeBackupFilePicker([this.file]);

  @override
  Future<PickedBinaryFile?> pick() async {
    calls++;
    return file;
  }
}
