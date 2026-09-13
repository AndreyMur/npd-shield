import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:npd_shield/data/pdf/pdf_fonts.dart';
import 'package:npd_shield/data/pdf/receipt_pdf_service.dart';
import 'package:npd_shield/domain/documents/receipt.dart';

/// Интеграционные тесты локальной генерации PDF-чека для НПД.
///
/// Проверяют требования PRD: генерация полностью локальная, формат A4,
/// кириллица через встроенный Roboto, время формирования < 10 секунд.
void main() {
  late PdfFonts fonts;

  setUpAll(() async {
    fonts = PdfFonts(
      regular: await File('assets/fonts/Roboto-Regular.ttf').readAsBytes(),
      bold: await File('assets/fonts/Roboto-Bold.ttf').readAsBytes(),
    );
  });

  Receipt receipt({String serviceName = 'Разработка сайта'}) {
    return Receipt(
      sellerName: 'Иванов Иван Иванович',
      sellerInn: '771234567890',
      serviceName: serviceName,
      amount: 150000,
      date: DateTime(2026, 9, 5),
      buyerName: 'ООО «Ромашка»',
      buyerInn: '7701234567',
      contractDraftId: 1,
      contractNumber: '14/09',
    );
  }

  test('генерация PDF чека возвращает корректный файл и укладывается в 10 секунд',
      () async {
    final generated = await const ReceiptPdfService().generate(
      receipt: receipt(),
      fonts: fonts,
      fileName: 'receipt_14-09.pdf',
    );

    expect(generated.generationTime, lessThan(const Duration(seconds: 10)));
    expect(generated.pageCount, greaterThanOrEqualTo(1));
    expect(generated.bytes, isNotEmpty);
    expect(String.fromCharCodes(generated.bytes.take(4)), '%PDF');
    expect(generated.fileName, 'receipt_14-09.pdf');
  });

  test('generateInBackground возвращает корректный PDF', () async {
    final generated = await const ReceiptPdfService().generateInBackground(
      receipt: receipt(),
      fonts: fonts,
      fileName: 'receipt_bg.pdf',
    );

    expect(generated.bytes, isNotEmpty);
    expect(String.fromCharCodes(generated.bytes.take(4)), '%PDF');
    expect(generated.pageCount, greaterThanOrEqualTo(1));
  });

  test('макет: страница PDF имеет геометрию A4', () async {
    final generated = await const ReceiptPdfService().generate(
      receipt: receipt(),
      fonts: fonts,
    );

    final pdfText = String.fromCharCodes(generated.bytes);
    expect(pdfText, contains('/MediaBox'));
    expect(pdfText, matches(RegExp(r'595\.2\d*')));
    expect(pdfText, matches(RegExp(r'841\.8\d*')));
  });

  test('кириллица: чек с русским текстом генерируется без ошибок', () async {
    final generated = await const ReceiptPdfService().generate(
      receipt: receipt(
        serviceName:
            'Оказание услуг по разработке программного обеспечения '
            'и техническому сопровождению',
      ),
      fonts: fonts,
    );

    expect(String.fromCharCodes(generated.bytes.take(4)), '%PDF');
    expect(generated.bytes.length, greaterThan(1000));
  });

  test('генерация детерминирована для одинаковых данных', () async {
    const service = ReceiptPdfService();
    final first = await service.generate(receipt: receipt(), fonts: fonts);
    final second = await service.generate(receipt: receipt(), fonts: fonts);

    expect(second.pageCount, first.pageCount);
    expect(second.bytes.length, first.bytes.length);
  });
}
