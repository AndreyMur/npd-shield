import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';

/// Чип-фильтр дизайн-системы.
///
/// Опциональный [accent] окрашивает выбранное состояние (например, цветом
/// сферы деятельности). Всегда имеет touch-target не меньше 48 dp.
class AppFilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onSelected;
  final Color? accent;
  final IconData? icon;

  const AppFilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onSelected,
    this.accent,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = AppTokens.of(context);
    final theme = Theme.of(context);
    final color = accent ?? tokens.primary;
    final foreground = selected ? color : tokens.muted;

    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: AppSpacing.xxl),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onSelected(),
        avatar: icon == null
            ? null
            : Icon(
                icon,
                size: 18,
                color: selected ? color : tokens.muted,
              ),
        showCheckmark: false,
        selectedColor: color.withValues(alpha: 0.14),
        backgroundColor: tokens.surfaceVariant,
        side: BorderSide(
          color: selected ? color.withValues(alpha: 0.5) : tokens.border,
        ),
        labelStyle: theme.textTheme.labelLarge?.copyWith(
          color: foreground,
          fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
        ),
        shape: const StadiumBorder(),
      ),
    );
  }
}

/// Компактная цветная метка статуса.
class AppStatusChip extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;

  const AppStatusChip({
    super.key,
    required this.label,
    required this.color,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: AppRadius.chipRadius,
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
