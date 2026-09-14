import '../../core/constants/contract_field_keys.dart';
import '../../domain/documents/act.dart';
import '../../domain/documents/receipt.dart';
import '../models/document.dart';
import 'act_pdf_service.dart';
import 'contract_pdf_font_loader.dart';
import 'generated_pdf.dart';
import 'receipt_pdf_service.dart';

/// Сигнатура генерации PDF-версии документа архива, переопределяемая в тестах.
typedef DocumentPdfGenerator = Future<GeneratedPdf> Function(Document document);

/// Ошибка экспорта документа, не поддерживаемого в текущей версии.
class DocumentPdfUnsupportedException implements Exception {
  final String message;

  const DocumentPdfUnsupportedException([
    this.message = 'Экспорт договоров в PDF появится в следующем обновлении.',
  ]);

  @override
  String toString() => message;
}

/// Генерирует PDF-версию документа архива по его типу.
///
/// Для чеков и актов PDF собирается из денормализованных полей записи архива
/// ([Receipt.fromDocument] и [Act.fromDocument]) встроенными сервисами с
/// кириллическими шрифтами. Экспорт договоров относится к следующей фазе.
class DocumentPdfService {
  final ContractPdfFontLoader fontLoader;

  const DocumentPdfService({this.fontLoader = const ContractPdfFontLoader()});

  /// Генерирует PDF-файл документа [document].
  Future<GeneratedPdf> generate(Document document) async {
    final fileName = documentPdfFileName(document);
    final fonts = await fontLoader.load();
    return switch (document.type) {
      DocumentType.receipt => const ReceiptPdfService().generateInBackground(
        receipt: Receipt.fromDocument(document),
        fonts: fonts,
        fileName: fileName,
      ),
      DocumentType.act => const ActPdfService().generateInBackground(
        act: Act.fromDocument(document),
        fonts: fonts,
        fileName: fileName,
      ),
      DocumentType.contract => throw const DocumentPdfUnsupportedException(),
    };
  }
}

/// Предлагаемое имя PDF-файла документа архива.
String documentPdfFileName(Document document) {
  final prefix = switch (document.type) {
    DocumentType.receipt => 'receipt',
    DocumentType.act => 'act',
    DocumentType.contract => 'contract',
  };
  final raw = document.contractNumber.trim().isEmpty
      ? formatContractDate(document.date)
      : document.contractNumber;
  final safe = raw.replaceAll(RegExp(r'[^A-Za-z0-9_-]+'), '_');
  return '${prefix}_${safe.isEmpty ? 'untitled' : safe}.pdf';
}
