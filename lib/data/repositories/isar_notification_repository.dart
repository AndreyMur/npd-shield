import 'package:isar/isar.dart';

import '../models/app_notification.dart';
import 'notification_repository.dart';

/// Реализация центра уведомлений поверх Isar.
///
/// Уведомления не содержат конфиденциальных данных, поэтому репозиторий не
/// шифрует поля — в отличие от архива документов и транзакций.
class IsarNotificationRepository implements NotificationRepository {
  final Isar isar;

  IsarNotificationRepository(this.isar);

  @override
  Future<int> save(AppNotification notification) {
    return isar.writeTxn(() => isar.appNotifications.put(notification));
  }

  @override
  Future<AppNotification?> getById(int id) {
    return isar.appNotifications.where().idEqualTo(id).findFirst();
  }

  @override
  Future<AppNotification?> findByDedupeKey(String dedupeKey) {
    return isar.appNotifications
        .filter()
        .dedupeKeyEqualTo(dedupeKey)
        .findFirst();
  }

  @override
  Future<List<AppNotification>> getAll() {
    return isar.appNotifications.where().sortByCreatedAtDesc().findAll();
  }

  @override
  Future<List<AppNotification>> getByType(NotificationType type) {
    return isar.appNotifications
        .filter()
        .typeEqualTo(type)
        .sortByCreatedAtDesc()
        .findAll();
  }

  @override
  Future<List<AppNotification>> getUnread() {
    return isar.appNotifications
        .filter()
        .statusEqualTo(NotificationStatus.unread)
        .sortByCreatedAtDesc()
        .findAll();
  }

  @override
  Future<int> unreadCount() {
    return isar.appNotifications
        .filter()
        .statusEqualTo(NotificationStatus.unread)
        .count();
  }

  @override
  Future<void> markRead(int id) {
    return isar.writeTxn(() async {
      final notification = await isar.appNotifications
          .where()
          .idEqualTo(id)
          .findFirst();
      if (notification == null || notification.isRead) return;
      notification.markRead();
      await isar.appNotifications.put(notification);
    });
  }

  @override
  Future<void> markAllRead() {
    return isar.writeTxn(() async {
      final unread = await isar.appNotifications
          .filter()
          .statusEqualTo(NotificationStatus.unread)
          .findAll();
      if (unread.isEmpty) return;
      final now = DateTime.now();
      for (final notification in unread) {
        notification.markRead(now);
      }
      await isar.appNotifications.putAll(unread);
    });
  }

  @override
  Future<int> count() {
    return isar.appNotifications.where().count();
  }

  @override
  Future<void> delete(int id) {
    return isar.writeTxn(() => isar.appNotifications.delete(id));
  }

  @override
  Future<int> purgeOlderThan(DateTime threshold) {
    return isar.writeTxn(() async {
      final stale = await isar.appNotifications
          .filter()
          .createdAtLessThan(threshold)
          .findAll();
      if (stale.isEmpty) return 0;
      await isar.appNotifications.deleteAll(
        stale.map((notification) => notification.id).toList(growable: false),
      );
      return stale.length;
    });
  }

  @override
  Future<void> clear() {
    return isar.writeTxn(() => isar.appNotifications.clear());
  }
}
