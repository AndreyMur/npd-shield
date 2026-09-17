import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../../core/theme/app_tokens.dart';
import '../../core/widgets/widgets.dart';
import '../../data/pdf/contract_pdf_service.dart';
import '../../data/pdf/contract_pdf_share_service.dart';

/// Результат действий пользователя в нижнем листе предпросмотра PDF.
enum ContractPdfPreviewResult {
  /// Пользователь поделился PDF через стандартные приложения.
  shared,

  /// Пользователь сохранил PDF-файл в документы.
  saved,

  /// Пользователь закрыл лист без действий.
  dismissed,
}

/// Показывает Bottom sheet предпросмотра готового PDF перед сохранением
/// и шарингом через стандартные приложения.
///
/// [previewBuilder] позволяет подменить реальный рендер PDF (использующий
/// плагин printing) в тестах.
Future<ContractPdfPreviewResult> showContractPdfPreviewSheet(
  BuildContext context, {
  required GeneratedContractPdf pdf,
  required ContractPdfShareService shareService,
  Widget Function()? previewBuilder,
}) async {
  final result = await showModalBottomSheet<ContractPdfPreviewResult>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => ContractPdfPreviewSheet(
      pdf: pdf,
      shareService: shareService,
      previewBuilder: previewBuilder,
    ),
  );
  return result ?? ContractPdfPreviewResult.dismissed;
}

/// Содержимое Bottom sheet: предпросмотр PDF и действия «Поделиться»
/// и «Сохранить PDF».
class ContractPdfPreviewSheet extends StatefulWidget {
  final GeneratedContractPdf pdf;
  final ContractPdfShareService shareService;
  final Widget Function()? previewBuilder;

  const ContractPdfPreviewSheet({
    super.key,
    required this.pdf,
    required this.shareService,
    this.previewBuilder,
  });

  @override
  State<ContractPdfPreviewSheet> createState() =>
      _ContractPdfPreviewSheetState();
}

class _ContractPdfPreviewSheetState extends State<ContractPdfPreviewSheet> {
  bool _busy = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pdf = widget.pdf;
    final sizeKb = (pdf.bytes.length / 1024).toStringAsFixed(1);

    return SafeArea(
      child: FractionallySizedBox(
        key: const Key('pdf_preview_sheet'),
        heightFactor: 0.95,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Предпросмотр PDF',
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 4),
              Text(
                '${pdf.fileName} · ${pdf.pageCount} стр. · $sizeKb КБ',
                key: const Key('pdf_file_info'),
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              Expanded(child: _buildPreview(theme)),
              const SizedBox(height: 12),
              if (_error != null) ...[
                Text(
                  _error!,
                  key: const Key('pdf_action_error'),
                  style: theme.textTheme.bodySmall!.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
                const SizedBox(height: 8),
              ],
              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      key: const Key('pdf_share_button'),
                      label: 'Поделиться',
                      icon: Icons.share_outlined,
                      onPressed: _busy ? null : _share,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: AppButton(
                      key: const Key('pdf_save_button'),
                      label: 'Сохранить PDF',
                      icon: Icons.save_alt_outlined,
                      variant: AppButtonVariant.secondary,
                      onPressed: _busy ? null : _save,
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

  Widget _buildPreview(ThemeData theme) {
    final builder = widget.previewBuilder;
    if (builder != null) return builder();
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
        ),
        child: PdfPreview(
          canChangeOrientation: false,
          canChangePageFormat: false,
          canDebug: false,
          allowPrinting: false,
          allowSharing: false,
          build: (_) async => widget.pdf.bytes,
        ),
      ),
    );
  }

  Future<void> _share() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.shareService.share(widget.pdf);
      if (!mounted) return;
      Navigator.of(context).pop(ContractPdfPreviewResult.shared);
    } on ContractPdfActionException catch (error) {
      _fail(error.message);
    } catch (_) {
      _fail('Не удалось поделиться PDF.');
    }
  }

  Future<void> _save() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.shareService.saveToDocuments(widget.pdf);
      if (!mounted) return;
      Navigator.of(context).pop(ContractPdfPreviewResult.saved);
    } on ContractPdfActionException catch (error) {
      _fail(error.message);
    } catch (_) {
      _fail('Не удалось сохранить PDF.');
    }
  }

  void _fail(String message) {
    if (!mounted) return;
    setState(() {
      _busy = false;
      _error = message;
    });
  }
}
