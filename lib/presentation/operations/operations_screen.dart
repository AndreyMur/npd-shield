import 'package:flutter/material.dart';

import '../../core/constants/contract_field_keys.dart';
import '../../data/models/transaction.dart';
import '../../data/repositories/client_repository.dart';
import '../../data/repositories/transaction_repository.dart';
import '../../domain/documents/receipt.dart';
import 'transaction_form_screen.dart';

/// Пресет периода для фильтра операций.
enum _PeriodPreset {
  all,
  month,
  year,
  custom;

  String get label => switch (this) {
    _PeriodPreset.all => 'Всё время',
    _PeriodPreset.month => 'Месяц',
    _PeriodPreset.year => 'Год',
    _PeriodPreset.custom => 'Свой период',
  };
}

/// Экран «Операции»: список доходов и расходов, фильтры (тип, сфера, период,
/// контрагент), поиск и итоги за период.
///
/// Операцию можно создать, отредактировать и удалить (с подтверждением и
/// отменой). Любое изменение пересчитывает список и итоги.
class OperationsScreen extends StatefulWidget {
  final TransactionRepository repository;

  /// Справочник клиентов. Если задан — контрагента можно выбрать из него.
  final ClientRepository? clientRepository;

  /// «Сейчас» для стабильности тестов.
  final DateTime? now;

  const OperationsScreen({
    super.key,
    required this.repository,
    this.clientRepository,
    this.now,
  });

  @override
  State<OperationsScreen> createState() => _OperationsScreenState();
}

class _OperationsScreenState extends State<OperationsScreen> {
  final _searchController = TextEditingController();

  List<Transaction> _transactions = [];
  PeriodSummary _summary = const PeriodSummary(income: 0, expense: 0);

  TransactionType? _typeFilter;
  TransactionSphere? _sphereFilter;
  String? _clientFilter;
  String _search = '';
  _PeriodPreset _period = _PeriodPreset.all;
  DateTimeRange? _customRange;

  bool _loading = true;
  Object? _error;

  DateTime get _now => widget.now ?? DateTime.now();

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

  DateTime? get _from {
    switch (_period) {
      case _PeriodPreset.all:
        return null;
      case _PeriodPreset.month:
        return DateTime(_now.year, _now.month);
      case _PeriodPreset.year:
        return DateTime(_now.year);
      case _PeriodPreset.custom:
        final start = _customRange?.start;
        return start == null ? null : DateTime(start.year, start.month, start.day);
    }
  }

  DateTime? get _to {
    switch (_period) {
      case _PeriodPreset.all:
        return null;
      case _PeriodPreset.month:
        return DateTime(_now.year, _now.month + 1);
      case _PeriodPreset.year:
        return DateTime(_now.year + 1);
      case _PeriodPreset.custom:
        final end = _customRange?.end;
        return end == null
            ? null
            : DateTime(end.year, end.month, end.day).add(const Duration(days: 1));
    }
  }

