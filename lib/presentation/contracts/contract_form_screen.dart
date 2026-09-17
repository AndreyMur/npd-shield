import 'package:flutter/material.dart';

import '../../core/constants/contract_field_keys.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/widgets.dart';
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
    if (_saving) return;
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final draft = ContractDraft(
      templateId: widget.template.code,
      filledFields: contractFieldsFromMap(_collectFields()),
      status: ContractStatus.draft,
    );
    try {
      await widget.draftRepository.save(draft);
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Не удалось сохранить черновик. Попробуйте ещё раз.'),
        ),
      );
      return;
    }
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
    final tokens = AppTokens.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Новый договор')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: AppSpacing.screen,
          children: [
            _TemplateHeader(template: widget.template),
            const SizedBox(height: AppSpacing.md),
            _SectionTitle('Параметры договора'),
            const SizedBox(height: AppSpacing.sm),
            AppTextFormField(
              key: const Key('field_contractNumber'),
              controller: _numberController,
              label: 'Номер договора',
              hint: 'Например, 14/09',
            ),
            const SizedBox(height: AppSpacing.sm),
            AppTextFormField(
              key: const Key('field_contractDate'),
              controller: _dateController,
              label: 'Дата договора',
              hint: 'ДД.ММ.ГГГГ',
              validator: _dateValidator,
            ),
            const SizedBox(height: AppSpacing.sm),
            AppTextFormField(
              key: const Key('field_contractCity'),
              controller: _cityController,
              label: 'Город заключения',
              hint: 'Например, Москва',
            ),
            const SizedBox(height: AppSpacing.lg),
            _SectionTitle('Исполнитель'),
            const SizedBox(height: AppSpacing.xxs),
            Text(
              _profile == null
                  ? 'Данные берутся из профиля. Заполните профиль, '
                        'чтобы они подставлялись автоматически.'
                  : 'Реквизиты из профиля подставлены автоматически.',
              style: theme.textTheme.bodySmall?.copyWith(color: tokens.muted),
            ),
            const SizedBox(height: AppSpacing.sm),
            AppTextFormField(
              key: const Key('field_executorFullName'),
              controller: _executorFullNameController,
              label: 'ФИО исполнителя (ИП)',
              validator: (v) =>
                  _requiredValidator(v, 'Укажите ФИО исполнителя'),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: AppTextFormField(
                    key: const Key('field_executorInn'),
                    controller: _executorInnController,
                    label: 'ИНН исполнителя',
                    keyboardType: TextInputType.number,
                    validator: _innValidator,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: AppTextFormField(
                    key: const Key('field_executorOgrnip'),
                    controller: _executorOgrnipController,
                    label: 'ОГРНИП',
                    keyboardType: TextInputType.number,
                    validator: (v) => _requiredValidator(v, 'Укажите ОГРНИП'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            AppTextFormField(
              key: const Key('field_executorAddress'),
              controller: _executorAddressController,
              label: 'Адрес регистрации',
              validator: (v) =>
                  _requiredValidator(v, 'Укажите адрес регистрации'),
            ),
            const SizedBox(height: AppSpacing.lg),
            _SectionTitle('Заказчик'),
            const SizedBox(height: AppSpacing.sm),
            AppTextFormField(
              key: const Key('field_clientName'),
              controller: _clientNameController,
              label: 'Заказчик',
              hint: 'Организация или ФИО ИП',
              validator: (v) => _requiredValidator(v, 'Укажите заказчика'),
            ),
            const SizedBox(height: AppSpacing.sm),
            AppTextFormField(
              key: const Key('field_clientInn'),
              controller: _clientInnController,
              label: 'ИНН заказчика',
              keyboardType: TextInputType.number,
              validator: _innValidator,
            ),
            const SizedBox(height: AppSpacing.sm),
            AppTextFormField(
              key: const Key('field_clientAddress'),
              controller: _clientAddressController,
              label: 'Адрес заказчика',
            ),
            const SizedBox(height: AppSpacing.lg),
            _SectionTitle('Предмет и стоимость'),
            const SizedBox(height: AppSpacing.sm),
            AppTextFormField(
              key: const Key('field_subject'),
              controller: _subjectController,
              label: 'Предмет договора',
              hint: 'Какие услуги/работы выполняются',
              maxLines: 3,
              validator: (v) => _requiredValidator(v, 'Опишите предмет договора'),
            ),
            const SizedBox(height: AppSpacing.sm),
            AppTextFormField(
              key: const Key('field_amount'),
              controller: _amountController,
              label: 'Стоимость, ₽',
              hint: 'Например, 150000',
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              validator: _amountValidator,
            ),
            const SizedBox(height: AppSpacing.lg),
            AppButton(
              key: const Key('save_draft_button'),
              label: 'Сохранить черновик',
              icon: Icons.save_outlined,
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

/// Заголовок раздела формы.
class _SectionTitle extends StatelessWidget {
  final String text;

  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text, style: Theme.of(context).textTheme.titleMedium);
  }
}

class _TemplateHeader extends StatelessWidget {
  final Template template;

  const _TemplateHeader({required this.template});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = template.sphere.color;
    return AppCard(
      color: color.withValues(alpha: 0.1),
      borderColor: color.withValues(alpha: 0.3),
      child: Row(
        children: [
          Icon(template.sphere.icon, color: color),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(template.title, style: theme.textTheme.titleMedium),
                const SizedBox(height: 2),
                Text(
                  template.sphere.category,
                  style: theme.textTheme.bodySmall?.copyWith(color: color),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
