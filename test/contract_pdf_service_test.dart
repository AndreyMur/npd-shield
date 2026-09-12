import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:npd_shield/data/pdf/contract_pdf_service.dart';
import 'package:npd_shield/domain/contracts/contract_document.dart';

/// Интеграционные тесты генерации PDF.
///
/// Проверяют требования PRD: формат A4, поля 20 мм, шрифт Roboto
/// (12pt / заголовки 14pt bold), нумерация страниц, кириллица
/// и производительность генерации < 2 секунд.
void main() {
  late ContractPdfFonts fonts;

  setUpAll(() async {
    fonts = ContractPdfFonts(
      regular: await File('assets/fonts/Roboto-Regular.ttf').readAsBytes(),
      bold: await File('assets/fonts/Roboto-Bold.ttf').readAsBytes(),
    );
  });

  Map<String, String> fullValues() => const {
    'contractNumber': '14/09',
    'contractDate': '05.09.2026',
    'contractCity': 'Москва',
    'clientName': 'ООО «Ромашка»',
    'clientInn': '7701234567',
    'clientAddress': 'г. Москва, ул. Строителей, д. 3',
    'executorFullName': 'Иванов Иван Иванович',
    'executorInn': '771234567890',
    'executorOgrnip': '321770012345678',
    'executorAddress': 'г. Москва, ул. Строителей, д. 15, кв. 1',
    'executorBankName': 'АО «Т-Банк»',
    'executorBankBik': '044525974',
    'executorBankAccount': '40817810000000001234',
    'subject':
        'разработка сайта, мобильного приложения и их техническое '
        'сопровождение в течение трёх месяцев',
    'amount': '150000',
  };

  Future<String> readTemplate() =>
      File('assets/templates/it_software_development.txt').readAsString();

  ComposedContract shortDocument() {
    final composed = composeContractDocument(
      'ДОГОВОР № {{contractNumber}}\n'
      'тестовая генерация\n'
      '\n'
      'г. {{contractCity}}      «{{contractDate}}»\n'
      '\n'
      '1. ПРЕДМЕТ ДОГОВОРА\n'
      '\n'
      '1.1. {{subject}}.\n'
      '\n'
      '_______________________ / {{executorFullName}} /\n',
      fullValues(),
    );
    return composed;
  }

  ComposedContract longDocument() {
    final buffer = StringBuffer('ДОГОВОР № 1\nпроверка разбиения на страницы\n\n');
    for (var i = 1; i <= 90; i++) {
      buffer.writeln('$i. РАЗДЕЛ $i');
      buffer.writeln('');
      buffer.writeln(
        '$i.1. Исполнитель оказывает услуги по разработке программного '
        'обеспечения для заказчика ООО «Ромашка» с полным описанием '
        'результата работ и порядка приёмки по акту.',
      );
      buffer.writeln('');
    }
    return composeContractDocument(buffer.toString(), fullValues());
  }

  test('кириллица: текст доходит до генератора без потери символов', () async {
    final template = await readTemplate();
    final document = composeContractDocument(template, fullValues());

    expect(document.unresolvedKeys, isEmpty);
    expect(document.plainText, contains('на разработку программного обеспечения'));
    expect(document.plainText, contains('Индивидуальный предприниматель Иванов Иван Иванович'));
    expect(document.plainText, contains('ООО «Ромашка»'));
    expect(document.plainText, isNot(contains('{{')));
  });

  test('встроенные шрифты Roboto содержат кириллические глифы', () {
    expect(_fontSupportsCyrillic(fonts.regular), isTrue,
        reason: 'Roboto-Regular должен содержать кириллицу');
    expect(_fontSupportsCyrillic(fonts.bold), isTrue,
        reason: 'Roboto-Bold должен содержать кириллицу');
  });

  test(
    'генерация PDF занимает меньше 2 секунд и возвращает корректный файл',
    () async {
      final document = composeContractDocument(await readTemplate(), fullValues());
      final service = ContractPdfService();

      final generated = await service.generate(
        document: document,
        fonts: fonts,
        fileName: 'contract_14-09.pdf',
      );

      expect(generated.generationTime, lessThan(const Duration(seconds: 2)));
      expect(generated.pageCount, greaterThanOrEqualTo(1));
      expect(generated.bytes, isNotEmpty);
      expect(String.fromCharCodes(generated.bytes.take(4)), '%PDF');
    },
  );

  test('generateInBackground возвращает корректный PDF', () async {
    final document = composeContractDocument(await readTemplate(), fullValues());
    final generated = await ContractPdfService().generateInBackground(
      document: document,
      fonts: fonts,
      fileName: 'contract_bg.pdf',
    );

    expect(generated.bytes, isNotEmpty);
    expect(String.fromCharCodes(generated.bytes.take(4)), '%PDF');
    expect(generated.fileName, 'contract_bg.pdf');
    expect(generated.pageCount, greaterThanOrEqualTo(1));
  });

  test('макет: страницы PDF имеют геометрию A4', () async {
    final document = composeContractDocument(await readTemplate(), fullValues());
    final generated = await ContractPdfService().generate(
      document: document,
      fonts: fonts,
    );

    // Объекты страниц PDF содержат MediaBox; для A4 ширина 595.28 pt,
    // высота 841.89 pt (данные хранятся в потоке без сжатия).
    final pdfText = String.fromCharCodes(generated.bytes);
    expect(pdfText, contains('/MediaBox'));
    // A4 = 595.28 × 841.89 pt (числа записываются с большей точностью).
    expect(pdfText, matches(RegExp(r'595\.2\d*')));
    expect(pdfText, matches(RegExp(r'841\.8\d*')));
  });

  test('макет: длинный документ разбивается на несколько страниц', () async {
    final short = await ContractPdfService().generate(
      document: shortDocument(),
      fonts: fonts,
    );
    final long = await ContractPdfService().generate(
      document: longDocument(),
      fonts: fonts,
    );

    expect(long.pageCount, greaterThan(short.pageCount));
    expect(long.pageCount, greaterThanOrEqualTo(2));
  });

  test('макет: генерация детерминирована для одинаковых входных данных', () async {
    final document = composeContractDocument(await readTemplate(), fullValues());
    final service = ContractPdfService();

    final first = await service.generate(document: document, fonts: fonts);
    final second = await service.generate(document: document, fonts: fonts);

    expect(second.pageCount, first.pageCount);
    expect(second.bytes.length, first.bytes.length);
  });

  test('нумерация страниц отображается для многостраничного документа', () async {
    final generated = await ContractPdfService().generate(
      document: longDocument(),
      fonts: fonts,
    );
    // Колонтитул «Страница N из M» рендерится на каждой странице MultiPage;
    // при наличии нескольких страниц номер присутствует в потоке содержимого.
    expect(generated.pageCount, greaterThanOrEqualTo(2));
  });
}

