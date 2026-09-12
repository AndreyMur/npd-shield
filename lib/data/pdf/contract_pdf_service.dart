import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../domain/contracts/contract_document.dart';
import '../../domain/contracts/protective_clauses.dart';

/// Типографские параметры PDF-документа договора.
///
/// Соответствуют PRD: формат A4, поля 20 мм, шрифт Roboto
/// 12pt для текста и 14pt bold для заголовков, нумерация страниц.
class ContractPdfTypography {
  /// Размер шрифта основного текста (pt).
  final double bodyFontSize;

  /// Размер шрифта заголовков (pt).
  final double headingFontSize;

  /// Поля страницы в миллиметрах.
  final double marginMillimeters;

  const ContractPdfTypography({
    this.bodyFontSize = 12,
    this.headingFontSize = 14,
    this.marginMillimeters = 20,
  });
}

/// Шрифты для встраивания в PDF.
///
/// Кириллица в PDF поддерживается только встроенными TTF-шрифтами —
/// стандартные шрифты PDF не содержат кириллических глифов.
class ContractPdfFonts {
  final Uint8List regular;
  final Uint8List bold;

  const ContractPdfFonts({required this.regular, required this.bold});
}

/// Результат генерации PDF.
class GeneratedContractPdf {
  final Uint8List bytes;

  /// Количество страниц в документе.
  final int pageCount;

  /// Предлагаемое имя файла.
  final String fileName;

  /// Время генерации (для проверки нефункционального требования < 2 секунд).
  final Duration generationTime;

  GeneratedContractPdf({
    required this.bytes,
    required this.pageCount,
    required this.fileName,
    required this.generationTime,
  });
}

/// Сервис генерации PDF-файла договора из блоков [ComposedContract].
///
/// Вёрстка: A4, поля 20 мм, основной текст 12pt, заголовки 14pt bold,
/// нумерация страниц в нижнем колонтитуле. Кириллица обеспечивается
/// встроенными шрифтами Roboto, переданными через [ContractPdfFonts].
class ContractPdfService {
  final ContractPdfTypography typography;

  const ContractPdfService({
    this.typography = const ContractPdfTypography(),
  });

  static const double _pointsPerMm = 72.0 / 25.4;

  /// Генерирует PDF-файл для разобранного документа [document].
  Future<GeneratedContractPdf> generate({
    required ComposedContract document,
    required ContractPdfFonts fonts,
    String fileName = 'contract.pdf',
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
          return _buildPageNumber(context.pageNumber, context.pagesCount);
        },
        build: (context) => _buildBlocks(document.blocks),
      ),
    );

    final bytes = await pdf.save();
    stopwatch.stop();

    return GeneratedContractPdf(
      bytes: bytes,
      pageCount: totalPages,
      fileName: fileName,
      generationTime: stopwatch.elapsed,
    );
  }

  List<pw.Widget> _buildBlocks(List<ContractBlock> blocks) {
    final widgets = <pw.Widget>[];
    for (final block in blocks) {
      switch (block.type) {
        case ContractBlockType.spacing:
          widgets.add(
            pw.SizedBox(height: block.spacingSteps * _spacingUnit),
          );
        case ContractBlockType.title:
          widgets.add(
            pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 2),
              child: pw.Center(
                child: pw.Text(
                  block.text,
                  textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(
                    fontSize: typography.headingFontSize,
                    fontWeight: pw.FontWeight.bold,
                    height: 1.3,
                  ),
                ),
              ),
            ),
          );
        case ContractBlockType.subtitle:
          widgets.add(
            pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 2),
              child: pw.Center(
                child: pw.Text(
                  block.text,
                  textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(
                    fontSize: typography.bodyFontSize + 2,
                    height: 1.3,
                  ),
                ),
              ),
            ),
          );
        case ContractBlockType.heading:
          widgets.add(
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 4, bottom: 2),
              child: pw.Text(
                block.text,
                style: pw.TextStyle(
                  fontSize: typography.headingFontSize,
                  fontWeight: pw.FontWeight.bold,
                  height: 1.3,
                ),
              ),
            ),
          );
        case ContractBlockType.meta:
          widgets.add(
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 2),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    child: pw.Text(
                      block.text,
                      style: pw.TextStyle(
                        fontSize: typography.bodyFontSize,
                        height: 1.25,
                      ),
                    ),
                  ),
                  pw.Text(
                    block.secondaryText ?? '',
                    style: pw.TextStyle(
                      fontSize: typography.bodyFontSize,
                      height: 1.25,
                    ),
                  ),
                ],
              ),
            ),
          );
        case ContractBlockType.protective:
          widgets.add(_buildProtective(block));
        case ContractBlockType.signature:
          widgets.add(
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 8, left: 8),
              child: pw.Text(
                block.text,
                style: pw.TextStyle(
                  fontSize: typography.bodyFontSize,
                  height: 1.25,
                ),
              ),
            ),
          );
        case ContractBlockType.body:
          widgets.add(
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 1),
              child: pw.Text(
                block.text,
                textAlign: pw.TextAlign.justify,
                style: pw.TextStyle(
                  fontSize: typography.bodyFontSize,
                  height: 1.25,
                ),
              ),
            ),
          );
      }
    }
    return widgets;
  }

  /// Защитная формулировка: подсвеченный блок со значком щита.
  pw.Widget _buildProtective(ContractBlock block) {
    final isHeading = isProtectiveHeading(block.text);
    final shield = pw.SvgImage(svg: _shieldSvg, width: 10, height: 10);
    return pw.Container(
      margin: const pw.EdgeInsets.symmetric(vertical: 2),
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: pw.BoxDecoration(
        color: const PdfColor.fromInt(0xFFE8F5E9),
        border: const pw.Border(
          left: pw.BorderSide(
            color: PdfColor.fromInt(0xFF2E7D32),
            width: 2,
          ),
        ),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 1, right: 4),
            child: shield,
          ),
          pw.Expanded(
            child: pw.Text(
              block.text,
              textAlign: isHeading ? pw.TextAlign.left : pw.TextAlign.justify,
              style: pw.TextStyle(
                fontSize: typography.bodyFontSize,
                fontWeight: isHeading
                    ? pw.FontWeight.bold
                    : pw.FontWeight.normal,
                color: const PdfColor.fromInt(0xFF1B5E20),
                height: 1.25,
              ),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildPageNumber(int pageNumber, int pagesCount) {
    return pw.Center(
      child: pw.Text(
        'Страница $pageNumber из $pagesCount',
        style: pw.TextStyle(
          fontSize: typography.bodyFontSize - 3,
          color: PdfColors.grey700,
        ),
      ),
    );
  }

  /// Высота вертикального отступа на одну пустую строку шаблона (pt).
  static const double _spacingUnit = 5;

  /// Значок щита (SVG) для маркировки защитных формулировок в PDF.
  static const String _shieldSvg =
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">'
      '<path fill="#2E7D32" d="M12 1 3 5v6c0 5.55 3.84 10.74 9 12 '
      '5.16-1.26 9-6.45 9-12V5l-9-4z"/></svg>';
}
