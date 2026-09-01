import 'package:flutter/material.dart';

import '../../data/models/transaction.dart';
import '../../data/repositories/transaction_repository.dart';
import '../../domain/limit/limit_calculator.dart';

enum DashboardFilter { all, it, logistics }

class DashboardScreen extends StatefulWidget {
  final TransactionRepository repository;
  final DateTime? now;
  final void Function(ThemeMode mode)? onThemeModeChanged;

  const DashboardScreen({
    super.key,
    required this.repository,
    this.now,
    this.onThemeModeChanged,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  DashboardFilter _filter = DashboardFilter.all;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Дашборд'),
        actions: [
          _ThemeModeButton(onChanged: widget.onThemeModeChanged),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SegmentedButton<DashboardFilter>(
              segments: const [
                ButtonSegment(
                  value: DashboardFilter.all,
                  label: Text('Все'),
                  icon: Icon(Icons.all_inclusive),
                ),
                ButtonSegment(
                  value: DashboardFilter.it,
                  label: Text('IT'),
                  icon: Icon(Icons.code),
                ),
                ButtonSegment(
                  value: DashboardFilter.logistics,
                  label: Text('Логистика'),
                  icon: Icon(Icons.local_shipping),
                ),
              ],
              selected: {_filter},
              onSelectionChanged: (selection) {
                setState(() => _filter = selection.first);
              },
            ),
          ),
          Expanded(
            child: _DashboardView(
              future: _load(_filter),
              filter: _filter,
            ),
          ),
        ],
      ),
    );
  }

  Future<_DashboardData> _load(DashboardFilter filter) {
    final now = widget.now ?? DateTime.now();
    switch (filter) {
      case DashboardFilter.all:
        return Future.wait([
          widget.repository.getIncomeSummary(now: now),
          widget.repository
              .getIncomeSummary(sphere: TransactionSphere.it, now: now),
          widget.repository
              .getIncomeSummary(sphere: TransactionSphere.logistics, now: now),
          widget.repository.getAverageMonthlyIncome(now: now),
        ]).then((values) => _DashboardData(
              total: values[0] as IncomeSummary,
              it: values[1] as IncomeSummary,
              logistics: values[2] as IncomeSummary,
              averageMonthlyIncome: values[3] as double,
            ));
      case DashboardFilter.it:
        return Future.wait([
          widget.repository
              .getIncomeSummary(sphere: TransactionSphere.it, now: now),
          widget.repository.getAverageMonthlyIncome(
            sphere: TransactionSphere.it,
            now: now,
          ),
        ]).then((values) => _DashboardData(
              total: values[0] as IncomeSummary,
              averageMonthlyIncome: values[1] as double,
            ));
      case DashboardFilter.logistics:
        return Future.wait([
          widget.repository
              .getIncomeSummary(sphere: TransactionSphere.logistics, now: now),
          widget.repository.getAverageMonthlyIncome(
            sphere: TransactionSphere.logistics,
            now: now,
          ),
        ]).then((values) => _DashboardData(
              total: values[0] as IncomeSummary,
              averageMonthlyIncome: values[1] as double,
            ));
    }
  }
}

class _DashboardData {
  final IncomeSummary? total;
  final IncomeSummary? it;
  final IncomeSummary? logistics;
  final double averageMonthlyIncome;

  const _DashboardData({
    this.total,
    this.it,
    this.logistics,
    this.averageMonthlyIncome = 0,
  });
}

class _DashboardView extends StatelessWidget {
  final Future<_DashboardData> future;
  final DashboardFilter filter;

  const _DashboardView({required this.future, required this.filter});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_DashboardData>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError || snapshot.data == null) {
          return const Center(child: Text('Не удалось загрузить данные'));
        }
        return _DashboardBody(data: snapshot.data!, filter: filter);
      },
    );
  }
}

class _DashboardBody extends StatelessWidget {
  final _DashboardData data;
  final DashboardFilter filter;

  const _DashboardBody({required this.data, required this.filter});

