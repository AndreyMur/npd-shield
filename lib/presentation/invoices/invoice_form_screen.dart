import 'package:flutter/material.dart';

import '../../core/constants/contract_field_keys.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/widgets.dart';
import '../../data/models/invoice.dart';
import '../../data/repositories/client_repository.dart';
import '../../data/repositories/invoice_repository.dart';
import '../../domain/documents/receipt.dart';
import '../clients/client_picker.dart';
import 'invoice_status_visuals.dart';

/// Форма создания и редактирования счёта на оплату.
///
/// Поля: номер, клиент (из справочника или вручную), сумма, дата выставления,
/// срок оплаты, статус и комментарий. Номер и сумма обязательны; срок оплаты
/// не может быть раньше даты выставления. Статус «просрочен» в списке
/// недоступен — он определяется автоматически по сроку.
///
/// При сохранении счёт записывается в репозиторий, а экран возвращает `true`,
/// чтобы вызывающий список обновился.
class InvoiceFormScreen extends StatefulWidget {
  final InvoiceRepository repository;

  /// Справочник клиентов. Если задан — клиента можно выбрать из него.
  final ClientRepository? clientRepository;

  /// Редактируемый счёт. `null` — создание нового.
  final Invoice? invoice;

  /// «Сейчас» для стабильности тестов.
  final DateTime? now;

  const InvoiceFormScreen({
    super.key,
    required this.repository,
    this.clientRepository,
    this.invoice,
    this.now,
  });

  @override
  State<InvoiceFormScreen> createState() => _InvoiceFormScreenState();
}

class _InvoiceFormScreenState extends State<InvoiceFormScreen> {
  /// Срок оплаты по умолчанию — через две недели после выставления.
  static const _defaultDueDays = 14;

  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _numberController;
  late final TextEditingController _amountController;
  late final TextEditingController _issuedAtController;
  late final TextEditingController _dueDateController;
  late final TextEditingController _clientNameController;
  late final TextEditingController _clientInnController;
  late final TextEditingController _commentController;

  late DateTime _issuedAt;
  late DateTime _dueDate;
  late InvoiceStatus _status;

  /// Идентификатор клиента из справочника; `null` — контрагент введён вручную
  /// или не указан.
  int? _selectedClientId;
  bool _saving = false;

  bool get _isEditing => widget.invoice != null;

  @override
  void initState() {
    super.initState();
    final invoice = widget.invoice;
    final now = widget.now ?? DateTime.now();

    _issuedAt = invoice?.issuedAt ?? now;
    _dueDate = invoice?.dueDate ?? now.add(const Duration(days: _defaultDueDays));
    _status = invoice?.status ?? InvoiceStatus.draft;
    _selectedClientId =
        (invoice?.clientId ?? 0) == 0 ? null : invoice!.clientId;

    _numberController = TextEditingController(text: invoice?.number ?? '');
    _amountController = TextEditingController(
      text: invoice == null || invoice.amount == 0
          ? ''
          : invoice.amount.toStringAsFixed(2).replaceAll('.', ','),
    );
    _issuedAtController = TextEditingController(text: formatContractDate(_issuedAt));
    _dueDateController = TextEditingController(text: formatContractDate(_dueDate));
    _clientNameController = TextEditingController(text: invoice?.clientName ?? '');
    _clientInnController = TextEditingController(text: invoice?.clientInn ?? '');
    _commentController = TextEditingController(text: invoice?.comment ?? '');
  }

