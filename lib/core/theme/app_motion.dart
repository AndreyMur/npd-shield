import 'package:flutter/material.dart';

/// Motion-токены дизайн-системы.
///
/// Длительности укладываются в диапазон 150–300 мс (переходы) и 80–150 мс
/// (микро-взаимодействия). При включённом reduced-motion длительность
/// сводится к нулю, чтобы анимации отключались.
abstract final class AppMotion {
  /// Микро-взаимодействия (нажатия, переключения).
  static const Duration fast = Duration(milliseconds: 120);

  /// Стандартные переходы и появление контента.
  static const Duration normal = Duration(milliseconds: 220);

  /// Крупные переходы между разделами.
  static const Duration slow = Duration(milliseconds: 300);

  /// Кривая входа (ease-out).
  static const Curve enter = Curves.easeOutCubic;

  /// Кривая выхода (ease-in).
  static const Curve exit = Curves.easeInCubic;

  /// Нейтральная кривая для микро-взаимодействий.
  static const Curve standard = Curves.easeInOut;

  /// Включён ли режим сниженной анимации.
  static bool reduced(BuildContext context) =>
      MediaQuery.maybeOf(context)?.disableAnimations ?? false;

  /// Возвращает [base] или [Duration.zero] при reduced-motion.
  static Duration duration(BuildContext context, Duration base) =>
      reduced(context) ? Duration.zero : base;
}
