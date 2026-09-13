import 'package:flutter/material.dart';

/// Дисклеймер о том, что Risk Shield не заменяет юридическую консультацию.
const String riskShieldDisclaimer =
    'Risk Shield — вспомогательный инструмент. Он не заменяет юридическую '
    'консультацию и не гарантирует отсутствие рисков. Решение о подписании '
    'договора принимайте осознанно; при сомнениях обратитесь к юристу.';

/// Инструкция по конвертации PDF/DOCX в TXT для проверки.
const List<String> riskShieldConversionSteps = [
  'Risk Shield анализирует только текстовые файлы TXT размером до 100 КБ.',
  'DOCX: откройте документ в Word или Google Docs и сохраните как '
      '«Обычный текст (*.txt)».',
  'PDF: откройте файл в просмотрщике и выберите «Сохранить как текст», либо '
      'воспользуйтесь конвертером PDF → TXT.',
  'Проверьте размер полученного файла — он должен быть не больше 100 КБ.',
  'Загрузите TXT-файл на вкладке «Проверка» — анализ запустится автоматически.',
];

/// Показывает нижний лист с дисклеймером и инструкцией по конвертации.
Future<void> showRiskShieldInfoSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => const RiskShieldInfoSheet(),
  );
}

/// Содержимое листа: дисклеймер и пошаговая инструкция PDF/DOCX → TXT.
class RiskShieldInfoSheet extends StatelessWidget {
  const RiskShieldInfoSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: FractionallySizedBox(
        key: const Key('risk_info_sheet'),
        heightFactor: 0.8,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.shield_outlined, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Text('Как работает Risk Shield', style: theme.textTheme.titleLarge),
                ],
              ),
              const SizedBox(height: 16),
              _SectionTitle('Важно', theme: theme),
              const SizedBox(height: 8),
              Text(
                riskShieldDisclaimer,
                key: const Key('risk_info_disclaimer'),
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 20),
              _SectionTitle('Как подготовить договор', theme: theme),
              const SizedBox(height: 8),
              for (var i = 0; i < riskShieldConversionSteps.length; i++) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${i + 1}.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        riskShieldConversionSteps[i],
                        key: Key('risk_info_step_$i'),
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.lock_outline,
                    size: 18,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Файлы обрабатываются локально и не покидают устройство.',
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  final ThemeData theme;

  const _SectionTitle(this.text, {required this.theme});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: theme.textTheme.titleMedium?.copyWith(
        color: theme.colorScheme.primary,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