  @override
  Widget build(BuildContext context) {
    final title = switch (filter) {
      DashboardFilter.all => 'Все сферы',
      DashboardFilter.it => 'IT',
      DashboardFilter.logistics => 'Логистика',
    };

    final children = <Widget>[
      _TotalCard(title: title, summary: data.total!),
      const SizedBox(height: 16),
      _LimitCard(
        usedAmount: data.total!.year,
        averageMonthlyIncome: data.averageMonthlyIncome,
      ),
    ];

    if (filter == DashboardFilter.all) {
      children
        ..add(const SizedBox(height: 16))
        ..add(_SphereCard(title: 'IT', summary: data.it!))
        ..add(const SizedBox(height: 16))
        ..add(_SphereCard(title: 'Логистика', summary: data.logistics!));
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: children,
    );
  }
}

class _TotalCard extends StatelessWidget {
  final String title;
  final IncomeSummary summary;

  const _TotalCard({required this.title, required this.summary});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: theme.textTheme.titleLarge),
            const SizedBox(height: 12),
            _MetricRow(label: 'Доход за месяц', value: summary.month),
            const SizedBox(height: 8),
            _MetricRow(label: 'Доход за год', value: summary.year),
          ],
        ),
      ),
    );
  }
}

class _SphereCard extends StatelessWidget {
  final String title;
  final IncomeSummary summary;

  const _SphereCard({required this.title, required this.summary});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: theme.textTheme.titleLarge),
            const SizedBox(height: 12),
            _MetricRow(label: 'Доход за месяц', value: summary.month),
            const SizedBox(height: 8),
            _MetricRow(label: 'Доход за год', value: summary.year),
          ],
        ),
      ),
    );
  }
}

class _LimitCard extends StatelessWidget {
  final double usedAmount;
  final double averageMonthlyIncome;

  const _LimitCard({
    required this.usedAmount,
    required this.averageMonthlyIncome,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final result = const LimitCalculator().calculate(
      usedAmount: usedAmount,
      averageMonthlyIncome: averageMonthlyIncome,
    );
    final ratio = result.ratio.clamp(0.0, 1.0);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Лимит НПД', style: theme.textTheme.titleLarge),
                Text(
                  '${LimitCalculator.formatAmount(usedAmount)} ₽ / '
                  '${LimitCalculator.formatAmount(result.limit)} ₽',
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                key: const Key('limit_progress'),
                minHeight: 16,
                value: ratio,
                valueColor: AlwaysStoppedAnimation<Color>(_levelColor(result.level)),
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              result.text,
              key: const Key('limit_text'),
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Точность прогноза ±15 дней на горизонте 3 месяцев.',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 4),
            Text(
              'Прогноз не учитывает сезонность.',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  static Color _levelColor(LimitLevel level) {
    return switch (level) {
      LimitLevel.green => const Color(0xFF4CAF50),
      LimitLevel.yellow => const Color(0xFFFFC107),
      LimitLevel.red => const Color(0xFFF44336),
    };
  }
}

class _MetricRow extends StatelessWidget {
  final String label;
  final double value;

  const _MetricRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: theme.textTheme.bodyMedium),
        Text(
          _formatRubles(value),
          style: theme.textTheme.titleMedium,
          key: Key('summary_$label'),
        ),
      ],
    );
  }

  static String _formatRubles(double value) {
    final fixed = value.toStringAsFixed(2);
    final parts = fixed.split('.');
    final digits = parts[0];
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(' ');
      buffer.write(digits[i]);
    }
    return '${buffer.toString().replaceAll('.', ',')},${parts[1]} ₽';
  }
}

class _ThemeModeButton extends StatelessWidget {
  final void Function(ThemeMode mode)? onChanged;

  const _ThemeModeButton({this.onChanged});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<ThemeMode>(
      tooltip: 'Тема',
      icon: const Icon(Icons.brightness_6),
      onSelected: onChanged,
      itemBuilder: (context) => const [
        PopupMenuItem(
          value: ThemeMode.system,
          child: Text('Системная'),
        ),
        PopupMenuItem(
          value: ThemeMode.light,
          child: Text('Светлая'),
        ),
        PopupMenuItem(
          value: ThemeMode.dark,
          child: Text('Тёмная'),
        ),
      ],
    );
  }
}
