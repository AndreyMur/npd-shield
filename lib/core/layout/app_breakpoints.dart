import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';

/// Размер окна приложения по ширине.
enum AppWindowSize {
  /// Узкий телефон (до 600 dp).
  compact,

  /// Крупный телефон / планшет в портрете (600–900 dp).
  medium,

  /// Планшет в ландшафте и десктоп (от 900 dp).
  expanded,
}

/// Breakpoint-ы адаптивной вёрстки.
///
/// Единая точка правды для адаптива: от неё зависят gutters, выбор нижней или
/// боковой навигации и ограничение ширины контента. Desktop-режим наследует ту
/// же систему, что и мобильный.
abstract final class AppBreakpoints {
  /// Граница компактного и среднего окна.
  static const double compact = 600;

  /// Граница среднего и расширенного окна (текущий desktop-breakpoint).
  static const double medium = 900;

  /// Максимальная ширина контента на широких экранах.
  static const double maxContentWidth = 1200;

  /// Размер окна для текущего [BuildContext].
  static AppWindowSize of(BuildContext context) =>
      fromWidth(MediaQuery.sizeOf(context).width);

  /// Размер окна по ширине.
  static AppWindowSize fromWidth(double width) {
    if (width < compact) return AppWindowSize.compact;
    if (width < medium) return AppWindowSize.medium;
    return AppWindowSize.expanded;
  }

  /// Нужна ли боковая навигация вместо нижней панели.
  ///
  /// Боковая навигация включается на широких экранах и в ландшафте телефона,
  /// где по горизонтали больше места, чем по вертикали.
  static bool useRail({required double width, required double height}) {
    if (width >= medium) return true;
    return width > height && width >= compact;
  }

  /// Адаптивные горизонтальные отступы (gutters) по ширине окна.
  static double horizontalGutter(double width) {
    if (width < compact) return AppSpacing.md;
    if (width < medium) return AppSpacing.lg;
    return AppSpacing.xl;
  }

  /// Адаптивные вертикальные отступы (gutters) по ширине окна.
  static double verticalGutter(double width) =>
      width < compact ? AppSpacing.md : AppSpacing.lg;

  /// [EdgeInsets] экрана с адаптивными gutters.
  static EdgeInsets screenPadding(double width) => EdgeInsets.symmetric(
    horizontal: horizontalGutter(width),
    vertical: verticalGutter(width),
  );
}

/// Ограничивает ширину контента и добавляет адаптивные gutters.
///
/// На телефоне даёт базовые отступы, на планшете и десктопе — более широкие
/// поля и центрирование с ограничением [maxWidth], чтобы строки не растягивались
/// на всю ширину монитора.
class AppAdaptiveContent extends StatelessWidget {
  final Widget child;

  /// Максимальная ширина контента.
  final double maxWidth;

  /// Дополнительные внутренние отступы (например, под app bar).
  final EdgeInsetsGeometry? padding;

  /// Центрировать ли контент на широких экранах.
  final bool center;

  const AppAdaptiveContent({
    super.key,
    required this.child,
    this.maxWidth = AppBreakpoints.maxContentWidth,
    this.padding,
    this.center = true,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final horizontal = AppBreakpoints.horizontalGutter(width);
    final effectivePadding =
        padding ?? EdgeInsets.symmetric(horizontal: horizontal);

    Widget content = Padding(padding: effectivePadding, child: child);
    content = ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: content,
    );
    return center ? Center(child: content) : content;
  }
}
