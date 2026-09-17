import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:npd_shield/core/theme/app_theme.dart';
import 'package:npd_shield/core/theme/app_tokens.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('по умолчанию тема системная', () async {
    expect(await AppTheme.loadMode(), ThemeMode.system);
  });

  test('сохранённая тема применяется между запусками', () async {
    await AppTheme.saveMode(ThemeMode.dark);

    expect(await AppTheme.loadMode(), ThemeMode.dark);
  });

  test('каждая тема сохраняется и читается', () async {
    for (final mode in ThemeMode.values) {
      await AppTheme.saveMode(mode);
      expect(await AppTheme.loadMode(), mode);
    }
  });

  group('Интеграция токенов в AppTheme', () {
    test('светлая тема регистрирует светлые токены', () {
      final theme = AppTheme.light(null);
      expect(theme.brightness, Brightness.light);
      expect(theme.extension<AppTokens>(), AppTokens.light);
      expect(theme.scaffoldBackgroundColor, AppTokens.light.surface);
      expect(theme.cardTheme.shape, isA<RoundedRectangleBorder>());
    });

    test('тёмная тема регистрирует тёмные токены', () {
      final theme = AppTheme.dark(null);
      expect(theme.brightness, Brightness.dark);
      expect(theme.extension<AppTokens>(), AppTokens.dark);
      expect(theme.scaffoldBackgroundColor, AppTokens.dark.surface);
    });

    test('Dynamic Color не переопределяет семантические цвета', () {
      final dynamicScheme = ColorScheme.fromSeed(
        seedColor: const Color(0xFFFF00FF),
        brightness: Brightness.light,
      ).copyWith(error: const Color(0xFF00FF00));

      final theme = AppTheme.light(dynamicScheme);

      expect(theme.colorScheme.error, AppTokens.light.destructive);
      expect(theme.colorScheme.onError, AppTokens.light.onDestructive);
      expect(theme.extension<AppTokens>()!.success, AppTokens.light.success);
      expect(
        theme.extension<AppTokens>()!.destructive,
        AppTokens.light.destructive,
      );
    });

    test('Dynamic Color задаёт схему, но токены остаются фирменными', () {
      final dynamicScheme = ColorScheme.fromSeed(
        seedColor: const Color(0xFF7C3AED),
        brightness: Brightness.dark,
      );

      final theme = AppTheme.dark(dynamicScheme);

      expect(theme.colorScheme.primary, dynamicScheme.primary);
      expect(theme.extension<AppTokens>()!.primary, AppTokens.dark.primary);
    });
  });
}
