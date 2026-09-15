import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/models/transaction.dart';
import '../../data/repositories/contractor_profile_repository.dart';
import '../../data/services/activity_spheres_service.dart';
import '../../data/services/first_run_service.dart';
import '../../domain/profile/contractor_profile.dart';
import '../settings/data_management_dialogs.dart';

/// Онбординг первого запуска.
///
/// Проводит пользователя через три шага: выбор сфер деятельности, заполнение
/// профиля ИП и выбор режима старта («с нуля» или «демо»). По завершении
/// сохраняет введённые данные и отмечает онбординг пройденным.
class OnboardingScreen extends StatefulWidget {
  final ActivitySpheresService activitySpheresService;
  final ContractorProfileRepository profileRepository;
  final FirstRunService firstRunService;

  /// Загружает демонстрационные данные по подтверждению пользователя.
  final Future<void> Function() onLoadDemoData;

  /// Вызывается после успешного завершения онбординга.
  final VoidCallback onCompleted;

  const OnboardingScreen({
    super.key,
    required this.activitySpheresService,
    required this.profileRepository,
    required this.firstRunService,
    required this.onLoadDemoData,
    required this.onCompleted,
  });

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  static const _stepCount = 3;

  int _step = 0;
  bool _busy = false;

  final _selectedSpheres = <TransactionSphere>{};
  StartMode _startMode = StartMode.fromScratch;

  final _formKey = GlobalKey<FormState>();
  final _fullName = TextEditingController();
  final _inn = TextEditingController();
  final _ogrnip = TextEditingController();
  final _address = TextEditingController();
  final _bankName = TextEditingController();
  final _bankAccount = TextEditingController();
  final _bankBik = TextEditingController();

  @override
  void dispose() {
    _fullName.dispose();
    _inn.dispose();
    _ogrnip.dispose();
    _address.dispose();
    _bankName.dispose();
    _bankAccount.dispose();
    _bankBik.dispose();
    super.dispose();
  }

  void _next() {
    if (_step == 0 && _selectedSpheres.isEmpty) {
      _showSnack('Выберите хотя бы одну сферу деятельности');
      return;
    }
    if (_step == 1 && !(_formKey.currentState?.validate() ?? true)) {
      return;
    }
    if (_step == _stepCount - 1) {
      _finish();
      return;
    }
    setState(() => _step++);
  }

  void _back() {
    if (_step == 0) return;
    setState(() => _step--);
  }

