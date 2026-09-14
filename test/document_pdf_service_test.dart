import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:npd_shield/data/models/document.dart';
import 'package:npd_shield/data/pdf/contract_pdf_font_loader.dart';
import 'package:npd_shield/data/pdf/contract_pdf_service.dart';
import 'package:npd_shield/data/pdf/document_pdf_service.dart';
import 'package:npd_shield/domain/contracts/contract_document.dart';

/// Тесты экспорта всех типов документов архива в PDF (issue 98).
void main() {
  late ContractPdfFonts fonts;

  setUpAll(() async {
    fonts = ContractPdfFonts(
      regular: await File('assets/fonts/Roboto-Regular.ttf').readAsBytes(),
      bold: await File('assets/fonts/Roboto-Bold.ttf').readAsBytes(),
    );
  });

  DocumentPdfService service() =>
      DocumentPdfService(fontLoader: _TestFontLoader(fonts));

  String contractText() {
    return composeContractDocument(
      'ДОГОВОР № {{contractNumber}}\n'
      'на разработку программного обеспечения\n'
      '\n'
      'г. {{contractCity}}      «{{contractDate}}»\n'
      '\n'
      '1. ПРЕДМЕТ ДОГОВОРА\n'
      '\n'
      '1.1. {{subject}}.\n',
      const {
        'contractNumber': '14/09',
        'contractCity': 'Москва',
        'contractDate': '05.09.2026',
        'subject': 'Разработка сайта',
      },
    ).rawText;
  }

  Document document({
    required DocumentType type,
    String content = '',
  }) {
    final document = Document(
      type: type,
      amount: 150000,
      date: DateTime(2026, 9, 5),
      contractNumber: '14/09',
      counterpartyName: 'ООО «Ромашка»',
      counterpartyInn: '7701234567',
      serviceName: 'Разработка сайта',
      issuerName: 'Иванов Иван Иванович',
      issuerInn: '771234567890',
      content: content,
    );
    document.id = 1;
    return document;
  }

  test('чек экспортируется в PDF', () async {
    final pdf = await service().generate(document(type: DocumentType.receipt));

    expect(String.fromCharCodes(pdf.bytes.take(4)), '%PDF');
    expect(pdf.fileName, 'receipt_14_09.pdf');
  });

  test('акт экспортируется в PDF', () async {
    final pdf = await service().generate(document(type: DocumentType.act));

    expect(String.fromCharCodes(pdf.bytes.take(4)), '%PDF');
    expect(pdf.fileName, 'act_14_09.pdf');
  });

  test('договор экспортируется в PDF из сохранённого текста', () async {
    final pdf = await service().generate(
      document(type: DocumentType.contract, content: contractText()),
    );

    expect(String.fromCharCodes(pdf.bytes.take(4)), '%PDF');
    expect(pdf.fileName, 'contract_14_09.pdf');
    expect(pdf.pageCount, greaterThanOrEqualTo(1));
  });

  test('договор без сохранённого текста не экспортируется', () async {
    expect(
      () => service().generate(document(type: DocumentType.contract)),
      throwsA(isA<DocumentPdfUnsupportedException>()),
    );
  });
}

/// Загрузчик шрифтов из тестовых байтов вместо Assets.
class _TestFontLoader extends ContractPdfFontLoader {
  final ContractPdfFonts fonts;

  const _TestFontLoader(this.fonts);

  @override
  Future<ContractPdfFonts> load() async => fonts;
}
