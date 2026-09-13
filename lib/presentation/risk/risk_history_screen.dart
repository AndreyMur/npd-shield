import 'package:flutter/material.dart';

import '../../data/models/risk_marker.dart';
import '../../data/repositories/risk_report_repository.dart';
import '../../domain/risk/safety_index.dart';
import 'risk_report_detail_screen.dart';
import 'safety_index_gauge.dart';

/// Форматирует дату проверки как `дд.мм.гггг чч:мм` в локальном времени.
///
/// Собственный формат вместо `intl`, чтобы не тянуть зависимость и не зависеть
/// от локали устройства в тестах.
String formatHistoryDate(DateTime date) {
  final local = date.toLocal();
  String two(int value) => value.toString().padLeft(2, '0');
  return '${two(local.day)}.${two(local.month)}.${local.year} '
      '${two(local.hour)}:${two(local.minute)}';
}

/// Экран истории проверок: список сохранённых отчётов Risk Shield.
///
/// Каждый элемент показывает договор, дату, индекс безопасности и число
/// рисков; по нажатию открывается результат проверки, по кнопке — удаляется.
class RiskHistoryScreen extends StatefulWidget {
  /// Репозиторий сохранённых результатов проверок.
  final RiskReportRepository repository;

  const RiskHistoryScreen({super.key, required this.repository});

  @override
  State<RiskHistoryScreen> createState() => _RiskHistoryScreenState();
}

class _RiskHistoryScreenState extends State<RiskHistoryScreen> {
  List<RiskReport> _reports = [];
  bool _loading = true;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final reports = await widget.repository.getAll();
      if (!mounted) return;
      setState(() {
        _reports = reports;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error;
        _loading = false;
      });
    }
  }

  Future<void> _open(RiskReport report) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RiskReportDetailScreen(report: report),
      ),
    );
  }

  Future<void> _delete(RiskReport report) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Удалить проверку?'),
        content: Text(
          report.sourceName.isEmpty
              ? 'Результат проверки будет удалён без возможности восстановления.'
              : 'Результат проверки «${report.sourceName}» будет удалён '
                    'без возможности восстановления.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            key: const Key('confirm_history_delete_button'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await widget.repository.delete(report.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Проверка удалена')));
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('risk_history_screen'),
      appBar: AppBar(title: const Text('История проверок')),
      body: SafeArea(child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(key: Key('risk_history_loading')),
      );
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Не удалось загрузить историю проверок'),
            const SizedBox(height: 12),
            OutlinedButton(
              key: const Key('risk_history_retry'),
              onPressed: _load,
              child: const Text('Повторить'),
            ),
          ],
        ),
      );
    }
    if (_reports.isEmpty) {
      return const Center(
        key: Key('risk_history_empty'),
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.history, size: 56),
              SizedBox(height: 12),
              Text(
                'История проверок пуста',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 4),
              Text(
                'Загрузите договор на вкладке «Проверка», '
                'чтобы результаты сохранились здесь.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        key: const Key('risk_history_list'),
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        itemCount: _reports.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final report = _reports[index];
          return _HistoryCard(
            key: Key('risk_history_card_${report.id}'),
            report: report,
            onTap: () => _open(report),
            onDelete: () => _delete(report),
          );
        },
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final RiskReport report;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _HistoryCard({
    super.key,
    required this.report,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final id = report.id;
    final percent = report.safetyIndex.clamp(0, 100).round();
    final level = SafetyIndexCalculator.levelFor(percent.toDouble());
    final color = safetyIndexColor(percent.toDouble());
    final name = report.sourceName.isEmpty ? 'Без имени' : report.sourceName;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      key: Key('risk_history_name_$id'),
                      style: theme.textTheme.titleMedium,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formatHistoryDate(report.createdAt),
                      key: Key('risk_history_date_$id'),
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            'Индекс: $percent% · ${level.label}',
                            key: Key('risk_history_index_$id'),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: color,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Рисков: ${report.riskCount}',
                      key: Key('risk_history_risks_$id'),
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              IconButton(
                key: Key('risk_history_delete_$id'),
                tooltip: 'Удалить из истории',
                icon: const Icon(Icons.delete_outline),
                onPressed: onDelete,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
