import 'package:flutter/services.dart';

import 'contract_pdf_service.dart';

/// Загружает встроенные шрифты Roboto из Assets приложения.
///
/// Файлы объявлены в `pubspec.yaml` в секции `flutter.fonts` как шрифты
/// семейства Roboto и дополнительно используются генератором PDF.
class ContractPdfFontLoader {
  static const regularAsset = 'assets/fonts/Roboto-Regular.ttf';
  static const boldAsset = 'assets/fonts/Roboto-Bold.ttf';

  const ContractPdfFontLoader();

  /// Кэш загруженных шрифтов: ассеты читаются один раз за сессию.
  static ContractPdfFonts? _cache;

  Future<ContractPdfFonts> load() async {
    final cached = _cache;
    if (cached != null) return cached;
    final regular = await rootBundle.load(regularAsset);
    final bold = await rootBundle.load(boldAsset);
    final fonts = ContractPdfFonts(
      regular: _toUint8List(regular),
      bold: _toUint8List(bold),
    );
    _cache = fonts;
    return fonts;
  }

  /// Сбрасывает кэш шрифтов (используется в тестах).
  static void clearCache() => _cache = null;

  static Uint8List _toUint8List(ByteData data) {
    return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
  }
}
