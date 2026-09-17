import 'package:flutter_test/flutter_test.dart';
import 'package:npd_shield/data/models/app_notification.dart';
import 'package:npd_shield/domain/notifications/notification_settings.dart';

void main() {
  group('NotificationSettings', () {
    test('по умолчанию все типы включены, тихие часы 22:00–08:00', () {
      const settings = NotificationSettings.defaults;
      for (final type in NotificationType.values) {
        expect(settings.isTypeEnabled(type), isTrue, reason: type.name);
      }
      expect(settings.quietHoursEnabled, isTrue);
      expect(settings.quietHoursStartMinutes, 22 * 60);
      expect(settings.quietHoursEndMinutes, 8 * 60);
      expect(settings.limitThresholds, containsAll(<double>[0.8, 0.9, 0.95, 1]));
      expect(settings.invoiceReminderDays, containsAll(<int>[14, 7, 3]));
    });

    test('isQuietAt распознаёт ночные и дневные часы', () {
      const settings = NotificationSettings.defaults;
      expect(settings.isQuietAt(DateTime(2026, 9, 15, 23, 0)), isTrue);
      expect(settings.isQuietAt(DateTime(2026, 9, 15, 7, 59)), isTrue);
      expect(settings.isQuietAt(DateTime(2026, 9, 15, 8, 0)), isFalse);
      expect(settings.isQuietAt(DateTime(2026, 9, 15, 12, 0)), isFalse);
      expect(settings.isQuietAt(DateTime(2026, 9, 15, 21, 59)), isFalse);
      expect(settings.isQuietAt(DateTime(2026, 9, 15, 22, 0)), isTrue);
    });

    test('тихие часы, не пересекающие полночь', () {
      const settings = NotificationSettings(
        quietHoursStartMinutes: 13 * 60,
        quietHoursEndMinutes: 15 * 60,
      );
      expect(settings.isQuietAt(DateTime(2026, 9, 15, 14, 0)), isTrue);
      expect(settings.isQuietAt(DateTime(2026, 9, 15, 16, 0)), isFalse);
      expect(settings.isQuietAt(DateTime(2026, 9, 15, 2, 0)), isFalse);
    });

    test('совпадающие начало и конец означают выключенные тихие часы', () {
      const settings = NotificationSettings(
        quietHoursStartMinutes: 10 * 60,
        quietHoursEndMinutes: 10 * 60,
      );
      expect(settings.isQuietAt(DateTime(2026, 9, 15, 10, 0)), isFalse);
    });

    test('выключенные тихие часы не блокируют уведомления', () {
      const settings = NotificationSettings(quietHoursEnabled: false);
      expect(settings.isQuietAt(DateTime(2026, 9, 15, 3, 0)), isFalse);
    });

    test('isTypeEnabled учитывает отключённые типы', () {
      const settings = NotificationSettings(
        limitEnabled: false,
        anomalyEnabled: false,
      );
      expect(settings.isTypeEnabled(NotificationType.limit), isFalse);
      expect(settings.isTypeEnabled(NotificationType.anomaly), isFalse);
      expect(settings.isTypeEnabled(NotificationType.invoice), isTrue);
      expect(settings.isTypeEnabled(NotificationType.digest), isTrue);
    });

    test('toJson/fromJson сохраняют настройки', () {
      const settings = NotificationSettings(
        limitEnabled: false,
        digestEnabled: false,
        quietHoursEnabled: false,
        quietHoursStartMinutes: 21 * 60 + 30,
        quietHoursEndMinutes: 7 * 60,
        limitThresholds: [0.8, 1.0],
        invoiceReminderDays: {7},
      );

      final restored = NotificationSettings.fromJson(settings.toJson());

      expect(restored.limitEnabled, isFalse);
      expect(restored.digestEnabled, isFalse);
      expect(restored.quietHoursEnabled, isFalse);
      expect(restored.quietHoursStartMinutes, 21 * 60 + 30);
      expect(restored.quietHoursEndMinutes, 7 * 60);
      expect(restored.limitThresholds, [0.8, 1.0]);
      expect(restored.invoiceReminderDays, {7});
    });

    test('fromJson с мусором возвращает значения по умолчанию', () {
      final restored = NotificationSettings.fromJson({
        'limitEnabled': 'nope',
        'limitThresholds': 'bad',
        'quietHoursStartMinutes': 99999,
      });
      expect(restored.limitEnabled, isTrue);
      expect(restored.limitThresholds, NotificationSettings.defaults.limitThresholds);
      expect(
        restored.quietHoursStartMinutes,
        NotificationSettings.defaults.quietHoursStartMinutes,
      );
    });
  });
}
