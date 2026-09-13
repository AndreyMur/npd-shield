import 'package:flutter/material.dart';

import '../../data/files/text_file_picker.dart';
import '../../data/models/risk_marker.dart';
import '../../data/repositories/risk_report_repository.dart';
import '../../domain/risk/risk_analyzer.dart';
import '../../domain/risk/risk_file_limits.dart';
import 'risk_history_screen.dart';
import 'risk_report_view.dart';
import 'risk_shield_info_sheet.dart';

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

  Future<void> _openHistory() async {
    final repository = widget.reportRepository;
    if (repository == null) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RiskHistoryScreen(repository: repository),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('risk_shield_screen'),
      appBar: AppBar(
        title: const Text('Risk Shield'),
        actions: [
          IconButton(
            key: const Key('risk_info_button'),
            tooltip: 'Как это работает и как подготовить договор',
            icon: const Icon(Icons.info_outline),
            onPressed: () => showRiskShieldInfoSheet(context),
          ),
          if (widget.reportRepository != null)
            IconButton(
              key: const Key('risk_history_button'),
              tooltip: 'История проверок',
              icon: const Icon(Icons.history),
              onPressed: _openHistory,
            ),
        ],
      ),
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
    return RiskReportView(
      report: _report!,
      fileName: _file?.name ?? '',
      error: _error,
      footer: OutlinedButton.icon(
        key: const Key('risk_pick_another_button'),
        onPressed: _pickAndAnalyze,
        icon: const Icon(Icons.upload_file),
        label: const Text('Проверить другой договор'),
      ),
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
            const SizedBox(height: 12),
            Text(
              riskShieldDisclaimer,
              key: const Key('risk_empty_disclaimer'),
              style: theme.textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              key: const Key('risk_empty_info_button'),
              onPressed: () => showRiskShieldInfoSheet(context),
              icon: const Icon(Icons.help_outline, size: 18),
              label: const Text('Как подготовить договор из PDF или DOCX'),
            ),
            if (error != null) ...[
              const SizedBox(height: 16),
              RiskErrorText(error!),
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
