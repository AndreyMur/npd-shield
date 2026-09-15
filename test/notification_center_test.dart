import 'package:flutter_test/flutter_test.dart';
import 'package:npd_shield/data/models/app_notification.dart';
import 'package:npd_shield/domain/notifications/notification_center.dart';

void main() {
  AppNotification note({
    int id = 0,
    NotificationType type = NotificationType.limit,
    NotificationStatus status = NotificationStatus.unread,
    String title = 'Заголовок',
    String body = 'Текст уведомления',
    String actionLabel = '',
    DateTime? createdAt,
  }) {
    final notification = AppNotification(
      type: type,
      status: status,
      title: title,
      body: body,
      actionLabel: actionLabel,
      createdAt: createdAt ?? DateTime(2026, 9, 14, 10),
    );
    notification.id = id;
    return notification;
  }

  group('filterNotifications', () {
    final notifications = [
      note(id: 1, type: NotificationType.limit),
      note(id: 2, type: NotificationType.invoice, status: NotificationStatus.read),
      note(id: 3, type: NotificationType.anomaly),
      note(id: 4, type: NotificationType.digest, title: 'Сводка за неделю'),
    ];

    test('без фильтров возвращает все уведомления', () {
      final result = filterNotifications(
        notifications: notifications,
        filter: const NotificationFilter(),
      );
      expect(result, hasLength(4));
    });

    test('фильтрует по типу', () {
      final result = filterNotifications(
        notifications: notifications,
        filter: const NotificationFilter(type: NotificationType.anomaly),
      );
      expect(result.map((n) => n.id), [3]);
    });

    test('фильтрует по статусу', () {
      final result = filterNotifications(
        notifications: notifications,
        filter: const NotificationFilter(status: NotificationStatus.read),
      );
      expect(result.map((n) => n.id), [2]);
    });

    test('фильтрует по диапазону дат', () {
      final dated = [
        note(id: 1, createdAt: DateTime(2026, 9, 1)),
        note(id: 2, createdAt: DateTime(2026, 9, 10)),
        note(id: 3, createdAt: DateTime(2026, 9, 20)),
      ];
      final result = filterNotifications(
        notifications: dated,
        filter: NotificationFilter(
          from: DateTime(2026, 9, 5),
          to: DateTime(2026, 9, 15),
        ),
      );
      expect(result.map((n) => n.id), [2]);
    });

    test('фильтрует по поисковому запросу без учёта регистра', () {
      final result = filterNotifications(
        notifications: notifications,
        filter: const NotificationFilter(query: 'СВОДКА'),
      );
      expect(result.map((n) => n.id), [4]);
    });

    test('комбинирует тип, статус и запрос', () {
      final result = filterNotifications(
        notifications: notifications,
        filter: const NotificationFilter(
          type: NotificationType.invoice,
          status: NotificationStatus.read,
        ),
      );
      expect(result.map((n) => n.id), [2]);
    });
  });

  group('sortNotifications и applyNotificationCenter', () {
    test('сортирует от новых к старым, не изменяя исходный список', () {
      final notifications = [
        note(id: 1, createdAt: DateTime(2026, 9, 10)),
        note(id: 2, createdAt: DateTime(2026, 9, 14)),
        note(id: 3, createdAt: DateTime(2026, 9, 12)),
      ];
      final sorted = sortNotifications(notifications);
      expect(sorted.map((n) => n.id), [2, 3, 1]);
      expect(notifications.map((n) => n.id), [1, 2, 3]);
    });

    test('применяет фильтр и сортировку вместе', () {
      final notifications = [
        note(id: 1, type: NotificationType.limit, createdAt: DateTime(2026, 9, 10)),
        note(id: 2, type: NotificationType.limit, createdAt: DateTime(2026, 9, 14)),
        note(id: 3, type: NotificationType.anomaly, createdAt: DateTime(2026, 9, 12)),
      ];
      final result = applyNotificationCenter(
        notifications: notifications,
        filter: const NotificationFilter(type: NotificationType.limit),
      );
      expect(result.map((n) => n.id), [2, 1]);
    });
  });

  group('unreadNotificationCount', () {
    test('считает непрочитанные', () {
      final notifications = [
        note(id: 1),
        note(id: 2, status: NotificationStatus.read),
        note(id: 3),
      ];
      expect(unreadNotificationCount(notifications), 2);
    });
  });

  group('purgeExpiredNotifications', () {
    test('удаляет уведомления старше 30 дней', () {
      final now = DateTime(2026, 9, 14);
      final notifications = [
        note(id: 1, createdAt: now.subtract(const Duration(days: 29))),
        note(id: 2, createdAt: now.subtract(const Duration(days: 31))),
      ];
      final result = purgeExpiredNotifications(
        notifications: notifications,
        now: now,
      );
      expect(result.map((n) => n.id), [1]);
    });
  });

  group('notificationDateGroup', () {
    final now = DateTime(2026, 9, 16, 12); // среда

    test('сегодня', () {
      expect(
        notificationDateGroup(DateTime(2026, 9, 16, 8), now: now),
        NotificationDateGroup.today,
      );
    });

    test('вчера', () {
      expect(
        notificationDateGroup(DateTime(2026, 9, 15, 23), now: now),
        NotificationDateGroup.yesterday,
      );
    });

    test('на этой неделе', () {
      expect(
        notificationDateGroup(DateTime(2026, 9, 14), now: now),
        NotificationDateGroup.thisWeek,
      );
    });

    test('ранее', () {
      expect(
        notificationDateGroup(DateTime(2026, 9, 1), now: now),
        NotificationDateGroup.earlier,
      );
    });
  });

  group('groupNotificationsByDate', () {
    test('группирует по дате в хронологическом порядке', () {
      final now = DateTime(2026, 9, 14, 12);
      final notifications = [
        note(id: 1, createdAt: DateTime(2026, 9, 14, 9)),
        note(id: 2, createdAt: DateTime(2026, 9, 13, 9)),
        note(id: 3, createdAt: DateTime(2026, 9, 1)),
      ];
      final groups = groupNotificationsByDate(notifications, now: now);
      expect(groups.map((g) => g.group), [
        NotificationDateGroup.today,
        NotificationDateGroup.yesterday,
        NotificationDateGroup.earlier,
      ]);
      expect(groups.first.notifications.map((n) => n.id), [1]);
    });

    test('не возвращает пустые группы', () {
      final now = DateTime(2026, 9, 14, 12);
      final groups = groupNotificationsByDate(
        [note(id: 1, createdAt: DateTime(2026, 9, 14, 9))],
        now: now,
      );
      expect(groups, hasLength(1));
      expect(groups.single.group, NotificationDateGroup.today);
    });
  });

  group('NotificationFilter', () {
    test('copyWith изменяет поля', () {
      const filter = NotificationFilter();
      final updated = filter.copyWith(
        type: NotificationType.invoice,
        query: 'счёт',
      );
      expect(updated.type, NotificationType.invoice);
      expect(updated.query, 'счёт');
    });

    test('clearType и clearDateRange снимают фильтры', () {
      final filter = NotificationFilter(
        type: NotificationType.limit,
        status: NotificationStatus.unread,
        from: DateTime(2026, 9, 1),
        to: DateTime(2026, 9, 14),
      );
      final cleared = filter.copyWith(clearType: true, clearDateRange: true);
      expect(cleared.type, isNull);
      expect(cleared.from, isNull);
      expect(cleared.to, isNull);
      expect(cleared.status, NotificationStatus.unread);
    });

    test('isEmpty учитывает все поля', () {
      expect(const NotificationFilter().isEmpty, isTrue);
      expect(const NotificationFilter(query: '  ').isEmpty, isTrue);
      expect(
        const NotificationFilter(type: NotificationType.limit).isEmpty,
        isFalse,
      );
    });

    test('равенство по значению', () {
      final a = NotificationFilter(
        type: NotificationType.limit,
        from: DateTime(2026, 9, 1),
      );
      final b = NotificationFilter(
        type: NotificationType.limit,
        from: DateTime(2026, 9, 1),
      );
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });
  });
}
