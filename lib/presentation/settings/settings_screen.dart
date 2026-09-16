import 'package:flutter/material.dart';

import '../../data/models/transaction.dart';
import '../../data/repositories/contractor_profile_repository.dart';
import '../../data/services/activity_spheres_service.dart';
import '../../domain/profile/contractor_profile.dart';
import 'data_management_dialogs.dart';
import 'profile_edit_screen.dart';

/// Экран настроек приложения.
///
/// Разделы: профиль ИП, оформление (тема), сферы деятельности, управление
/// данными (демо и полная очистка) и «О приложении». Настройки применяются
/// сразу и сохраняются между запусками.
class SettingsScreen extends StatefulWidget {
  /// Загружает демонстрационные данные после подтверждения пользователя.
  final Future<void> Function() onLoadDemoData;

  /// Полностью очищает данные и возвращает приложение к онбордингу.
  final Future<void> Function() onClearAllData;

  /// Репозиторий профиля ИП.
  final ContractorProfileRepository profileRepository;

  /// Сервис выбранных сфер деятельности.
  final ActivitySpheresService activitySpheresService;

  /// Текущая тема оформления.
  final ThemeMode themeMode;

  /// Применяет выбранную тему.
  final ValueChanged<ThemeMode> onThemeModeChanged;

  const SettingsScreen({
    super.key,
    required this.onLoadDemoData,
    required this.onClearAllData,
    required this.profileRepository,
    required this.activitySpheresService,
    required this.themeMode,
    required this.onThemeModeChanged,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  ContractorProfile? _profile;
  List<TransactionSphere> _spheres = const [];
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _loadSpheres();
  }

  Future<void> _loadProfile() async {
    final profile = await widget.profileRepository.load();
    if (mounted) setState(() => _profile = profile);
  }

  Future<void> _loadSpheres() async {
    final spheres = await widget.activitySpheresService.load();
    if (mounted) setState(() => _spheres = spheres);
  }

  Future<void> _openProfileEditor() async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ProfileEditScreen(
          profileRepository: widget.profileRepository,
        ),
      ),
    );
    await _loadProfile();
  }

  Future<void> _toggleSphere(TransactionSphere sphere, bool selected) async {
    final next = List<TransactionSphere>.of(_spheres);
    if (selected) {
      if (!next.contains(sphere)) next.add(sphere);
    } else {
      if (next.length == 1) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(content: Text('Нужна хотя бы одна сфера деятельности')),
          );
        return;
      }
      next.remove(sphere);
    }
    setState(() => _spheres = next);
    await widget.activitySpheresService.save(next);
  }

  Future<void> _loadDemoData() async {
    if (_busy) return;
    final confirmed = await showDemoDataConfirmation(context);
    if (!confirmed || !mounted) return;

    setState(() => _busy = true);
    try {
      await widget.onLoadDemoData();
      await _loadProfile();
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(const SnackBar(content: Text('Демо-данные загружены')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _clearAllData() async {
    if (_busy) return;
    final confirmed = await showDataResetConfirmation(context);
    if (!confirmed || !mounted) return;

    setState(() => _busy = true);
    try {
      await widget.onClearAllData();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showAbout() {
    showAboutDialog(
      context: context,
      applicationName: 'NPD Shield',
      applicationVersion: '1.0.0',
      applicationIcon: const Icon(Icons.shield_outlined, size: 40),
      children: const [
        Text(
          'Помощник самозанятого на НПД: учёт доходов и расходов, лимит '
          '2,4 млн ₽, налог 6%, генератор договоров, чеков и актов, проверка '
          'контрагентов и уведомления.',
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Настройки')),
      body: ListView(
        children: [
          _SectionHeader(title: 'Профиль'),
          ListTile(
            key: const Key('settings_profile'),
            leading: const Icon(Icons.person_outline),
            title: const Text('Профиль ИП'),
            subtitle: Text(
              _profile?.fullName.isNotEmpty == true
                  ? _profile!.fullName
                  : 'Заполнить реквизиты для документов',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: _busy ? null : _openProfileEditor,
          ),
          const Divider(height: 1),
          _SectionHeader(title: 'Оформление'),
          RadioGroup<ThemeMode>(
            groupValue: widget.themeMode,
            onChanged: (mode) {
              if (mode != null) widget.onThemeModeChanged(mode);
            },
            child: const Column(
              children: [
                RadioListTile<ThemeMode>(
                  key: Key('settings_theme_system'),
                  value: ThemeMode.system,
                  title: Text('Системная'),
                  subtitle: Text('Как в операционной системе'),
                ),
                RadioListTile<ThemeMode>(
                  key: Key('settings_theme_light'),
                  value: ThemeMode.light,
                  title: Text('Светлая'),
                ),
                RadioListTile<ThemeMode>(
                  key: Key('settings_theme_dark'),
                  value: ThemeMode.dark,
                  title: Text('Тёмная'),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          _SectionHeader(title: 'Сферы деятельности'),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(
              'Выберите направления, которые нужно учитывать. Сферы также '
              'используются для фильтров и подбора шаблонов.',
              style: theme.textTheme.bodyMedium,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final sphere in TransactionSphere.values)
                  FilterChip(
                    key: Key('settings_sphere_${sphere.name}'),
                    label: Text(sphere.label),
                    selected: _spheres.contains(sphere),
                    onSelected: _busy
                        ? null
                        : (selected) => _toggleSphere(sphere, selected),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          _SectionHeader(title: 'Управление данными'),
          ListTile(
            key: const Key('settings_load_demo'),
            enabled: !_busy,
            leading: const Icon(Icons.download_outlined),
            title: const Text('Загрузить демо-данные'),
            subtitle: const Text(
              'Добавить демонстрационные операции и уведомления',
            ),
            onTap: _loadDemoData,
          ),
          ListTile(
            key: const Key('settings_clear_data'),
            enabled: !_busy,
            leading: Icon(
              Icons.delete_forever_outlined,
              color: theme.colorScheme.error,
            ),
            title: Text(
              'Очистить все данные',
              style: TextStyle(color: theme.colorScheme.error),
            ),
            subtitle: const Text(
              'Удалить все записи и вернуться к первому запуску',
            ),
            onTap: _clearAllData,
          ),
          const Divider(height: 1),
          _SectionHeader(title: 'О приложении'),
          ListTile(
            key: const Key('settings_about'),
            leading: const Icon(Icons.info_outline),
            title: const Text('NPD Shield'),
            subtitle: const Text('Версия 1.0.0'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _showAbout,
          ),
          if (_busy)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }
}
