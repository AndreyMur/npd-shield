import 'package:flutter/material.dart';

import '../../core/constants/contract_field_keys.dart';
import '../../data/models/contract_draft.dart';
import '../../data/models/contract_template.dart';
import '../../data/repositories/contract_draft_repository.dart';
import '../../data/repositories/contractor_profile_repository.dart';
import '../../domain/profile/contractor_profile.dart';
import 'template_sphere_visuals.dart';

/// Форма основных полей договора.
///
/// Раздел «Исполнитель» автозаполняется реквизитами из профиля пользователя.
/// Обязательные поля валидируются перед сохранением черновика в Isar.
class ContractFormScreen extends StatefulWidget {
  final Template template;
  final ContractDraftRepository draftRepository;
  final ContractorProfileRepository profileRepository;
  final DateTime? now;

  const ContractFormScreen({
    super.key,
    required this.template,
    required this.draftRepository,
    required this.profileRepository,
    this.now,
  });

  @override
  State<ContractFormScreen> createState() => _ContractFormScreenState();
}

class _ContractFormScreenState extends State<ContractFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _numberController;
  late final TextEditingController _dateController;
  late final TextEditingController _cityController;
  late final TextEditingController _clientNameController;
  late final TextEditingController _clientInnController;
  late final TextEditingController _clientAddressController;
  late final TextEditingController _executorFullNameController;
  late final TextEditingController _executorInnController;
  late final TextEditingController _executorOgrnipController;
  late final TextEditingController _executorAddressController;
  late final TextEditingController _subjectController;
  late final TextEditingController _amountController;

  ContractorProfile? _profile;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final now = widget.now ?? DateTime.now();
    _numberController = TextEditingController();
    _dateController = TextEditingController(text: formatContractDate(now));
    _cityController = TextEditingController();
    _clientNameController = TextEditingController();
    _clientInnController = TextEditingController();
    _clientAddressController = TextEditingController();
    _executorFullNameController = TextEditingController();
    _executorInnController = TextEditingController();
    _executorOgrnipController = TextEditingController();
    _executorAddressController = TextEditingController();
    _subjectController = TextEditingController();
    _amountController = TextEditingController();
    _loadProfile();
  }

  @override
  void dispose() {
    _numberController.dispose();
    _dateController.dispose();
    _cityController.dispose();
    _clientNameController.dispose();
    _clientInnController.dispose();
    _clientAddressController.dispose();
    _executorFullNameController.dispose();
    _executorInnController.dispose();
    _executorOgrnipController.dispose();
    _executorAddressController.dispose();
    _subjectController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final profile = await widget.profileRepository.load();
    if (!mounted) return;
    setState(() => _profile = profile);
    if (profile == null) return;
    _executorFullNameController.text = profile.fullName;
    _executorInnController.text = profile.inn;
    _executorOgrnipController.text = profile.ogrnip;
    _executorAddressController.text = profile.registrationAddress;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final draft = ContractDraft(
      templateId: widget.template.code,
      filledFields: contractFieldsFromMap(_collectFields()),
      status: ContractStatus.draft,
    );
    await widget.draftRepository.save(draft);
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  Map<String, String> _collectFields() {
    final fields = <String, String>{
      ContractFieldKeys.contractNumber: _numberController.text.trim(),
      ContractFieldKeys.contractDate: _dateController.text.trim(),
      ContractFieldKeys.contractCity: _cityController.text.trim(),
      ContractFieldKeys.clientName: _clientNameController.text.trim(),
      ContractFieldKeys.clientInn: _clientInnController.text.trim(),
      ContractFieldKeys.clientAddress: _clientAddressController.text.trim(),
      ContractFieldKeys.executorFullName: _executorFullNameController.text
          .trim(),
      ContractFieldKeys.executorInn: _executorInnController.text.trim(),
      ContractFieldKeys.executorOgrnip: _executorOgrnipController.text.trim(),
      ContractFieldKeys.executorAddress: _executorAddressController.text.trim(),
      ContractFieldKeys.subject: _subjectController.text.trim(),
      ContractFieldKeys.amount: _amountController.text
          .replaceAll(' ', '')
          .trim(),
    };
    final profile = _profile;
    if (profile != null) {
      fields.addAll({
        ContractFieldKeys.executorBankName: profile.bankName,
        ContractFieldKeys.executorBankBik: profile.bankBik,
        ContractFieldKeys.executorBankAccount: profile.bankAccount,
      });
    }
    return fields;
  }

  String? _requiredValidator(String? value, String message) {
    if (value == null || value.trim().isEmpty) return message;
    return null;
  }

  String? _innValidator(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return 'Укажите ИНН';
    if (!RegExp(r'^\d+$').hasMatch(trimmed)) {
      return 'ИНН должен содержать только цифры';
    }
    if (trimmed.length != 10 && trimmed.length != 12) {
      return 'ИНН: 10 или 12 цифр';
    }
    return null;
  }

  String? _amountValidator(String? value) {
    final cleaned = value?.replaceAll(' ', '') ?? '';
    if (cleaned.isEmpty) return 'Укажите стоимость';
    final parsed = double.tryParse(cleaned.replaceAll(',', '.'));
    if (parsed == null || parsed <= 0) {
      return 'Стоимость должна быть больше нуля';
    }
    return null;
  }

  String? _dateValidator(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return null;
    if (!RegExp(r'^\d{2}\.\d{2}\.\d{4}$').hasMatch(trimmed)) {
      return 'Дата в формате ДД.ММ.ГГГГ';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Новый договор')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _TemplateHeader(template: widget.template),
            const SizedBox(height: 16),
            Text('Параметры договора', style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            TextFormField(
              key: const Key('field_contractNumber'),
              controller: _numberController,
              decoration: const InputDecoration(
                labelText: 'Номер договора',
                hintText: 'Например, 14/09',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: const Key('field_contractDate'),
              controller: _dateController,
              validator: _dateValidator,
              decoration: const InputDecoration(
                labelText: 'Дата договора',
                hintText: 'ДД.ММ.ГГГГ',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: const Key('field_contractCity'),
              controller: _cityController,
              decoration: const InputDecoration(
                labelText: 'Город заключения',
                hintText: 'Например, Москва',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            Text('Исполнитель', style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              _profile == null
                  ? 'Данные берутся из профиля. Заполните профиль, '
                        'чтобы они подставлялись автоматически.'
                  : 'Реквизиты из профиля подставлены автоматически.',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: const Key('field_executorFullName'),
              controller: _executorFullNameController,
              validator: (v) =>
                  _requiredValidator(v, 'Укажите ФИО исполнителя'),
              decoration: const InputDecoration(
                labelText: 'ФИО исполнителя (ИП)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextFormField(
                    key: const Key('field_executorInn'),
                    controller: _executorInnController,
                    validator: _innValidator,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'ИНН исполнителя',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    key: const Key('field_executorOgrnip'),
                    controller: _executorOgrnipController,
                    validator: (v) => _requiredValidator(v, 'Укажите ОГРНИП'),
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'ОГРНИП',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: const Key('field_executorAddress'),
              controller: _executorAddressController,
              validator: (v) =>
                  _requiredValidator(v, 'Укажите адрес регистрации'),
              decoration: const InputDecoration(
                labelText: 'Адрес регистрации',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            Text('Заказчик', style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            TextFormField(
              key: const Key('field_clientName'),
              controller: _clientNameController,
              validator: (v) => _requiredValidator(v, 'Укажите заказчика'),
              decoration: const InputDecoration(
                labelText: 'Заказчик',
                hintText: 'Организация или ФИО ИП',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: const Key('field_clientInn'),
              controller: _clientInnController,
              validator: _innValidator,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'ИНН заказчика',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: const Key('field_clientAddress'),
              controller: _clientAddressController,
              decoration: const InputDecoration(
                labelText: 'Адрес заказчика',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            Text('Предмет и стоимость', style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            TextFormField(
              key: const Key('field_subject'),
              controller: _subjectController,
              validator: (v) =>
                  _requiredValidator(v, 'Опишите предмет договора'),
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Предмет договора',
                hintText: 'Какие услуги/работы выполняются',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: const Key('field_amount'),
              controller: _amountController,
              validator: _amountValidator,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Стоимость, ₽',
                hintText: 'Например, 150000',
                border: OutlineInputBorder(),
                prefixText: '₽ ',
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              key: const Key('save_draft_button'),
              onPressed: _saving ? null : _save,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Сохранить черновик'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TemplateHeader extends StatelessWidget {
  final Template template;

  const _TemplateHeader({required this.template});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      color: template.sphere.color.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(template.sphere.icon, color: template.sphere.color),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(template.title, style: theme.textTheme.titleMedium),
                  const SizedBox(height: 2),
                  Text(
                    template.sphere.category,
                    style: theme.textTheme.bodySmall!.copyWith(
                      color: template.sphere.color,
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
