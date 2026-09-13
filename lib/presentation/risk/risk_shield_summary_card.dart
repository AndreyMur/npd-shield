import 'package:flutter/material.dart';

import '../../data/models/risk_marker.dart';
import 'risk_match_card.dart';
import 'safety_index_gauge.dart';

/// Карточка результатов Risk Shield для договора, созданного в генераторе.
///
/// Показывает индекс безопасности, число найденных рисков, дисклеймер и
/// найденные формулировки с безопасными альтернативами, которые можно
/// скопировать до сохранения договора.
class RiskShieldSummaryCard extends StatelessWidget {
  /// Отчёт автопроверки созданного договора.
  final RiskReport report;

  const RiskShieldSummaryCard({super.key, required this.report});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final risks = report.risks;
    final percent = report.safetyIndex.clamp(0, 100).round();
    final color = safetyIndexColor(percent.toDouble());

    return Card(
      key: const Key('risk_contract_card'),
      color: theme.colorScheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.shield_outlined, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Risk Shield',
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                Text(
                  '$percent%',
                  key: const Key('risk_contract_index'),
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              risks.isEmpty
                  ? 'Опасных формулировок не найдено'
                  : 'Найдено рисков: ${risks.length}',
              key: const Key('risk_contract_summary'),
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Risk Shield — вспомогательный инструмент и не заменяет '
              'юридическую консультацию. Исправьте опасные формулировки '
              'перед сохранением договора.',
              key: const Key('risk_contract_disclaimer'),
              style: theme.textTheme.bodySmall,
            ),
            if (risks.isNotEmpty) ...[
              const SizedBox(height: 12),
              for (final risk in risks) ...[
                RiskMatchCard(match: risk),
                const SizedBox(height: 8),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
