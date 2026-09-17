import 'package:flutter/material.dart';

/// Длительности motion-языка.
///
/// Переходы между экранами и разделами укладываются в 150–300 мс, отклик
/// микро-взаимодействий — в 80–150 мс. Значения используются через
/// [AppMotion.resolve], чтобы флаг reduced-motion сводил анимацию к нулю.
abstract final class AppMotionDurations {
  /// Мгновенный переход (reduced-motion).
  static const instant = Duration.zero;

  /// Отклик микро-взаимодействий (нажатие, переключение) — 100 мс.
  static const micro = Duration(milliseconds: 100);

  /// Быстрый вход (появление, fade) — 150 мс.
  static const quick = Duration(milliseconds: 150);

  /// Стандартный переход между состояниями — 220 мс.
  static const medium = Duration(milliseconds: 220);

  /// Полный переход между экранами — 300 мс.
  static const slow = Duration(milliseconds: 300);
}

/// Кривые motion-языка.
///
/// На входе — ease-out (быстрый старт, мягкое торможение), на выходе —
/// ease-in, для смены состояний — ease-in-out.
abstract final class AppMotionCurves {
  /// Появление элемента.
  static const enter = Curves.easeOut;

  /// Исчезновение элемента.
  static const exit = Curves.easeIn;

  /// Смена состояния без входа/выхода.
  static const standard = Curves.easeInOut;

  /// Подчёркнутый вход для акцентных элементов.
  static const emphasized = Curves.easeOutCubic;
}

/// Motion-токены дизайн-системы.
///
/// Хелперы с уважением к reduced-motion: при включённом флаге все длительности
/// сводятся к [AppMotionDurations.instant], то есть анимации отключаются.
/// Алиасы [fast], [normal], [slow], [enter], [exit], [standard] и [duration]
/// сохранены для компонентов дизайн-системы.
abstract final class AppMotion {
  /// Нижняя граница длительности перехода.
  static const minTransition = Duration(milliseconds: 150);

  /// Верхняя граница длительности перехода.
  static const maxTransition = Duration(milliseconds: 300);

  /// Нижняя граница отклика микро-взаимодействий.
  static const minMicro = Duration(milliseconds: 80);

  /// Верхняя граница отклика микро-взаимодействий.
  static const maxMicro = Duration(milliseconds: 150);

  /// Микро-взаимодействия (нажатия, переключения).
  static const Duration fast = Duration(milliseconds: 120);

  /// Стандартные переходы и появление контента.
  static const Duration normal = AppMotionDurations.medium;

  /// Крупные переходы между разделами.
  static const Duration slow = AppMotionDurations.slow;

  /// Кривая входа (ease-out).
  static const Curve enter = Curves.easeOutCubic;

  /// Кривая выхода (ease-in).
  static const Curve exit = Curves.easeInCubic;

  /// Нейтральная кривая для микро-взаимодействий.
  static const Curve standard = Curves.easeInOut;

  /// Включён ли режим reduced-motion для текущего контекста.
  static bool reduced(BuildContext context) =>
      MediaQuery.maybeOf(context)?.disableAnimations ?? false;

  /// Возвращает [duration] или мгновенный переход при reduced-motion.
  static Duration resolve(BuildContext context, Duration duration) =>
      effective(reducedMotion: reduced(context), duration: duration);

  /// Чистое правило выбора длительности (без [BuildContext], для тестов).
  static Duration effective({
    required bool reducedMotion,
    required Duration duration,
  }) =>
      reducedMotion ? AppMotionDurations.instant : duration;

  /// Длительность стандартного перехода между состояниями.
  static Duration transition(BuildContext context) =>
      resolve(context, AppMotionDurations.medium);

  /// Длительность отклика микро-взаимодействий.
  static Duration microInteraction(BuildContext context) =>
      resolve(context, AppMotionDurations.micro);

  /// Возвращает [base] или нулевую длительность при reduced-motion.
  static Duration duration(BuildContext context, Duration base) =>
      resolve(context, base);

  /// Кривая входа (ease-out) или линейная при reduced-motion.
  static Curve enterCurve(BuildContext context) =>
      reduced(context) ? Curves.linear : AppMotionCurves.enter;

  /// Кривая выхода (ease-in) или линейная при reduced-motion.
  static Curve exitCurve(BuildContext context) =>
      reduced(context) ? Curves.linear : AppMotionCurves.exit;
}
