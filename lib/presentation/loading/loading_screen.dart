import 'package:flutter/material.dart';

import '../../core/theme/app_icons.dart';
import '../../core/theme/app_tokens.dart';

/// Экран-заглушка загрузки приложения.
///
/// Показывается, пока не загружено состояние онбординга. Использует фирменный
/// градиент, логотип и прогресс дизайн-системы.
class LoadingScreen extends StatelessWidget {
  const LoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = AppTokens.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(gradient: tokens.brandGradient),
        child: SafeArea(
          child: Semantics(
            key: const Key('app_loading_screen'),
            label: 'Загрузка приложения',
            liveRegion: true,
            child: Column(
              children: [
                const Spacer(),
                Icon(
                  Icons.shield,
                  size: AppIconSize.xl * 2,
                  color: tokens.onPrimary,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'NPD Shield',
                  style: theme.textTheme.headlineLarge?.copyWith(
                    color: tokens.onPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Помощник самозанятого',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: tokens.onPrimary.withValues(alpha: 0.85),
                  ),
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: ExcludeSemantics(
                    child: ClipRRect(
                      borderRadius: AppRadius.buttonRadius,
                      child: const LinearProgressIndicator(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
