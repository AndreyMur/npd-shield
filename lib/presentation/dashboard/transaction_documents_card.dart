import 'package:flutter/material.dart';

import '../../core/constants/contract_field_keys.dart';
import '../../data/models/document.dart';
import '../../data/models/transaction.dart';
import '../../data/pdf/contract_pdf_font_loader.dart';
import '../../data/pdf/contract_pdf_share_service.dart';
import '../../data/pdf/document_pdf_service.dart';
import '../../data/pdf/generated_pdf.dart';
import '../../data/repositories/document_repository.dart';
import '../../data/repositories/transaction_repository.dart';
import '../../domain/documents/document_transaction_linker.dart';
import '../../domain/documents/document_transaction_matcher.dart';
import '../../domain/documents/receipt.dart';
import '../documents/document_details_sheet.dart';

/// Список последних транзакций дашборда с индикацией привязанных документов.
///
/// Документы сопоставляются с транзакциями автоматически (по явной привязке
/// или по сумме, дате и контрагенту). Рядом с транзакцией показывается значок
/// документа; нажатие открывает карточку документа (issue 96 и 97).
class TransactionDocumentsCard extends StatefulWidget {
  final TransactionRepository transactionRepository;
  final DocumentRepository documentRepository;

  /// Генератор PDF-версии документа (для тестов). По умолчанию — встроенный.
  final DocumentPdfGenerator? pdfGenerator;

  /// Сервис шаринга и сохранения PDF (по умолчанию — системный).
  final ContractPdfShareService? shareService;

  /// Загрузчик шрифтов Roboto для PDF (по умолчанию — из Assets).
  final ContractPdfFontLoader? fontLoader;

  /// Сфера, по которой фильтруются транзакции. `null` — все сферы.
  final TransactionSphere? sphere;

  /// «Сейчас» для стабильности тестов.
  final DateTime? now;

  /// Сколько последних транзакций показывать.
  final int maxItems;

  /// Сервис автоматической привязки документов к транзакциям.
  final DocumentTransactionLinker linker;

  const TransactionDocumentsCard({
    super.key,
    required this.transactionRepository,
    required this.documentRepository,
    this.pdfGenerator,
    this.shareService,
    this.fontLoader,
    this.sphere,
    this.now,
    this.maxItems = 10,
    this.linker = const DocumentTransactionLinker(),
  });

  @override
  State<TransactionDocumentsCard> createState() =>
      _TransactionDocumentsCardState();
}

class _TransactionDocumentsCardState extends State<TransactionDocumentsCard> {
  late final ContractPdfShareService _shareService;
  late final DocumentPdfService _pdfService;