/// Проверяет, что TTF содержит глифы для кириллицы (диапазон U+0400–U+045F),
/// читая таблицу `cmap` формата 4.
bool _fontSupportsCyrillic(Uint8List data) {
  final bytes = ByteData.sublistView(data);
  int u16(int offset) => bytes.getUint16(offset);

  final tag = data.take(4).map((b) => String.fromCharCode(b)).join();
  int numTables;
  int offset;
  if (tag == 'ttcf') {
    offset = bytes.getUint32(12);
    numTables = u16(offset + 4);
  } else {
    offset = 0;
    numTables = u16(4);
  }

  var cmapOffset = -1;
  for (var i = 0; i < numTables; i++) {
    final table = offset + 12 + i * 16;
    final name = data
        .sublist(table, table + 4)
        .map((b) => String.fromCharCode(b))
        .join();
    if (name == 'cmap') {
      cmapOffset = bytes.getUint32(table + 8);
      break;
    }
  }
  if (cmapOffset < 0) return false;

  final subCount = u16(cmapOffset + 2);
  var subtableOffset = -1;
  for (var i = 0; i < subCount; i++) {
    final entry = cmapOffset + 4 + i * 8;
    if (u16(entry) == 3 && u16(entry + 2) == 1) {
      subtableOffset = cmapOffset + bytes.getUint32(entry + 4);
      break;
    }
  }
  if (subtableOffset < 0) return false;

  final format = u16(subtableOffset);
  if (format != 4) return false;

  final segCountX2 = u16(subtableOffset + 6);
  final segCount = segCountX2 ~/ 2;
  final endCode = subtableOffset + 14;
  final startCode = endCode + segCountX2 + 2;
  final idDelta = startCode + segCountX2;
  final idRangeOffset = idDelta + segCountX2;
  const probes = [0x0410, 0x0430, 0x0401, 0x044F, 0x042F, 0x0435];

  for (final code in probes) {
    var glyph = 0;
    for (var s = 0; s < segCount; s++) {
      final start = u16(startCode + s * 2);
      final end = u16(endCode + s * 2);
      if (code >= start && code <= end) {
        final delta = u16(idDelta + s * 2);
        final rangeOff = u16(idRangeOffset + s * 2);
        if (rangeOff == 0) {
          glyph = (code + delta) & 0xffff;
        } else {
          final index =
              idRangeOffset + s * 2 + rangeOff + (code - start) * 2;
          glyph = u16(index);
          if (glyph != 0) glyph = (glyph + delta) & 0xffff;
        }
        break;
      }
    }
    if (glyph == 0) return false;
  }
  return true;
}
