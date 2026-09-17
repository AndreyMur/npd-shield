import 'dart:typed_data';

/// Проверяет, что TTF содержит глифы для кириллицы (диапазон U+0400–U+045F),
/// читая таблицу `cmap` формата 4.
///
/// Используется тестами шрифтовых ассетов: интерфейсные шрифты (Inter,
/// JetBrains Mono) должны поддерживать кириллицу без внешних загрузок.
bool fontSupportsCyrillic(Uint8List data) {
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
          final index = idRangeOffset + s * 2 + rangeOff + (code - start) * 2;
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
