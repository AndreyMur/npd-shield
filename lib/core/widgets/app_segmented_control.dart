import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';

/// Опция сегмент-контрола дизайн-системы.
@immutable
class AppSegmentOption<T> {
  /// Значение, возвращаемое при выборе сегмента.
  final T value;

  /// Подпись сегмента.
  final String label;

  /// Необязательная иконка сегмента.
  final IconData? icon;

  /// Акцент выбранного сегмента (например, цвет сферы деятельности).
  final Color? accent;

  const AppSegmentOption({
    required this.value,
    required this.label,
    this.icon,
    this.accent,
  });
}

/// Сегмент-контрол дизайн-системы.
///
/// Поддерживает акцентные цвета для отдельных сегментов (в том числе цвета
/// сфер IT/Логистика). Каждый сегмент имеет touch-target не меньше 48 dp,
/// выбранное состояние кодируется фоном, цветом, иконкой и текстом, а также
/// semantic-меткой для скринридеров.
class AppSegmentedControl<T> extends StatelessWidget {
  /// Сегменты контрола.
  final List<AppSegmentOption<T>> segments;

  /// Текущее выбранное значение.
  final T selected;

  /// Вызывается при выборе сегмента.
  final ValueChanged<T> onChanged;

  /// Общая semantic-метка группы сегментов.
  final String? semanticLabel;

  const AppSegmentedControl({
    super.key,
    required this.segments,
    required this.selected,
    required this.onChanged,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = AppTokens.of(context);
    return Semantics(
      label: semanticLabel,
      container: true,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.xxs),
        decoration: BoxDecoration(
          color: tokens.surfaceVariant,
          borderRadius: AppRadius.buttonRadius,
          border: Border.all(color: tokens.border),
        ),
        child: Row(
          children: [
            for (final segment in segments)
              Expanded(
                child: _Segment<T>(
                  segment: segment,
                  selected: segment.value == selected,
                  onTap: () => onChanged(segment.value),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Segment<T> extends StatelessWidget {
  final AppSegmentOption<T> segment;
  final bool selected;
  final VoidCallback onTap;

  const _Segment({
    required this.segment,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = AppTokens.of(context);
    final accent = segment.accent ?? tokens.primary;
    final foreground = selected ? accent : tokens.muted;

    return Semantics(
      button: true,
      selected: selected,
      label: segment.label,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: AppSpacing.xxl),
        child: Material(
          color: selected
              ? accent.withValues(alpha: 0.14)
              : tokens.surfaceVariant.withValues(alpha: 0),
          borderRadius: AppRadius.buttonRadius,
          child: InkWell(
            onTap: onTap,
            borderRadius: AppRadius.buttonRadius,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (segment.icon != null) ...[
                    Icon(segment.icon, size: 18, color: foreground),
                    const SizedBox(width: AppSpacing.xxs),
                  ],
                  Flexible(
                    child: Text(
                      segment.label,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: foreground,
                        fontWeight: selected
                            ? FontWeight.w600
                            : FontWeight.w500,
                      ),
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
