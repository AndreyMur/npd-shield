import 'package:flutter/material.dart';

import '../../data/models/app_notification.dart';
import '../../data/repositories/notification_settings_repository.dart';
import '../../domain/notifications/notification_settings.dart';

/// Выбор времени суток для тихих часов.
///
/// Вынесен в параметр, чтобы виджет-тесты могли подменять системный диалог.
typedef NotificationTimePicker = Future<TimeOfDay?> Function(
  BuildContext context,
  TimeOfDay initialTime,
);

/// Системный выбор времени по умолчанию.
Future<TimeOfDay?> defaultNotificationTimePicker(
  BuildContext context,
  TimeOfDay initialTime,
) {
  return showTimePicker(context: context, initialTime: initialTime);
}

/// Экран настроек уведомлений: тумблеры по типам и тихие часы.
///
/// Изменения применяются и сохраняются сразу, как и в остальных настройках.
/// Тихие часы можно сдвигать; они поддерживают интервал через полночь.
class NotificationSettingsScreen extends StatefulWidget {
  /// Хранилище настроек уведомлений.
  final NotificationSettingsRepository repository;

  /// Выбор времени начала и конца тихих часов (подменяется в тестах).
  final NotificationTimePicker timePicker;

  const NotificationSettingsScreen({
    super.key,
    required this.repository,
    this.timePicker = defaultNotificationTimePicker,
  });

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  NotificationSettings? _settings;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final settings = await widget.repository.load();
    if (mounted) setState(() => _settings = settings);
  }

  Future<void> _update(NotificationSettings next) async {
    setState(() => _settings = next);
    await widget.repository.save(next);
  }

  Future<void> _pickStart(NotificationSettings settings) async {
    final picked = await widget.timePicker(
      context,
      _toTimeOfDay(settings.quietHoursStartMinutes),
    );
    if (picked == null || !mounted) return;
    await _update(
      settings.copyWith(quietHoursStartMinutes: _toMinutes(picked)),
    );
  }

  Future<void> _pickEnd(NotificationSettings settings) async {
    final picked = await widget.timePicker(
      context,
      _toTimeOfDay(settings.quietHoursEndMinutes),
    );
    if (picked == null || !mounted) return;
    await _update(settings.copyWith(quietHoursEndMinutes: _toMinutes(picked)));
  }

  @override
  Widget build(BuildContext context) {
    final settings = _settings;
    return Scaffold(
      appBar: AppBar(title: const Text('Уведомления')),
      body: settings == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                const _SectionHeader(title: 'Типы уведомлений'),
                for (final type in NotificationType.values)
                  SwitchListTile(
                    key: Key('notification_settings_${type.name}'),
                    value: settings.isTypeEnabled(type),
                    title: Text(type.label),
                    subtitle: Text(type.description),
                    onChanged: (value) =>
                        _update(settings.withTypeEnabled(type, value)),
                  ),
                const Divider(height: 1),
                const _SectionHeader(title: 'Тихие часы'),
                SwitchListTile(
                  key: const Key('notification_settings_quiet_hours'),
                  value: settings.quietHoursEnabled,
                  title: const Text('Тихие часы'),
                  subtitle: const Text('Не беспокоить в заданное время'),
                  onChanged: (value) =>
                      _update(settings.copyWith(quietHoursEnabled: value)),
                ),
                ListTile(
                  key: const Key('notification_settings_quiet_start'),
                  enabled: settings.quietHoursEnabled,
                  leading: const Icon(Icons.bedtime_outlined),
                  title: const Text('Начало'),
                  trailing: Text(
                    _formatMinutes(settings.quietHoursStartMinutes),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  onTap: settings.quietHoursEnabled
                      ? () => _pickStart(settings)
                      : null,
                ),
                ListTile(
                  key: const Key('notification_settings_quiet_end'),
                  enabled: settings.quietHoursEnabled,
                  leading: const Icon(Icons.wb_sunny_outlined),
                  title: const Text('Конец'),
                  trailing: Text(
                    _formatMinutes(settings.quietHoursEndMinutes),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  onTap: settings.quietHoursEnabled
                      ? () => _pickEnd(settings)
                      : null,
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  child: Text(
                    'В тихие часы уведомления не показываются, но остаются '
                    'в центре. Интервал может пересекать полночь.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  static TimeOfDay _toTimeOfDay(int minutes) =>
      TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60);

  static int _toMinutes(TimeOfDay time) => time.hour * 60 + time.minute;

  static String _formatMinutes(int minutes) {
    final hours = (minutes ~/ 60).toString().padLeft(2, '0');
    final mins = (minutes % 60).toString().padLeft(2, '0');
    return '$hours:$mins';
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