  List<TransactionDocumentMatch> _matches = [];
  bool _loading = true;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _shareService = widget.shareService ?? const ContractPdfShareService();
    _pdfService = DocumentPdfService(
      fontLoader: widget.fontLoader ?? const ContractPdfFontLoader(),
    );
    _load();
  }

  @override
  void didUpdateWidget(covariant TransactionDocumentsCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.sphere != widget.sphere || oldWidget.now != widget.now) {
      _load();
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final transactions = await _loadTransactions();
      var documents = await widget.documentRepository.getAll();

      final linked = await widget.linker.link(
        documentRepository: widget.documentRepository,
        transactions: transactions,
        documents: documents,
      );
      if (linked > 0) {
        documents = await widget.documentRepository.getAll();
      }

      if (!mounted) return;
      setState(() {
        _matches = matchDocumentsToTransactions(
          transactions: transactions,
          documents: documents,
        );
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

  Future<List<Transaction>> _loadTransactions() async {
    final sphere = widget.sphere;
    final transactions = sphere == null
        ? await widget.transactionRepository.getAll()
        : await widget.transactionRepository.getAllForSphere(sphere);
    final sorted = List<Transaction>.of(transactions)
      ..sort((a, b) => b.date.compareTo(a.date));
    return sorted;
  }

  Future<GeneratedPdf> _generatePdf(Document document) {
    final generator = widget.pdfGenerator;
    if (generator != null) return generator(document);
    return _pdfService.generate(document);
  }

  Future<void> _openDocuments(TransactionDocumentMatch match) async {
    final documents = match.documents;
    if (documents.isEmpty) return;
    if (documents.length == 1) {
      await _openDetails(documents.first);
      return;
    }
    final selected = await showModalBottomSheet<Document>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Text(
                'Документы по сделке',
                style: Theme.of(sheetContext).textTheme.titleMedium,
              ),
            ),
            for (final document in documents)
              ListTile(
                key: Key('transaction_document_option_${document.id}'),
                leading: Icon(_iconFor(document.type)),
                title: Text(document.type.label),
                subtitle: Text(
                  '${formatReceiptAmount(document.amount)} · '
                  '${formatContractDate(document.date)}',
                ),
                onTap: () => Navigator.of(sheetContext).pop(document),
              ),
          ],
        ),
      ),
    );
    if (selected != null) await _openDetails(selected);
  }

  Future<void> _openDetails(Document document) async {
    await showDocumentDetailsSheet(
      context,
      document: document,
      pdfGenerator: _generatePdf,
      shareService: _shareService,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final visible = _matches.take(widget.maxItems).toList(growable: false);

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 12, 8, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  Text('Транзакции', style: theme.textTheme.titleLarge),
                  const Spacer(),
                  Text(
                    'документы отмечены значком',
                    style: theme.textTheme.labelSmall,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            if (_loading)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Не удалось загрузить транзакции',
                  key: const Key('transaction_documents_error'),
                  style: theme.textTheme.bodyMedium,
                ),
              )
            else if (visible.isEmpty)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Транзакций пока нет',
                  key: const Key('transaction_documents_empty'),
                  style: theme.textTheme.bodyMedium,
                ),
              )
            else
              for (final match in visible) _buildTile(theme, match),
            if (!_loading && _error == null && _matches.length > visible.length)
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
                child: Text(
                  'Показаны последние ${visible.length} транзакций',
                  style: theme.textTheme.labelSmall,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTile(ThemeData theme, TransactionDocumentMatch match) {
    final transaction = match.transaction;
    final client = transaction.clientName.trim();
    final documents = match.documents;

    return ListTile(
      key: Key('transaction_entry_${transaction.id}'),
      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
      leading: CircleAvatar(
        backgroundColor: theme.colorScheme.secondaryContainer,
        child: Icon(
          transaction.sphere == TransactionSphere.it
              ? Icons.code
              : Icons.local_shipping,
          size: 18,
          color: theme.colorScheme.onSecondaryContainer,
        ),
      ),
      title: Text(client.isEmpty ? 'Без контрагента' : client),
      subtitle: Text(
        '${formatContractDate(transaction.date)} · '
        '${formatReceiptAmount(transaction.amount)}',
      ),
      trailing: match.hasDocuments
          ? Tooltip(
              message: 'Открыть документ',
              child: Semantics(
                button: true,
                label: 'Документы: ${documents.length}',
                child: Container(
                  key: Key('transaction_document_badge_${transaction.id}'),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.receipt_long_outlined,
                        size: 16,
                        color: theme.colorScheme.primary,
                      ),
                      if (documents.length > 1) ...[
                        const SizedBox(width: 4),
                        Text(
                          '${documents.length}',
                          style: theme.textTheme.labelSmall!.copyWith(
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            )
          : null,
      onTap: match.hasDocuments ? () => _openDocuments(match) : null,
    );
  }

  static IconData _iconFor(DocumentType type) {
    return switch (type) {
      DocumentType.receipt => Icons.receipt_long_outlined,
      DocumentType.act => Icons.assignment_turned_in_outlined,
      DocumentType.contract => Icons.description_outlined,
    };
  }
}
