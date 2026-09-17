import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:npd_shield/core/theme/app_gradients.dart';
import 'package:npd_shield/core/theme/app_tokens.dart';

void main() {
  group('Цветовые токены', () {
    test('светлая палитра соответствует PRD', () {
      const t = AppTokens.light;
      expect(t.primary, const Color(0xFF1E40AF));
      expect(t.secondary, const Color(0xFF3B82F6));
      expect(t.accent, const Color(0xFF059669));
      expect(t.success, const Color(0xFF059669));
      expect(t.warning, const Color(0xFFF59E0B));
      expect(t.destructive, const Color(0xFFDC2626));
      expect(t.surface, const Color(0xFFFFFFFF));
    });

    test('тёмная палитра использует отдельные значения', () {
      const t = AppTokens.dark;
      expect(t.surface, const Color(0xFF0F172A));
      expect(t.onSurface, const Color(0xFFF8FAFC));
      expect(t.primary, isNot(AppTokens.light.primary));
      expect(t.muted, isNot(AppTokens.light.muted));
    });

    test('семантические цвета стабильны для обеих тем', () {
      expect(AppTokens.light.success, AppTokens.light.accent);
      expect(AppTokens.dark.success, AppTokens.dark.accent);
      expect(
        AppTokens.light.sphereIt,
        const Color(0xFF2196F3),
      );
      expect(
        AppTokens.light.sphereLogistics,
        const Color(0xFFFF9800),
      );
      expect(AppTokens.dark.sphereIt, AppTokens.light.sphereIt);
      expect(AppTokens.dark.sphereLogistics, AppTokens.light.sphereLogistics);
    });

    test('forBrightness возвращает нужный набор', () {
      expect(AppTokens.forBrightness(Brightness.light), AppTokens.light);
      expect(AppTokens.forBrightness(Brightness.dark), AppTokens.dark);
    });

    test('copyWith заменяет только заданные поля', () {
      final copy = AppTokens.light.copyWith(primary: const Color(0xFF123456));
      expect(copy.primary, const Color(0xFF123456));
      expect(copy.secondary, AppTokens.light.secondary);
      expect(copy.success, AppTokens.light.success);
    });

    test('lerp проходит между темами', () {
      final mid = AppTokens.light.lerp(AppTokens.dark, 0.5);
      expect(mid.surface, isNot(AppTokens.light.surface));
      expect(mid.surface, isNot(AppTokens.dark.surface));
      expect(AppTokens.light.lerp(null, 0.5), AppTokens.light);
    });
  });

  group('Контраст light/dark (WCAG)', () {
    for (final entry in {
      'light': AppTokens.light,
      'dark': AppTokens.dark,
    }.entries) {
      final theme = entry.key;
      final t = entry.value;

      test('$theme: основной текст на фоне ≥ 4.5:1', () {
        expect(_ratio(t.onSurface, t.surface), greaterThanOrEqualTo(4.5));
        expect(_ratio(t.onSurface, t.surfaceVariant), greaterThanOrEqualTo(4.5));
      });

      test('$theme: вторичный текст на фоне ≥ 3:1', () {
        expect(_ratio(t.muted, t.surface), greaterThanOrEqualTo(3.0));
        expect(_ratio(t.muted, t.surfaceVariant), greaterThanOrEqualTo(3.0));
      });

      test('$theme: текст на акцентных цветах ≥ 4.5:1', () {
        expect(_ratio(t.onPrimary, t.primary), greaterThanOrEqualTo(4.5));
        expect(
          _ratio(t.onDestructive, t.destructive),
          greaterThanOrEqualTo(4.5),
        );
      });

      test('$theme: семантический текст различим на фоне ≥ 3:1', () {
        expect(_ratio(t.success, t.surface), greaterThanOrEqualTo(3.0));
        expect(_ratio(t.destructive, t.surface), greaterThanOrEqualTo(3.0));
      });
    }
  });

  group('Spacing и radius', () {
    test('spacing-шкала кратна 4 dp', () {
      const values = [
        AppSpacing.xxs,
        AppSpacing.xs,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.xl,
        AppSpacing.xxl,
      ];
      for (final value in values) {
        expect(value % 4, 0, reason: '$value должно быть кратно 4');
      }
      expect(values, orderedEquals(List.of(values)..sort()));
    });

    test('radius-шкала в заданных диапазонах', () {
      expect(AppRadius.card, inInclusiveRange(16, 20));
      expect(AppRadius.button, inInclusiveRange(12, 16));
      expect(AppRadius.field, inInclusiveRange(12, 16));
      expect(AppRadius.chip, greaterThanOrEqualTo(100));
      expect(AppRadius.cardRadius.topLeft.x, AppRadius.card);
      expect(AppRadius.chipRadius.topLeft.x, AppRadius.chip);
    });

    test('elevation-шкала возрастает', () {
      expect(AppElevation.none, 0);
      expect(AppElevation.low, lessThan(AppElevation.medium));
      expect(AppElevation.medium, lessThan(AppElevation.high));
    });
  });

  group('Градиентные токены', () {
    test('брендовый градиент идёт от primary к secondary', () {
      expect(AppGradients.brand.colors.first, const Color(0xFF1E40AF));
      expect(AppGradients.brand.colors.last, const Color(0xFF3B82F6));
      expect(AppTokens.light.brandGradient, AppGradients.brand);
      expect(AppTokens.dark.brandGradient, AppGradients.brandDark);
    });

    test('градиент лимита содержит три уровня', () {
      expect(AppGradients.limit.colors.length, 3);
      expect(AppTokens.light.limitGradient, AppGradients.limit);
      expect(AppTokens.dark.limitGradient, AppGradients.limit);
    });

    test('градиенты риска и дохода заданы', () {
      expect(AppGradients.risk.colors.length, 2);
      expect(AppGradients.income.colors.length, 2);
      expect(AppTokens.light.riskGradient, AppGradients.risk);
      expect(AppTokens.light.incomeGradient, AppGradients.income);
    });
  });
}

double _ratio(Color a, Color b) {
  final l1 = _luminance(a);
  final l2 = _luminance(b);
  final lighter = max(l1, l2);
  final darker = min(l1, l2);
  return (lighter + 0.05) / (darker + 0.05);
}

double _luminance(Color color) {
  double channel(double value) {
    return value <= 0.03928
        ? value / 12.92
        : pow((value + 0.055) / 1.055, 2.4).toDouble();
  }

  return 0.2126 * channel(color.r) +
      0.7152 * channel(color.g) +
      0.0722 * channel(color.b);
}
