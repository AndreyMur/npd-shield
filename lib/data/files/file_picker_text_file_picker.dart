import 'dart:convert';

import 'package:file_picker/file_picker.dart';

import '../../domain/risk/risk_file_limits.dart';
import 'text_file_picker.dart';

/// Выбор TXT-файла через нативный диалог `file_picker`.
class FilePickerTextFilePicker implements TextFilePicker {
  const FilePickerTextFilePicker();

  @override
  Future<PickedTextFile?> pick() async {
    final file = await FilePicker.pickFile(
      dialogTitle: 'Выберите договор в формате TXT',
      type: FileType.custom,
      allowedExtensions: const ['txt'],
    );
    if (file == null) return null;

    final size = file.lengthSync() ?? await file.length();
    if (size > maxRiskContractFileBytes) {
      throw ContractFileTooLargeException(
        actualBytes: size,
        maxBytes: maxRiskContractFileBytes,
      );
    }

    final bytes = await file.readAsBytes();
    if (bytes.length > maxRiskContractFileBytes) {
      throw ContractFileTooLargeException(
        actualBytes: bytes.length,
        maxBytes: maxRiskContractFileBytes,
      );
    }

    return PickedTextFile(
      name: file.name,
      content: utf8.decode(bytes, allowMalformed: true),
    );
  }
}