  @override
  void dispose() {
    _numberController.dispose();
    _amountController.dispose();
    _issuedAtController.dispose();
    _dueDateController.dispose();
    _clientNameController.dispose();
    _clientInnController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _pickIssuedAt() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _issuedAt,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() {
      _issuedAt = picked;
      _issuedAtController.text = formatContractDate(picked);
    });
  }

  Future<void> _pickDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() {
      _dueDate = picked;
      _dueDateController.text = formatContractDate(picked);
    });
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

  /// Сбрасывает связь со справочником при ручном изменении клиента.
  void _clearClientSelection() {
    if (_selectedClientId == null) return;
    setState(() => _selectedClientId = null);
  }

  Future<void> _save() async {
    if (_saving) return;
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final existing = widget.invoice;
    final invoice = Invoice(
      number: _numberController.text.trim(),
      amount: parseReceiptAmount(_amountController.text),
      issuedAt: _issuedAt,
      dueDate: _dueDate,
      clientId: _selectedClientId ?? 0,
      clientName: _clientNameController.text.trim(),
      clientInn: _clientInnController.text.trim(),
      status: _status,
      paidAmount: existing?.paidAmount ?? 0,
      paidAt: existing?.paidAt,
      transactionId: existing?.transactionId ?? 0,
      comment: _commentController.text.trim(),
    );

    try {
      if (existing != null) {
        invoice.id = existing.id;
        await widget.repository.update(invoice);
      } else {
        await widget.repository.add(invoice);
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Не удалось сохранить счёт')),
        );
    }
  }

  String? _numberValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Укажите номер счёта';
    }
    return null;
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

  String? _dueDateValidator(String? value) {
    final date = parseContractDate(value ?? '');
    if (date == null) return 'Укажите дату в формате ДД.ММ.ГГГГ';
    if (date.isBefore(_issuedAt)) {
      return 'Срок не может быть раньше даты выставления';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = AppTokens.of(context);
    final effective = widget.invoice?.effectiveStatus(now: widget.now);
    final showOverdueNote =
        effective == InvoiceStatus.overdue && _status == InvoiceStatus.sent;

    OutlineInputBorder fieldBorder(Color color, {double width = 1}) =>
        OutlineInputBorder(
          borderRadius: AppRadius.fieldRadius,
          borderSide: BorderSide(color: color, width: width),
        );

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Счёт' : 'Новый счёт'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            AppTextFormField(
              key: const Key('invoice_number_field'),
              controller: _numberController,
              validator: _numberValidator,
              textCapitalization: TextCapitalization.characters,
              label: 'Номер счёта',
              hint: 'Например, 14/09',
            ),
            const SizedBox(height: AppSpacing.sm),
            AppTextFormField(
              key: const Key('invoice_amount_field'),
              controller: _amountController,
              validator: _amountValidator,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              label: 'Сумма, ₽',
              hint: 'Например, 50000',
            ),
            const SizedBox(height: AppSpacing.sm),
            AppTextFormField(
              key: const Key('invoice_issued_at_field'),
              controller: _issuedAtController,
              validator: _dateValidator,
              label: 'Дата выставления',
              hint: 'ДД.ММ.ГГГГ',
              suffixIcon: IconButton(
                key: const Key('invoice_issued_at_picker'),
                tooltip: 'Выбрать дату',
                icon: const Icon(Icons.calendar_today_outlined),
                onPressed: _pickIssuedAt,
              ),
              onChanged: (value) {
                final parsed = parseContractDate(value);
                if (parsed != null) setState(() => _issuedAt = parsed);
              },
            ),
            const SizedBox(height: AppSpacing.sm),
            AppTextFormField(
              key: const Key('invoice_due_date_field'),
              controller: _dueDateController,
              validator: _dueDateValidator,
              label: 'Срок оплаты',
              hint: 'ДД.ММ.ГГГГ',
              suffixIcon: IconButton(
                key: const Key('invoice_due_date_picker'),
                tooltip: 'Выбрать дату',
                icon: const Icon(Icons.event_outlined),
                onPressed: _pickDueDate,
              ),
              onChanged: (value) {
                final parsed = parseContractDate(value);
                if (parsed != null) setState(() => _dueDate = parsed);
              },
            ),
            if (showOverdueNote) ...[
              const SizedBox(height: AppSpacing.sm),
              const _OverdueNote(),
            ],
            const SizedBox(height: AppSpacing.lg),
            Text('Статус', style: theme.textTheme.titleMedium),
            const SizedBox(height: AppSpacing.xs),
            DropdownButtonFormField<InvoiceStatus>(
              key: const Key('invoice_status_field'),
              initialValue: _status,
              decoration: InputDecoration(
                isDense: true,
                filled: true,
                fillColor: tokens.surfaceVariant,
                border: fieldBorder(tokens.border),
                enabledBorder: fieldBorder(tokens.border),
                focusedBorder: fieldBorder(tokens.primary, width: 1.5),
              ),
              items: [
                for (final status in InvoiceStatus.manualValues)
                  DropdownMenuItem(
                    value: status,
                    child: Row(
                      children: [
                        Icon(
                          invoiceStatusVisuals(context, status).icon,
                          size: 18,
                          color: invoiceStatusVisuals(context, status).color,
                        ),
                        const SizedBox(width: 8),
                        Text(status.label),
                      ],
                    ),
                  ),
              ],
              onChanged: (status) {
                if (status == null) return;
                setState(() => _status = status);
              },
            ),
            const SizedBox(height: AppSpacing.lg),
            if (widget.clientRepository != null) ...[
              AppButton(
                key: const Key('invoice_pick_client_button'),
                label: _selectedClientId != null
                    ? 'Клиент из справочника'
                    : 'Выбрать из справочника',
                icon: Icons.people_outline,
                variant: AppButtonVariant.secondary,
                expanded: true,
                onPressed: _pickClient,
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
            AppTextFormField(
              key: const Key('invoice_client_name_field'),
              controller: _clientNameController,
              textCapitalization: TextCapitalization.words,
              onChanged: (_) => _clearClientSelection(),
              label: 'Клиент',
              hint: 'Наименование или ФИО',
            ),
            const SizedBox(height: AppSpacing.sm),
            AppTextFormField(
              key: const Key('invoice_client_inn_field'),
              controller: _clientInnController,
              keyboardType: TextInputType.number,
              onChanged: (_) => _clearClientSelection(),
              label: 'ИНН клиента',
            ),
            const SizedBox(height: AppSpacing.sm),
            AppTextFormField(
              key: const Key('invoice_comment_field'),
              controller: _commentController,
              minLines: 2,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              label: 'Комментарий',
            ),
            const SizedBox(height: AppSpacing.lg),
            AppButton(
              key: const Key('invoice_save_button'),
              label: _isEditing ? 'Сохранить' : 'Добавить счёт',
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

/// Подсказка о том, что срок оплаты уже истёк и счёт считается просроченным.
class _OverdueNote extends StatelessWidget {
  const _OverdueNote();

  @override
  Widget build(BuildContext context) {
    return const StatusBanner(
      key: Key('invoice_overdue_note'),
      type: StatusBannerType.warning,
      message: 'Срок оплаты истёк — счёт отображается как просроченный',
    );
  }
}
