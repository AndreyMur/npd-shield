import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_tokens.dart';
import '../../domain/risk/safety_index.dart';
import 'risk_visuals.dart';

/// Круговая диаграмма индекса безопасности с процентом, цветовой шкалой и
/// текстовой меткой зоны.
///
/// Цвет не является единственным способом передачи уровня: рядом с диаграммой
/// выводятся иконка и текстовая метка зоны, а также трёхзонная шкала с
/// маркером текущего значения. Диаграмма помечена [Semantics]-меткой для
/// скринридеров.
class SafetyIndexGauge extends StatelessWidget {
  /// Индекс безопасности в диапазоне 0–100.
  final double index;

  const SafetyIndexGauge({super.key, required this.index});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = AppTokens.of(context);
    final clamped = index.clamp(0, 100).toDouble();
    final level = SafetyIndexCalculator.levelFor(clamped);
    final color = level.color(tokens);
    final percent = clamped.round();

    return Semantics(
      key: const Key('safety_index_gauge'),
      container: true,
      label: 'Индекс безопасности: $percent процентов. ${level.label}.',
      child: ExcludeSemantics(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 150,
              height: 150,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  PieChart(
                    PieChartData(
                      startDegreeOffset: -90,
                      sectionsSpace: 0,
                      centerSpaceRadius: 54,
                      sections: [
                        PieChartSectionData(
                          value: clamped == 0 ? 0.0001 : clamped,
                          color: color,
                          radius: 18,
                          showTitle: false,
                        ),
                        PieChartSectionData(
                          value: (100 - clamped) == 0 ? 0.0001 : 100 - clamped,
                          color: tokens.surfaceVariant,
                          radius: 18,
                          showTitle: false,
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '$percent%',
                    key: const Key('safety_index_percent'),
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            _SafetyScale(index: clamped, tokens: tokens),
            const SizedBox(height: AppSpacing.xs),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(level.icon, size: 18, color: color),
                const SizedBox(width: AppSpacing.xxs),
                Text(
                  level.label,
                  key: const Key('safety_index_level'),
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            Text(
              'Индекс безопасности',
              style: theme.textTheme.bodySmall?.copyWith(color: tokens.muted),
            ),
          ],
        ),
      ),
    );
  }
}

/// Трёхзонная шкала индекса (риск → внимание → безопасно) с маркером.
class _SafetyScale extends StatelessWidget {
  final double index;
  final AppTokens tokens;

  const _SafetyScale({required this.index, required this.tokens});

  @override
  Widget build(BuildContext context) {
    final fraction = (index / 100).clamp(0, 1).toDouble();
    return SizedBox(
      key: const Key('safety_index_scale'),
      width: 220,
      height: 16,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.xxs),
            child: Row(
              children: [
                Expanded(
                  child: Container(height: 8, color: tokens.destructive),
                ),
                Expanded(
                  child: Container(height: 8, color: tokens.warning),
                ),
                Expanded(
                  child: Container(height: 8, color: tokens.success),
                ),
              ],
            ),
          ),
          Align(
            alignment: Alignment(fraction * 2 - 1, 0),
            child: Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: tokens.surface,
                shape: BoxShape.circle,
                border: Border.all(color: tokens.onSurface, width: 2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
