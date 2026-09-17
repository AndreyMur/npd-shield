import 'package:flutter/material.dart';

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
    return Card(
      key: const Key('report_period_selector'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Период отчёта', style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final value in ReportPeriodPreset.values)
                  ChoiceChip(
                    key: Key('report_period_${value.name}'),
                    label: Text(value.label),
                    selected: preset == value,
                    onSelected: (_) => onPresetSelected(value),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.event_outlined,
                  size: 18,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
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
      ),
    );
  }
}
