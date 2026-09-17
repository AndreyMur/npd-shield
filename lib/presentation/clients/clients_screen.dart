import 'package:flutter/material.dart';

import '../../core/theme/app_tokens.dart';
import '../../core/widgets/widgets.dart';
import '../../data/models/client.dart';
import '../../data/repositories/client_repository.dart';
import '../../data/repositories/document_repository.dart';
import '../../data/repositories/transaction_repository.dart';
import '../../domain/documents/my_tax_deep_link.dart';
import 'client_details_screen.dart';
import 'client_form_screen.dart';

/// Экран справочника клиентов: список, поиск, создание, редактирование и
/// удаление карточек с подтверждением.
///
/// По нажатию открывается [ClientDetailsScreen] с историей операций и
/// документов. Удаление можно отменить сразу после подтверждения.
class ClientsScreen extends StatefulWidget {
  final ClientRepository repository;
  final TransactionRepository transactionRepository;
  final DocumentRepository documentRepository;

  const ClientsScreen({
    super.key,
    required this.repository,
    required this.transactionRepository,
    required this.documentRepository,
  });

  @override
  State<ClientsScreen> createState() => _ClientsScreenState();
}

class _ClientsScreenState extends State<ClientsScreen> {
  final _searchController = TextEditingController();

  List<Client> _clients = [];
  bool _loading = true;
  Object? _error;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final clients = await widget.repository.getAll(search: _query);
      if (!mounted) return;
      setState(() {
        _clients = clients;
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

  Future<void> _openForm({Client? client}) async {
    final saved = await Navigator.of(context).push<Client>(
      MaterialPageRoute(
        builder: (_) => ClientFormScreen(
          repository: widget.repository,
          client: client,
        ),
      ),
    );
    if (saved != null) await _reload();
  }

  Future<void> _openDetails(Client client) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => ClientDetailsScreen(
          client: client,
          clientRepository: widget.repository,
          transactionRepository: widget.transactionRepository,
          documentRepository: widget.documentRepository,
        ),
      ),
    );
    if (mounted) await _reload();
  }

  Future<void> _delete(Client client) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Удалить клиента?'),
        content: Text(
          'Карточка «${client.name}» будет удалена. '
          'Связанные операции и документы сохранятся. '
          'Действие можно отменить сразу после удаления.',
        ),
        actions: [
          TextButton(
            key: const Key('client_delete_cancel'),
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            key: const Key('client_delete_confirm'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final deleted = await widget.repository.delete(client.id);
    if (!deleted || !mounted) return;
    await _reload();
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: const Text('Клиент удалён'),
          action: SnackBarAction(
            label: 'Отменить',
            onPressed: () => _undoDelete(client),
          ),
        ),
      );
  }

  Future<void> _undoDelete(Client client) async {
    await widget.repository.add(client);
    await _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Клиенты')),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('clients_add_button'),
        onPressed: () => _openForm(),
        icon: const Icon(Icons.person_add_alt),
        label: const Text('Клиент'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.md,
              AppSpacing.xs,
            ),
            child: AppTextField(
              key: const Key('clients_search_field'),
              controller: _searchController,
              onChanged: (value) {
                _query = value;
                _reload();
              },
              hint: 'Поиск по наименованию и ИНН',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _query.isEmpty
                  ? null
                  : IconButton(
                      key: const Key('clients_search_clear'),
                      tooltip: 'Очистить поиск',
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        _searchController.clear();
                        _query = '';
                        _reload();
                      },
                    ),
            ),
          ),
          Expanded(child: _buildList()),
        ],
      ),
    );
  }

  Widget _buildList() {
    if (_loading) {
      return const AppLoadingState(semanticLabel: 'Загрузка клиентов');
    }
    if (_error != null) {
      return AppErrorState(
        message: 'Не удалось загрузить справочник',
        retryKey: const Key('clients_retry'),
        onRetry: _reload,
      );
    }
    if (_clients.isEmpty) {
      final isEmpty = _query.isEmpty;
      return AppEmptyState(
        key: const Key('clients_empty'),
        icon: isEmpty ? Icons.people_outline : Icons.search_off,
        title: isEmpty ? 'Клиентов пока нет' : 'Ничего не найдено',
        message: isEmpty
            ? 'Добавьте первого клиента, чтобы связывать с ним операции и документы.'
            : null,
      );
    }
    return ListView.builder(
      key: const Key('clients_list'),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        0,
        AppSpacing.md,
        88,
      ),
      itemCount: _clients.length,
      itemBuilder: (context, index) => _buildTile(_clients[index]),
    );
  }

  Widget _buildTile(Client client) {
    final theme = Theme.of(context);
    final tokens = AppTokens.of(context);
    final isLegal = client.type == ClientType.legal;
    final accent = isLegal ? tokens.primary : tokens.sphereLogistics;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: AppCard(
        key: Key('client_entry_${client.id}'),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.sm,
          AppSpacing.sm,
          AppSpacing.xxs,
          AppSpacing.sm,
        ),
        semanticLabel: '${client.name}. ${_subtitle(client)}',
        onTap: () => _openDetails(client),
        child: Row(
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(client.name, style: theme.textTheme.titleMedium),
                  const SizedBox(height: 2),
                  Text(
                    _subtitle(client),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: tokens.muted,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              key: Key('client_delete_${client.id}'),
              tooltip: 'Удалить клиента',
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _delete(client),
            ),
          ],
        ),
      ),
    );
  }

  String _subtitle(Client client) {
    final parts = <String>[client.type.label];
    if (client.inn.trim().isNotEmpty) parts.add('ИНН ${client.inn.trim()}');
    return parts.join(' · ');
  }
}
