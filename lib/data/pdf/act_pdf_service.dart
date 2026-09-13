import 'package:flutter/foundation.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../domain/documents/act.dart';
import 'generated_pdf.dart';
import 'pdf_fonts.dart';

/// Сигнатура функции генерации PDF-акта, переопределяемой в тестах.
typedef ActPdfGenerator = Future<GeneratedPdf> Function(Act act, String fileName);

/// Типографские параметры PDF-акта выполненных работ.
class ActPdfTypography {
  /// Размер шрифта основного текста (pt).
  final double bodyFontSize;

  /// Размер шрифта заголовка (pt).
  final double headingFontSize;

  /// Поля страницы в миллиметрах.
  final double marginMillimeters;

  const ActPdfTypography({
    this.bodyFontSize = 11,
    this.headingFontSize = 15,
    this.marginMillimeters = 20,
  });
}

/// Сервис локальной генерации PDF-версии акта выполненных работ.
///
/// Акт формируется полностью на устройстве: стороны, описание и результат
/// работ, сумма и дата выполнения берутся из [Act]. Подписи сторон выводятся
/// как поля для распечатки — линии для подписи с расшифровкой. Кириллица
/// обеспечивается встроенными шрифтами Roboto, переданными через [PdfFonts].
class ActPdfService {
  final ActPdfTypography typography;

  const ActPdfService({this.typography = const ActPdfTypography()});

  static const double _pointsPerMm = 72.0 / 25.4;

  /// Генерирует PDF-файл акта в фоновом изоляте, не блокируя UI-поток.
  Future<GeneratedPdf> generateInBackground({
    required Act act,
    required PdfFonts fonts,
    String fileName = 'act.pdf',
  }) {
    return compute(
      _generateActPdfInIsolate,
      ActPdfJob(
        act: act,
        regularFont: fonts.regular,
        boldFont: fonts.bold,
        fileName: fileName,
        bodyFontSize: typography.bodyFontSize,
        headingFontSize: typography.headingFontSize,
        marginMillimeters: typography.marginMillimeters,
      ),
    );
  }

  /// Генерирует PDF-файл акта [act].
  Future<GeneratedPdf> generate({
    required Act act,
    required PdfFonts fonts,
    String fileName = 'act.pdf',
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
        margin: pw.EdgeInsets.all(
          typography.marginMillimeters * _pointsPerMm,
        ),
        footer: (context) {
          totalPages = context.pagesCount;
          return _buildFooter(context.pageNumber, context.pagesCount);
        },
        build: (context) => _buildContent(act),
      ),
    );

    final bytes = await pdf.save();
    stopwatch.stop();

