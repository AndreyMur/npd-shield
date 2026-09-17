import 'package:flutter/material.dart';

import '../../core/theme/app_tokens.dart';
import '../../core/widgets/widgets.dart';
import '../../data/models/risk_marker.dart';
import 'risk_match_card.dart';
import 'risk_visuals.dart';
import 'safety_index_gauge.dart';

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
    final tokens = AppTokens.of(context);
    final risks = report.risks;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.xs,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                fileName,
                key: const Key('risk_file_name'),
                style: theme.textTheme.titleMedium,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppSpacing.sm),
              Center(child: SafetyIndexGauge(index: report.safetyIndex)),
              const SizedBox(height: AppSpacing.sm),
              Text(
                risks.isEmpty
                    ? 'Риски не найдены'
                    : 'Найдено рисков: ${risks.length}',
                key: const Key('risk_summary'),
                style: theme.textTheme.bodyLarge,
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                'Это не заменяет юридическую консультацию.',
                key: const Key('risk_disclaimer'),
                style: theme.textTheme.bodySmall?.copyWith(color: tokens.muted),
              ),
              if (error != null) ...[
                const SizedBox(height: AppSpacing.xs),
                RiskErrorText(error!),
              ],
            ],
          ),
        ),
        Expanded(
          child: risks.isEmpty
              ? const AppEmptyState(
                  icon: Icons.verified_outlined,
                  title: 'Опасных формулировок не найдено',
                  message: 'Это не заменяет юридическую консультацию.',
                )
              : _RiskList(risks: risks),
        ),
        if (footer != null)
          Padding(padding: const EdgeInsets.all(AppSpacing.md), child: footer!),
      ],
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
    final tokens = AppTokens.of(context);
    final filtered = _filter == null
        ? widget.risks
        : widget.risks.where((match) => match.severity == _filter).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                AppFilterChip(
                  key: const Key('risk_filter_all'),
                  label: 'Все (${widget.risks.length})',
                  selected: _filter == null,
                  onSelected: () => setState(() => _filter = null),
                ),
                for (final severity in RiskSeverity.values) ...[
                  const SizedBox(width: AppSpacing.xs),
                  AppFilterChip(
                    key: Key('risk_filter_${severity.name}'),
                    label: '${severity.pluralLabel} (${_count(severity)})',
                    accent: severity.color(tokens),
                    icon: severity.icon,
                    selected: _filter == severity,
                    onSelected: () => setState(() => _filter = severity),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Expanded(
          child: filtered.isEmpty
              ? const AppEmptyState(
                  key: Key('risk_filter_empty'),
                  compact: true,
                  icon: Icons.search_off,
                  title: 'Нет рисков выбранного уровня',
                )
              : ListView.separated(
                  key: const Key('risk_result_list'),
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    0,
                    AppSpacing.md,
                    AppSpacing.xs,
                  ),
                  itemCount: filtered.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: AppSpacing.xs),
                  itemBuilder: (context, index) =>
                      RiskMatchCard(match: filtered[index]),
                ),
        ),
      ],
    );
  }
}

/// Текст ошибки проверки договора.
class RiskErrorText extends StatelessWidget {
  final String message;

  const RiskErrorText(this.message, {super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = AppTokens.of(context);
    return Row(
      key: const Key('risk_error'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.error_outline, size: 18, color: tokens.destructive),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Text(
            message,
            style: TextStyle(color: tokens.destructive),
          ),
        ),
      ],
    );
  }
}
