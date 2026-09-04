import 'dart:io';

import 'package:flutter/services.dart' show PlatformException;
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';

import 'contract_pdf_service.dart';

/// Ошибка операции с PDF-файлом (поделиться/сохранить).
class ContractPdfActionException implements Exception {
  final String message;

  const ContractPdfActionException(this.message);

  @override
  String toString() => message;
}

/// Выполняет действия с готовым PDF: шаринг через стандартные приложения
/// операционной системы и сохранение файла в документы приложения.
class ContractPdfShareService {
  const ContractPdfShareService();

  /// Открывает системный диалог «Поделиться» с PDF-файлом.
  Future<void> share(GeneratedContractPdf pdf) async {
    try {
      await Printing.sharePdf(bytes: pdf.bytes, filename: pdf.fileName);
    } on PlatformException {
      throw const ContractPdfActionException(
        'Не удалось открыть меню «Поделиться».',
      );
    } catch (_) {
      throw const ContractPdfActionException(
        'Не удалось открыть меню «Поделиться».',
      );
    }
  }

  /// Сохраняет PDF-файл в папку документов приложения и возвращает путь.
  Future<String> saveToDocuments(GeneratedContractPdf pdf) async {
    final documents = await getApplicationDocumentsDirectory();
    final folder = Directory(
      '${documents.path}${Platform.pathSeparator}npd_contracts',
    );
    await folder.create(recursive: true);
    final file = File('${folder.path}${Platform.pathSeparator}${pdf.fileName}');
    await file.writeAsBytes(pdf.bytes, flush: true);
    return file.path;
  }
}
