import 'package:flutter/material.dart';

import '../../core/constants/contract_field_keys.dart';
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
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          _buildInfoCard(),
          const SizedBox(height: 20),
          _buildOperationsSection(),
          const SizedBox(height: 20),
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

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  child: Icon(
                    _client.type == ClientType.legal
                        ? Icons.business_outlined
                        : Icons.person_outline,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _client.name,
                    key: const Key('client_details_name'),
                    style: theme.textTheme.titleLarge,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
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
                        style: theme.textTheme.bodyMedium!.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
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
      ),
    );
  }

  Widget _buildOperationsSection() {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Операции', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        if (_loading)
          const Center(child: Padding(
            padding: EdgeInsets.all(16),
            child: CircularProgressIndicator(),
          ))
        else if (_error != null)
          _ErrorBox(onRetry: _reload)
        else if (_transactions.isEmpty)
          _EmptyBox(
            key: const Key('client_details_operations_empty'),
            message: 'Операций с этим клиентом пока нет',
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
        const SizedBox(height: 8),
        if (_loading)
          const SizedBox.shrink()
        else if (_error != null)
          const SizedBox.shrink()
        else if (_documents.isEmpty)
          _EmptyBox(
            key: const Key('client_details_documents_empty'),
            message: 'Документов по этому клиенту пока нет',
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
    final isIncome = transaction.type.isIncome;
    final color = isIncome
        ? const Color(0xFF2E7D32)
        : theme.colorScheme.error;
    return Card(
      key: Key('client_details_operation_${transaction.id}'),
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(
          isIncome ? Icons.trending_up : Icons.trending_down,
          color: color,
        ),
        title: Text(
          '${isIncome ? '+' : '−'}${formatReceiptAmount(transaction.amount)}',
          style: theme.textTheme.titleMedium!.copyWith(color: color),
        ),
        subtitle: Text(
          [
            formatContractDate(transaction.date),
            transaction.sphere.label,
            if (transaction.category.trim().isNotEmpty)
              transaction.category.trim(),
          ].join(' · '),
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
    return Card(
      key: Key('client_details_document_${document.id}'),
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const Icon(Icons.description_outlined),
        title: Text(
          '${document.type.label} · ${formatReceiptAmount(document.amount)}',
        ),
        subtitle: Text(
          [
            formatContractDate(document.date),
            if (document.contractNumber.trim().isNotEmpty)
              '№ ${document.contractNumber.trim()}',
          ].join(' · '),
        ),
      ),
    );
  }
}

class _EmptyBox extends StatelessWidget {
  final String message;

  const _EmptyBox({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          message,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  final VoidCallback onRetry;

  const _ErrorBox({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text('Не удалось загрузить историю'),
            const SizedBox(height: 12),
            OutlinedButton(
              key: const Key('client_details_retry'),
              onPressed: onRetry,
              child: const Text('Повторить'),
            ),
          ],
        ),
      ),
    );
  }
}
