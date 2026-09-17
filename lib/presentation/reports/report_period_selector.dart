import 'package:flutter/material.dart';

import '../../core/theme/app_tokens.dart';
import '../../core/widgets/widgets.dart';
import 'report_period.dart';

/// Выбор периода отчёта: предустановки (месяц, квартал, год) и произвольный
/// диапазон дат.
class ReportPeriodSelector extends StatelessWidget {
  /// Активная предустановка.
  final ReportPeriodPreset preset;

  /// Текущий выбранный период.
  final ReportPeriod period;

  /// Выбор предустановки или переход к произвольному периоду.
  final ValueChanged<ReportPeriodPreset> onPresetSelected;

  const ReportPeriodSelector({
    super.key,
    required this.preset,
    required this.period,
    required this.onPresetSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = AppTokens.of(context);
    return AppCard(
      key: const Key('report_period_selector'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Период отчёта', style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              for (final value in ReportPeriodPreset.values)
                AppFilterChip(
                  key: Key('report_period_${value.name}'),
                  label: value.label,
                  selected: preset == value,
                  onSelected: () => onPresetSelected(value),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Icon(
                Icons.event_outlined,
                size: 18,
                color: tokens.muted,
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  period.label,
                  key: const Key('report_period_label'),
                  style: theme.textTheme.bodyLarge,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
