import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/validation/profile_input.dart';
import '../../data/repositories/contractor_profile_repository.dart';
import '../../domain/profile/contractor_profile.dart';

/// Экран редактирования профиля ИП.
///
/// Реквизиты сохраняются в [ContractorProfileRepository] и впоследствии
/// автоматически подставляются в новые договоры, чеки и акты. Все поля
/// необязательны: если очистить их, сохранённый профиль удаляется.
class ProfileEditScreen extends StatefulWidget {
  final ContractorProfileRepository profileRepository;

  const ProfileEditScreen({super.key, required this.profileRepository});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullName = TextEditingController();
  final _inn = TextEditingController();
  final _ogrnip = TextEditingController();
  final _address = TextEditingController();
  final _bankName = TextEditingController();
  final _bankAccount = TextEditingController();
  final _bankBik = TextEditingController();

  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

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

  Future<void> _load() async {
    final profile = await widget.profileRepository.load();
    if (!mounted) return;
    if (profile != null) {
      _fullName.text = profile.fullName;
      _inn.text = profile.inn;
      _ogrnip.text = profile.ogrnip;
      _address.text = profile.registrationAddress;
      _bankName.text = profile.bankName;
      _bankAccount.text = profile.bankAccount;
      _bankBik.text = profile.bankBik;
    }
    setState(() => _loading = false);
  }

  Future<void> _save() async {
    if (_saving) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      final profile = _buildProfile();
      if (profile == null) {
        await widget.profileRepository.clear();
      } else {
        await widget.profileRepository.save(profile);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Не удалось сохранить профиль. Попробуйте ещё раз.'),
        ),
      );
      return;
    }
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  ContractorProfile? _buildProfile() {
    final values = [
      _fullName.text.trim(),
      _inn.text.trim(),
      _ogrnip.text.trim(),
      _address.text.trim(),
      _bankName.text.trim(),
      _bankAccount.text.trim(),
      _bankBik.text.trim(),
    ];
    if (values.every((value) => value.isEmpty)) return null;

    return ContractorProfile(
      fullName: values[0],
      inn: values[1],
      ogrnip: values[2],
      registrationAddress: values[3],
      bankName: values[4],
      bankAccount: values[5],
      bankBik: values[6],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Профиль ИП')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                    'Реквизиты подставляются в договоры, чеки и акты. '
                    'Все поля необязательны.',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    key: const Key('profile_full_name'),
                    controller: _fullName,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'ФИО',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    key: const Key('profile_inn'),
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
                    validator: (value) =>
                        ProfileInput.validateDigits(value, lengths: const [10, 12]),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    key: const Key('profile_ogrnip'),
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
                    validator: (value) =>
                        ProfileInput.validateDigits(value, lengths: const [15]),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    key: const Key('profile_address'),
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
                    key: const Key('profile_bank_name'),
                    controller: _bankName,
                    decoration: const InputDecoration(
                      labelText: 'Банк',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    key: const Key('profile_bank_account'),
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
                    validator: (value) =>
                        ProfileInput.validateDigits(value, lengths: const [20]),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    key: const Key('profile_bank_bik'),
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
                    validator: (value) =>
                        ProfileInput.validateDigits(value, lengths: const [9]),
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    key: const Key('profile_save'),
                    onPressed: _saving ? null : _save,
                    child: _saving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Сохранить'),
                  ),
                ],
              ),
            ),
    );
  }
}
