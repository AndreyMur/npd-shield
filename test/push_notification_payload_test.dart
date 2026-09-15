import 'package:flutter_test/flutter_test.dart';
import 'package:npd_shield/data/models/app_notification.dart';
import 'package:npd_shield/data/notifications/push_notification_payload.dart';

void main() {
  group('notificationTypeFromName', () {
    test('разбирает известные типы', () {
      expect(notificationTypeFromName('limit'), NotificationType.limit);
      expect(notificationTypeFromName('invoice'), NotificationType.invoice);
      expect(notificationTypeFromName('anomaly'), NotificationType.anomaly);
      expect(notificationTypeFromName('digest'), NotificationType.digest);
    });

    test('неизвестный или пустой тип — дайджест', () {
      expect(notificationTypeFromName(null), NotificationType.digest);
      expect(notificationTypeFromName(''), NotificationType.digest);
      expect(notificationTypeFromName('unknown'), NotificationType.digest);
    });

    test('имя типа совпадает с обратным преобразованием', () {
      for (final type in NotificationType.values) {
        expect(notificationTypeFromName(notificationTypeName(type)), type);
      }
    });
  });

  group('notificationFromPushData', () {
    test('собирает уведомление из данных push', () {
      final notification = notificationFromPushData(
        {
          'type': 'invoice',
          'title': 'Счёт не оплачен',
          'body': 'Проверьте оплату',
          'payload': 'invoice:42',
          'actionLabel': 'Отметить как оплаченный',
        },
        receivedAt: DateTime(2026, 9, 14, 10),
      );

      expect(notification, isNotNull);
      expect(notification!.type, NotificationType.invoice);
      expect(notification.title, 'Счёт не оплачен');
      expect(notification.body, 'Проверьте оплату');
      expect(notification.payload, 'invoice:42');
      expect(notification.actionLabel, 'Отметить как оплаченный');
      expect(notification.createdAt, DateTime(2026, 9, 14, 10));
      expect(notification.status, NotificationStatus.unread);
    });

    test('использует запасные заголовок и текст из блока notification', () {
      final notification = notificationFromPushData(
        const {},
        fallbackTitle: 'Заголовок FCM',
        fallbackBody: 'Текст FCM',
      );

      expect(notification, isNotNull);
      expect(notification!.title, 'Заголовок FCM');
      expect(notification.body, 'Текст FCM');
      expect(notification.type, NotificationType.digest);
    });

    test('данные push имеют приоритет над запасными значениями', () {
      final notification = notificationFromPushData(
        const {'title': 'Из данных', 'body': 'Тоже из данных'},
        fallbackTitle: 'Запасной',
        fallbackBody: 'Запасной текст',
      );
      expect(notification!.title, 'Из данных');
      expect(notification.body, 'Тоже из данных');
    });

    test('возвращает null, если нет ни заголовка, ни текста', () {
      expect(notificationFromPushData(const {}), isNull);
      expect(notificationFromPushData(const {'title': '   '}), isNull);
    });
  });
}
