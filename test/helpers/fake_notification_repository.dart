import 'package:npd_shield/data/models/app_notification.dart';
import 'package:npd_shield/data/repositories/notification_repository.dart';

/// Фейковый репозиторий центра уведомлений для unit- и widget-тестов.
class FakeNotificationRepository implements NotificationRepository {
  final List<AppNotification> notifications;
  final bool failOnLoad;
  int _nextId = 1;

  FakeNotificationRepository([List<AppNotification>? initial, this.failOnLoad = false])
    : notifications = initial ?? [];

  factory FakeNotificationRepository.failing() =>
      FakeNotificationRepository(null, true);

  @override
  Future<int> save(AppNotification notification) async {
    final index = notifications.indexWhere(
      (item) => item.id == notification.id && notification.id > 0,
    );
    if (index >= 0) {
      notifications[index] = notification;
      return notification.id;
    }
    if (notification.id <= 0) {
      notification.id = _nextId++;
    } else if (notification.id >= _nextId) {
      _nextId = notification.id + 1;
    }
    notifications.add(notification);
    return notification.id;
  }

  @override
  Future<AppNotification?> getById(int id) async {
    for (final notification in notifications) {
      if (notification.id == id) return notification;
    }
    return null;
  }

  @override
  Future<List<AppNotification>> getAll() async {
    if (failOnLoad) throw Exception('load failed');
    final result = List.of(notifications);
    result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return result;
  }

  @override
  Future<List<AppNotification>> getByType(NotificationType type) async {
    final result = notifications.where((n) => n.type == type).toList();
    result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return result;
  }

  @override
  Future<List<AppNotification>> getUnread() async {
    final result = notifications.where((n) => !n.isRead).toList();
    result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return result;
  }

  @override
  Future<int> unreadCount() async =>
      notifications.where((n) => !n.isRead).length;

  @override
  Future<void> markRead(int id) async {
    for (final notification in notifications) {
      if (notification.id == id && !notification.isRead) {
        notification.markRead();
      }
    }
  }

  @override
  Future<void> markAllRead() async {
    final now = DateTime.now();
    for (final notification in notifications) {
      if (!notification.isRead) notification.markRead(now);
    }
  }

  @override
  Future<int> count() async => notifications.length;

  @override
  Future<void> delete(int id) async {
    notifications.removeWhere((n) => n.id == id);
  }

  @override
  Future<int> purgeOlderThan(DateTime threshold) async {
    final before = notifications.length;
    notifications.removeWhere((n) => n.createdAt.isBefore(threshold));
    return before - notifications.length;
  }

  @override
  Future<void> clear() async => notifications.clear();
}