    return GeneratedPdf(
      bytes: bytes,
      pageCount: totalPages,
      fileName: fileName,
      generationTime: stopwatch.elapsed,
    );
  }

  List<pw.Widget> _buildContent(Act act) {
    return [
      pw.Center(
        child: pw.Text(
          'АКТ ВЫПОЛНЕННЫХ РАБОТ',
          style: pw.TextStyle(
            fontSize: typography.headingFontSize,
            fontWeight: pw.FontWeight.bold,
            letterSpacing: 1.0,
          ),
        ),
      ),
      if (act.contractNumber.isNotEmpty) ...[
        pw.SizedBox(height: 2),
        pw.Center(
          child: pw.Text(
            'к договору № ${act.contractNumber} от ${act.formattedDate}',
            style: pw.TextStyle(
              fontSize: typography.bodyFontSize - 1,
              color: PdfColors.grey700,
            ),
          ),
        ),
      ],
      pw.SizedBox(height: 16),
      _buildPartiesBlock(act),
      pw.SizedBox(height: 14),
      _buildWorksTable(act),
      pw.SizedBox(height: 14),
      _buildResultBlock(act),
      pw.SizedBox(height: 24),
      _buildSignatureBlock(act),
      pw.SizedBox(height: 18),
      pw.Divider(color: PdfColors.grey400),
      pw.SizedBox(height: 6),
      pw.Text(
        'Акт сформирован в приложении NPD Shield. Документ не имеет '
        'юридической силы без подписей сторон и усиленной электронной '
        'подписи.',
        style: pw.TextStyle(
          fontSize: typography.bodyFontSize - 2,
          color: PdfColors.grey700,
          height: 1.3,
        ),
      ),
    ];
  }

  pw.Widget _buildPartiesBlock(Act act) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _partyRow('Исполнитель', act.sellerName, act.sellerInn),
        pw.SizedBox(height: 4),
        _partyRow('Заказчик', act.buyerName, act.buyerInn),
      ],
    );
  }

  pw.Widget _partyRow(String role, String name, String inn) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(
          width: 90,
          child: pw.Text(
            role,
            style: pw.TextStyle(
              fontSize: typography.bodyFontSize,
              color: PdfColors.grey700,
            ),
          ),
        ),
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                name.isEmpty ? '—' : name,
                style: pw.TextStyle(
                  fontSize: typography.bodyFontSize,
                  fontWeight: pw.FontWeight.bold,
                  height: 1.3,
                ),
              ),
              if (inn.isNotEmpty)
                pw.Text(
                  'ИНН $inn',
                  style: pw.TextStyle(
                    fontSize: typography.bodyFontSize,
                    height: 1.3,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  pw.Widget _buildWorksTable(Act act) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Выполненные работы',
          style: pw.TextStyle(
            fontSize: typography.bodyFontSize,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 6),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
          columnWidths: const {
            0: pw.FixedColumnWidth(28),
            1: pw.FlexColumnWidth(),
            2: pw.FixedColumnWidth(110),
          },
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(
                color: PdfColor.fromInt(0xFFF2F2F2),
              ),
              children: [
                _cell('№', bold: true, align: pw.TextAlign.center),
                _cell('Наименование работ', bold: true),
                _cell('Сумма', bold: true, align: pw.TextAlign.right),
              ],
            ),
            pw.TableRow(
              children: [
                _cell('1', align: pw.TextAlign.center),
                _cell(act.worksDescription.isEmpty ? '—' : act.worksDescription),
                _cell(act.formattedAmount, align: pw.TextAlign.right),
              ],
            ),
            pw.TableRow(
              children: [
                _cell(''),
                _cell('ИТОГО', bold: true, align: pw.TextAlign.right),
                _cell(
                  act.formattedAmount,
                  bold: true,
                  align: pw.TextAlign.right,
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildResultBlock(Act act) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Результат работ',
          style: pw.TextStyle(
            fontSize: typography.bodyFontSize,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          act.hasResult ? act.result : defaultActResult,
          style: pw.TextStyle(
            fontSize: typography.bodyFontSize,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  pw.Widget _buildSignatureBlock(Act act) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Подписи сторон',
          style: pw.TextStyle(
            fontSize: typography.bodyFontSize,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 10),
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              child: _signatureColumn('Исполнитель', act.executorSignatory),
            ),
            pw.SizedBox(width: 24),
            pw.Expanded(
              child: _signatureColumn('Заказчик', act.customerSignatory),
            ),
          ],
        ),
      ],
    );
  }

  pw.Widget _signatureColumn(String role, String signatory) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          role,
          style: pw.TextStyle(
            fontSize: typography.bodyFontSize,
            color: PdfColors.grey700,
          ),
        ),
        pw.SizedBox(height: 18),
        pw.Container(
          decoration: const pw.BoxDecoration(
            border: pw.Border(
              bottom: pw.BorderSide(color: PdfColors.grey700, width: 0.7),
            ),
          ),
        ),
        pw.SizedBox(height: 3),
        pw.Text(
          signatory.isEmpty ? 'подпись / ФИО' : signatory,
          style: pw.TextStyle(fontSize: typography.bodyFontSize - 1),
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

/// Задание на генерацию PDF-акта, передаваемое в фоновый изолят.
class ActPdfJob {
  final Act act;
  final Uint8List regularFont;
  final Uint8List boldFont;
  final String fileName;
  final double bodyFontSize;
  final double headingFontSize;
  final double marginMillimeters;

  const ActPdfJob({
    required this.act,
    required this.regularFont,
    required this.boldFont,
    required this.fileName,
    required this.bodyFontSize,
    required this.headingFontSize,
    required this.marginMillimeters,
  });
}

/// Точка входа генерации PDF-акта в фоновом изоляте (для [compute]).
Future<GeneratedPdf> _generateActPdfInIsolate(ActPdfJob job) {
  return ActPdfService(
    typography: ActPdfTypography(
      bodyFontSize: job.bodyFontSize,
      headingFontSize: job.headingFontSize,
      marginMillimeters: job.marginMillimeters,
    ),
  ).generate(
    act: job.act,
    fonts: PdfFonts(regular: job.regularFont, bold: job.boldFont),
    fileName: job.fileName,
  );
}
