import 'package:flutter/material.dart';

import 'app_tokens.dart';

/// Размеры иконок дизайн-системы.
///
/// Единый набор размеров вместо произвольных значений на экранах. Для
/// интерактивных иконок минимальная зона нажатия — [touchTarget].
abstract final class AppIconSize {
  /// Вспомогательная иконка (16 dp).
  static const xs = 16.0;

  /// Компактная иконка в тексте и чипах (20 dp).
  static const sm = 20.0;

  /// Базовый размер иконок интерфейса (24 dp).
  static const md = 24.0;

  /// Акцентная иконка заголовка (32 dp).
  static const lg = 32.0;

  /// Крупная иллюстративная иконка (40 dp).
  static const xl = 40.0;

  /// Минимальная зона нажатия для интерактивной иконки.
  static const touchTarget = 48.0;
}

/// Семейство иконок.
///
/// Приложение использует единое семейство Material Symbols (в Flutter —
/// `Icons`): `*_outlined` для невыбранного состояния и заполненный вариант
/// для выбранного. Эмодзи как структурные иконки запрещены.
abstract final class AppIcons {
  /// Выбирает заполненный или контурный вариант иконки.
  ///
  /// Используется для навигации и переключателей: выбранное состояние —
  /// filled, невыбранное — outline.
  static IconData toggle(
    IconData outlined,
    IconData filled, {
    required bool selected,
  }) =>
      selected ? filled : outlined;
}

/// Иконка дизайн-системы с токеном размера и цветом из [AppTokens].
///
/// Отрисовка идёт единым семейством и только через размеры [AppIconSize],
/// чтобы на экранах не появлялись произвольные размеры.
class AppIcon extends StatelessWidget {
  /// Иконка из семейства Material Symbols (`Icons`).
  final IconData icon;

  /// Размер из [AppIconSize].
  final double size;

  /// Цвет; по умолчанию — основной цвет текста темы.
  final Color? color;

  /// Семантическая подпись. `null` — иконка декоративная.
  final String? semanticLabel;

  /// Направление текста для зеркальных иконок.
  final TextDirection? textDirection;

  const AppIcon(
    this.icon, {
    super.key,
    this.size = AppIconSize.md,
    this.color,
    this.semanticLabel,
    this.textDirection,
  });

  @override
  Widget build(BuildContext context) {
    return Icon(
      icon,
      size: size,
      color: color ?? AppTokens.of(context).onSurface,
      semanticLabel: semanticLabel,
      textDirection: textDirection,
    );
  }
}
