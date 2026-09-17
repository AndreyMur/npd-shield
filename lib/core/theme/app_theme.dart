import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_icons.dart';
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

    OutlineInputBorder fieldBorder(Color color, {double width = 1}) =>
        OutlineInputBorder(
          borderRadius: AppRadius.fieldRadius,
          borderSide: BorderSide(color: color, width: width),
        );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: tokens.surface,
      fontFamily: AppFonts.inter,
      fontFamilyFallback: AppFonts.interFallback,
      textTheme: AppTypography.textTheme,
      extensions: <ThemeExtension<dynamic>>[tokens],
      iconTheme: IconThemeData(color: tokens.onSurface),
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
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: tokens.surfaceVariant,
        labelStyle: TextStyle(color: tokens.muted),
        hintStyle: TextStyle(color: tokens.muted),
        border: fieldBorder(tokens.border),
        enabledBorder: fieldBorder(tokens.border),
        focusedBorder: fieldBorder(tokens.primary, width: 1.5),
        errorBorder: fieldBorder(tokens.destructive),
        focusedErrorBorder: fieldBorder(tokens.destructive, width: 1.5),
        disabledBorder: fieldBorder(tokens.border.withValues(alpha: 0.5)),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: tokens.surfaceVariant,
        selectedColor: tokens.primary.withValues(alpha: 0.14),
        side: BorderSide(color: tokens.border),
        shape: const StadiumBorder(),
        labelStyle: TextStyle(color: tokens.onSurface),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? tokens.primary.withValues(alpha: 0.14)
                : tokens.surfaceVariant,
          ),
          foregroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? tokens.primary
                : tokens.onSurface,
          ),
          side: WidgetStatePropertyAll(BorderSide(color: tokens.border)),
          shape: const WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: AppRadius.buttonRadius),
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: tokens.onSurface,
        contentTextStyle: TextStyle(color: tokens.surface),
        actionTextColor: tokens.secondary,
        shape: const RoundedRectangleBorder(
          borderRadius: AppRadius.buttonRadius,
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: tokens.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: AppRadius.cardRadius,
        ),
        titleTextStyle: TextStyle(
          color: tokens.onSurface,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        contentTextStyle: TextStyle(color: tokens.onSurface),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: tokens.primary,
        foregroundColor: tokens.onPrimary,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: tokens.primary,
          foregroundColor: tokens.onPrimary,
          minimumSize: const Size(0, AppSpacing.xxl),
          shape: const RoundedRectangleBorder(
            borderRadius: AppRadius.buttonRadius,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: tokens.primary,
          side: BorderSide(color: tokens.border),
          minimumSize: const Size(0, AppSpacing.xxl),
          shape: const RoundedRectangleBorder(
            borderRadius: AppRadius.buttonRadius,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: tokens.primary),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: tokens.muted,
        textColor: tokens.onSurface,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: tokens.surface,
        indicatorColor: tokens.primary.withValues(alpha: 0.14),
        elevation: AppElevation.none,
        height: 72,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            size: AppIconSize.md,
            color: states.contains(WidgetState.selected)
                ? tokens.primary
                : tokens.muted,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => AppTypography.label.copyWith(
            color: states.contains(WidgetState.selected)
                ? tokens.primary
                : tokens.muted,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w600
                : FontWeight.w500,
          ),
        ),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: tokens.surface,
        indicatorColor: tokens.primary.withValues(alpha: 0.14),
        selectedIconTheme: IconThemeData(color: tokens.primary),
        unselectedIconTheme: IconThemeData(color: tokens.muted),
        selectedLabelTextStyle: AppTypography.label.copyWith(
          color: tokens.primary,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelTextStyle: AppTypography.label.copyWith(
          color: tokens.muted,
        ),
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
