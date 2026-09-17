import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';

/// Тип статусного баннера.
enum StatusBannerType { info, success, warning, danger }

/// Статусный баннер: info, success, warning, danger.
///
/// Использует семантические токены и не зависит от Dynamic Color, поэтому
/// предупреждения и ошибки выглядят одинаково предсказуемо.
class StatusBanner extends StatelessWidget {
  final StatusBannerType type;
  final String message;
  final IconData? icon;
  final Widget? action;

  const StatusBanner({
    super.key,
    required this.type,
    required this.message,
    this.icon,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = AppTokens.of(context);
    final (Color color, IconData defaultIcon) = switch (type) {
      StatusBannerType.info => (tokens.secondary, Icons.info_outline),
      StatusBannerType.success => (tokens.success, Icons.check_circle_outline),
      StatusBannerType.warning => (
        tokens.warning,
        Icons.warning_amber_rounded,
      ),
      StatusBannerType.danger => (tokens.destructive, Icons.error_outline),
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: AppRadius.buttonRadius,
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon ?? defaultIcon, size: 18, color: color),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodySmall?.copyWith(color: color),
            ),
          ),
          if (action != null) ...[
            const SizedBox(width: AppSpacing.xs),
            action!,
          ],
        ],
      ),
    );
  }
}
