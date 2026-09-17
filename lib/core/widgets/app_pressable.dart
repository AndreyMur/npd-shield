import 'package:flutter/material.dart';

import '../theme/app_motion.dart';

/// Обёртка для интерактивных поверхностей с явным pressed-state.
///
/// При нажатии содержимое мягко уменьшается и слегка теряет непрозрачность
/// (80–150 мс). При включённом reduced-motion анимация отключается, а отклик
/// остаётся мгновенным. Опционально добавляет semantic-метку для скринридеров.
class AppPressable extends StatefulWidget {
  final Widget child;

  final VoidCallback? onTap;

  final BorderRadius borderRadius;

  /// Semantic-метка. Если задана, элемент помечается как кнопка.
  final String? semanticLabel;

  /// Дополнительная semantic-подсказка.
  final String? semanticHint;

  const AppPressable({
    super.key,
    required this.child,
    this.onTap,
    this.borderRadius = BorderRadius.zero,
    this.semanticLabel,
    this.semanticHint,
  });

  @override
  State<AppPressable> createState() => _AppPressableState();
}

class _AppPressableState extends State<AppPressable> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    final scale = _pressed && enabled ? 0.98 : 1.0;
    final opacity = _pressed && enabled ? 0.92 : 1.0;

    Widget content = AnimatedScale(
      scale: scale,
      duration: AppMotion.duration(context, AppMotion.fast),
      curve: AppMotion.standard,
      child: AnimatedOpacity(
        opacity: opacity,
        duration: AppMotion.duration(context, AppMotion.fast),
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: widget.borderRadius,
          onHighlightChanged: (value) => setState(() => _pressed = value),
          child: widget.child,
        ),
      ),
    );

    final label = widget.semanticLabel;
    if (label != null) {
      content = Semantics(
        button: enabled,
        label: label,
        hint: widget.semanticHint,
        child: content,
      );
    }
    return content;
  }
}
