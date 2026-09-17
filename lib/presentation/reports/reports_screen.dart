import 'package:flutter/material.dart';

import '../../core/theme/app_tokens.dart';
import '../../core/widgets/widgets.dart';
import '../../data/backup/backup_service.dart';
import '../../data/export/csv_export_service.dart';
import '../../data/files/backup_file_picker.dart';
import '../../data/files/export_file_saver.dart';
import '../../data/pdf/contract_pdf_font_loader.dart';
import '../../data/pdf/generated_pdf.dart';
import '../../data/pdf/report_pdf_service.dart';
import '../../data/repositories/invoice_repository.dart';
import '../../data/repositories/transaction_repository.dart';
import '../../domain/reports/business_report.dart';
import '../../domain/reports/report_builder.dart';
import '../../domain/reports/report_format.dart';
import 'backup_dialogs.dart';
import 'report_period.dart';
import 'report_period_selector.dart';
import 'report_sphere_chart.dart';

/// Строит PDF-отчёт, переопределяется в тестах.
typedef ReportPdfBuilder = Future<GeneratedPdf> Function(BusinessReport report);

/// Экран отчётов, экспорта и резервного копирования (Модуль 5).
///
/// Показывает отчёт за выбранный период: итоги (доход, расход, прибыль,
/// налог), график и разбивку по сферам и клиентам. Отсюда же выгружаются
/// операции и счета в CSV, отчёт в PDF, а также создаются и восстанавливаются
/// резервные копии всех данных.
class ReportsScreen extends StatefulWidget {
  /// Репозиторий операций — источник данных отчёта и CSV-выгрузки.
  final TransactionRepository transactionRepository;

  /// Репозиторий счетов — источник CSV-выгрузки счетов.
  final InvoiceRepository invoiceRepository;

  /// Операции резервного копирования.
  final BackupGateway backupGateway;

  /// Сохранение файлов на устройство.
  final ExportFileSaver fileSaver;

  /// Выбор файла резервной копии для импорта.
  final BackupFilePicker backupFilePicker;

  /// «Сейчас» для стабильности периода и тестов.
  final DateTime? now;

  /// Генерация PDF-отчёта. По умолчанию — встроенный сервис с кириллицей.
  final ReportPdfBuilder? pdfBuilder;

  const ReportsScreen({
    super.key,
    required this.transactionRepository,
    required this.invoiceRepository,
    required this.backupGateway,
    required this.fileSaver,
    required this.backupFilePicker,
    this.now,
    this.pdfBuilder,
  });

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  static const _csvService = CsvExportService();

  ReportPeriodPreset _preset = ReportPeriodPreset.month;
  late ReportPeriod _period;

  BusinessReport? _report;
  bool _loading = true;
  Object? _error;
  bool _busy = false;

  DateTime get _now => widget.now ?? DateTime.now();

  @override
  void initState() {
    super.initState();
    _period = ReportPeriodPreset.month.range(_now)!;
    _reload();
  }

