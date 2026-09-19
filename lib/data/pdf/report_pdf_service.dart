import 'package:flutter/foundation.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../domain/documents/legal_disclaimer.dart';
import '../../domain/reports/business_report.dart';
import '../../domain/reports/report_format.dart';
import 'generated_pdf.dart';
import 'pdf_fonts.dart';

/// Типографские параметры PDF-отчёта.
///
/// Формат A4, поля 20 мм, шрифт Roboto 11pt для текста и 15pt bold для
/// заголовка — как у остальных документов приложения.
class ReportPdfTypography {
  final double bodyFontSize;
  final double headingFontSize;
  final double marginMillimeters;

  const ReportPdfTypography({
    this.bodyFontSize = 11,
    this.headingFontSize = 15,
    this.marginMillimeters = 20,
  });
}

/// Сервис локальной генерации PDF-отчёта о деятельности за период.
///
/// Отчёт собирается из [BusinessReport]: итоговые суммы (доход, расход,
/// прибыль, налог) и разбивка по сферам и клиентам. Кириллица обеспечивается
/// встроенными шрифтами Roboto, переданными через [PdfFonts].
class ReportPdfService {
  final ReportPdfTypography typography;

  const ReportPdfService({this.typography = const ReportPdfTypography()});

  static const double _pointsPerMm = 72.0 / 25.4;

  /// Генерирует PDF-отчёт в фоновом изоляте, не блокируя UI-поток.
  Future<GeneratedPdf> generateInBackground({
    required BusinessReport report,
    required PdfFonts fonts,
    String? fileName,
  }) {
    return compute(
      _generateReportPdfInIsolate,
      ReportPdfJob(
        report: report,
        regularFont: fonts.regular,
        boldFont: fonts.bold,
        fileName: fileName ?? reportPdfFileName(report),
        bodyFontSize: typography.bodyFontSize,
        headingFontSize: typography.headingFontSize,
        marginMillimeters: typography.marginMillimeters,
      ),
    );
  }

  /// Генерирует PDF-отчёт [report].
  Future<GeneratedPdf> generate({
    required BusinessReport report,
    required PdfFonts fonts,
    String? fileName,
    PdfPageFormat pageFormat = PdfPageFormat.a4,
  }) async {
    final stopwatch = Stopwatch()..start();

    final baseFont = pw.Font.ttf(fonts.regular.buffer.asByteData());
    final boldFont = pw.Font.ttf(fonts.bold.buffer.asByteData());

    final pdf = pw.Document(
      theme: pw.ThemeData.withFont(base: baseFont, bold: boldFont),
    );

    var totalPages = 0;
    pdf.addPage(
      pw.MultiPage(
        pageFormat: pageFormat,
        margin: pw.EdgeInsets.all(typography.marginMillimeters * _pointsPerMm),
        footer: (context) {
          totalPages = context.pagesCount;
          return _buildFooter(context.pageNumber, context.pagesCount);
        },
        build: (context) => _buildContent(report),
      ),
    );

    final bytes = await pdf.save();
    stopwatch.stop();

    return GeneratedPdf(
      bytes: bytes,
      pageCount: totalPages,
      fileName: fileName ?? reportPdfFileName(report),
      generationTime: stopwatch.elapsed,
    );
  }

  List<pw.Widget> _buildContent(BusinessReport report) {
    return [
      pw.Center(
        child: pw.Text(
          'ОТЧЁТ О ДЕЯТЕЛЬНОСТИ',
          style: pw.TextStyle(
            fontSize: typography.headingFontSize,
            fontWeight: pw.FontWeight.bold,
            letterSpacing: 1.1,
          ),
        ),
      ),
      pw.SizedBox(height: 2),
      pw.Center(
        child: pw.Text(
          'за период ${formatReportDate(report.from)} — '
          '${formatReportDate(report.to)}',
          style: pw.TextStyle(
            fontSize: typography.bodyFontSize,
            color: PdfColors.grey700,
          ),
        ),
      ),
      pw.SizedBox(height: 16),
      _sectionTitle('Итоги'),
      pw.SizedBox(height: 6),
      _summaryTable(report),
      pw.SizedBox(height: 16),
      _sectionTitle('Разбивка по сферам деятельности'),
      pw.SizedBox(height: 6),
      _sphereTable(report),
      pw.SizedBox(height: 16),
      _sectionTitle('Разбивка по клиентам'),
      pw.SizedBox(height: 6),
      _clientTable(report),
      pw.SizedBox(height: 18),
      pw.Divider(color: PdfColors.grey400),
      pw.SizedBox(height: 6),
      pw.Text(
        'Отчёт сформирован в приложении «Своё дело» на основании введённых '
        'операций. $kNoLegalForceDisclaimer',
        style: pw.TextStyle(
          fontSize: typography.bodyFontSize - 2,
          color: PdfColors.grey700,
          height: 1.3,
        ),
      ),
    ];
  }

  pw.Widget _sectionTitle(String text) {
    return pw.Text(
      text,
      style: pw.TextStyle(
        fontSize: typography.bodyFontSize + 1,
        fontWeight: pw.FontWeight.bold,
      ),
    );
  }