  Future<void> _finish() async {
    if (_busy) return;
    final mode = _startMode;

    if (mode == StartMode.demo) {
      final confirmed = await showDemoDataConfirmation(context);
      if (!confirmed) return;
    }
    if (!mounted) return;

    setState(() => _busy = true);
    try {
      if (mode == StartMode.demo) {
        await widget.onLoadDemoData();
      }
      final profile = _buildProfile();
      if (profile != null) {
        await widget.profileRepository.save(profile);
      }
      await widget.activitySpheresService.save(_selectedSpheres.toList());
      await widget.firstRunService.completeOnboarding(mode);
      widget.onCompleted();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  ContractorProfile? _buildProfile() {
    final fullName = _fullName.text.trim();
    final inn = _inn.text.trim();
    final ogrnip = _ogrnip.text.trim();
    final address = _address.text.trim();
    final bankName = _bankName.text.trim();
    final bankAccount = _bankAccount.text.trim();
    final bankBik = _bankBik.text.trim();

    final isEmpty = [
      fullName,
      inn,
      ogrnip,
      address,
      bankName,
      bankAccount,
      bankBik,
    ].every((value) => value.isEmpty);
    if (isEmpty) return null;

    return ContractorProfile(
      fullName: fullName,
      inn: inn,
      ogrnip: ogrnip,
      registrationAddress: address,
      bankName: bankName,
      bankAccount: bankAccount,
      bankBik: bankBik,
    );
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Настройка приложения'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Column(
          children: [
            LinearProgressIndicator(value: (_step + 1) / _stepCount),
            Expanded(
              child: switch (_step) {
                0 => _buildSpheresStep(context),
                1 => _buildProfileStep(context),
                _ => _buildStartModeStep(context),
              },
            ),
            _buildActions(context),
          ],
        ),
      ),
    );
  }

  Widget _buildSpheresStep(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      key: const Key('onboarding_step_spheres'),
      padding: const EdgeInsets.all(24),
      children: [
        Text('Сферы деятельности', style: theme.textTheme.headlineSmall),
        const SizedBox(height: 8),
        Text(
          'Выберите, чем вы занимаетесь. Это поможет подобрать шаблоны '
          'договоров и разделить учёт по направлениям.',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 24),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final sphere in TransactionSphere.values)
              FilterChip(
                key: Key('onboarding_sphere_${sphere.name}'),
                label: Text(sphere.label),
                selected: _selectedSpheres.contains(sphere),
                onSelected: (selected) => setState(() {
                  if (selected) {
                    _selectedSpheres.add(sphere);
                  } else {
                    _selectedSpheres.remove(sphere);
                  }
                }),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildProfileStep(BuildContext context) {
    final theme = Theme.of(context);
    return Form(
      key: _formKey,
      child: ListView(
        key: const Key('onboarding_step_profile'),
        padding: const EdgeInsets.all(24),
        children: [
          Text('Профиль ИП', style: theme.textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(
            'Реквизиты подставляются в договоры, чеки и акты. Можно заполнить '
            'позже — все поля необязательны.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          TextFormField(
            key: const Key('onboarding_full_name'),
            controller: _fullName,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'ФИО',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            key: const Key('onboarding_inn'),
            controller: _inn,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(12),
            ],
            decoration: const InputDecoration(
              labelText: 'ИНН',
              border: OutlineInputBorder(),
            ),
            validator: (value) => _validateDigits(value, lengths: const [10, 12]),
          ),
          const SizedBox(height: 16),
          TextFormField(
            key: const Key('onboarding_ogrnip'),
            controller: _ogrnip,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(15),
            ],
            decoration: const InputDecoration(
              labelText: 'ОГРНИП',
              border: OutlineInputBorder(),
            ),
            validator: (value) => _validateDigits(value, lengths: const [15]),
          ),
          const SizedBox(height: 16),
          TextFormField(
            key: const Key('onboarding_address'),
            controller: _address,
            textCapitalization: TextCapitalization.sentences,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Адрес регистрации',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),
          Text('Банковские реквизиты', style: theme.textTheme.titleMedium),
          const SizedBox(height: 16),
          TextFormField(
            key: const Key('onboarding_bank_name'),
            controller: _bankName,
            decoration: const InputDecoration(
              labelText: 'Банк',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            key: const Key('onboarding_bank_account'),
            controller: _bankAccount,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(20),
            ],
            decoration: const InputDecoration(
              labelText: 'Расчётный счёт',
              border: OutlineInputBorder(),
            ),
            validator: (value) => _validateDigits(value, lengths: const [20]),
          ),
          const SizedBox(height: 16),
          TextFormField(
            key: const Key('onboarding_bank_bik'),
            controller: _bankBik,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(9),
            ],
            decoration: const InputDecoration(
              labelText: 'БИК',
              border: OutlineInputBorder(),
            ),
            validator: (value) => _validateDigits(value, lengths: const [9]),
          ),
        ],
      ),
    );
  }

  Widget _buildStartModeStep(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      key: const Key('onboarding_step_start'),
      padding: const EdgeInsets.all(24),
      children: [
        Text('Режим старта', style: theme.textTheme.headlineSmall),
        const SizedBox(height: 8),
        Text(
          'Выберите, как начать работу. Решение можно изменить позже в '
          'настройках.',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        RadioGroup<StartMode>(
          groupValue: _startMode,
          onChanged: (value) => setState(() => _startMode = value!),
          child: const Column(
            children: [
              RadioListTile<StartMode>(
                key: Key('onboarding_mode_from_scratch'),
                value: StartMode.fromScratch,
                title: Text('Начать с нуля'),
                subtitle: Text('Пустые, но готовые к работе экраны'),
              ),
              RadioListTile<StartMode>(
                key: Key('onboarding_mode_demo'),
                value: StartMode.demo,
                title: Text('Загрузить демо-данные'),
                subtitle: Text('Наполненное приложение для ознакомления'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActions(BuildContext context) {
    final isLast = _step == _stepCount - 1;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          if (_step > 0)
            TextButton(
              key: const Key('onboarding_back'),
              onPressed: _busy ? null : _back,
              child: const Text('Назад'),
            ),
          const Spacer(),
          FilledButton(
            key: isLast
                ? const Key('onboarding_finish')
                : const Key('onboarding_next'),
            onPressed: _busy ? null : _next,
            child: _busy
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(isLast ? 'Начать работу' : 'Далее'),
          ),
        ],
      ),
    );
  }

  String? _validateDigits(String? value, {required List<int> lengths}) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return null;
    if (!lengths.contains(text.length) || int.tryParse(text) == null) {
      final expected = lengths.join(' или ');
      return 'Введите $expected цифр';
    }
    return null;
  }
}
