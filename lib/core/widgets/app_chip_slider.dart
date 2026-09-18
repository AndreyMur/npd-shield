import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';
import 'app_segmented_control.dart';

/// Горизонтально прокручиваемый ряд компактных чипов-фильтров.
///
/// Применяется на узких экранах, где обычный сегмент-контрол не помещается
/// целиком. Чипы не сжимаются по ширине, поэтому при нехватке места ряд
/// прокручивается по горизонтали, а край следующего чипа остаётся видимым —
/// это служит признаком прокручиваемости.
///
/// Активный чип выделен акцентным цветом ([AppSegmentOption.accent] или
/// [AppTokens.primary]), неактивные — нейтральные. Каждый чип имеет
/// touch-target не меньше 48 dp и semantic-метку для скринридеров.
class AppChipSlider<T> extends StatelessWidget {
  /// Варианты фильтра.
  final List<AppSegmentOption<T>> options;

  /// Текущее выбранное значение.
  final T selected;

  /// Вызывается при выборе чипа.
  final ValueChanged<T> onChanged;

  /// Общая semantic-метка группы чипов.
  final String? semanticLabel;

  const AppChipSlider({
    super.key,
    required this.options,
    required this.selected,
    required this.onChanged,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      container: true,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        child: Row(
          children: [
            for (var i = 0; i < options.length; i++) ...[
              if (i > 0) const SizedBox(width: AppSpacing.xs),
              _Chip<T>(
                option: options[i],
                selected: options[i].value == selected,
                onTap: () => onChanged(options[i].value),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Chip<T> extends StatelessWidget {
  final AppSegmentOption<T> option;
  final bool selected;
  final VoidCallback onTap;

  const _Chip({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = AppTokens.of(context);
    final accent = option.accent ?? tokens.primary;
    final foreground = selected ? accent : tokens.muted;
    final background =
        selected ? accent.withValues(alpha: 0.14) : tokens.surfaceVariant;
    final borderColor =
        selected ? accent.withValues(alpha: 0.5) : tokens.border;

    return Semantics(
      button: true,
      selected: selected,
      label: option.label,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: AppSpacing.xxl),
        child: Material(
          color: background,
          shape: StadiumBorder(side: BorderSide(color: borderColor)),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            customBorder: const StadiumBorder(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (option.icon != null) ...[
                    Icon(option.icon, size: 18, color: foreground),
                    const SizedBox(width: AppSpacing.xxs),
                  ],
                  Text(
                    option.label,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: foreground,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
