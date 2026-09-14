import 'package:flutter/material.dart';

import '../../core/constants/contract_field_keys.dart';
import '../../data/models/document.dart';
import '../../data/pdf/contract_pdf_share_service.dart';
import '../../data/pdf/document_pdf_service.dart';
import '../../domain/documents/receipt.dart';

/// Показывает Bottom sheet с деталями документа архива и действиями.
///
/// Возвращает `true`, если документ был удалён (родительский экран должен
/// обновить список), и `false` во всех остальных случаях.
Future<bool> showDocumentDetailsSheet(
  BuildContext context, {
  required Document document,
  required DocumentPdfGenerator pdfGenerator,
  required ContractPdfShareService shareService,
  Future<void> Function()? onDelete,
}) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => DocumentDetailsSheet(
      document: document,
      pdfGenerator: pdfGenerator,
      shareService: shareService,
      onDelete: onDelete,
    ),
  );
  return result ?? false;
}

/// Содержимое Bottom sheet: детали документа и кнопки «Отправить»,
/// «Скачать PDF» и «Удалить».
class DocumentDetailsSheet extends StatefulWidget {
  final Document document;

  /// Генератор PDF-версии документа (по типу документа).
  final DocumentPdfGenerator pdfGenerator;

  /// Сервис шаринга и сохранения PDF.
  final ContractPdfShareService shareService;

  /// Удаление документа. Если не задано, кнопка «Удалить» не показывается.
  final Future<void> Function()? onDelete;

  const DocumentDetailsSheet({
    super.key,
    required this.document,
    required this.pdfGenerator,
    required this.shareService,
    this.onDelete,
  });

  @override
  State<DocumentDetailsSheet> createState() => _DocumentDetailsSheetState();
}

class _DocumentDetailsSheetState extends State<DocumentDetailsSheet> {
  bool _busy = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final document = widget.document;
    final isAct = document.type == DocumentType.act;

    return SafeArea(
      child: FractionallySizedBox(
        key: const Key('document_details_sheet'),
        heightFactor: 0.9,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _iconFor(document.type),
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            document.type.label,
                            key: const Key('document_sheet_title'),
                            style: theme.textTheme.titleLarge,
                          ),
                        ),
                        _StatusChip(status: document.status),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      formatReceiptAmount(document.amount),
                      style: theme.textTheme.headlineSmall,
                    ),
                    const Divider(height: 24),
                    _DetailRow(
                      label: 'Контрагент',
                      value: document.counterpartyName,
                    ),
                    _DetailRow(
                      label: 'ИНН',
                      value: document.counterpartyInn,
                    ),
                    _DetailRow(
                      label: 'Дата',
                      value: formatContractDate(document.date),
                    ),
                    _DetailRow(
                      label: 'Номер договора',
                      value: document.contractNumber,
                    ),
                    _DetailRow(
                      label: 'Услуга',
                      value: document.serviceName,
                    ),
                    if (isAct)
                      _DetailRow(
                        label: 'Результат работ',
                        value: document.result,
                      ),
                    if (isAct)
                      _DetailRow(
                        label: 'Подпись исполнителя',
                        value: document.executorSignatory,
                      ),
                    if (isAct)
                      _DetailRow(
                        label: 'Подпись заказчика',
                        value: document.customerSignatory,
                      ),
                    _DetailRow(
                      label: 'Создан',
                      value: formatContractDate(document.createdAt),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Документ не имеет юридической силы без усиленной '
                      'электронной подписи.',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(
                  _error!,
                  key: const Key('document_sheet_error'),
                  style: theme.textTheme.bodySmall!.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      key: const Key('document_send_button'),
                      onPressed: _busy ? null : _send,
                      icon: const Icon(Icons.send_outlined),
                      label: const Text('Отправить'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      key: const Key('document_download_button'),
                      onPressed: _busy ? null : _download,
                      icon: const Icon(Icons.download_outlined),
                      label: const Text('Скачать PDF'),
                    ),
                  ),
                ],
              ),
              if (widget.onDelete != null) ...[
                const SizedBox(height: 4),
                TextButton.icon(
                  key: const Key('document_delete_button'),
                  onPressed: _busy ? null : _delete,
                  style: TextButton.styleFrom(
                    foregroundColor: theme.colorScheme.error,
                  ),
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Удалить'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _send() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final pdf = await widget.pdfGenerator(widget.document);
      await widget.shareService.share(pdf);
      if (!mounted) return;
      Navigator.of(context).pop(false);
    } on DocumentPdfUnsupportedException catch (error) {
      _fail(error.message);
    } on ContractPdfActionException catch (error) {
      _fail(error.message);
    } catch (_) {
      _fail('Не удалось отправить документ.');
    }
  }

  Future<void> _download() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final pdf = await widget.pdfGenerator(widget.document);
      final path = await widget.shareService.saveToDocuments(pdf);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('PDF сохранён: $path')));
      Navigator.of(context).pop(false);
    } on DocumentPdfUnsupportedException catch (error) {
      _fail(error.message);
    } on ContractPdfActionException catch (error) {
      _fail(error.message);
    } catch (_) {
      _fail('Не удалось сохранить PDF.');
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Удалить документ?'),
        content: const Text('Действие нельзя отменить.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            key: const Key('document_delete_confirm'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.onDelete?.call();
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (_) {
      _fail('Не удалось удалить документ.');
    }
  }

  void _fail(String message) {
    if (!mounted) return;
    setState(() {
      _busy = false;
      _error = message;
    });
  }

  static IconData _iconFor(DocumentType type) {
    return switch (type) {
      DocumentType.receipt => Icons.receipt_long_outlined,
      DocumentType.act => Icons.assignment_turned_in_outlined,
      DocumentType.contract => Icons.description_outlined,
    };
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final shown = value.trim().isEmpty ? '—' : value.trim();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium!.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(shown, style: theme.textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final DocumentStatus status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = switch (status) {
      DocumentStatus.draft => theme.colorScheme.outline,
      DocumentStatus.generated => theme.colorScheme.primary,
      DocumentStatus.sent => theme.colorScheme.tertiary,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        status.label,
        style: theme.textTheme.labelSmall?.copyWith(color: color),
      ),
    );
  }
}
