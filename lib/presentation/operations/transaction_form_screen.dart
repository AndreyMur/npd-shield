import 'package:flutter/material.dart';

import '../../core/constants/contract_field_keys.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/widgets.dart';
import '../../data/models/transaction.dart';
import '../../data/repositories/client_repository.dart';
import '../../data/repositories/transaction_repository.dart';
import '../../domain/documents/receipt.dart';
import '../clients/client_picker.dart';

/// Форма создания и редактирования операции (дохода или расхода).
///
/// Поля: тип, сумма, дата, сфера деятельности, категория, контрагент и
/// комментарий. Сумма и дата валидируются; сфера выбирается сегментами.
/// При сохранении операция записывается в репозиторий, а экран возвращает
/// `true`, чтобы вызывающий список обновился.
class TransactionFormScreen extends StatefulWidget {
  final TransactionRepository repository;

  /// Справочник клиентов. Если задан — контрагента можно выбрать из него.
  final ClientRepository? clientRepository;

  /// Редактируемая операция. `null` — создание новой.
  final Transaction? transaction;

  /// «Сейчас» для стабильности тестов.
  final DateTime? now;

  const TransactionFormScreen({
    super.key,
    required this.repository,
    this.clientRepository,
    this.transaction,
    this.now,
  });

  @override
  State<TransactionFormScreen> createState() => _TransactionFormScreenState();
}

