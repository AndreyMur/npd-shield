import 'package:flutter/material.dart';

import '../theme/app_motion.dart';
import '../theme/app_tokens.dart';

/// Варианты кнопок дизайн-системы.
enum AppButtonVariant {
  /// Основная кнопка с фирменным градиентом.
  primary,

  /// Второстепенная кнопка с контуром.
  secondary,

  /// Текстовая кнопка без фона.
  text,

  /// Кнопка опасного действия.
  destructive,
}

/// Кнопка дизайн-системы.
///
/// Поддерживает варианты [AppButtonVariant], иконку, состояние загрузки и
/// явный pressed-state. Минимальная высота — 48 dp, чтобы соответствовать
/// требованию touch-target.
class AppButton extends StatefulWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final bool loading;
  final bool expanded;
  final EdgeInsetsGeometry? padding;

  /// Узел фокуса. Позволяет управлять фокусом и проверять focus-состояние.
  final FocusNode? focusNode;

  const AppButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.loading = false,
    this.expanded = false,
    this.padding,
    this.focusNode,
  });

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> {
  bool _pressed = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final tokens = AppTokens.of(context);
    final enabled = widget.onPressed != null && !widget.loading;
    final scale = _pressed && enabled ? 0.97 : 1.0;

    final content = _content();

    if (widget.variant == AppButtonVariant.text) {
      return TextButton(
        onPressed: enabled ? widget.onPressed : null,
        focusNode: widget.focusNode,
        child: content,
      );
    }

    final (BoxDecoration decoration, Color foreground) = switch (widget.variant) {
      AppButtonVariant.primary => (
        BoxDecoration(
          gradient: enabled ? tokens.brandGradient : null,
          color: enabled ? null : tokens.surfaceVariant,
          borderRadius: AppRadius.buttonRadius,
        ),
        enabled ? tokens.onPrimary : tokens.muted,
      ),
      AppButtonVariant.destructive => (
        BoxDecoration(
          color: enabled ? tokens.destructive : tokens.surfaceVariant,
          borderRadius: AppRadius.buttonRadius,
        ),
        enabled ? tokens.onDestructive : tokens.muted,
      ),
      AppButtonVariant.secondary => (
        BoxDecoration(
          color: tokens.surface,
          border: Border.all(color: enabled ? tokens.primary : tokens.border),
          borderRadius: AppRadius.buttonRadius,
        ),
        enabled ? tokens.primary : tokens.muted,
      ),
      AppButtonVariant.text => (
        const BoxDecoration(),
        enabled ? tokens.primary : tokens.muted,
      ),
    };

    Widget button = Material(
      color: Colors.transparent,
      child: Ink(
        decoration: decoration,
        child: InkWell(
          onTap: enabled ? widget.onPressed : null,
          focusNode: widget.focusNode,
          borderRadius: AppRadius.buttonRadius,
          onHighlightChanged: (value) => setState(() => _pressed = value),
          onFocusChange: (value) => setState(() => _focused = value),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: AppSpacing.xxl),
            child: Padding(
              padding: widget.padding ??
                  const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.sm,
                  ),
              child: Align(
                alignment: Alignment.center,
                widthFactor: widget.expanded ? null : 1,
                heightFactor: 1,
                child: DefaultTextStyle.merge(
                  style: TextStyle(
                    color: foreground,
                    fontWeight: FontWeight.w600,
                  ),
                  child: IconTheme.merge(
                    data: IconThemeData(color: foreground, size: 18),
                    child: content,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    // Фокус-кольцо рисуется поверх и не влияет на layout (без сдвига).
    button = DecoratedBox(
      position: DecorationPosition.foreground,
      decoration: BoxDecoration(
        borderRadius: AppRadius.buttonRadius,
        border: Border.all(
          color: _focused ? tokens.primary : tokens.primary.withValues(alpha: 0),
          width: 2,
        ),
      ),
      child: button,
    );

    button = AnimatedScale(
      scale: scale,
      duration: AppMotion.duration(context, AppMotion.fast),
      curve: AppMotion.standard,
      child: button,
    );

    if (widget.expanded) {
      button = SizedBox(width: double.infinity, child: button);
    }
    return button;
  }

  Widget _content() {
    if (widget.loading) {
      return const SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }
    final icon = widget.icon;
    if (icon == null) return Text(widget.label);
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon),
        const SizedBox(width: AppSpacing.xs),
        Text(widget.label),
      ],
    );
  }
}
