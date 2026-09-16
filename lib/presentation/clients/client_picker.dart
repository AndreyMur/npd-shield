import 'package:flutter/material.dart';

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
    return FractionallySizedBox(
      heightFactor: 0.75,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(widget.title, style: theme.textTheme.titleLarge),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              key: const Key('client_picker_search'),
              controller: _searchController,
              onChanged: (value) {
                _query = value;
                _reload();
              },
              decoration: InputDecoration(
                hintText: 'Поиск по наименованию и ИНН',
                prefixIcon: const Icon(Icons.search),
                isDense: true,
                border: const OutlineInputBorder(),
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
          ),
          const SizedBox(height: 8),
          Expanded(child: _buildList()),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: OutlinedButton.icon(
              key: const Key('client_picker_create'),
              onPressed: _create,
              icon: const Icon(Icons.person_add_alt),
              label: const Text('Новый клиент'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Не удалось загрузить справочник'),
            const SizedBox(height: 12),
            OutlinedButton(
              key: const Key('client_picker_retry'),
              onPressed: _reload,
              child: const Text('Повторить'),
            ),
          ],
        ),
      );
    }
    if (_clients.isEmpty) {
      return Center(
        child: Text(
          _query.isEmpty ? 'Справочник пуст' : 'Ничего не найдено',
          key: const Key('client_picker_empty'),
        ),
      );
    }
    return ListView.builder(
      key: const Key('client_picker_list'),
      padding: const EdgeInsets.symmetric(horizontal: 8),
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