class _TransactionFormScreenState extends State<TransactionFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _amountController;
  late final TextEditingController _dateController;
  late final TextEditingController _categoryController;
  late final TextEditingController _clientNameController;
  late final TextEditingController _clientInnController;
  late final TextEditingController _commentController;

  late TransactionType _type;
  late TransactionSphere _sphere;
  DateTime _date = DateTime.now();

  /// Идентификатор клиента, выбранного из справочника; `null` — контрагент
  /// введён вручную или не указан.
  int? _selectedClientId;
  bool _saving = false;

  bool get _isEditing => widget.transaction != null;

  @override
  void initState() {
    super.initState();
    final transaction = widget.transaction;
    final now = widget.now ?? DateTime.now();

    _type = transaction?.type ?? TransactionType.income;
    _sphere = transaction?.sphere ?? TransactionSphere.it;
    _date = transaction?.date ?? now;
    _selectedClientId = transaction?.clientId;

    _amountController = TextEditingController(
      text: transaction == null || transaction.amount == 0
          ? ''
          : transaction.amount.toStringAsFixed(2).replaceAll('.', ','),
    );
    _dateController = TextEditingController(text: formatContractDate(_date));
    _categoryController = TextEditingController(text: transaction?.category ?? '');
    _clientNameController =
        TextEditingController(text: transaction?.clientName ?? '');
    _clientInnController =
        TextEditingController(text: transaction?.clientInn ?? '');
    _commentController = TextEditingController(text: transaction?.comment ?? '');
  }

  @override
  void dispose() {
    _amountController.dispose();
    _dateController.dispose();
    _categoryController.dispose();
    _clientNameController.dispose();
    _clientInnController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() {
      _date = picked;
      _dateController.text = formatContractDate(picked);
    });
  }

  Future<void> _save() async {
    if (_saving) return;
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final transaction = Transaction(
      amount: parseReceiptAmount(_amountController.text),
      date: _date,
      sphere: _sphere,
      type: _type,
      category: _categoryController.text.trim(),
      clientName: _clientNameController.text.trim(),
      clientInn: _clientInnController.text.trim(),
      clientId: _selectedClientId,
      comment: _commentController.text.trim(),
    );

    try {
      final existing = widget.transaction;
      if (existing != null) {
        transaction.id = existing.id;
        await widget.repository.update(transaction);
      } else {
        await widget.repository.add(transaction);
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Не удалось сохранить операцию')),
        );
    }
  }

  Future<void> _pickClient() async {
    final repository = widget.clientRepository;
    if (repository == null) return;
    final client = await showClientPicker(context, repository: repository);
    if (client == null || !mounted) return;
    setState(() {
      _selectedClientId = client.id;
      _clientNameController.text = client.name;
      _clientInnController.text = client.inn;
    });
  }

  /// Сбрасывает связь со справочником при ручном изменении контрагента.
  void _clearClientSelection() {
    if (_selectedClientId == null) return;
    setState(() => _selectedClientId = null);
  }

  String? _amountValidator(String? value) {
    final amount = parseReceiptAmount(value ?? '');
    if (amount <= 0) return 'Укажите сумму больше нуля';
    return null;
  }

  String? _dateValidator(String? value) {
    if (parseContractDate(value ?? '') == null) {
      return 'Укажите дату в формате ДД.ММ.ГГГГ';
    }
    return null;
  }

  Widget _buildClientPickerRow() {
    final selected = _selectedClientId != null;
    return Row(
      children: [
        Expanded(
          child: AppButton(
            key: const Key('transaction_pick_client_button'),
            label: selected
                ? 'Клиент из справочника'
                : 'Выбрать из справочника',
            icon: Icons.people_outline,
            variant: AppButtonVariant.secondary,
            onPressed: _pickClient,
          ),
        ),
        if (selected)
          IconButton(
            key: const Key('transaction_clear_client_button'),
            tooltip: 'Отвязать клиента',
            icon: const Icon(Icons.close),
            onPressed: () => setState(() => _selectedClientId = null),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = AppTokens.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Операция' : 'Новая операция'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            Text('Тип операции', style: theme.textTheme.titleMedium),
            const SizedBox(height: AppSpacing.xs),
            AppSegmentedControl<TransactionType>(
              key: const Key('transaction_type_selector'),
              semanticLabel: 'Тип операции',
              selected: _type,
              onChanged: (type) => setState(() => _type = type),
              segments: [
                for (final type in TransactionType.values)
                  AppSegmentOption(
                    value: type,
                    label: type.label,
                    icon: type.isIncome
                        ? Icons.trending_up
                        : Icons.trending_down,
                    accent: type.isIncome
                        ? tokens.success
                        : tokens.destructive,
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            AppTextFormField(
              key: const Key('transaction_amount_field'),
              controller: _amountController,
              validator: _amountValidator,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              label: 'Сумма, ₽',
              hint: 'Например, 15000',
            ),
            const SizedBox(height: AppSpacing.sm),
            AppTextFormField(
              key: const Key('transaction_date_field'),
              controller: _dateController,
              validator: _dateValidator,
              label: 'Дата',
              hint: 'ДД.ММ.ГГГГ',
              suffixIcon: IconButton(
                key: const Key('transaction_date_picker'),
                tooltip: 'Выбрать дату',
                icon: const Icon(Icons.calendar_today_outlined),
                onPressed: _pickDate,
              ),
              onChanged: (value) {
                final parsed = parseContractDate(value);
                if (parsed != null) setState(() => _date = parsed);
              },
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('Сфера деятельности', style: theme.textTheme.titleMedium),
            const SizedBox(height: AppSpacing.xs),
            AppSegmentedControl<TransactionSphere>(
              key: const Key('transaction_sphere_selector'),
              semanticLabel: 'Сфера деятельности',
              selected: _sphere,
              onChanged: (sphere) => setState(() => _sphere = sphere),
              segments: [
                for (final sphere in TransactionSphere.values)
                  AppSegmentOption(
                    value: sphere,
                    label: sphere.label,
                    icon: sphere == TransactionSphere.it
                        ? Icons.code
                        : Icons.local_shipping,
                    accent: sphere == TransactionSphere.it
                        ? tokens.sphereIt
                        : tokens.sphereLogistics,
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            AppTextFormField(
              key: const Key('transaction_category_field'),
              controller: _categoryController,
              textCapitalization: TextCapitalization.sentences,
              label: 'Категория',
              hint: 'Например, Материалы',
            ),
            if (widget.clientRepository != null) ...[
              const SizedBox(height: AppSpacing.xs),
              _buildClientPickerRow(),
            ],
            const SizedBox(height: AppSpacing.sm),
            AppTextFormField(
              key: const Key('transaction_client_name_field'),
              controller: _clientNameController,
              textCapitalization: TextCapitalization.words,
              onChanged: (_) => _clearClientSelection(),
              label: 'Контрагент',
              hint: 'Наименование или ФИО',
            ),
            const SizedBox(height: AppSpacing.sm),
            AppTextFormField(
              key: const Key('transaction_client_inn_field'),
              controller: _clientInnController,
              keyboardType: TextInputType.number,
              onChanged: (_) => _clearClientSelection(),
              label: 'ИНН контрагента',
            ),
            const SizedBox(height: AppSpacing.sm),
            AppTextFormField(
              key: const Key('transaction_comment_field'),
              controller: _commentController,
              minLines: 2,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              label: 'Комментарий',
            ),
            const SizedBox(height: AppSpacing.lg),
            AppButton(
              key: const Key('transaction_save_button'),
              label: _isEditing ? 'Сохранить' : 'Добавить операцию',
              icon: Icons.check,
              expanded: true,
              loading: _saving,
              onPressed: _saving ? null : _save,
            ),
          ],
        ),
      ),
    );
  }
}
