import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:npd_shield/core/theme/app_icons.dart';
import 'package:npd_shield/core/theme/app_theme.dart';
import 'package:npd_shield/core/theme/app_tokens.dart';

void main() {
  group('Размеры иконок', () {
    test('токены размеров упорядочены и вмещаются в touch-target', () {
      const sizes = [
        AppIconSize.xs,
        AppIconSize.sm,
        AppIconSize.md,
        AppIconSize.lg,
        AppIconSize.xl,
      ];
      expect(sizes, orderedEquals(List.of(sizes)..sort()));
      for (final size in sizes) {
        expect(size, lessThanOrEqualTo(AppIconSize.touchTarget));
      }
      expect(AppIconSize.touchTarget, greaterThanOrEqualTo(48));
    });
  });

  group('Дисциплина filled/outline', () {
    test('toggle выбирает заполненный вариант для выбранного состояния', () {
      expect(
        AppIcons.toggle(Icons.home_outlined, Icons.home, selected: false),
        Icons.home_outlined,
      );
      expect(
        AppIcons.toggle(Icons.home_outlined, Icons.home, selected: true),
        Icons.home,
      );
    });
  });

  group('Виджет AppIcon', () {
    Future<void> pumpIcon(
      WidgetTester tester, {
      required Widget icon,
      ThemeData? theme,
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: theme ?? AppTheme.light(null),
          home: Scaffold(body: Center(child: icon)),
        ),
      );
    }

    testWidgets('использует размер и цвет из токенов', (tester) async {
      const color = Color(0xFF123456);
      await pumpIcon(
        tester,
        icon: const AppIcon(
          Icons.shield,
          size: AppIconSize.lg,
          color: color,
        ),
      );

      final widget = tester.widget<Icon>(find.byType(Icon));
      expect(widget.icon, Icons.shield);
      expect(widget.size, AppIconSize.lg);
      expect(widget.color, color);
    });

    testWidgets('по умолчанию — базовый размер и цвет текста темы',
        (tester) async {
      await pumpIcon(tester, icon: const AppIcon(Icons.shield));

      final widget = tester.widget<Icon>(find.byType(Icon));
      expect(widget.size, AppIconSize.md);
      expect(widget.color, AppTokens.light.onSurface);
    });

    testWidgets('semantic label доступен скринридеру', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpIcon(
        tester,
        icon: const AppIcon(Icons.shield, semanticLabel: 'Проверка'),
      );

      expect(
        tester.getSemantics(find.byType(AppIcon)).label,
        contains('Проверка'),
      );
      handle.dispose();
    });

    testWidgets('без подписи иконка декоративная', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpIcon(tester, icon: const AppIcon(Icons.shield));

      expect(tester.getSemantics(find.byType(AppIcon)).label, isEmpty);
      handle.dispose();
    });
  });

  group('Запрет эмодзи как структурных иконок', () {
    test('в lib нет эмодзи', () {
      final emoji = RegExp(
        r'[\u{1F000}-\u{1FAFF}\u{2600}-\u{27BF}\u{2B00}-\u{2BFF}\u{FE0F}]',
        unicode: true,
      );
      final offenders = <String>[];
      for (final entity in Directory('lib').listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;
        final content = entity.readAsStringSync();
        if (emoji.hasMatch(content)) offenders.add(entity.path);
      }
      expect(
        offenders,
        isEmpty,
        reason: 'Эмодзи недопустимы как структурные иконки: $offenders',
      );
    });
  });
}
