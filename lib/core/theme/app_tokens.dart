import 'package:flutter/material.dart';

import 'app_gradients.dart';

/// Семантические дизайн-токены приложения.
///
/// Токены заданы отдельно для светлой и тёмной темы и доступны через
/// [Theme.of] как [ThemeExtension]. Семантические цвета (риск, успех)
/// фиксированы и не переопределяются Dynamic Color.
@immutable
class AppTokens extends ThemeExtension<AppTokens> {
  /// Основной фирменный цвет.
  final Color primary;

  /// Дополнительный фирменный цвет.
  final Color secondary;

  /// Акцентный цвет (совпадает с [success]).
  final Color accent;

  /// Базовый фон поверхностей.
  final Color surface;

  /// Вторичный фон (заливки, подложки).
  final Color surfaceVariant;

  /// Приглушённый цвет вторичного текста.
  final Color muted;

  /// Цвет границ и разделителей.
  final Color border;

  /// Цвет опасности/ошибки.
  final Color destructive;

  /// Цвет предупреждения.
  final Color warning;

  /// Затемнённый цвет предупреждения для текста и мелких элементов:
  /// сохраняет контраст ≥4.5:1 на светлом фоне.
  final Color warningStrong;

  /// Цвет успеха/дохода.
  final Color success;

  /// Основной цвет текста на [surface].
  final Color onSurface;

  /// Цвет текста на [primary].
  final Color onPrimary;

  /// Цвет текста на [destructive].
  final Color onDestructive;

  /// Брендовый градиент (primary → secondary).
  final LinearGradient brandGradient;

  /// Градиент дохода.
  final LinearGradient incomeGradient;

  /// Градиент риска (warning → destructive).
  final LinearGradient riskGradient;

  /// Градиент шкалы лимита НПД.
  final LinearGradient limitGradient;

  /// Акцент сферы IT.
  final Color sphereIt;

  /// Акцент сферы «Логистика».
  final Color sphereLogistics;

  const AppTokens({
    required this.primary,
    required this.secondary,
    required this.accent,
    required this.surface,
    required this.surfaceVariant,
    required this.muted,
    required this.border,
    required this.destructive,
    required this.warning,
    required this.warningStrong,
    required this.success,
    required this.onSurface,
    required this.onPrimary,
    required this.onDestructive,
    required this.brandGradient,
    required this.incomeGradient,
    required this.riskGradient,
    required this.limitGradient,
    required this.sphereIt,
    required this.sphereLogistics,
  });

  /// Токены светлой темы.
  static const light = AppTokens(
    primary: Color(0xFF1E40AF),
    secondary: Color(0xFF3B82F6),
    accent: Color(0xFF059669),
    surface: Color(0xFFFFFFFF),
    surfaceVariant: Color(0xFFF1F5F9),
    muted: Color(0xFF64748B),
    border: Color(0xFFE2E8F0),
    destructive: Color(0xFFDC2626),
    warning: Color(0xFFF59E0B),
    warningStrong: Color(0xFFB45309),
    success: Color(0xFF059669),
    onSurface: Color(0xFF0F172A),
    onPrimary: Color(0xFFFFFFFF),
    onDestructive: Color(0xFFFFFFFF),
    brandGradient: AppGradients.brand,
    incomeGradient: AppGradients.income,
    riskGradient: AppGradients.risk,
    limitGradient: AppGradients.limit,
    sphereIt: SphereColors.it,
    sphereLogistics: SphereColors.logistics,
  );

  /// Токены тёмной темы.
  ///
  /// Значения подобраны отдельно, чтобы сохранить контраст на тёмном фоне
  /// и не переносить светлые оттенки напрямую.
  static const dark = AppTokens(
    primary: Color(0xFF3B82F6),
    secondary: Color(0xFF60A5FA),
    accent: Color(0xFF10B981),
    surface: Color(0xFF0F172A),
    surfaceVariant: Color(0xFF1E293B),
    muted: Color(0xFF94A3B8),
    border: Color(0xFF334155),
    destructive: Color(0xFFF87171),
    warning: Color(0xFFFBBF24),
    warningStrong: Color(0xFFFBBF24),
    success: Color(0xFF10B981),
    onSurface: Color(0xFFF8FAFC),
    onPrimary: Color(0xFF0B1220),
    onDestructive: Color(0xFF450A0A),
    brandGradient: AppGradients.brandDark,
    incomeGradient: AppGradients.income,
    riskGradient: AppGradients.risk,
    limitGradient: AppGradients.limit,
    sphereIt: SphereColors.it,
    sphereLogistics: SphereColors.logistics,
  );

  /// Токены для текущей темы. Если расширение не зарегистрировано,
  /// возвращаются значения по яркости темы.
  static AppTokens of(BuildContext context) {
    final theme = Theme.of(context);
    return theme.extension<AppTokens>() ??
        (theme.brightness == Brightness.dark ? dark : light);
  }

  /// Токены для заданной яркости.
  static AppTokens forBrightness(Brightness brightness) =>
      brightness == Brightness.dark ? dark : light;

