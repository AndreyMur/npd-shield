import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_tokens.dart';
import '../../core/widgets/widgets.dart';
import '../../domain/reports/business_report.dart';
import '../../domain/reports/report_format.dart';

/// Столбчатый график дохода и расхода по сферам деятельности.
///
/// Палитра берётся из семантических токенов темы (доход — success, расход —
/// destructive), поэтому график читаем и различим в обеих темах. Легенда и
/// всплывающие подсказки подписаны текстом, а не только цветом.
class ReportSphereChart extends StatelessWidget {
  /// Разбивка показателей по сферам.
  final List<ReportSphereBreakdown> spheres;

  const ReportSphereChart({super.key, required this.spheres});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = AppTokens.of(context);
    return AppCard(
      key: const Key('report_sphere_chart'),
      semanticLabel: 'График дохода и расхода по сферам деятельности',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Доход и расход по сферам', style: theme.textTheme.titleLarge),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              _LegendDot(color: tokens.success, label: 'Доход'),
              const SizedBox(width: AppSpacing.md),
              _LegendDot(color: tokens.destructive, label: 'Расход'),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (spheres.isEmpty)
            Text(
              'За выбранный период операций по сферам нет',
              key: const Key('report_sphere_chart_empty'),
              style: theme.textTheme.bodyMedium?.copyWith(color: tokens.muted),
            )
          else
            SizedBox(height: 220, child: _SphereBarChart(spheres: spheres)),
        ],
      ),
    );
  }
}

class _SphereBarChart extends StatelessWidget {
  final List<ReportSphereBreakdown> spheres;

  const _SphereBarChart({required this.spheres});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = AppTokens.of(context);
    final maxValue = spheres.fold<double>(0, (acc, sphere) {
      final value = sphere.income > sphere.expense
          ? sphere.income
          : sphere.expense;
      return value > acc ? value : acc;
    });
    final step = _niceStep(maxValue);
    final maxY = maxValue == 0 ? step * 4 : (maxValue / step).ceil() * step;
    final axisStyle = theme.textTheme.bodySmall?.copyWith(color: tokens.muted);

    return BarChart(
      BarChartData(
        maxY: maxY,
        barGroups: [
          for (var i = 0; i < spheres.length; i++)
            BarChartGroupData(
              x: i,
              barsSpace: 4,
              barRods: [
                BarChartRodData(
                  toY: spheres[i].income,
                  color: tokens.success,
                  width: 12,
                  borderRadius: BorderRadius.circular(3),
                ),
                BarChartRodData(
                  toY: spheres[i].expense,
                  color: tokens.destructive,
                  width: 12,
                  borderRadius: BorderRadius.circular(3),
                ),
              ],
            ),
        ],
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 52,
              interval: step,
              getTitlesWidget: (value, meta) {
                if (value > maxY) return const SizedBox.shrink();
                return SideTitleWidget(
                  meta: meta,
                  space: 8,
                  child: Text(_formatAxisNumber(value), style: axisStyle),
                );
              },
            ),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (value, meta) {
                final index = value.round();
                if (index < 0 || index >= spheres.length) {
                  return const SizedBox.shrink();
                }
                return SideTitleWidget(
                  meta: meta,
                  space: 8,
                  child: Text(spheres[index].sphere.label, style: axisStyle),
                );
              },
            ),
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: step,
          getDrawingHorizontalLine: (value) => FlLine(
            color: tokens.border,
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (group) => tokens.onSurface,
            getTooltipItem: (group, groupIndex, rod, rodIndex) => BarTooltipItem(
              '${rodIndex == 0 ? 'Доход' : 'Расход'}: '
              '${formatReportMoney(rod.toY)}',
              theme.textTheme.labelMedium!.copyWith(color: tokens.surface),
            ),
          ),
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = AppTokens.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: theme.textTheme.bodyMedium?.copyWith(color: tokens.onSurface)),
      ],
    );
  }
}

double _niceStep(double max) {
  if (max <= 0) return 25;
  final target = max / 4;
  final exp = (log(target) / ln10).floor();
  final base = pow(10, exp).toDouble();
  final normalized = target / base;
  final nice = normalized <= 1
      ? 1
      : normalized <= 2
      ? 2
      : normalized <= 5
      ? 5
      : 10;
  return nice * base;
}

const _k = 1000;
const _m = 1000000;
const _b = 1000000000;

String _formatAxisNumber(double value) {
  final rounded = value.round();
  if (rounded >= _b) return '${_toStringRounded(rounded / _b)} млрд';
  if (rounded >= _m) return '${_toStringRounded(rounded / _m)} млн';
  if (rounded >= _k) return '${_toStringRounded(rounded / _k)}к';
  return '$rounded';
}

String _toStringRounded(double value) {
  return value.toStringAsFixed(value >= 10 ? 0 : 1).replaceAll('.', ',');
}
