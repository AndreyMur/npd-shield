import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_tokens.dart';
import 'app_typography.dart';

class AppTheme {
  static const seedColor = Color(0xFF2196F3);

  static const _prefsKey = 'theme_mode';

  static ThemeData light(ColorScheme? dynamicScheme) {
    return _build(Brightness.light, dynamicScheme);
  }

  static ThemeData dark(ColorScheme? dynamicScheme) {
    return _build(Brightness.dark, dynamicScheme);
  }

  /// Собирает тему из дизайн-токенов.
  ///
  /// Dynamic Color остаётся опциональным слоем: он задаёт схему Material, но
  /// семантические цвета (ошибка/риск, успех) берутся из [AppTokens] и не
  /// переопределяются системной палитрой.
  static ThemeData _build(Brightness brightness, ColorScheme? dynamicScheme) {
    final tokens = AppTokens.forBrightness(brightness);
    final base = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: brightness,
    );
    final scheme = (dynamicScheme ?? base).copyWith(
      error: tokens.destructive,
      onError: tokens.onDestructive,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: tokens.surface,
      fontFamily: AppFonts.inter,
      fontFamilyFallback: AppFonts.interFallback,
      textTheme: AppTypography.textTheme,
      extensions: <ThemeExtension<dynamic>>[tokens],
      cardTheme: CardThemeData(
        color: tokens.surface,
        elevation: AppElevation.low,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.cardRadius,
          side: BorderSide(color: tokens.border),
        ),
      ),
      appBarTheme: AppBarThemeData(
        backgroundColor: tokens.surface,
        foregroundColor: tokens.onSurface,
        elevation: AppElevation.none,
        scrolledUnderElevation: AppElevation.none,
        centerTitle: false,
      ),
      dividerTheme: DividerThemeData(
        color: tokens.border,
        space: AppSpacing.lg,
      ),
    );
  }

  static Future<ThemeMode> loadMode() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_prefsKey);
    return switch (value) {
      'dark' => ThemeMode.dark,
      'light' => ThemeMode.light,
      _ => ThemeMode.system,
    };
  }

  static Future<void> saveMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, mode.name);
  }
}
