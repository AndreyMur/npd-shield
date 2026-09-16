import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:npd_shield/core/tax/tax_calculator.dart';
import 'package:npd_shield/data/models/transaction.dart';
import 'package:npd_shield/data/pdf/pdf_fonts.dart';
import 'package:npd_shield/data/pdf/report_pdf_service.dart';
import 'package:npd_shield/domain/reports/business_report.dart';

/// Интеграционные тесты локальной генерации PDF-отчёта.
///
/// Проверяют требования PRD: отчёт формируется с корректной кириллицей, формат
/// A4, время генерации меньше 10 секунд.
void main() {
  late PdfFonts fonts;

  setUpAll(() async {
    fonts = PdfFonts(
      regular: await File('assets/fonts/Roboto-Regular.ttf').readAsBytes(),
      bold: await File('assets/fonts/Roboto-Bold.ttf').readAsBytes(),
    );
  });

  BusinessReport report() {
    return BusinessReport(
      from: DateTime(2026, 9, 1),
      to: DateTime(2026, 9, 30),
      income: 1000000,
      expense: 250000,
      tax: const TaxCalculator().calculate(income: 1000000),
      spheres: const [
        ReportSphereBreakdown(
          sphere: TransactionSphere.it,
          income: 700000,
          expense: 100000,
        ),
        ReportSphereBreakdown(
          sphere: TransactionSphere.logistics,
          income: 300000,
          expense: 150000,
        ),
      ],
      clients: const [
        ReportClientBreakdown(
          clientId: 1,
          clientName: 'ООО «Ромашка»',
          clientInn: '7701234567',
          income: 700000,
          expense: 100000,
        ),
        ReportClientBreakdown(
          clientId: 2,
          clientName: 'ИП Петров Пётр Петрович',
          clientInn: '771234567890',
          income: 300000,
          expense: 150000,
        ),
      ],
    );
  }

  test('генерация PDF отчёта возвращает корректный файл', () async {
    final generated = await const ReportPdfService().generate(
      report: report(),
      fonts: fonts,
      fileName: 'report_test.pdf',
    );

    expect(generated.generationTime, lessThan(const Duration(seconds: 10)));
    expect(generated.pageCount, greaterThanOrEqualTo(1));
    expect(generated.bytes, isNotEmpty);
    expect(String.fromCharCodes(generated.bytes.take(4)), '%PDF');
    expect(generated.fileName, 'report_test.pdf');
  });

  test('имя файла по умолчанию содержит период отчёта', () async {
    final generated = await const ReportPdfService().generate(
      report: report(),
      fonts: fonts,
    );

    expect(generated.fileName, 'report_2026-09-01_2026-09-30.pdf');
  });

  test('generateInBackground возвращает корректный PDF', () async {
    final generated = await const ReportPdfService().generateInBackground(
      report: report(),
      fonts: fonts,
    );

    expect(String.fromCharCodes(generated.bytes.take(4)), '%PDF');
    expect(generated.pageCount, greaterThanOrEqualTo(1));
  });

  test('страница PDF имеет геометрию A4', () async {
    final generated = await const ReportPdfService().generate(
      report: report(),
      fonts: fonts,
    );

    final pdfText = String.fromCharCodes(generated.bytes);
    expect(pdfText, contains('/MediaBox'));
    expect(pdfText, matches(RegExp(r'595\.2\d*')));
    expect(pdfText, matches(RegExp(r'841\.8\d*')));
  });

  test('кириллица: длинные русские названия генерируются без ошибок', () async {
    final generated = await const ReportPdfService().generate(
      report: BusinessReport(
        from: DateTime(2026, 1, 1),
        to: DateTime(2026, 12, 31),
        income: 2400000,
        expense: 500000,
        tax: const TaxCalculator().calculate(income: 2400000),
        spheres: const [
          ReportSphereBreakdown(
            sphere: TransactionSphere.it,
            income: 2400000,
            expense: 500000,
          ),
        ],
        clients: const [
          ReportClientBreakdown(
            clientName: 'Общество с ограниченной ответственностью «Ромашка»',
            clientInn: '7701234567',
            income: 2400000,
            expense: 500000,
          ),
        ],
      ),
      fonts: fonts,
    );

    expect(String.fromCharCodes(generated.bytes.take(4)), '%PDF');
    expect(generated.bytes.length, greaterThan(1000));
  });

  test('генерация детерминирована для одинаковых данных', () async {
    const service = ReportPdfService();
    final first = await service.generate(report: report(), fonts: fonts);
    final second = await service.generate(report: report(), fonts: fonts);

    expect(second.pageCount, first.pageCount);
    expect(second.bytes.length, first.bytes.length);
  });
}