  Future<void> _reload() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final report = await ReportBuilder(
        transactionRepository: widget.transactionRepository,
      ).build(from: _period.from, to: _period.to);
      if (!mounted) return;
      setState(() {
        _report = report;
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

  void _setPeriod(ReportPeriod period, ReportPeriodPreset preset) {
    setState(() {
      _period = period;
      _preset = preset;
    });
    _reload();
  }

  Future<void> _selectPreset(ReportPeriodPreset preset) async {
    if (preset == ReportPeriodPreset.custom) {
      final picked = await showDateRangePicker(
        context: context,
        firstDate: DateTime(2000),
        lastDate: DateTime(_now.year + 5, 12, 31),
        initialDateRange: DateTimeRange(start: _period.from, end: _period.to),
        helpText: 'Период отчёта',
        saveText: 'Готово',
      );
      if (picked == null || !mounted) return;
      _setPeriod(
        ReportPeriod(from: picked.start, to: picked.end),
        ReportPeriodPreset.custom,
      );
      return;
    }
    final range = preset.range(_now);
    if (range != null) _setPeriod(range, preset);
  }

  Future<void> _exportTransactionsCsv() async {
    await _runExport('Выгружено операций', () async {
      final transactions = await widget.transactionRepository.getAll(
        filter: TransactionFilter(
          from: _period.from,
          to: _period.to.add(const Duration(days: 1)),
        ),
      );
      final export = _csvService.exportTransactions(
        transactions,
        from: _period.from,
        to: _period.to,
      );
      return widget.fileSaver.save(
        fileName: export.fileName,
        bytes: export.bytes,
      );
    });
  }

  Future<void> _exportInvoicesCsv() async {
    await _runExport('Выгружено счетов', () async {
      final invoices = await widget.invoiceRepository.getAll();
      final export = _csvService.exportInvoices(
        invoices,
        from: _period.from,
        to: _period.to,
        now: _now,
      );
      return widget.fileSaver.save(
        fileName: export.fileName,
        bytes: export.bytes,
      );
    });
  }

  Future<void> _exportPdf() async {
    final report = _report;
    if (report == null) return;
    await _runExport('PDF-отчёт сохранён', () async {
      final builder = widget.pdfBuilder ?? _generatePdf;
      final pdf = await builder(report);
      final path = await widget.fileSaver.save(
        fileName: pdf.fileName,
        bytes: pdf.bytes,
      );
      return path;
    });
  }

  Future<void> _exportBackup() async {
    await _runExport('Резервная копия создана', () async {
      final backup = await widget.backupGateway.exportBackup();
      final path = await widget.fileSaver.save(
        fileName: backup.fileName,
        bytes: backup.bytes,
      );
      return path;
    });
  }

  Future<void> _importBackup() async {
    if (_busy) return;
    final file = await widget.backupFilePicker.pick();
    if (file == null || !mounted) return;

    final confirmed = await showBackupImportConfirmation(
      context,
      fileName: file.name,
    );
    if (!confirmed || !mounted) return;

    setState(() => _busy = true);
    try {
      final result = await widget.backupGateway.importBackup(file.bytes);
      await _reload();
      if (!mounted) return;
      _showMessage(
        'Данные восстановлены: ${result.counts.total} записей',
      );
    } on BackupFormatException catch (error) {
      _showError(error.message);
    } catch (_) {
      _showError('Не удалось восстановить данные из копии');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<GeneratedPdf> _generatePdf(BusinessReport report) async {
    final fonts = await const ContractPdfFontLoader().load();
    return const ReportPdfService().generateInBackground(
      report: report,
      fonts: fonts,
    );
  }

  Future<void> _runExport(
    String successMessage,
    Future<String?> Function() action,
  ) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final path = await action();
      if (path == null) {
        _showMessage('Сохранение отменено');
      } else {
        _showMessage('$successMessage: $path');
      }
    } catch (_) {
      _showError('Не удалось сохранить файл');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Отчёты')),
      body: ListView(
        key: const Key('reports_list'),
        padding: AppSpacing.screen,
        children: [
          ReportPeriodSelector(
            preset: _preset,
            period: _period,
            onPresetSelected: _selectPreset,
          ),
          const SizedBox(height: AppSpacing.md),
          _buildReportSection(),
          const SizedBox(height: AppSpacing.md),
          _ExportCard(
            busy: _busy,
            onExportTransactions: _exportTransactionsCsv,
            onExportInvoices: _exportInvoicesCsv,
            onExportPdf: _exportPdf,
          ),
          const SizedBox(height: AppSpacing.md),
          _BackupCard(
            busy: _busy,
            onExportBackup: _exportBackup,
            onImportBackup: _importBackup,
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }

  Widget _buildReportSection() {
    if (_loading) {
      return const AppLoadingState(
        itemCount: 3,
        semanticLabel: 'Построение отчёта',
      );
    }
    if (_error != null) {
      return AppErrorState(
        message: 'Не удалось построить отчёт',
        retryKey: const Key('reports_retry'),
        onRetry: _reload,
      );
    }
    final report = _report!;
    return Column(
      children: [
        _SummaryCard(report: report),
        const SizedBox(height: AppSpacing.md),
        ReportSphereChart(spheres: report.spheres),
        const SizedBox(height: AppSpacing.md),
        _BreakdownCard(
          keyPrefix: 'sphere',
          title: 'Разбивка по сферам',
          headers: const ['Сфера', 'Доход', 'Расход', 'Прибыль'],
          rows: [
            for (final row in report.spheres)
              [
                row.sphere.label,
                formatReportAmount(row.income),
                formatReportAmount(row.expense),
                formatReportAmount(row.profit),
              ],
          ],
          emptyText: 'За выбранный период операций по сферам нет',
        ),
        const SizedBox(height: AppSpacing.md),
        _BreakdownCard(
          keyPrefix: 'client',
          title: 'Разбивка по клиентам',
          headers: const ['Клиент', 'Доход', 'Расход', 'Прибыль'],
          rows: [
            for (final row in report.clients)
              [
                row.displayName,
                formatReportAmount(row.income),
                formatReportAmount(row.expense),
                formatReportAmount(row.profit),
              ],
          ],
          emptyText: 'За выбранный период операций по клиентам нет',
        ),
      ],
    );
  }
}

/// Карточка итогов отчёта.
class _SummaryCard extends StatelessWidget {
  final BusinessReport report;

  const _SummaryCard({required this.report});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = AppTokens.of(context);
    final profitColor = report.profit < 0
        ? tokens.destructive
        : tokens.success;
    return AppCard(
      key: const Key('report_summary'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Итоги за период', style: theme.textTheme.titleLarge),
          const SizedBox(height: AppSpacing.sm),
          _SummaryRow(
            label: 'Доход',
            value: report.income,
            color: tokens.success,
            valueKey: 'report_income',
          ),
          const SizedBox(height: AppSpacing.xs),
          _SummaryRow(
            label: 'Расход',
            value: report.expense,
            color: tokens.destructive,
            valueKey: 'report_expense',
          ),
          const SizedBox(height: AppSpacing.xs),
          _SummaryRow(
            label: 'Прибыль',
            value: report.profit,
            color: profitColor,
            valueKey: 'report_profit',
          ),
          Divider(height: AppSpacing.lg, color: tokens.border),
          _SummaryRow(
            label: 'Налог к уплате',
            value: report.taxAmount,
            valueKey: 'report_tax',
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            'Начислено ${formatReportMoney(report.tax.accruedTax)} · '
            'вычет взносов ${formatReportMoney(report.tax.insuranceDeduction)}',
            style: theme.textTheme.bodySmall?.copyWith(color: tokens.muted),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final double value;
  final Color? color;
  final String valueKey;

  const _SummaryRow({
    required this.label,
    required this.value,
    required this.valueKey,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = AppTokens.of(context);
    final style = theme.textTheme.titleMedium;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(color: tokens.muted),
        ),
        Text(
          formatReportMoney(value),
          key: Key(valueKey),
          style: color == null ? style : style!.copyWith(color: color),
        ),
      ],
    );
  }
}

/// Таблица разбивки показателей по строкам.
class _BreakdownCard extends StatelessWidget {
  final String keyPrefix;
  final String title;
  final List<String> headers;
  final List<List<String>> rows;
  final String emptyText;

  const _BreakdownCard({
    required this.keyPrefix,
    required this.title,
    required this.headers,
    required this.rows,
    required this.emptyText,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = AppTokens.of(context);
    return AppCard(
      key: Key('report_breakdown_$keyPrefix'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.titleLarge),
          const SizedBox(height: AppSpacing.sm),
          if (rows.isEmpty)
            Text(
              emptyText,
              key: Key('report_breakdown_${keyPrefix}_empty'),
              style: theme.textTheme.bodyMedium?.copyWith(color: tokens.muted),
            )
          else ...[
            _row(theme, tokens, headers, header: true),
            Divider(height: AppSpacing.sm, color: tokens.border),
            for (var i = 0; i < rows.length; i++)
              _row(
                theme,
                tokens,
                rows[i],
                key: Key('report_${keyPrefix}_row_$i'),
              ),
          ],
        ],
      ),
    );
  }

  Widget _row(
    ThemeData theme,
    AppTokens tokens,
    List<String> cells, {
    bool header = false,
    Key? key,
  }) {
    final style = header
        ? theme.textTheme.bodySmall?.copyWith(color: tokens.muted)
        : theme.textTheme.bodyMedium;
    return Padding(
      key: key,
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              cells.first,
              style: style?.copyWith(
                fontWeight: header ? FontWeight.w600 : null,
              ),
            ),
          ),
          for (final cell in cells.skip(1))
            Expanded(
              child: Text(cell, textAlign: TextAlign.right, style: style),
            ),
        ],
      ),
    );
  }
}

/// Карточка выгрузки CSV и PDF.
class _ExportCard extends StatelessWidget {
  final bool busy;
  final VoidCallback onExportTransactions;
  final VoidCallback onExportInvoices;
  final VoidCallback onExportPdf;

  const _ExportCard({
    required this.busy,
    required this.onExportTransactions,
    required this.onExportInvoices,
    required this.onExportPdf,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = AppTokens.of(context);
    return AppCard(
      key: const Key('report_export_card'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Экспорт', style: theme.textTheme.titleLarge),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            'Файлы сохраняются на устройство в выбранную папку.',
            style: theme.textTheme.bodySmall?.copyWith(color: tokens.muted),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              AppButton(
                key: const Key('reports_export_operations_csv'),
                label: 'Операции в CSV',
                icon: Icons.table_view_outlined,
                variant: AppButtonVariant.secondary,
                onPressed: busy ? null : onExportTransactions,
              ),
              AppButton(
                key: const Key('reports_export_invoices_csv'),
                label: 'Счета в CSV',
                icon: Icons.table_view_outlined,
                variant: AppButtonVariant.secondary,
                onPressed: busy ? null : onExportInvoices,
              ),
              AppButton(
                key: const Key('reports_export_pdf'),
                label: 'Отчёт в PDF',
                icon: Icons.picture_as_pdf_outlined,
                onPressed: busy ? null : onExportPdf,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Карточка резервного копирования.
class _BackupCard extends StatelessWidget {
  final bool busy;
  final VoidCallback onExportBackup;
  final VoidCallback onImportBackup;

  const _BackupCard({
    required this.busy,
    required this.onExportBackup,
    required this.onImportBackup,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = AppTokens.of(context);
    return AppCard(
      key: const Key('report_backup_card'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Резервное копирование', style: theme.textTheme.titleLarge),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            'Копия содержит все данные приложения. Восстановление заменяет '
            'текущие данные.',
            style: theme.textTheme.bodySmall?.copyWith(color: tokens.muted),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              AppButton(
                key: const Key('reports_export_backup'),
                label: 'Создать копию',
                icon: Icons.backup_outlined,
                onPressed: busy ? null : onExportBackup,
              ),
              AppButton(
                key: const Key('reports_import_backup'),
                label: 'Восстановить из копии',
                icon: Icons.restore_outlined,
                variant: AppButtonVariant.secondary,
                onPressed: busy ? null : onImportBackup,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
