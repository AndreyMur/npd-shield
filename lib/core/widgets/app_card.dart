import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';
import 'app_pressable.dart';

/// Базовая карточка дизайн-системы.
///
/// Использует токены границ, радиуса и elevation. Поддерживает нажатие с
/// pressed-state и semantic-метку, а также градиентную заливку для акцентных
/// поверхностей.
class AppCard extends StatelessWidget {
  final Widget child;

  /// Внутренние отступы. По умолчанию — [AppSpacing.md] со всех сторон.
  final EdgeInsetsGeometry? padding;

  final VoidCallback? onTap;

  /// Semantic-метка для скринридеров.
  final String? semanticLabel;

  /// Фоновая заливка. Игнорируется при заданном [gradient].
  final Color? color;

  /// Градиентная заливка (акцентная карточка).
  final LinearGradient? gradient;

  /// Цвет границы. По умолчанию — [AppTokens.border].
  final Color? borderColor;

  /// Тень. По умолчанию — [AppElevation.low], для акцентных — medium.
  final double? elevation;

  /// Признак акцентной карточки: усиливает тень.
  final bool accent;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.semanticLabel,
    this.color,
    this.gradient,
    this.borderColor,
    this.elevation,
    this.accent = false,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = AppTokens.of(context);
    final effectivePadding = padding ?? const EdgeInsets.all(AppSpacing.md);

    Widget content = Padding(padding: effectivePadding, child: child);
    if (onTap != null) {
      content = AppPressable(
        onTap: onTap,
        borderRadius: AppRadius.cardRadius,
        semanticLabel: semanticLabel,
        child: content,
      );
    } else if (semanticLabel != null) {
      content = Semantics(label: semanticLabel, child: content);
    }

    if (gradient != null) {
      content = Ink(
        decoration: BoxDecoration(gradient: gradient),
        child: content,
      );
    }

    return Card(
      color: gradient != null ? Colors.transparent : (color ?? tokens.surface),
      elevation: elevation ?? (accent ? AppElevation.medium : AppElevation.low),
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.cardRadius,
        side: BorderSide(color: borderColor ?? tokens.border),
      ),
      child: content,
    );
  }
}

/// Акцентная карточка с фирменным градиентом.
class AppGradientCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final String? semanticLabel;
  final LinearGradient? gradient;

  const AppGradientCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.semanticLabel,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = AppTokens.of(context);
    return AppCard(
      padding: padding,
      onTap: onTap,
      semanticLabel: semanticLabel,
      accent: true,
      gradient: gradient ?? tokens.brandGradient,
      borderColor: Colors.transparent,
      child: DefaultTextStyle.merge(
        style: TextStyle(color: tokens.onPrimary),
        child: IconTheme.merge(
          data: IconThemeData(color: tokens.onPrimary),
          child: child,
        ),
      ),
    );
  }
}

/// Метрическая карточка: подпись и крупное числовое значение.
class AppMetricCard extends StatelessWidget {
  final String label;
  final String value;
  final Color? accent;
  final IconData? icon;
  final String? caption;
  final VoidCallback? onTap;
  final String? semanticLabel;

  const AppMetricCard({
    super.key,
    required this.label,
    required this.value,
    this.accent,
    this.icon,
    this.caption,
    this.onTap,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = AppTokens.of(context);
    final color = accent ?? tokens.primary;

    return AppCard(
      onTap: onTap,
      semanticLabel: semanticLabel ?? '$label: $value',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: color),
                const SizedBox(width: AppSpacing.xs),
              ],
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: tokens.muted,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (caption != null) ...[
            const SizedBox(height: AppSpacing.xxs),
            Text(
              caption!,
              style: theme.textTheme.bodySmall?.copyWith(color: tokens.muted),
            ),
          ],
        ],
      ),
    );
  }
}
