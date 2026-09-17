import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/notifications/notification_settings.dart';

/// Хранилище настроек уведомлений.
abstract class NotificationSettingsRepository {
  /// Возвращает сохранённые настройки или значения по умолчанию.
  Future<NotificationSettings> load();

  /// Сохраняет настройки.
  Future<void> save(NotificationSettings settings);

  /// Сбрасывает настройки к значениям по умолчанию (при очистке данных).
  Future<void> reset();
}

/// Реализация [NotificationSettingsRepository] поверх `SharedPreferences`.
class SharedPrefsNotificationSettingsRepository
    implements NotificationSettingsRepository {
  static const _key = 'notification_settings';

  @override
  Future<NotificationSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return NotificationSettings.defaults;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        return NotificationSettings.fromJson(
          decoded.map((key, value) => MapEntry(key.toString(), value)),
        );
      }
    } catch (_) {
      // Повреждённые настройки не должны ломать приложение.
    }
    return NotificationSettings.defaults;
  }

  @override
  Future<void> save(NotificationSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(settings.toJson()));
  }

  @override
  Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
