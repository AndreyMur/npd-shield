import 'package:flutter/material.dart';

import '../../core/theme/app_tokens.dart';
import '../../core/widgets/widgets.dart';
import '../../data/models/client.dart';
import '../../data/repositories/client_repository.dart';
import 'client_form_screen.dart';

/// Открывает выбор клиента из справочника и возвращает выбранного клиента.
///
/// Список поддерживает поиск по наименованию и ИНН. Из листа можно создать
/// нового клиента — он сразу возвращается как выбранный. `null` означает, что
/// пользователь закрыл лист, ничего не выбрав.
Future<Client?> showClientPicker(
  BuildContext context, {
  required ClientRepository repository,
  String title = 'Выбор клиента',
}) {
  return showModalBottomSheet<Client>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => _ClientPickerSheet(repository: repository, title: title),
  );
}

class _ClientPickerSheet extends StatefulWidget {
  final ClientRepository repository;
  final String title;

  const _ClientPickerSheet({required this.repository, required this.title});

  @override
  State<_ClientPickerSheet> createState() => _ClientPickerSheetState();
}

class _ClientPickerSheetState extends State<_ClientPickerSheet> {
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

  Future<void> _create() async {
    final created = await Navigator.of(context).push<Client>(
      MaterialPageRoute(
        builder: (_) => ClientFormScreen(repository: widget.repository),
      ),
    );
    if (created == null || !mounted) return;
    Navigator.of(context).pop(created);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = AppTokens.of(context);
    return FractionallySizedBox(
      heightFactor: 0.75,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Text(widget.title, style: theme.textTheme.titleLarge),
          ),
          const SizedBox(height: AppSpacing.sm),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: AppTextField(
              key: const Key('client_picker_search'),
              controller: _searchController,
              onChanged: (value) {
                _query = value;
                _reload();
              },
              hint: 'Поиск по наименованию и ИНН',
              prefixIcon: const Icon(Icons.search),
              dense: true,
              suffixIcon: _query.isEmpty
                  ? null
                  : IconButton(
                      key: const Key('client_picker_search_clear'),
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
          const SizedBox(height: AppSpacing.xs),
          Expanded(child: _buildList()),
          Divider(height: 1, color: tokens.border),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: AppButton(
              key: const Key('client_picker_create'),
              label: 'Новый клиент',
              icon: Icons.person_add_alt,
              variant: AppButtonVariant.secondary,
              expanded: true,
              onPressed: _create,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList() {
    if (_loading) {
      return const AppLoadingState(
        itemCount: 3,
        semanticLabel: 'Загрузка справочника',
      );
    }
    if (_error != null) {
      return AppErrorState(
        message: 'Не удалось загрузить справочник',
        retryKey: const Key('client_picker_retry'),
        onRetry: _reload,
      );
    }
    if (_clients.isEmpty) {
      final isEmpty = _query.isEmpty;
      return AppEmptyState(
        key: const Key('client_picker_empty'),
        icon: isEmpty ? Icons.people_outline : Icons.search_off,
        title: isEmpty ? 'Справочник пуст' : 'Ничего не найдено',
      );
    }
    return ListView.builder(
      key: const Key('client_picker_list'),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      itemCount: _clients.length,
      itemBuilder: (context, index) {
        final client = _clients[index];
        return ListTile(
          key: Key('client_picker_option_${client.id}'),
          leading: CircleAvatar(
            child: Icon(
              client.type.label == 'Физлицо'
                  ? Icons.person_outline
                  : Icons.business_outlined,
            ),
          ),
          title: Text(client.name),
          subtitle: Text(_subtitle(client)),
          onTap: () => Navigator.of(context).pop(client),
        );
      },
    );
  }

  String _subtitle(Client client) {
    final parts = <String>[client.type.label];
    if (client.inn.trim().isNotEmpty) parts.add('ИНН ${client.inn.trim()}');
    return parts.join(' · ');
  }
}
