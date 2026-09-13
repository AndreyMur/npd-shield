import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/models/risk_marker.dart';
import 'safety_index_gauge.dart';

/// Цвет индикатора уровня риска (дублируется текстовой меткой в карточке).
Color severityColor(RiskSeverity severity) => switch (severity) {
  RiskSeverity.critical => const Color(0xFFD32F2F),
  RiskSeverity.medium => const Color(0xFFF9A825),
  RiskSeverity.low => const Color(0xFF2E7D32),
};

/// Отображение результата проверки договора: индекс безопасности и список рисков.
///
/// Используется и сразу после анализа, и при повторном открытии отчёта из
/// истории — поэтому не зависит от источника данных.
class RiskReportView extends StatelessWidget {
  /// Отчёт с индексом и найденными рисками.
  final RiskReport report;

  /// Отображаемое имя проверенного договора.
  final String fileName;

  /// Сообщение об ошибке, если проверку не удалось выполнить.
  final String? error;

  /// Необязательное действие под списком (например, «Проверить другой договор»).
  final Widget? footer;

  const RiskReportView({
    super.key,
    required this.report,
    required this.fileName,
    this.error,
    this.footer,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final risks = report.risks;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                fileName,
                key: const Key('risk_file_name'),
                style: theme.textTheme.titleMedium,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Center(child: SafetyIndexGauge(index: report.safetyIndex)),
              const SizedBox(height: 12),
              Text(
                risks.isEmpty
                    ? 'Риски не найдены'
                    : 'Найдено рисков: ${risks.length}',
                key: const Key('risk_summary'),
                style: theme.textTheme.bodyLarge,
              ),
              if (error != null) ...[
                const SizedBox(height: 8),
                RiskErrorText(error!),
              ],
            ],
          ),
        ),
        Expanded(
          child: risks.isEmpty
              ? _NoRisksView(theme: theme)
              : _RiskList(risks: risks),
        ),
        if (footer != null)
          Padding(padding: const EdgeInsets.all(16), child: footer!),
      ],
    );
  }
}

class _NoRisksView extends StatelessWidget {
  final ThemeData theme;

  const _NoRisksView({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.verified_outlined, size: 56),
          const SizedBox(height: 12),
          Text('Опасных формулировок не найдено', style: theme.textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            'Это не заменяет юридическую консультацию.',
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

/// Список найденных рисков с фильтрацией по уровню.
class _RiskList extends StatefulWidget {
  final List<RiskMatch> risks;

  const _RiskList({required this.risks});

  @override
  State<_RiskList> createState() => _RiskListState();
}

class _RiskListState extends State<_RiskList> {
  RiskSeverity? _filter;

  int _count(RiskSeverity severity) =>
      widget.risks.where((match) => match.severity == severity).length;

  @override
  Widget build(BuildContext context) {
    final filtered = _filter == null
        ? widget.risks
        : widget.risks.where((match) => match.severity == _filter).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _FilterChip(
                  key: const Key('risk_filter_all'),
                  label: 'Все',
                  count: widget.risks.length,
                  selected: _filter == null,
                  onSelected: () => setState(() => _filter = null),
                ),
                const SizedBox(width: 8),
                for (final severity in RiskSeverity.values) ...[
                  _FilterChip(
                    key: Key('risk_filter_${severity.name}'),
                    label: severity.pluralLabel,
                    count: _count(severity),
                    selected: _filter == severity,
                    onSelected: () => setState(() => _filter = severity),
                  ),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: filtered.isEmpty
              ? const Center(
                  key: Key('risk_filter_empty'),
                  child: Text('Нет рисков выбранного уровня'),
                )
              : ListView.separated(
                  key: const Key('risk_result_list'),
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  itemCount: filtered.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) =>
                      _RiskCard(match: filtered[index]),
                ),
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final int count;
  final bool selected;
  final VoidCallback onSelected;

  const _FilterChip({
    super.key,
    required this.label,
    required this.count,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text('$label ($count)'),
      selected: selected,
      onSelected: (_) => onSelected(),
    );
  }
}

/// Карточка риска: цветная полоса уровня слева и раскрывающиеся детали.
class _RiskCard extends StatefulWidget {
  final RiskMatch match;

  const _RiskCard({required this.match});

  @override
  State<_RiskCard> createState() => _RiskCardState();
}

class _RiskCardState extends State<_RiskCard> {
  bool _expanded = false;

  Future<void> _copySuggestion() async {
    await Clipboard.setData(ClipboardData(text: widget.match.suggestion));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Безопасная формулировка скопирована')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final match = widget.match;
    final color = severityColor(match.severity);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 6, color: color),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Semantics(
                    button: true,
                    expanded: _expanded,
                    label: '${match.severity.label}: ${match.description}',
                    child: InkWell(
                      key: Key('risk_toggle_${match.start}'),
                      onTap: () => setState(() => _expanded = !_expanded),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Icon(Icons.circle, size: 10, color: color),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    match.severity.label,
                                    style: theme.textTheme.labelLarge?.copyWith(
                                      color: color,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    match.description,
                                    style: theme.textTheme.bodyLarge,
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              _expanded
                                  ? Icons.expand_less
                                  : Icons.expand_more,
                              semanticLabel: _expanded
                                  ? 'Свернуть детали'
                                  : 'Развернуть детали',
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (_expanded)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Где найдено', style: theme.textTheme.labelMedium),
                          const SizedBox(height: 2),
                          Text(
                            '«${match.matchedText}» '
                            '(позиция ${match.start}–${match.end})',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Безопасная формулировка',
                            style: theme.textTheme.labelMedium,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            match.suggestion,
                            style: theme.textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: FilledButton.tonalIcon(
                              key: Key('risk_copy_${match.start}'),
                              onPressed: _copySuggestion,
                              icon: const Icon(Icons.copy, size: 18),
                              label: const Text('Скопировать формулировку'),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Текст ошибки проверки договора.
class RiskErrorText extends StatelessWidget {
  final String message;

  const RiskErrorText(this.message, {super.key});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.error;
    return Row(
      key: const Key('risk_error'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.error_outline, size: 18, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(message, style: TextStyle(color: color)),
        ),
      ],
    );
  }
}
