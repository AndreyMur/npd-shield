import 'package:npd_shield/data/repositories/notification_settings_repository.dart';
import 'package:npd_shield/domain/notifications/notification_settings.dart';

/// Фейковый репозиторий настроек уведомлений для тестов.
class FakeNotificationSettingsRepository
    implements NotificationSettingsRepository {
  NotificationSettings settings;
  int saveCount = 0;

  FakeNotificationSettingsRepository([
    this.settings = NotificationSettings.defaults,
  ]);

  @override
  Future<NotificationSettings> load() async => settings;

  @override
  Future<void> save(NotificationSettings settings) async {
    this.settings = settings;
    saveCount++;
  }

  @override
  Future<void> reset() async {
    settings = NotificationSettings.defaults;
  }
}
