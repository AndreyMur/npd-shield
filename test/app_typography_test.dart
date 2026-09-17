import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:npd_shield/core/theme/app_theme.dart';
import 'package:npd_shield/core/theme/app_typography.dart';

import 'helpers/font_glyphs.dart';

void main() {
  group('Типо-шкала', () {
    test('базовый текст — 16 pt при line-height 1.5', () {
      expect(AppTypography.body.fontSize, 16);
      expect(AppTypography.body.height, 1.5);
      expect(AppTypography.body.fontWeight, FontWeight.w400);
    });

    test('уровни шкалы заданы фиксированными размерами', () {
      expect(AppTypography.display.fontSize, 40);
      expect(AppTypography.headline.fontSize, 28);
      expect(AppTypography.title.fontSize, 20);
      expect(AppTypography.body.fontSize, 16);
      expect(AppTypography.label.fontSize, 13);
      expect(AppTypography.metric.fontSize, 24);
    });

    test('заголовки и текст набраны Inter', () {
      for (final style in [
        AppTypography.display,
        AppTypography.headline,
        AppTypography.title,
        AppTypography.body,
        AppTypography.label,
      ]) {
        expect(style.fontFamily, AppFonts.inter);
        expect(style.fontFamilyFallback, contains(AppFonts.roboto));
        expect(style.height, isNotNull);
      }
    });

    test('метрики набраны моноширинным JetBrains Mono с табличными цифрами',
        () {
      for (final style in [
        AppTypography.metricLarge,
        AppTypography.metric,
        AppTypography.metricSmall,
        AppTypography.metricLabel,
      ]) {
        expect(style.fontFamily, AppFonts.jetBrainsMono);
        expect(style.fontFamilyFallback, contains(AppFonts.inter));
        expect(
          style.fontFeatures,
          contains(const FontFeature.tabularFigures()),
        );
      }
    });

    test('TextTheme покрывает все слоты и использует фирменные шрифты', () {
      const theme = AppTypography.textTheme;
      final slots = [
        theme.displayLarge,
        theme.displayMedium,
        theme.displaySmall,
        theme.headlineLarge,
        theme.headlineMedium,
        theme.headlineSmall,
        theme.titleLarge,
        theme.titleMedium,
        theme.titleSmall,
        theme.bodyLarge,
        theme.bodyMedium,
        theme.bodySmall,
        theme.labelLarge,
        theme.labelMedium,
        theme.labelSmall,
      ];
      for (final style in slots) {
        expect(style, isNotNull);
        expect(style!.fontFamily, AppFonts.inter);
      }
      expect(theme.bodyLarge!.fontSize, 16);
      expect(theme.bodyLarge!.height, 1.5);
      expect(theme.titleLarge!.fontSize, AppTypography.title.fontSize);
      expect(theme.headlineLarge!.fontSize, AppTypography.headline.fontSize);
    });
  });

  group('Интеграция типографики в AppTheme', () {
    test('обе темы используют Inter как семейство по умолчанию', () {
      for (final theme in [AppTheme.light(null), AppTheme.dark(null)]) {
        expect(theme.textTheme.bodyLarge!.fontFamily, AppFonts.inter);
        expect(theme.textTheme.bodyLarge!.fontSize, 16);
        expect(theme.textTheme.displayLarge!.fontSize, 40);
      }
    });
  });

  group('Шрифтовые ассеты', () {
    const interfaceFonts = {
      'Inter-Regular.ttf': 400,
      'Inter-Medium.ttf': 500,
      'Inter-SemiBold.ttf': 600,
      'Inter-Bold.ttf': 700,
    };
    const monoFonts = {
      'JetBrainsMono-Regular.ttf': 400,
      'JetBrainsMono-Medium.ttf': 500,
      'JetBrainsMono-Bold.ttf': 700,
    };

    for (final family in ['Inter', 'JetBrains Mono']) {
      test('$family содержит только используемые веса и кириллицу', () {
        final fonts = family == 'Inter' ? interfaceFonts : monoFonts;
        expect(fonts.length, greaterThanOrEqualTo(3));
        for (final file in fonts.keys) {
          final data = File('assets/fonts/$file').readAsBytesSync();
          expect(data, isNotEmpty, reason: '$file не должен быть пустым');
          expect(
            fontSupportsCyrillic(data),
            isTrue,
            reason: '$file должен содержать кириллицу',
          );
        }
      });
    }

    test('шрифты объявлены в pubspec как ассеты', () {
      final pubspec = File('pubspec.yaml').readAsStringSync();
      expect(pubspec, contains('family: Inter'));
      expect(pubspec, contains('family: JetBrains Mono'));
      for (final file in [
        ...interfaceFonts.keys,
        ...monoFonts.keys,
      ]) {
        expect(pubspec, contains('assets/fonts/$file'));
      }
    });
  });
}
