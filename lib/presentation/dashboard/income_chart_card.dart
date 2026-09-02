import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../data/models/transaction.dart';
import '../../data/repositories/transaction_repository.dart';

/// Цветовая палитра сфер для графиков: IT — синий, Логистика — оранжевый.
const kItColor = Color(0xFF2196F3);
const kLogisticsColor = Color(0xFFFF9800);

/// Карточка с линейным графиком доходов и переключателем периода.
class IncomeChartCard extends StatefulWidget {
  final TransactionRepository repository;
  final DateTime? now;

  /// Если задана, на графике показывается только соответствующая сфера.
  final TransactionSphere? sphere;

  const IncomeChartCard({
    super.key,
    required this.repository,
    this.now,
    this.sphere,
  });

  @override
  State<IncomeChartCard> createState() => _IncomeChartCardState();
}

class _IncomeChartCardState extends State<IncomeChartCard> {
  SeriesPeriod _period = SeriesPeriod.month;
  late Future<_ChartData> _chartFuture;

  @override
  void initState() {
    super.initState();
    _chartFuture = _load();
  }

  @override
  void didUpdateWidget(covariant IncomeChartCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.sphere != widget.sphere || oldWidget.now != widget.now) {
      _chartFuture = _load();
    }
  }

  Future<_ChartData> _load() async {
    final now = widget.now ?? DateTime.now();
    switch (widget.sphere) {
      case TransactionSphere.it:
        return _ChartData(
          it: await widget.repository
              .getIncomeSeries(period: _period, sphere: TransactionSphere.it, now: now),
        );
      case TransactionSphere.logistics:
        return _ChartData(
          logistics: await widget.repository.getIncomeSeries(
            period: _period,
            sphere: TransactionSphere.logistics,
            now: now,
          ),
        );
      case null:
        return _ChartData.loadForAll(widget.repository, period: _period, now: now);
    }
  }

  void _setPeriod(SeriesPeriod period) {
    setState(() {
      _period = period;
      _chartFuture = _load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Динамика доходов', style: theme.textTheme.titleLarge),
            if (widget.sphere == null) ...[
              const SizedBox(height: 12),
              const Row(
                children: [
                  _LegendDot(color: kItColor, label: 'IT'),
                  SizedBox(width: 16),
                  _LegendDot(color: kLogisticsColor, label: 'Логистика'),
                ],
              ),
            ],
            const SizedBox(height: 12),
            SegmentedButton<SeriesPeriod>(
              segments: [
                for (final period in SeriesPeriod.values)
                  ButtonSegment(value: period, label: Text(period.label)),
              ],
              selected: {_period},
              showSelectedIcon: false,
              style: const ButtonStyle(
                visualDensity: VisualDensity.compact,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              onSelectionChanged: (selection) => _setPeriod(selection.first),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 240,
              width: double.infinity,
              child: FutureBuilder<_ChartData>(
                future: _chartFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError || snapshot.data == null) {
                    return const Center(child: Text('Не удалось загрузить график'));
                  }
                  final data = snapshot.data!;
                  return Semantics(
                    key: const Key('income_chart'),
                    label: _accessibilityLabel(_period, data.it, data.logistics),
                    container: true,
                    child: _IncomeLineChart(
                      it: data.it,
                      logistics: data.logistics,
                      period: _period,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChartData {
  final List<IncomePoint>? it;
  final List<IncomePoint>? logistics;

  const _ChartData({this.it, this.logistics});

  static Future<_ChartData> loadForAll(
    TransactionRepository repository, {
    required SeriesPeriod period,
    required DateTime now,
  }) async {
    final results = await Future.wait([
      repository.getIncomeSeries(period: period, sphere: TransactionSphere.it, now: now),
      repository
          .getIncomeSeries(period: period, sphere: TransactionSphere.logistics, now: now),
    ]);
    return _ChartData(it: results[0], logistics: results[1]);
  }
}

class _IncomeLineChart extends StatelessWidget {
  final List<IncomePoint>? it;
  final List<IncomePoint>? logistics;
  final SeriesPeriod period;

  const _IncomeLineChart({required this.it, required this.logistics, required this.period});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final length = it?.length ?? logistics?.length ?? 0;
    if (length == 0) {
      return const SizedBox.shrink();
    }

    final lineBars = <LineChartBarData>[
      if (it != null)
        _buildLine(it!, kItColor),
      if (logistics != null)
        _buildLine(logistics!, kLogisticsColor),
    ];

    final maxValue = [
      ...?it,
      ...?logistics,
    ].fold<double>(0, (acc, point) => point.amount > acc ? point.amount : acc);
    final step = _niceStep(maxValue);
    final maxY = maxValue == 0 ? step * 4 : (maxValue / step).ceil() * step;

    final axisStyle = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );

    return LineChart(
      LineChartData(
        minX: -0.4,
        maxX: length - 1 + 0.4,
        minY: 0,
        maxY: maxY,
        lineBarsData: lineBars,
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
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: 1,
              getTitlesWidget: (value, meta) {
                final index = value.round();
                if (index < 0 || index >= length) return const SizedBox.shrink();
                final showEvery = period.bucketCount > 8 ? 2 : 1;
                if (index % showEvery != 0 && index != length - 1) {
                  return const SizedBox.shrink();
                }
                final start = (it ?? logistics)![index].start;
                return SideTitleWidget(
                  meta: meta,
                  space: 8,
                  child: Text(_shortAxisLabel(period, start), style: axisStyle),
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
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        lineTouchData: LineTouchData(
          touchSpotThreshold: 24,
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (spots) => theme.colorScheme.inverseSurface,
            tooltipBorderRadius: BorderRadius.circular(8),
            tooltipMargin: 12,
            getTooltipItems: (touchedSpots) => [
              for (final spot in touchedSpots)
                LineTooltipItem(
                  '${_barLabel(spot.barIndex)}: ${_formatAmount(spot.y)}',
                  theme.textTheme.labelMedium!.copyWith(
                    color: theme.colorScheme.onInverseSurface,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  static LineChartBarData _buildLine(List<IncomePoint> points, Color color) {
    return LineChartBarData(
      spots: [
        for (var i = 0; i < points.length; i++)
          FlSpot(i.toDouble(), points[i].amount),
      ],
      color: color,
      barWidth: 3,
      isCurved: true,
      curveSmoothness: 0.35,
      dotData: FlDotData(
        show: true,
        getDotPainter: (spot, percent, barData, index) =>
            FlDotCirclePainter(radius: 3.5, color: color),
      ),
      belowBarData: BarAreaData(show: false),
    );
  }

  String _barLabel(int barIndex) {
    if (it != null && logistics != null) {
      return barIndex == 0 ? 'IT' : 'Логистика';
    }
    return it != null ? 'IT' : 'Логистика';
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: theme.textTheme.bodyMedium),
      ],
    );
  }
}

String _shortAxisLabel(SeriesPeriod period, DateTime start) {
  switch (period) {
    case SeriesPeriod.month:
      return _shortMonths[start.month - 1];
    case SeriesPeriod.week:
      final day = start.day.toString().padLeft(2, '0');
      final month = start.month.toString().padLeft(2, '0');
      return '$day.$month';
    case SeriesPeriod.quarter:
      return '${_quarterOf(start)} кв';
    case SeriesPeriod.year:
      return '${start.year}';
  }
}

const _shortMonths = [
  'Янв', 'Фев', 'Мар', 'Апр', 'Май', 'Июн',
  'Июл', 'Авг', 'Сен', 'Окт', 'Ноя', 'Дек',
];

const _longMonths = [
  'Январь', 'Февраль', 'Март', 'Апрель', 'Май', 'Июнь',
  'Июль', 'Август', 'Сентябрь', 'Октябрь', 'Ноябрь', 'Декабрь',
];

int _quarterOf(DateTime date) => (date.month - 1) ~/ 3 + 1;

String _periodGenitive(SeriesPeriod period) {
  switch (period) {
    case SeriesPeriod.week:
      return 'неделям';
    case SeriesPeriod.month:
      return 'месяцам';
    case SeriesPeriod.quarter:
      return 'кварталам';
    case SeriesPeriod.year:
      return 'годам';
  }
}

String _accessibilityLabel(
  SeriesPeriod period,
  List<IncomePoint>? it,
  List<IncomePoint>? logistics,
) {
  final length = it?.length ?? logistics?.length ?? 0;
  final buffer = StringBuffer()..write('График доходов по ${_periodGenitive(period)}: ');
  for (var i = 0; i < length; i++) {
    final start = (it ?? logistics)![i].start;
    final chunks = <String>[];
    if (it != null) chunks.add('IT: ${_formatAmount(it[i].amount)}');
    if (logistics != null) {
      chunks.add('Логистика: ${_formatAmount(logistics[i].amount)}');
    }
    if (i > 0) buffer.write('; ');
    buffer.write('${_longPeriodLabel(period, start)} — ${chunks.join(', ')}');
  }
  return buffer.toString();
}

String _longPeriodLabel(SeriesPeriod period, DateTime start) {
  switch (period) {
    case SeriesPeriod.month:
      return '${_longMonths[start.month - 1]} ${start.year}';
    case SeriesPeriod.week:
      return 'неделя с ${start.day}.${start.month}.${start.year}';
    case SeriesPeriod.quarter:
      return '${_quarterOf(start)} квартал ${start.year}';
    case SeriesPeriod.year:
      return '${start.year} год';
  }
}

const _k = 1000;
const _m = 1000000;
const _b = 1000000000;

String _formatAxisNumber(double value) {
  final v = value.round();
  if (v >= _b) return '${_toStringRounded(v / _b)} млрд';
  if (v >= _m) return '${_toStringRounded(v / _m)} млн';
  if (v >= _k) return '${_toStringRounded(v / _k)}к';
  return '$v';
}

String _toStringRounded(double value) {
  return value.toStringAsFixed(value >= 10 ? 0 : 1).replaceAll('.', ',');
}

String _formatAmount(double value) {
  final whole = value.roundToDouble();
  final text = value == whole ? whole.toStringAsFixed(0) : value.toStringAsFixed(2);
  final parts = text.split('.');
  final digits = parts[0];
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(' ');
    buffer.write(digits[i]);
  }
  if (parts.length > 1 && parts[1] != '00') {
    return '${buffer.toString().replaceAll('.', ',')},${parts[1]} ₽';
  }
  return '$buffer ₽';
}

double _niceStep(double max) {
  if (max <= 0) return 25;
  final target = max / 4;
  final exp = (log(target) / ln10).floor();
  final base = pow(10, exp).toDouble();
  final normalized = target / base;
  final nice = normalized <= 1 ? 1 : normalized <= 2 ? 2 : normalized <= 5 ? 5 : 10;
  return nice * base;
}