import 'package:flutter/material.dart';

/// Семейства шрифтов дизайн-системы.
///
/// Подключены как ассеты (`pubspec.yaml`) и содержат кириллицу, поэтому
/// интерфейс не зависит от сети. [fallback] подстраховывает редкие глифы,
/// которых нет в основном начертании.
abstract final class AppFonts {
  /// Основной интерфейсный шрифт (заголовки и текст).
  static const inter = 'Inter';

  /// Моноширинный шрифт для числовых метрик и подписей данных.
  static const jetBrainsMono = 'JetBrains Mono';

  /// Шрифт PDF-документов, используется только как резервный.
  static const roboto = 'Roboto';

  /// Резерв для интерфейсной типографики.
  static const interFallback = <String>[roboto];

  /// Резерв для моноширинной типографики.
  static const monoFallback = <String>[inter, roboto];
}

/// Типо-шкала дизайн-системы.
///
/// Размеры и line-height фиксированы и не задаются на экранах вручную.
/// Базовый текст — 16 pt при line-height 1.5. Числовые метрики набраны
/// моноширинным JetBrains Mono с табличными цифрами, чтобы разряды не
/// «прыгали» при обновлении значений.
abstract final class AppTypography {
  /// Крупный экранный заголовок (40 / 1.2, bold).
  static const display = TextStyle(
    fontFamily: AppFonts.inter,
    fontFamilyFallback: AppFonts.interFallback,
    fontSize: 40,
    height: 1.2,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
  );

  /// Крупный заголовок раздела (28 / 1.29, bold).
  static const headline = TextStyle(
    fontFamily: AppFonts.inter,
    fontFamilyFallback: AppFonts.interFallback,
    fontSize: 28,
    height: 1.29,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.25,
  );

  /// Заголовок карточки или блока (20 / 1.4, semibold).
  static const title = TextStyle(
    fontFamily: AppFonts.inter,
    fontFamilyFallback: AppFonts.interFallback,
    fontSize: 20,
    height: 1.4,
    fontWeight: FontWeight.w600,
  );

  /// Основной текст (16 / 1.5, regular).
  static const body = TextStyle(
    fontFamily: AppFonts.inter,
    fontFamilyFallback: AppFonts.interFallback,
    fontSize: 16,
    height: 1.5,
    fontWeight: FontWeight.w400,
  );

  /// Подпись, лейбл, служебный текст (13 / 1.38, medium).
  static const label = TextStyle(
    fontFamily: AppFonts.inter,
    fontFamilyFallback: AppFonts.interFallback,
    fontSize: 13,
    height: 1.38,
    fontWeight: FontWeight.w500,
  );

  /// Крупная числовая метрика (28 / 1.29, semibold, mono).
  static const metricLarge = TextStyle(
    fontFamily: AppFonts.jetBrainsMono,
    fontFamilyFallback: AppFonts.monoFallback,
    fontSize: 28,
    height: 1.29,
    fontWeight: FontWeight.w600,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  /// Числовая метрика (24 / 1.33, semibold, mono).
  static const metric = TextStyle(
    fontFamily: AppFonts.jetBrainsMono,
    fontFamilyFallback: AppFonts.monoFallback,
    fontSize: 24,
    height: 1.33,
    fontWeight: FontWeight.w600,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  /// Компактная числовая метрика (16 / 1.5, semibold, mono).
  static const metricSmall = TextStyle(
    fontFamily: AppFonts.jetBrainsMono,
    fontFamilyFallback: AppFonts.monoFallback,
    fontSize: 16,
    height: 1.5,
    fontWeight: FontWeight.w600,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  /// Подпись оси/легенды графика (12 / 1.33, medium, mono).
  static const metricLabel = TextStyle(
    fontFamily: AppFonts.jetBrainsMono,
    fontFamilyFallback: AppFonts.monoFallback,
    fontSize: 12,
    height: 1.33,
    fontWeight: FontWeight.w500,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  /// Материал `TextTheme` со всеми слотами типо-шкалы.
  static const TextTheme textTheme = TextTheme(
    displayLarge: display,
    displayMedium: TextStyle(
      fontFamily: AppFonts.inter,
      fontFamilyFallback: AppFonts.interFallback,
      fontSize: 34,
      height: 1.24,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.25,
    ),
    displaySmall: headline,
    headlineLarge: headline,
    headlineMedium: TextStyle(
      fontFamily: AppFonts.inter,
      fontFamilyFallback: AppFonts.interFallback,
      fontSize: 24,
      height: 1.33,
      fontWeight: FontWeight.w600,
    ),
    headlineSmall: title,
    titleLarge: title,
    titleMedium: TextStyle(
      fontFamily: AppFonts.inter,
      fontFamilyFallback: AppFonts.interFallback,
      fontSize: 16,
      height: 1.5,
      fontWeight: FontWeight.w600,
    ),
    titleSmall: TextStyle(
      fontFamily: AppFonts.inter,
      fontFamilyFallback: AppFonts.interFallback,
      fontSize: 14,
      height: 1.43,
      fontWeight: FontWeight.w600,
    ),
    bodyLarge: body,
    bodyMedium: TextStyle(
      fontFamily: AppFonts.inter,
      fontFamilyFallback: AppFonts.interFallback,
      fontSize: 14,
      height: 1.5,
      fontWeight: FontWeight.w400,
    ),
    bodySmall: TextStyle(
      fontFamily: AppFonts.inter,
      fontFamilyFallback: AppFonts.interFallback,
      fontSize: 12,
      height: 1.5,
      fontWeight: FontWeight.w400,
    ),
    labelLarge: TextStyle(
      fontFamily: AppFonts.inter,
      fontFamilyFallback: AppFonts.interFallback,
      fontSize: 14,
      height: 1.43,
      fontWeight: FontWeight.w500,
    ),
    labelMedium: label,
    labelSmall: TextStyle(
      fontFamily: AppFonts.inter,
      fontFamilyFallback: AppFonts.interFallback,
      fontSize: 11,
      height: 1.45,
      fontWeight: FontWeight.w500,
    ),
  );
}
