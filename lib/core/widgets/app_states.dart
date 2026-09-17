import 'package:flutter/material.dart';

import '../theme/app_motion.dart';
import '../theme/app_tokens.dart';
import 'app_button.dart';
import 'app_card.dart';

/// Эффект shimmer для skeleton-загрузки.
///
/// При включённом reduced-motion анимация отключается и остаётся статичный
/// skeleton.
class Shimmer extends StatefulWidget {
  final Widget child;

  const Shimmer({super.key, required this.child});

  @override
  State<Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<Shimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = AppTokens.of(context);
    if (AppMotion.reduced(context)) return widget.child;

    final base = tokens.surfaceVariant;
    final highlight = Color.lerp(base, tokens.surface, 0.7)!;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) => LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [base, highlight, base],
            stops: const [0.1, 0.3, 0.4],
            transform: _SlidingGradientTransform(_controller.value),
          ).createShader(bounds),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

class _SlidingGradientTransform extends GradientTransform {
  const _SlidingGradientTransform(this.slidePercent);

  final double slidePercent;

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(bounds.width * (slidePercent * 2 - 1), 0, 0);
  }
}

/// Плейсхолдер-строка skeleton-загрузки.
class SkeletonBox extends StatelessWidget {
  final double? width;
  final double height;
  final BorderRadius borderRadius;

  const SkeletonBox({
    super.key,
    this.width,
    this.height = 16,
    this.borderRadius = const BorderRadius.all(Radius.circular(8)),
  });

  @override
  Widget build(BuildContext context) {
    final tokens = AppTokens.of(context);
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: tokens.surfaceVariant,
        borderRadius: borderRadius,
      ),
    );
  }
}

/// Единое состояние загрузки: список skeleton-карточек с shimmer.
class AppLoadingState extends StatelessWidget {
  final int itemCount;
  final String semanticLabel;

  const AppLoadingState({
    super.key,
    this.itemCount = 4,
    this.semanticLabel = 'Загрузка',
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      liveRegion: true,
      child: Shimmer(
        child: Padding(
          key: const Key('app_loading_state'),
          padding: AppSpacing.screen,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var index = 0; index < itemCount; index++) ...[
                if (index > 0) const SizedBox(height: AppSpacing.sm),
                const AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SkeletonBox(width: 120, height: 14),
                      SizedBox(height: AppSpacing.sm),
                      SkeletonBox(width: double.infinity, height: 20),
                      SizedBox(height: AppSpacing.xs),
                      SkeletonBox(width: 180, height: 14),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Единое пустое состояние.
class AppEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? message;
  final Widget? action;

  /// Компактный вариант для встраивания в секции.
  final bool compact;

  const AppEmptyState({
    super.key,
    this.icon = Icons.inbox_outlined,
    required this.title,
    this.message,
    this.action,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = AppTokens.of(context);
    return Center(
      child: Padding(
        padding: EdgeInsets.all(compact ? AppSpacing.md : AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: compact ? AppSpacing.lg : AppSpacing.xxl,
              color: tokens.muted,
            ),
            SizedBox(height: compact ? AppSpacing.xs : AppSpacing.md),
            Text(
              title,
              textAlign: TextAlign.center,
              style: compact
                  ? theme.textTheme.bodyMedium
                  : theme.textTheme.titleMedium,
            ),
            if (message != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: tokens.muted,
                ),
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: AppSpacing.lg),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

/// Единое состояние ошибки с кнопкой повтора.
class AppErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  /// Ключ кнопки повтора (сохраняется для тестов).
  final Key? retryKey;

  const AppErrorState({
    super.key,
    this.message = 'Не удалось загрузить данные',
    required this.onRetry,
    this.retryKey,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = AppTokens.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off_outlined,
              size: AppSpacing.xxl,
              color: tokens.destructive,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.lg),
            AppButton(
              key: retryKey,
              label: 'Повторить',
              icon: Icons.refresh,
              variant: AppButtonVariant.secondary,
              onPressed: onRetry,
            ),
          ],
        ),
      ),
    );
  }
}
