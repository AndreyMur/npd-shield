import 'package:flutter/material.dart';

import '../../core/theme/app_tokens.dart';
import '../../core/widgets/widgets.dart';
import '../../data/models/risk_marker.dart';
import '../../domain/risk/safety_index.dart';
import 'risk_match_card.dart';
import 'risk_visuals.dart';

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
    final tokens = AppTokens.of(context);
    final risks = report.risks;
    final percent = report.safetyIndex.clamp(0, 100).round();
    final level = SafetyIndexCalculator.levelFor(percent.toDouble());
    final color = level.color(tokens);

    return AppCard(
      key: const Key('risk_contract_card'),
      semanticLabel:
          'Risk Shield. Индекс безопасности $percent процентов. '
          '${level.label}. '
          '${risks.isEmpty ? 'Опасных формулировок не найдено' : 'Найдено рисков: ${risks.length}'}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.shield_outlined, color: tokens.primary),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  'Risk Shield',
                  style: theme.textTheme.titleMedium,
                ),
              ),
              Icon(level.icon, size: 18, color: color),
              const SizedBox(width: AppSpacing.xxs),
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
          const SizedBox(height: AppSpacing.xxs),
          Text(
            risks.isEmpty
                ? 'Опасных формулировок не найдено'
                : 'Найдено рисков: ${risks.length}',
            key: const Key('risk_contract_summary'),
            style: theme.textTheme.bodyMedium?.copyWith(color: tokens.muted),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Risk Shield — вспомогательный инструмент и не заменяет '
            'юридическую консультацию. Исправьте опасные формулировки '
            'перед сохранением договора.',
            key: const Key('risk_contract_disclaimer'),
            style: theme.textTheme.bodySmall?.copyWith(color: tokens.muted),
          ),
          if (risks.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            for (final risk in risks) ...[
              RiskMatchCard(match: risk),
              const SizedBox(height: AppSpacing.xs),
            ],
          ],
        ],
      ),
    );
  }
}