  pw.Widget _summaryTable(BusinessReport report) {
    final rows = <List<String>>[
      ['Доход', formatReportMoney(report.income)],
      ['Расход', formatReportMoney(report.expense)],
      ['Прибыль', formatReportMoney(report.profit)],
      ['Начислен налог 6%', formatReportMoney(report.tax.accruedTax)],
      ['Вычет страховых взносов', formatReportMoney(report.tax.insuranceDeduction)],
      ['Налог к уплате', formatReportMoney(report.taxAmount)],
    ];
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
      columnWidths: const {
        0: pw.FlexColumnWidth(2),
        1: pw.FlexColumnWidth(1.4),
      },
      children: [
        for (final row in rows)
          pw.TableRow(
            children: [
              _cell(row[0], bold: true),
              _cell(row[1], align: pw.TextAlign.right),
            ],
          ),
      ],
    );
  }

  pw.Widget _sphereTable(BusinessReport report) {
    return _dataTable(
      headers: const ['Сфера', 'Доход', 'Расход', 'Прибыль'],
      aligns: const [
        pw.TextAlign.left,
        pw.TextAlign.right,
        pw.TextAlign.right,
        pw.TextAlign.right,
      ],
      rows: [
        for (final row in report.spheres)
          [
            row.sphere.label,
            formatReportAmount(row.income),
            formatReportAmount(row.expense),
            formatReportAmount(row.profit),
          ],
      ],
      emptyText: 'За выбранный период операции по сферам отсутствуют.',
    );
  }

  pw.Widget _clientTable(BusinessReport report) {
    return _dataTable(
      headers: const ['Клиент', 'ИНН', 'Доход', 'Расход', 'Прибыль'],
      aligns: const [
        pw.TextAlign.left,
        pw.TextAlign.left,
        pw.TextAlign.right,
        pw.TextAlign.right,
        pw.TextAlign.right,
      ],
      rows: [
        for (final row in report.clients)
          [
            row.displayName,
            row.clientInn,
            formatReportAmount(row.income),
            formatReportAmount(row.expense),
            formatReportAmount(row.profit),
          ],
      ],
      emptyText: 'За выбранный период операции по клиентам отсутствуют.',
    );
  }

  pw.Widget _dataTable({
    required List<String> headers,
    required List<pw.TextAlign> aligns,
    required List<List<String>> rows,
    required String emptyText,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
          columnWidths: {
            for (var i = 0; i < headers.length; i++)
              i: pw.FlexColumnWidth(i == 0 ? 2 : 1.3),
          },
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(
                color: PdfColor.fromInt(0xFFF2F2F2),
              ),
              children: [
                for (var i = 0; i < headers.length; i++)
                  _cell(headers[i], bold: true, align: aligns[i]),
              ],
            ),
            for (final row in rows)
              pw.TableRow(
                children: [
                  for (var i = 0; i < row.length; i++)
                    _cell(row[i], align: aligns[i]),
                ],
              ),
          ],
        ),
        if (rows.isEmpty)
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 4),
            child: pw.Text(
              emptyText,
              style: pw.TextStyle(
                fontSize: typography.bodyFontSize - 1,
                color: PdfColors.grey700,
              ),
            ),
          ),
      ],
    );
  }

  pw.Widget _cell(
    String text, {
    bool bold = false,
    pw.TextAlign align = pw.TextAlign.left,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(
          fontSize: typography.bodyFontSize,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  pw.Widget _buildFooter(int pageNumber, int pagesCount) {
    return pw.Center(
      child: pw.Text(
        'Страница $pageNumber из $pagesCount',
        style: pw.TextStyle(
          fontSize: typography.bodyFontSize - 2,
          color: PdfColors.grey700,
        ),
      ),
    );
  }
}

/// Предлагаемое имя PDF-файла отчёта.
String reportPdfFileName(BusinessReport report) {
  String date(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '${value.year}-$month-$day';
  }

  return 'report_${date(report.from)}_${date(report.to)}.pdf';
}

/// Задание на генерацию PDF-отчёта, передаваемое в фоновый изолят.
class ReportPdfJob {
  final BusinessReport report;
  final Uint8List regularFont;
  final Uint8List boldFont;
  final String fileName;
  final double bodyFontSize;
  final double headingFontSize;
  final double marginMillimeters;

  const ReportPdfJob({
    required this.report,
    required this.regularFont,
    required this.boldFont,
    required this.fileName,
    required this.bodyFontSize,
    required this.headingFontSize,
    required this.marginMillimeters,
  });
}

/// Точка входа генерации PDF-отчёта в фоновом изоляте (для [compute]).
Future<GeneratedPdf> _generateReportPdfInIsolate(ReportPdfJob job) {
  return ReportPdfService(
    typography: ReportPdfTypography(
      bodyFontSize: job.bodyFontSize,
      headingFontSize: job.headingFontSize,
      marginMillimeters: job.marginMillimeters,
    ),
  ).generate(
    report: job.report,
    fonts: PdfFonts(regular: job.regularFont, bold: job.boldFont),
    fileName: job.fileName,
  );
}