  @override
  AppTokens copyWith({
    Color? primary,
    Color? secondary,
    Color? accent,
    Color? surface,
    Color? surfaceVariant,
    Color? muted,
    Color? border,
    Color? destructive,
    Color? warning,
    Color? warningStrong,
    Color? success,
    Color? onSurface,
    Color? onPrimary,
    Color? onDestructive,
    LinearGradient? brandGradient,
    LinearGradient? incomeGradient,
    LinearGradient? riskGradient,
    LinearGradient? limitGradient,
    Color? sphereIt,
    Color? sphereLogistics,
  }) {
    return AppTokens(
      primary: primary ?? this.primary,
      secondary: secondary ?? this.secondary,
      accent: accent ?? this.accent,
      surface: surface ?? this.surface,
      surfaceVariant: surfaceVariant ?? this.surfaceVariant,
      muted: muted ?? this.muted,
      border: border ?? this.border,
      destructive: destructive ?? this.destructive,
      warning: warning ?? this.warning,
      warningStrong: warningStrong ?? this.warningStrong,
      success: success ?? this.success,
      onSurface: onSurface ?? this.onSurface,
      onPrimary: onPrimary ?? this.onPrimary,
      onDestructive: onDestructive ?? this.onDestructive,
      brandGradient: brandGradient ?? this.brandGradient,
      incomeGradient: incomeGradient ?? this.incomeGradient,
      riskGradient: riskGradient ?? this.riskGradient,
      limitGradient: limitGradient ?? this.limitGradient,
      sphereIt: sphereIt ?? this.sphereIt,
      sphereLogistics: sphereLogistics ?? this.sphereLogistics,
    );
  }

  @override
  AppTokens lerp(covariant AppTokens? other, double t) {
    if (other == null) return this;
    return AppTokens(
      primary: Color.lerp(primary, other.primary, t)!,
      secondary: Color.lerp(secondary, other.secondary, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceVariant: Color.lerp(surfaceVariant, other.surfaceVariant, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
      border: Color.lerp(border, other.border, t)!,
      destructive: Color.lerp(destructive, other.destructive, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      warningStrong: Color.lerp(warningStrong, other.warningStrong, t)!,
      success: Color.lerp(success, other.success, t)!,
      onSurface: Color.lerp(onSurface, other.onSurface, t)!,
      onPrimary: Color.lerp(onPrimary, other.onPrimary, t)!,
      onDestructive: Color.lerp(onDestructive, other.onDestructive, t)!,
      brandGradient: LinearGradient.lerp(brandGradient, other.brandGradient, t)!,
      incomeGradient:
          LinearGradient.lerp(incomeGradient, other.incomeGradient, t)!,
      riskGradient: LinearGradient.lerp(riskGradient, other.riskGradient, t)!,
      limitGradient: LinearGradient.lerp(limitGradient, other.limitGradient, t)!,
      sphereIt: Color.lerp(sphereIt, other.sphereIt, t)!,
      sphereLogistics:
          Color.lerp(sphereLogistics, other.sphereLogistics, t)!,
    );
  }
}

/// Spacing-шкала по ритму 4/8 dp.
abstract final class AppSpacing {
  /// 4 dp.
  static const double xxs = 4;

  /// 8 dp.
  static const double xs = 8;

  /// 12 dp.
  static const double sm = 12;

  /// 16 dp.
  static const double md = 16;

  /// 24 dp.
  static const double lg = 24;

  /// 32 dp.
  static const double xl = 32;

  /// 48 dp.
  static const double xxl = 48;

  /// Стандартные отступы экрана.
  static const EdgeInsets screen = EdgeInsets.all(md);

  /// Вертикальный отступ между карточками.
  static const double cardGap = md;
}

/// Radius-шкала: карточки 16–20, кнопки/поля 12–16, чипы — pill.
abstract final class AppRadius {
  /// Скругление карточек.
  static const double card = 20;

  /// Скругление кнопок.
  static const double button = 14;

  /// Скругление полей ввода.
  static const double field = 14;

  /// Pill-скругление чипов.
  static const double chip = 999;

  /// [BorderRadius] карточек.
  static const BorderRadius cardRadius = BorderRadius.all(Radius.circular(card));

  /// [BorderRadius] кнопок.
  static const BorderRadius buttonRadius =
      BorderRadius.all(Radius.circular(button));

  /// [BorderRadius] полей ввода.
  static const BorderRadius fieldRadius =
      BorderRadius.all(Radius.circular(field));

  /// [BorderRadius] чипов (pill).
  static const BorderRadius chipRadius = BorderRadius.all(Radius.circular(chip));
}

/// Elevation-шкала.
abstract final class AppElevation {
  /// Без тени.
  static const double none = 0;

  /// Лёгкая тень (карточки по умолчанию).
  static const double low = 1;

  /// Средняя тень (акцентные поверхности).
  static const double medium = 3;

  /// Высокая тень (модальные поверхности).
  static const double high = 8;
}
