import 'package:flutter/foundation.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../domain/documents/receipt.dart';
import 'generated_pdf.dart';
import 'pdf_fonts.dart';

/// Сигнатура функции генерации PDF-чека, переопределяемой в тестах.
typedef ReceiptPdfGenerator =
    Future<GeneratedPdf> Function(Receipt receipt, String fileName);

/// Типографские параметры PDF-чека.
///
/// Соответствуют требованиям к печатной копии чека НПД: формат A4,
/// поля 20 мм, шрифт Roboto 11pt для текста и 15pt bold для заголовка.
class ReceiptPdfTypography {
  /// Размер шрифта основного текста (pt).
  final double bodyFontSize;

  /// Размер шрифта заголовка (pt).
  final double headingFontSize;

  /// Поля страницы в миллиметрах.
  final double marginMillimeters;

  const ReceiptPdfTypography({
    this.bodyFontSize = 11,
    this.headingFontSize = 15,
    this.marginMillimeters = 20,
  });
}

/// Сервис локальной генерации PDF-версии чека для НПД.
///
/// Чек формируется полностью на устройстве, без обращения к ФНС и «Мой
/// налог»: реквизиты продавца, предмет расчёта, сумма, дата и ИНН покупателя
/// берутся из [Receipt]. Кириллица обеспечивается встроенными шрифтами
/// Roboto, переданными через [PdfFonts].
class ReceiptPdfService {
  final ReceiptPdfTypography typography;

  const ReceiptPdfService({
    this.typography = const ReceiptPdfTypography(),
  });

  static const double _pointsPerMm = 72.0 / 25.4;

  /// Генерирует PDF-файл чека в фоновом изоляте, не блокируя UI-поток.
  Future<GeneratedPdf> generateInBackground({
    required Receipt receipt,
    required PdfFonts fonts,
    String fileName = 'receipt.pdf',
  }) {
    return compute(
      _generateReceiptPdfInIsolate,
      ReceiptPdfJob(
        receipt: receipt,
        regularFont: fonts.regular,
        boldFont: fonts.bold,
        fileName: fileName,
        bodyFontSize: typography.bodyFontSize,
        headingFontSize: typography.headingFontSize,
        marginMillimeters: typography.marginMillimeters,
      ),
    );
  }

  /// Генерирует PDF-файл чека [receipt].
  Future<GeneratedPdf> generate({
    required Receipt receipt,
    required PdfFonts fonts,
    String fileName = 'receipt.pdf',
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
        build: (context) => _buildContent(receipt),
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

  List<pw.Widget> _buildContent(Receipt receipt) {
    return [
      pw.Center(
        child: pw.Text(
          'КАССОВЫЙ ЧЕК',
          style: pw.TextStyle(
            fontSize: typography.headingFontSize,
            fontWeight: pw.FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
      ),
      pw.SizedBox(height: 2),
      pw.Center(
        child: pw.Text(
          'Наименование документа',
          style: pw.TextStyle(
            fontSize: typography.bodyFontSize - 1,
            color: PdfColors.grey700,
          ),
        ),
      ),
      pw.SizedBox(height: 16),
      _buildSellerBlock(receipt),
      pw.SizedBox(height: 12),
      _buildMetaBlock(receipt),
      pw.SizedBox(height: 14),
      _buildItemsTable(receipt),
      pw.SizedBox(height: 14),
      _buildBuyerBlock(receipt),
      pw.SizedBox(height: 18),
      pw.Divider(color: PdfColors.grey400),
      pw.SizedBox(height: 6),
      pw.Text(
        'Чек сформирован в приложении NPD Shield. Для придания чека '
        'юридической силы зарегистрируйте расчёт в приложении «Мой налог» '
        'ФНС России.',
        style: pw.TextStyle(
          fontSize: typography.bodyFontSize - 2,
          color: PdfColors.grey700,
          height: 1.3,
        ),
      ),
    ];
  }

  pw.Widget _buildSellerBlock(Receipt receipt) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Пользователь (продавец)',
          style: pw.TextStyle(
            fontSize: typography.bodyFontSize,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 2),
        pw.Text(
          receipt.sellerName,
          style: pw.TextStyle(fontSize: typography.bodyFontSize, height: 1.3),
        ),
        pw.Text(
          'ИНН ${receipt.sellerInn}',
          style: pw.TextStyle(fontSize: typography.bodyFontSize, height: 1.3),
        ),
      ],
    );
  }

  pw.Widget _buildMetaBlock(Receipt receipt) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _metaRow('Дата и время расчёта', receipt.formattedDate),
        _metaRow('Признак расчёта', 'ПОЛНЫЙ РАСЧЁТ'),
        if (receipt.contractNumber.isNotEmpty)
          _metaRow('Договор', '№ ${receipt.contractNumber}'),
      ],
    );
  }

  pw.Widget _metaRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 3),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 150,
            child: pw.Text(
              label,
              style: pw.TextStyle(
                fontSize: typography.bodyFontSize,
                color: PdfColors.grey700,
              ),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              style: pw.TextStyle(
                fontSize: typography.bodyFontSize,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildItemsTable(Receipt receipt) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Предмет расчёта',
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
              decoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFFF2F2F2)),
              children: [
                _cell('№', bold: true, align: pw.TextAlign.center),
                _cell('Наименование услуги', bold: true),
                _cell('Сумма', bold: true, align: pw.TextAlign.right),
              ],
            ),
            pw.TableRow(
              children: [
                _cell('1', align: pw.TextAlign.center),
                _cell(receipt.serviceName),
                _cell(receipt.formattedAmount, align: pw.TextAlign.right),
              ],
            ),
            pw.TableRow(
              children: [
                _cell(''),
                _cell('ИТОГО', bold: true, align: pw.TextAlign.right),
                _cell(receipt.formattedAmount, bold: true, align: pw.TextAlign.right),
              ],
            ),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildBuyerBlock(Receipt receipt) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Покупатель (заказчик)',
          style: pw.TextStyle(
            fontSize: typography.bodyFontSize,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 2),
        pw.Text(
          receipt.buyerName.isEmpty ? '—' : receipt.buyerName,
          style: pw.TextStyle(fontSize: typography.bodyFontSize, height: 1.3),
        ),
        pw.Text(
          receipt.hasBuyerInn ? 'ИНН ${receipt.buyerInn}' : 'ИНН не указан',
          style: pw.TextStyle(fontSize: typography.bodyFontSize, height: 1.3),
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

/// Задание на генерацию PDF-чека, передаваемое в фоновый изолят.
class ReceiptPdfJob {
  final Receipt receipt;
  final Uint8List regularFont;
  final Uint8List boldFont;
  final String fileName;
  final double bodyFontSize;
  final double headingFontSize;
  final double marginMillimeters;

  const ReceiptPdfJob({
    required this.receipt,
    required this.regularFont,
    required this.boldFont,
    required this.fileName,
    required this.bodyFontSize,
    required this.headingFontSize,
    required this.marginMillimeters,
  });
}

/// Точка входа генерации PDF-чека в фоновом изоляте (для [compute]).
Future<GeneratedPdf> _generateReceiptPdfInIsolate(ReceiptPdfJob job) {
  return ReceiptPdfService(
    typography: ReceiptPdfTypography(
      bodyFontSize: job.bodyFontSize,
      headingFontSize: job.headingFontSize,
      marginMillimeters: job.marginMillimeters,
    ),
  ).generate(
    receipt: job.receipt,
    fonts: PdfFonts(regular: job.regularFont, bold: job.boldFont),
    fileName: job.fileName,
  );
}
