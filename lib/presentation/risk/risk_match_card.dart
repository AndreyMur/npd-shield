import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/models/risk_marker.dart';

/// Цвет индикатора уровня риска (дублируется текстовой меткой в карточке).
Color severityColor(RiskSeverity severity) => switch (severity) {
  RiskSeverity.critical => const Color(0xFFD32F2F),
  RiskSeverity.medium => const Color(0xFFF9A825),
  RiskSeverity.low => const Color(0xFF2E7D32),
};

/// Карточка одного найденного риска: цветная полоса уровня слева,
/// раскрывающиеся детали и кнопка копирования безопасной формулировки.
///
/// Используется в полном отчёте Risk Shield и в карточке договора, поэтому
/// не зависит от источника данных.
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
