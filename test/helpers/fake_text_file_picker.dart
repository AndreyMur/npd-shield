import 'package:npd_shield/data/files/text_file_picker.dart';

/// Фейковый выбор текстового файла для виджет-тестов.
class FakeTextFilePicker implements TextFilePicker {
  PickedTextFile? file;
  int calls = 0;

  FakeTextFilePicker([this.file]);

  @override
  Future<PickedTextFile?> pick() async {
    calls++;
    return file;
  }
}
