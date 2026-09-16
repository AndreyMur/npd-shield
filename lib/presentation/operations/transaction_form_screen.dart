import 'package:flutter/material.dart';

import '../../core/constants/contract_field_keys.dart';
import '../../data/models/transaction.dart';
import '../../data/repositories/transaction_repository.dart';
import '../../domain/documents/receipt.dart';

/// Форма создания и редактирования операции (дохода или расхода).
///
/// Поля: тип, сумма, дата, сфера деятельности, категория, контрагент и
/// комментарий. Сумма и дата валидируются; сфера выбирается сегментами.
/// При сохранении операция записывается в репозиторий, а экран возвращает
/// `true`, чтобы вызывающий список обновился.
class TransactionFormScreen extends StatefulWidget {
  final TransactionRepository repository;

  /// Редактируемая операция. `null` — создание новой.
  final Transaction? transaction;

  /// «Сейчас» для стабильности тестов.
  final DateTime? now;

  const TransactionFormScreen({
    super.key,
    required this.repository,
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
      clientId: widget.transaction?.clientId,
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Операция' : 'Новая операция'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('Тип операции', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            SegmentedButton<TransactionType>(
              key: const Key('transaction_type_selector'),
              segments: [
                for (final type in TransactionType.values)
                  ButtonSegment(
                    value: type,
                    label: Text(type.label),
                    icon: Icon(
                      type.isIncome
                          ? Icons.trending_up
                          : Icons.trending_down,
                    ),
                  ),
              ],
              selected: {_type},
              onSelectionChanged: (selection) =>
                  setState(() => _type = selection.first),
            ),
            const SizedBox(height: 20),
            TextFormField(
              key: const Key('transaction_amount_field'),
              controller: _amountController,
              validator: _amountValidator,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Сумма, ₽',
                hintText: 'Например, 15000',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: const Key('transaction_date_field'),
              controller: _dateController,
              validator: _dateValidator,
              decoration: InputDecoration(
                labelText: 'Дата',
                hintText: 'ДД.ММ.ГГГГ',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  key: const Key('transaction_date_picker'),
                  tooltip: 'Выбрать дату',
                  icon: const Icon(Icons.calendar_today_outlined),
                  onPressed: _pickDate,
                ),
              ),
              onChanged: (value) {
                final parsed = parseContractDate(value);
                if (parsed != null) setState(() => _date = parsed);
              },
            ),
            const SizedBox(height: 20),
            Text('Сфера деятельности', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            SegmentedButton<TransactionSphere>(
              key: const Key('transaction_sphere_selector'),
              segments: [
                for (final sphere in TransactionSphere.values)
                  ButtonSegment(
                    value: sphere,
                    label: Text(sphere.label),
                    icon: Icon(
                      sphere == TransactionSphere.it
                          ? Icons.code
                          : Icons.local_shipping,
                    ),
                  ),
              ],
              selected: {_sphere},
              onSelectionChanged: (selection) =>
                  setState(() => _sphere = selection.first),
            ),
            const SizedBox(height: 20),
            TextFormField(
              key: const Key('transaction_category_field'),
              controller: _categoryController,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Категория',
                hintText: 'Например, Материалы',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: const Key('transaction_client_name_field'),
              controller: _clientNameController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Контрагент',
                hintText: 'Наименование или ФИО',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: const Key('transaction_client_inn_field'),
              controller: _clientInnController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'ИНН контрагента',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: const Key('transaction_comment_field'),
              controller: _commentController,
              minLines: 2,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Комментарий',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              key: const Key('transaction_save_button'),
              onPressed: _saving ? null : _save,
              icon: const Icon(Icons.check),
              label: Text(_isEditing ? 'Сохранить' : 'Добавить операцию'),
            ),
          ],
        ),
      ),
    );
  }
}
