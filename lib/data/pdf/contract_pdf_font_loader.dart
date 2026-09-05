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

  Future<ContractPdfFonts> load() async {
    final regular = await rootBundle.load(regularAsset);
    final bold = await rootBundle.load(boldAsset);
    return ContractPdfFonts(
      regular: _toUint8List(regular),
      bold: _toUint8List(bold),
    );
  }

  static Uint8List _toUint8List(ByteData data) {
    return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
  }
}
