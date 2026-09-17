import 'package:flutter/material.dart';

import '../../core/constants/contract_field_keys.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/widgets.dart';
import '../../data/models/client.dart';
import '../../data/models/document.dart';
import '../../data/models/transaction.dart';
import '../../data/repositories/client_repository.dart';
import '../../data/repositories/document_repository.dart';
import '../../data/repositories/transaction_repository.dart';
import '../../domain/documents/my_tax_deep_link.dart';
import '../../domain/documents/receipt.dart';
import 'client_form_screen.dart';

/// Карточка клиента: реквизиты, история операций и документов.
///
/// Связанные операции и документы выбираются по идентификатору клиента
/// (`clientId`), поэтому переживают редактирование карточки. Карточку можно
/// отредактировать прямо отсюда.
class ClientDetailsScreen extends StatefulWidget {
  final Client client;
  final ClientRepository clientRepository;
  final TransactionRepository transactionRepository;
  final DocumentRepository documentRepository;

  const ClientDetailsScreen({
    super.key,
    required this.client,
    required this.clientRepository,
    required this.transactionRepository,
    required this.documentRepository,
  });

  @override
  State<ClientDetailsScreen> createState() => _ClientDetailsScreenState();
}

class _ClientDetailsScreenState extends State<ClientDetailsScreen> {
  late Client _client;

  List<Transaction> _transactions = [];
  List<Document> _documents = [];
  bool _loading = true;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _client = widget.client;
    _reload();
  }

  Future<void> _reload() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final transactions = await widget.transactionRepository.getAll(
        filter: TransactionFilter(clientId: _client.id),
      );
      final documents = await widget.documentRepository.getByClientId(
        _client.id,
      );
      transactions.sort((a, b) {
        final byDate = b.date.compareTo(a.date);
        return byDate != 0 ? byDate : b.id.compareTo(a.id);
      });
      if (!mounted) return;
      setState(() {
        _transactions = transactions;
        _documents = documents;
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

  Future<void> _edit() async {
    final updated = await Navigator.of(context).push<Client>(
      MaterialPageRoute(
        builder: (_) => ClientFormScreen(
          repository: widget.clientRepository,
          client: _client,
        ),
      ),
    );
    if (updated == null || !mounted) return;
    setState(() => _client = updated);
    await _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Карточка клиента'),
        actions: [
          IconButton(
            key: const Key('client_details_edit'),
            tooltip: 'Редактировать',
            icon: const Icon(Icons.edit_outlined),
            onPressed: _edit,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.sm,
          AppSpacing.md,
          AppSpacing.lg,
        ),
        children: [
          _buildInfoCard(),
          const SizedBox(height: AppSpacing.lg),
          _buildOperationsSection(),
          const SizedBox(height: AppSpacing.lg),
          _buildDocumentsSection(),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    final theme = Theme.of(context);
    final details = <String, String>{
      'Тип': _client.type.label,
      if (_client.inn.trim().isNotEmpty) 'ИНН': _client.inn.trim(),
      if (_client.contacts.trim().isNotEmpty)
        'Контакты': _client.contacts.trim(),
      if (_client.notes.trim().isNotEmpty) 'Заметки': _client.notes.trim(),
    };

    final tokens = AppTokens.of(context);
    final isLegal = _client.type == ClientType.legal;
    final accent = isLegal ? tokens.primary : tokens.sphereLogistics;
    return AppCard(
      semanticLabel: 'Карточка клиента ${_client.name}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: accent.withValues(alpha: 0.12),
                child: Icon(
                  isLegal ? Icons.business_outlined : Icons.person_outline,
                  color: accent,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  _client.name,
                  key: const Key('client_details_name'),
                  style: theme.textTheme.titleLarge,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final entry in details.entries)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 90,
                    child: Text(
                      entry.key,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: tokens.muted,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      entry.value,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildOperationsSection() {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Операции', style: theme.textTheme.titleMedium),
        const SizedBox(height: AppSpacing.xs),
        if (_loading)
          const AppLoadingState(
            itemCount: 2,
            semanticLabel: 'Загрузка операций клиента',
          )
        else if (_error != null)
          AppErrorState(
            message: 'Не удалось загрузить историю',
            retryKey: const Key('client_details_retry'),
            onRetry: _reload,
          )
        else if (_transactions.isEmpty)
          const AppEmptyState(
            key: Key('client_details_operations_empty'),
            compact: true,
            icon: Icons.receipt_long_outlined,
            title: 'Операций с этим клиентом пока нет',
          )
        else
          for (final transaction in _transactions)
            _TransactionTile(transaction: transaction),
      ],
    );
  }

  Widget _buildDocumentsSection() {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Документы', style: theme.textTheme.titleMedium),
        const SizedBox(height: AppSpacing.xs),
        if (_loading)
          const SizedBox.shrink()
        else if (_error != null)
          const SizedBox.shrink()
        else if (_documents.isEmpty)
          const AppEmptyState(
            key: Key('client_details_documents_empty'),
            compact: true,
            icon: Icons.description_outlined,
            title: 'Документов по этому клиенту пока нет',
          )
        else
          for (final document in _documents) _DocumentTile(document: document),
      ],
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final Transaction transaction;

  const _TransactionTile({required this.transaction});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = AppTokens.of(context);
    final isIncome = transaction.type.isIncome;
    final color = isIncome ? tokens.success : tokens.destructive;
    final subtitle = [
      formatContractDate(transaction.date),
      transaction.sphere.label,
      if (transaction.category.trim().isNotEmpty)
        transaction.category.trim(),
    ].join(' · ');
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: AppCard(
        key: Key('client_details_operation_${transaction.id}'),
        semanticLabel:
            '${isIncome ? 'Доход' : 'Расход'} '
            '${formatReceiptAmount(transaction.amount)}. $subtitle',
        child: Row(
          children: [
            Icon(
              isIncome ? Icons.trending_up : Icons.trending_down,
              color: color,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${isIncome ? '+' : '−'}${formatReceiptAmount(transaction.amount)}',
                    style: theme.textTheme.titleMedium!.copyWith(color: color),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: tokens.muted,
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

class _DocumentTile extends StatelessWidget {
  final Document document;

  const _DocumentTile({required this.document});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = AppTokens.of(context);
    final subtitle = [
      formatContractDate(document.date),
      if (document.contractNumber.trim().isNotEmpty)
        '№ ${document.contractNumber.trim()}',
    ].join(' · ');
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: AppCard(
        key: Key('client_details_document_${document.id}'),
        semanticLabel:
            '${document.type.label} '
            '${formatReceiptAmount(document.amount)}. $subtitle',
        child: Row(
          children: [
            Icon(Icons.description_outlined, color: tokens.primary),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${document.type.label} · ${formatReceiptAmount(document.amount)}',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: tokens.muted,
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
