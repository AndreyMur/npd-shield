import 'package:flutter/foundation.dart';

/// Шрифты для встраивания в PDF.
///
/// Кириллица в PDF поддерживается только встроенными TTF-шрифтами —
/// стандартные шрифты PDF не содержат кириллических глифов.
class PdfFonts {
  final Uint8List regular;
  final Uint8List bold;

  const PdfFonts({required this.regular, required this.bold});
}
