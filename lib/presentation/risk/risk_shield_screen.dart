import 'package:flutter/material.dart';

import '../../core/theme/app_tokens.dart';
import '../../core/widgets/widgets.dart';
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
      footer: AppButton(
        key: const Key('risk_pick_another_button'),
        label: 'Проверить другой договор',
        icon: Icons.upload_file,
        variant: AppButtonVariant.secondary,
        onPressed: _pickAndAnalyze,
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
    final tokens = AppTokens.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                gradient: tokens.brandGradient,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.shield_outlined,
                size: 48,
                color: tokens.onPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Проверка договора на риски',
              style: theme.textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Загрузите договор в формате TXT (до 100 КБ) — приложение найдёт '
              'формулировки, по которым договор могут переквалифицировать '
              'в трудовой.',
              style: theme.textTheme.bodyMedium?.copyWith(color: tokens.muted),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              riskShieldDisclaimer,
              key: const Key('risk_empty_disclaimer'),
              style: theme.textTheme.bodySmall?.copyWith(color: tokens.muted),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xs),
            AppButton(
              key: const Key('risk_empty_info_button'),
              label: 'Как подготовить договор из PDF или DOCX',
              icon: Icons.help_outline,
              variant: AppButtonVariant.text,
              onPressed: () => showRiskShieldInfoSheet(context),
            ),
            if (error != null) ...[
              const SizedBox(height: AppSpacing.md),
              RiskErrorText(error!),
            ],
            const SizedBox(height: AppSpacing.lg),
            AppButton(
              key: const Key('risk_pick_button'),
              label: 'Загрузить договор',
              icon: Icons.upload_file,
              expanded: true,
              onPressed: onPick,
            ),
          ],
        ),
      ),
    );
  }
}
