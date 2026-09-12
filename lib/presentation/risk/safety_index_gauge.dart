import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../domain/risk/safety_index.dart';

/// Цвет индекса безопасности по его цветовой зоне.
Color safetyIndexColor(double index) =>
    switch (SafetyIndexCalculator.levelFor(index)) {
      SafetyLevel.green => const Color(0xFF2E7D32),
      SafetyLevel.yellow => const Color(0xFFF9A825),
      SafetyLevel.red => const Color(0xFFD32F2F),
    };

/// Круговая диаграмма индекса безопасности с процентом и цветовой шкалой.
///
/// Цвет не является единственным способом передачи уровня: рядом с диаграммой
/// выводится текстовая метка зоны, а сама диаграмма помечена [Semantics]-меткой
/// для скринридеров.
class SafetyIndexGauge extends StatelessWidget {
  /// Индекс безопасности в диапазоне 0–100.
  final double index;

  const SafetyIndexGauge({super.key, required this.index});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final clamped = index.clamp(0, 100).toDouble();
    final color = safetyIndexColor(clamped);
    final level = SafetyIndexCalculator.levelFor(clamped);
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
                          color: theme.colorScheme.surfaceContainerHighest,
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
            const SizedBox(height: 8),
            Text(
              level.label,
              key: const Key('safety_index_level'),
              style: theme.textTheme.titleMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text('Индекс безопасности', style: theme.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
