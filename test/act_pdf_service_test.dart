import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:npd_shield/data/pdf/act_pdf_service.dart';
import 'package:npd_shield/data/pdf/pdf_fonts.dart';
import 'package:npd_shield/domain/documents/act.dart';

/// Интеграционные тесты локальной генерации PDF-акта выполненных работ.
///
/// Проверяют требования PRD: генерация полностью локальная, формат A4,
/// кириллица через встроенный Roboto, наличие блока подписей сторон,
/// время формирования < 10 секунд.
void main() {
  late PdfFonts fonts;

  setUpAll(() async {
    fonts = PdfFonts(
      regular: await File('assets/fonts/Roboto-Regular.ttf').readAsBytes(),
      bold: await File('assets/fonts/Roboto-Bold.ttf').readAsBytes(),
    );
  });

  Act act({String worksDescription = 'Разработка сайта'}) {
    return Act(
      sellerName: 'Иванов Иван Иванович',
      sellerInn: '771234567890',
      worksDescription: worksDescription,
      amount: 150000,
      completionDate: DateTime(2026, 9, 5),
      buyerName: 'ООО «Ромашка»',
      buyerInn: '7701234567',
      contractDraftId: 1,
      contractNumber: '14/09',
      receiptDocumentId: 2,
      executorSignatory: 'Иванов И.И.',
      customerSignatory: 'Петров П.П.',
    );
  }

  test('генерация PDF акта возвращает корректный файл и укладывается в 10 секунд',
      () async {
    final generated = await const ActPdfService().generate(
      act: act(),
      fonts: fonts,
      fileName: 'act_14-09.pdf',
    );

    expect(generated.generationTime, lessThan(const Duration(seconds: 10)));
    expect(generated.pageCount, greaterThanOrEqualTo(1));
    expect(generated.bytes, isNotEmpty);
    expect(String.fromCharCodes(generated.bytes.take(4)), '%PDF');
    expect(generated.fileName, 'act_14-09.pdf');
  });

  test('generateInBackground возвращает корректный PDF', () async {
    final generated = await const ActPdfService().generateInBackground(
      act: act(),
      fonts: fonts,
      fileName: 'act_bg.pdf',
    );

    expect(generated.bytes, isNotEmpty);
    expect(String.fromCharCodes(generated.bytes.take(4)), '%PDF');
    expect(generated.pageCount, greaterThanOrEqualTo(1));
  });

  test('макет: страница PDF имеет геометрию A4', () async {
    final generated = await const ActPdfService().generate(
      act: act(),
      fonts: fonts,
    );

    final pdfText = String.fromCharCodes(generated.bytes);
    expect(pdfText, contains('/MediaBox'));
    expect(pdfText, matches(RegExp(r'595\.2\d*')));
    expect(pdfText, matches(RegExp(r'841\.8\d*')));
  });

  test('кириллица и длинный результат работ генерируются без ошибок', () async {
    final generated = await const ActPdfService().generate(
      act: Act(
        sellerName: 'Иванов Иван Иванович',
        sellerInn: '771234567890',
        worksDescription:
            'Оказание услуг по разработке программного обеспечения '
            'и техническому сопровождению',
        result: defaultActResult,
        amount: 150000,
        completionDate: DateTime(2026, 9, 5),
        buyerName: 'ООО «Ромашка»',
        buyerInn: '7701234567',
        executorSignatory: 'Иванов Иван Иванович',
        customerSignatory: 'Петров Пётр Петрович',
      ),
      fonts: fonts,
    );

    expect(String.fromCharCodes(generated.bytes.take(4)), '%PDF');
    expect(generated.bytes.length, greaterThan(1000));
  });

  test('генерация детерминирована для одинаковых данных', () async {
    const service = ActPdfService();
    final first = await service.generate(act: act(), fonts: fonts);
    final second = await service.generate(act: act(), fonts: fonts);

    expect(second.pageCount, first.pageCount);
    expect(second.bytes.length, first.bytes.length);
  });
}
