import 'package:flutter/material.dart';

import '../../data/files/text_file_picker.dart';
import '../../data/models/risk_marker.dart';
import '../../data/repositories/risk_report_repository.dart';
import '../../domain/risk/risk_analyzer.dart';
import '../../domain/risk/risk_file_limits.dart';

/// Экран Risk Shield: загрузка TXT-договора и автоматический анализ рисков.
class RiskShieldScreen extends StatefulWidget {
  /// Use case поиска рисков в тексте договора.
  final RiskAnalyzerUseCase analyzer;

  /// Источник TXT-файлов (нативный диалог или заглушка в тестах).
  final TextFilePicker filePicker;

  /// Репозиторий результатов проверок; если задан — отчёт сохраняется.
  final RiskReportRepository? reportRepository;

  const RiskShieldScreen({
    super.key,
    required this.analyzer,
    required this.filePicker,
    this.reportRepository,
  });

  @override
  State<RiskShieldScreen> createState() => _RiskShieldScreenState();
}

class _RiskShieldScreenState extends State<RiskShieldScreen> {
  PickedTextFile? _file;
  RiskReport? _report;
  bool _isAnalyzing = false;
  String? _error;

  Future<void> _pickAndAnalyze() async {
    setState(() {
      _isAnalyzing = true;
      _error = null;
    });

    try {
      final file = await widget.filePicker.pick();
      if (file == null) {
        setState(() => _isAnalyzing = false);
        return;
      }

      final report = await widget.analyzer.analyze(
        file.content,
        sourceName: file.name,
      );
      await widget.reportRepository?.save(report);

      if (!mounted) return;
      setState(() {
        _file = file;
        _report = report;
        _isAnalyzing = false;
      });
    } on ContractFileTooLargeException catch (error) {
      if (!mounted) return;
      setState(() {
        _error =
            'Файл больше 100 КБ (${(error.actualBytes / 1024).ceil()} КБ). '
            'Выберите файл меньшего размера.';
        _isAnalyzing = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Не удалось прочитать файл. Попробуйте другой TXT-документ.';
        _isAnalyzing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('risk_shield_screen'),
      appBar: AppBar(title: const Text('Risk Shield')),
      body: SafeArea(child: _buildBody(context)),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_isAnalyzing) {
      return const Center(
        child: CircularProgressIndicator(key: Key('risk_analyzing_indicator')),
      );
    }
    if (_report == null) {
      return _EmptyState(error: _error, onPick: _pickAndAnalyze);
    }
    return _ReportView(
      report: _report!,
      fileName: _file?.name ?? '',
      error: _error,
      onPick: _pickAndAnalyze,
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String? error;
  final VoidCallback onPick;

  const _EmptyState({required this.error, required this.onPick});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.shield_outlined,
              size: 72,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Проверка договора на риски',
              style: theme.textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Загрузите договор в формате TXT (до 100 КБ) — приложение найдёт '
              'формулировки, по которым договор могут переквалифицировать '
              'в трудовой.',
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            if (error != null) ...[
              const SizedBox(height: 16),
              _ErrorText(error!),
            ],
            const SizedBox(height: 24),
            FilledButton.icon(
              key: const Key('risk_pick_button'),
              onPressed: onPick,
              icon: const Icon(Icons.upload_file),
              label: const Text('Загрузить договор'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReportView extends StatelessWidget {
  final RiskReport report;
  final String fileName;
  final String? error;
  final VoidCallback onPick;

  const _ReportView({
    required this.report,
    required this.fileName,
    required this.error,
    required this.onPick,
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
              const SizedBox(height: 4),
              Text(
                risks.isEmpty
                    ? 'Риски не найдены'
                    : 'Найдено рисков: ${risks.length}',
                key: const Key('risk_summary'),
                style: theme.textTheme.bodyLarge,
              ),
              if (error != null) ...[
                const SizedBox(height: 8),
                _ErrorText(error!),
              ],
            ],
          ),
        ),
        Expanded(
          child: risks.isEmpty
              ? _NoRisksView(theme: theme)
              : ListView.separated(
                  key: const Key('risk_result_list'),
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  itemCount: risks.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) =>
                      _RiskCard(match: risks[index]),
                ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: OutlinedButton.icon(
            key: const Key('risk_pick_another_button'),
            onPressed: onPick,
            icon: const Icon(Icons.upload_file),
            label: const Text('Проверить другой договор'),
          ),
        ),
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

class _RiskCard extends StatelessWidget {
  final RiskMatch match;

  const _RiskCard({required this.match});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = severityColor(match.severity);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 6, color: color),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.circle, size: 10, color: color),
                        const SizedBox(width: 6),
                        Text(
                          match.severity.label,
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: color,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(match.description, style: theme.textTheme.bodyLarge),
                    const SizedBox(height: 8),
                    Text(
                      'Найдено: «${match.matchedText}»',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Безопасная формулировка:',
                      style: theme.textTheme.labelMedium,
                    ),
                    const SizedBox(height: 2),
                    Text(match.suggestion, style: theme.textTheme.bodyMedium),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorText extends StatelessWidget {
  final String message;

  const _ErrorText(this.message);

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
          child: Text(
            message,
            style: TextStyle(color: color),
          ),
        ),
      ],
    );
  }
}

/// Цвет индикатора уровня риска (дублируется текстовой меткой в карточке).
Color severityColor(RiskSeverity severity) => switch (severity) {
  RiskSeverity.critical => const Color(0xFFD32F2F),
  RiskSeverity.medium => const Color(0xFFF9A825),
  RiskSeverity.low => const Color(0xFF2E7D32),
};
