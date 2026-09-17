import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_tokens.dart';
import '../../core/widgets/widgets.dart';
import '../../data/models/risk_marker.dart';
import 'risk_visuals.dart';

/// Карточка одного найденного риска: цветная полоса уровня слева, иконка и
/// текстовая метка уровня, раскрывающиеся детали и кнопка копирования
/// безопасной формулировки.
///
/// Уровень риска кодируется одновременно цветом, иконкой и текстом, поэтому
/// остаётся различимым и без восприятия цвета. Используется в полном отчёте
/// Risk Shield и в карточке договора, поэтому не зависит от источника данных.
class RiskMatchCard extends StatefulWidget {
  /// Найденное совпадение маркера риска.
  final RiskMatch match;

  const RiskMatchCard({super.key, required this.match});

  @override
  State<RiskMatchCard> createState() => _RiskMatchCardState();
}

class _RiskMatchCardState extends State<RiskMatchCard> {
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
    final tokens = AppTokens.of(context);
    final match = widget.match;
    final color = match.severity.color(tokens);

    return AppCard(
      padding: EdgeInsets.zero,
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
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        child: Row(
                          children: [
                            Icon(match.severity.icon, size: 20, color: color),
                            const SizedBox(width: AppSpacing.xs),
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
                                  const SizedBox(height: AppSpacing.xxs),
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
                              color: tokens.muted,
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
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.sm,
                        0,
                        AppSpacing.sm,
                        AppSpacing.sm,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Где найдено',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: tokens.muted,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '«${match.matchedText}» '
                            '(позиция ${match.start}–${match.end})',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            'Безопасная формулировка',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: tokens.muted,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            match.suggestion,
                            style: theme.textTheme.bodyMedium,
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: AppButton(
                              key: Key('risk_copy_${match.start}'),
                              label: 'Скопировать формулировку',
                              icon: Icons.copy,
                              variant: AppButtonVariant.secondary,
                              onPressed: _copySuggestion,
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