  Future<void> _reload() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final transactions = await widget.repository.getAll();
      final summary = await widget.repository.getPeriodSummary(
        from: _from,
        to: _to,
        sphere: _sphereFilter,
      );
      if (!mounted) return;
      setState(() {
        _transactions = transactions;
        _summary = summary;
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

  List<String> get _clientOptions {
    final names = <String>{};
    for (final transaction in _transactions) {
      final name = transaction.clientName.trim();
      if (name.isNotEmpty) names.add(name);
    }
    final sorted = names.toList()..sort();
    return sorted;
  }

  List<Transaction> get _visible {
    final filter = TransactionFilter(
      type: _typeFilter,
      sphere: _sphereFilter,
      from: _from,
      to: _to,
      search: _search,
    );
    final client = _clientFilter;
    final result = _transactions
        .where(filter.matches)
        .where((t) => client == null || t.clientName.trim() == client)
        .toList()
      ..sort((a, b) {
        final byDate = b.date.compareTo(a.date);
        return byDate != 0 ? byDate : b.id.compareTo(a.id);
      });
    return result;
  }

  Future<void> _openForm({Transaction? transaction}) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => TransactionFormScreen(
          repository: widget.repository,
          clientRepository: widget.clientRepository,
          transaction: transaction,
          now: widget.now,
        ),
      ),
    );
    if (changed == true) await _reload();
  }

  Future<void> _delete(Transaction transaction) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Удалить операцию?'),
        content: Text(
          '${transaction.type.label} на '
          '${formatReceiptAmount(transaction.amount)} будет удалена. '
          'Действие можно отменить сразу после удаления.',
        ),
        actions: [
          TextButton(
            key: const Key('operation_delete_cancel'),
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            key: const Key('operation_delete_confirm'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final deleted = await widget.repository.delete(transaction.id);
    if (!deleted || !mounted) return;
    await _reload();
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: const Text('Операция удалена'),
          action: SnackBarAction(
            label: 'Отменить',
            onPressed: () => _undoDelete(transaction),
          ),
        ),
      );
  }

  Future<void> _undoDelete(Transaction transaction) async {
    await widget.repository.add(transaction);
    await _reload();
  }

  Future<void> _pickCustomRange() async {
    final initial = _customRange ??
        DateTimeRange(
          start: DateTime(_now.year, _now.month),
          end: DateTime(_now.year, _now.month, _now.day),
        );
    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() {
      _customRange = picked;
      _period = _PeriodPreset.custom;
    });
    await _reload();
  }

  void _setType(TransactionType? type) {
    setState(() => _typeFilter = type);
  }

  void _setSphere(TransactionSphere? sphere) {
    setState(() => _sphereFilter = sphere);
    _reload();
  }

  void _setClient(String? client) {
    setState(() => _clientFilter = client);
  }

  Future<void> _setPeriod(_PeriodPreset period) async {
    setState(() => _period = period);
    await _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Операции')),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('operations_add_button'),
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add),
        label: const Text('Операция'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: _buildSearchField(),
          ),
          _buildTypeFilters(),
          _buildSphereFilters(),
          _buildPeriodRow(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: _buildClientFilter(),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: _buildSummary(),
          ),
          Expanded(child: _buildList()),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      key: const Key('operations_search_field'),
      controller: _searchController,
      onChanged: (value) => setState(() => _search = value),
      decoration: InputDecoration(
        hintText: 'Поиск по контрагенту, ИНН, категории, комментарию',
        prefixIcon: const Icon(Icons.search),
        border: const OutlineInputBorder(),
        suffixIcon: _search.isEmpty
            ? null
            : IconButton(
                key: const Key('operations_search_clear'),
                tooltip: 'Очистить поиск',
                icon: const Icon(Icons.close),
                onPressed: () {
                  _searchController.clear();
                  setState(() => _search = '');
                },
              ),
      ),
    );
  }

  Widget _buildTypeFilters() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _FilterChip(
            key: const Key('operation_type_filter_all'),
            label: 'Все типы',
            selected: _typeFilter == null,
            onSelected: () => _setType(null),
          ),
          for (final type in TransactionType.values)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: _FilterChip(
                key: Key('operation_type_filter_${type.name}'),
                label: type.label,
                selected: _typeFilter == type,
                onSelected: () => _setType(type),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSphereFilters() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        children: [
          _FilterChip(
            key: const Key('operation_sphere_filter_all'),
            label: 'Все сферы',
            selected: _sphereFilter == null,
            onSelected: () => _setSphere(null),
          ),
          for (final sphere in TransactionSphere.values)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: _FilterChip(
                key: Key('operation_sphere_filter_${sphere.name}'),
                label: sphere.label,
                selected: _sphereFilter == sphere,
                onSelected: () => _setSphere(sphere),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPeriodRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SegmentedButton<_PeriodPreset>(
                key: const Key('operation_period_selector'),
                showSelectedIcon: false,
                style: const ButtonStyle(
                  visualDensity: VisualDensity.compact,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                segments: [
                  for (final preset in [
                    _PeriodPreset.all,
                    _PeriodPreset.month,
                    _PeriodPreset.year,
                    _PeriodPreset.custom,
                  ])
                    ButtonSegment(value: preset, label: Text(preset.label)),
                ],
                selected: {_period},
                onSelectionChanged: (selection) {
                  final preset = selection.first;
                  if (preset == _PeriodPreset.custom) {
                    _pickCustomRange();
                  } else {
                    _setPeriod(preset);
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClientFilter() {
    final options = _clientOptions;
    final value = options.contains(_clientFilter) ? _clientFilter : null;
    return DropdownButtonFormField<String?>(
      key: const Key('operation_client_filter'),
      initialValue: value,
      decoration: const InputDecoration(
        labelText: 'Контрагент',
        border: OutlineInputBorder(),
        isDense: true,
      ),
      items: [
        const DropdownMenuItem<String?>(
          value: null,
          child: Text('Все контрагенты'),
        ),
        for (final name in options)
          DropdownMenuItem<String?>(value: name, child: Text(name)),
      ],
      onChanged: _setClient,
    );
  }

  Widget _buildSummary() {
    return Card(
      key: const Key('operations_summary'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _SummaryRow(
              label: 'Доход',
              value: _summary.income,
              color: _incomeColor(context),
              key: const Key('operations_summary_income'),
            ),
            const SizedBox(height: 8),
            _SummaryRow(
              label: 'Расход',
              value: _summary.expense,
              color: _expenseColor(context),
              key: const Key('operations_summary_expense'),
            ),
            const Divider(height: 20),
            _SummaryRow(
              label: 'Прибыль',
              value: _summary.profit,
              color: _profitColor(context, _summary.profit),
              emphasized: true,
              key: const Key('operations_summary_profit'),
            ),
          ],
        ),
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
            const Text('Не удалось загрузить операции'),
            const SizedBox(height: 12),
            OutlinedButton(
              key: const Key('operations_retry'),
              onPressed: _reload,
              child: const Text('Повторить'),
            ),
          ],
        ),
      );
    }
    final visible = _visible;
    if (visible.isEmpty) {
      return Center(
        child: Text(
          _transactions.isEmpty ? 'Операций пока нет' : 'Ничего не найдено',
          key: const Key('operations_empty'),
        ),
      );
    }
    return ListView.builder(
      key: const Key('operations_list'),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 88),
      itemCount: visible.length,
      itemBuilder: (context, index) => _buildTile(visible[index]),
    );
  }

  Widget _buildTile(Transaction transaction) {
    final theme = Theme.of(context);
    final isIncome = transaction.type.isIncome;
    final color = isIncome ? _incomeColor(context) : _expenseColor(context);
    final client = transaction.clientName.trim();
    final subtitleParts = <String>[
      formatContractDate(transaction.date),
      transaction.sphere.label,
      if (transaction.category.trim().isNotEmpty) transaction.category.trim(),
    ];

    return Card(
      key: Key('operation_entry_${transaction.id}'),
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.12),
          child: Icon(
            isIncome ? Icons.trending_up : Icons.trending_down,
            color: color,
          ),
        ),
        title: Text(client.isEmpty ? 'Без контрагента' : client),
        subtitle: Text(subtitleParts.join(' · ')),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${isIncome ? '+' : '−'}${formatReceiptAmount(transaction.amount)}',
              key: Key('operation_amount_${transaction.id}'),
              style: theme.textTheme.titleMedium!.copyWith(color: color),
            ),
            IconButton(
              key: Key('operation_delete_${transaction.id}'),
              tooltip: 'Удалить операцию',
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _delete(transaction),
            ),
          ],
        ),
        onTap: () => _openForm(transaction: transaction),
      ),
    );
  }
}

Color _incomeColor(BuildContext context) => const Color(0xFF2E7D32);

Color _expenseColor(BuildContext context) => Theme.of(context).colorScheme.error;

Color _profitColor(BuildContext context, double profit) =>
    profit < 0 ? Theme.of(context).colorScheme.error : const Color(0xFF2E7D32);

class _SummaryRow extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  final bool emphasized;

  const _SummaryRow({
    super.key,
    required this.label,
    required this.value,
    required this.color,
    this.emphasized = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: emphasized
              ? theme.textTheme.titleMedium
              : theme.textTheme.bodyMedium,
        ),
        Text(
          formatReceiptAmount(value),
          style: (emphasized
                  ? theme.textTheme.titleLarge
                  : theme.textTheme.titleMedium)!
              .copyWith(color: color),
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onSelected;

  const _FilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
    );
  }
}
