import 'package:flutter/material.dart';

import 'data_management_dialogs.dart';

/// Настройки приложения.
///
/// Пока содержит только управление данными: загрузку демо и полную очистку.
/// Остальные разделы (тема, сферы деятельности, «О приложении») добавятся
/// в следующих фазах.
class SettingsScreen extends StatefulWidget {
  /// Загружает демонстрационные данные после подтверждения пользователя.
  final Future<void> Function() onLoadDemoData;

  /// Полностью очищает данные и возвращает приложение к онбордингу.
  final Future<void> Function() onClearAllData;

  const SettingsScreen({
    super.key,
    required this.onLoadDemoData,
    required this.onClearAllData,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _busy = false;

  Future<void> _loadDemoData() async {
    if (_busy) return;
    final confirmed = await showDemoDataConfirmation(context);
    if (!confirmed || !mounted) return;

    setState(() => _busy = true);
    try {
      await widget.onLoadDemoData();
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Настройки')),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Управление данными',
              style: theme.textTheme.titleMedium,
            ),
          ),
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
            leading: Icon(Icons.delete_forever_outlined, color: theme.colorScheme.error),
            title: Text(
              'Очистить все данные',
              style: TextStyle(color: theme.colorScheme.error),
            ),
            subtitle: const Text(
              'Удалить все записи и вернуться к первому запуску',
            ),
            onTap: _clearAllData,
          ),
          if (_busy)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}
