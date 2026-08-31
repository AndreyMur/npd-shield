import 'package:flutter/material.dart';

import '../../data/models/transaction.dart';
import '../../data/repositories/transaction_repository.dart';

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
            child: FutureBuilder<Map<DashboardFilter, IncomeSummary>>(
              future: _summaries(),
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                return _DashboardBody(
                  summaries: snapshot.data!,
                  filter: _filter,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<Map<DashboardFilter, IncomeSummary>> _summaries() async {
    final now = widget.now ?? DateTime.now();
    final summaries = <DashboardFilter, IncomeSummary>{};
    summaries[DashboardFilter.all] =
        await widget.repository.getIncomeSummary(now: now);
    summaries[DashboardFilter.it] = await widget.repository
        .getIncomeSummary(sphere: TransactionSphere.it, now: now);
    summaries[DashboardFilter.logistics] = await widget.repository
        .getIncomeSummary(sphere: TransactionSphere.logistics, now: now);
    return summaries;
  }
}

class _ThemeModeButton extends StatefulWidget {
  final void Function(ThemeMode mode)? onChanged;

  const _ThemeModeButton({this.onChanged});

  @override
  State<_ThemeModeButton> createState() => _ThemeModeButtonState();
}

class _ThemeModeButtonState extends State<_ThemeModeButton> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return IconButton(
      tooltip: isDark ? 'Светлая тема' : 'Тёмная тема',
      icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
      onPressed: () {
        final next = isDark ? ThemeMode.light : ThemeMode.dark;
        widget.onChanged?.call(next);
      },
    );
  }
}

class _DashboardBody extends StatelessWidget {
  final Map<DashboardFilter, IncomeSummary> summaries;
  final DashboardFilter filter;

  const _DashboardBody({required this.summaries, required this.filter});

  @override
  Widget build(BuildContext context) {
    final spheres = _visibleSpheres();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _TotalCard(
          summary: summaries[filter]!,
          filter: filter,
        ),
        const SizedBox(height: 16),
        for (final sphere in spheres) ...[
          _SphereCard(summary: summaries[_filterFor(sphere)]!),
          const SizedBox(height: 16),
        ],
      ],
    );
  }

  List<TransactionSphere> _visibleSpheres() {
    return switch (filter) {
      DashboardFilter.all => [TransactionSphere.it, TransactionSphere.logistics],
      DashboardFilter.it => [TransactionSphere.it],
      DashboardFilter.logistics => [TransactionSphere.logistics],
    };
  }

  DashboardFilter _filterFor(TransactionSphere sphere) {
    return switch (sphere) {
      TransactionSphere.it => DashboardFilter.it,
      TransactionSphere.logistics => DashboardFilter.logistics,
    };
  }
}

class _TotalCard extends StatelessWidget {
  final IncomeSummary summary;
  final DashboardFilter filter;

  const _TotalCard({required this.summary, required this.filter});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = switch (filter) {
      DashboardFilter.all => 'Все сферы',
      DashboardFilter.it => 'IT',
      DashboardFilter.logistics => 'Логистика',
    };
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
  final IncomeSummary summary;

  const _SphereCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Доход', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            _MetricRow(label: 'За месяц', value: summary.month),
            const SizedBox(height: 8),
            _MetricRow(label: 'За год', value: summary.year),
          ],
        ),
      ),
    );
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
          _format(value),
          style: theme.textTheme.titleMedium,
          key: Key('summary_$label'),
        ),
      ],
    );
  }

  static String _format(double value) {
    return '${value.toStringAsFixed(2).replaceAll('.', ',')} ₽';
  }
}
