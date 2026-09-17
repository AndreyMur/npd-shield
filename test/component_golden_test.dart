@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:npd_shield/core/theme/app_theme.dart';
import 'package:npd_shield/core/theme/app_tokens.dart';
import 'package:npd_shield/core/widgets/widgets.dart';

/// Галерея компонентов дизайн-системы для golden-снимков.
///
/// Golden-тесты платформозависимы (растеризация текста и теней отличается
/// между ОС), поэтому по умолчанию они пропускаются в CI — см. dart_test.yaml.
/// Локально запускаются через:
///   flutter test --run-skipped --tags golden --update-goldens
class _Gallery extends StatelessWidget {
  const _Gallery();

  @override
  Widget build(BuildContext context) {
    final tokens = AppTokens.of(context);
    return SizedBox(
      width: 360,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AppCard(child: Text('Обычная карточка')),
          const SizedBox(height: AppSpacing.sm),
          const AppGradientCard(child: Text('Акцентная карточка')),
          const SizedBox(height: AppSpacing.sm),
          AppMetricCard(
            label: 'Доход',
            value: '120 000,00 ₽',
            accent: tokens.success,
            icon: Icons.trending_up,
          ),
          const SizedBox(height: AppSpacing.md),
          AppButton(label: 'Основная', onPressed: () {}),
          const SizedBox(height: AppSpacing.xs),
          AppButton(
            label: 'Вторичная',
            variant: AppButtonVariant.secondary,
            onPressed: () {},
          ),
          const SizedBox(height: AppSpacing.xs),
          AppButton(
            label: 'Удалить',
            variant: AppButtonVariant.destructive,
            onPressed: () {},
          ),
          const SizedBox(height: AppSpacing.md),
          const AppTextField(
            label: 'Сумма',
            hint: 'Например, 15000',
            helper: 'В рублях',
          ),
          const SizedBox(height: AppSpacing.sm),
          const AppTextField(
            label: 'Сумма',
            errorText: 'Некорректная сумма',
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              AppFilterChip(
                label: 'IT',
                selected: true,
                accent: tokens.sphereIt,
                onSelected: () {},
              ),
              const SizedBox(width: AppSpacing.xs),
              AppFilterChip(
                label: 'Логистика',
                selected: false,
                onSelected: () {},
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          AppStatusChip(
            label: 'Подписан',
            color: tokens.success,
            icon: Icons.verified_outlined,
          ),
          const SizedBox(height: AppSpacing.md),
          AppSegmentedControl<String>(
            selected: 'it',
            onChanged: (_) {},
            segments: [
              AppSegmentOption(
                value: 'it',
                label: 'IT',
                icon: Icons.code,
                accent: tokens.sphereIt,
              ),
              AppSegmentOption(
                value: 'logistics',
                label: 'Логистика',
                icon: Icons.local_shipping,
                accent: tokens.sphereLogistics,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          const StatusBanner(
            type: StatusBannerType.info,
            message: 'Информация',
          ),
          const SizedBox(height: AppSpacing.xs),
          const StatusBanner(
            type: StatusBannerType.success,
            message: 'Успех',
          ),
          const SizedBox(height: AppSpacing.xs),
          const StatusBanner(
            type: StatusBannerType.warning,
            message: 'Предупреждение',
          ),
          const SizedBox(height: AppSpacing.xs),
          const StatusBanner(
            type: StatusBannerType.danger,
            message: 'Ошибка',
          ),
        ],
      ),
    );
  }
}

void main() {
  for (final entry in {
    'light': AppTheme.light(null),
    'dark': AppTheme.dark(null),
  }.entries) {
    testWidgets('галерея компонентов: ${entry.key} тема', (tester) async {
      tester.view.physicalSize = const Size(400, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(
          theme: entry.value,
          home: const Scaffold(
            body: Center(
              child: RepaintBoundary(child: _Gallery()),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(_Gallery),
        matchesGoldenFile('goldens/components_${entry.key}.png'),
      );
    });
  }
}
