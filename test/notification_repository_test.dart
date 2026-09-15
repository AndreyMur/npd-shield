import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:npd_shield/data/models/app_notification.dart';
import 'package:npd_shield/data/repositories/isar_notification_repository.dart';

void main() {
  late Isar isar;
  late IsarNotificationRepository repository;

  setUp(() async {
    final dir = await Directory.systemTemp.createTemp('npd_notification_test');
    isar = await Isar.open(
      [AppNotificationSchema],
      directory: dir.path,
      name: 'notification_test_${dir.path.hashCode}',
    );
    repository = IsarNotificationRepository(isar);
  });

  tearDown(() async {
    await isar.close(deleteFromDisk: true);
  });

  AppNotification note({
    NotificationType type = NotificationType.limit,
    NotificationStatus status = NotificationStatus.unread,
    String title = 'Заголовок',
    String body = 'Текст',
    DateTime? createdAt,
    String payload = '',
    String actionLabel = '',
  }) {
    return AppNotification(
      type: type,
      status: status,
      title: title,
      body: body,
      payload: payload,
      actionLabel: actionLabel,
      createdAt: createdAt ?? DateTime(2026, 9, 14, 10),
    );
  }

  group('IsarNotificationRepository', () {
    test('save присваивает id и позволяет прочитать уведомление', () async {
      final id = await repository.save(note(payload: 'invoice:42'));

      final found = await repository.getById(id);

      expect(id, isNot(0));
      expect(found, isNotNull);
      expect(found!.type, NotificationType.limit);
      expect(found.status, NotificationStatus.unread);
      expect(found.title, 'Заголовок');
      expect(found.payload, 'invoice:42');
      expect(found.isRead, isFalse);
    });

    test('getAll возвращает уведомления от новых к старым', () async {
      final now = DateTime(2026, 9, 14);
      await repository.save(note(createdAt: now.subtract(const Duration(days: 1))));
      await repository.save(note(createdAt: now));
      await repository.save(note(createdAt: now.subtract(const Duration(days: 2))));

      final all = await repository.getAll();

      expect(all.map((n) => n.createdAt).toList(), [
        now,
        now.subtract(const Duration(days: 1)),
        now.subtract(const Duration(days: 2)),
      ]);
    });

    test('getByType фильтрует по типу', () async {
      await repository.save(note(type: NotificationType.limit));
      await repository.save(note(type: NotificationType.invoice));
      await repository.save(note(type: NotificationType.invoice));

      final invoices = await repository.getByType(NotificationType.invoice);

      expect(invoices, hasLength(2));
      expect(invoices.every((n) => n.type == NotificationType.invoice), isTrue);
    });

    test('getUnread и unreadCount учитывают статус', () async {
      await repository.save(note());
      await repository.save(note(status: NotificationStatus.read));
      final unreadId = await repository.save(note());

      final unread = await repository.getUnread();

      expect(unread, hasLength(2));
      expect(await repository.unreadCount(), 2);

      await repository.markRead(unreadId);
      expect(await repository.unreadCount(), 1);
    });

    test('markRead помечает уведомление прочитанным с датой', () async {
      final id = await repository.save(note());

      await repository.markRead(id);

      final found = await repository.getById(id);
      expect(found!.isRead, isTrue);
      expect(found.readAt, isNotNull);
    });

    test('markAllRead помечает все непрочитанные', () async {
      await repository.save(note());
      await repository.save(note());
      await repository.save(note(status: NotificationStatus.read));

      await repository.markAllRead();

      expect(await repository.unreadCount(), 0);
      expect(await repository.count(), 3);
    });

    test('delete и clear удаляют уведомления', () async {
      final id1 = await repository.save(note());
      await repository.save(note());

      await repository.delete(id1);
      expect(await repository.getById(id1), isNull);
      expect(await repository.count(), 1);

      await repository.clear();
      expect(await repository.getAll(), isEmpty);
    });

    test('purgeOlderThan удаляет уведомления старше порога', () async {
      final now = DateTime(2026, 9, 14);
      await repository.save(note(createdAt: now.subtract(const Duration(days: 31))));
      await repository.save(note(createdAt: now.subtract(const Duration(days: 10))));

      final removed = await repository.purgeOlderThan(
        now.subtract(const Duration(days: 30)),
      );

      expect(removed, 1);
      expect(await repository.count(), 1);
    });
  });
}
