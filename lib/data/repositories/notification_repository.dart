import '../models/app_notification.dart';

/// Репозиторий центра уведомлений.
abstract class NotificationRepository {
  /// Сохраняет (вставляет или обновляет) уведомление и возвращает его `id`.
  Future<int> save(AppNotification notification);

  /// Возвращает уведомление по идентификатору или `null`.
  Future<AppNotification?> getById(int id);

  /// Возвращает уведомление с указанным [dedupeKey] или `null`.
  ///
  /// Используется движком уведомлений для проверки, не сформировано ли уже
  /// уведомление по этому же событию.
  Future<AppNotification?> findByDedupeKey(String dedupeKey);

  /// Возвращает все уведомления, самые новые — первыми.
  Future<List<AppNotification>> getAll();

  /// Возвращает уведомления указанного типа, самые новые — первыми.
  Future<List<AppNotification>> getByType(NotificationType type);

  /// Возвращает непрочитанные уведомления, самые новые — первыми.
  Future<List<AppNotification>> getUnread();

  /// Количество непрочитанных уведомлений — для значка на иконке.
  Future<int> unreadCount();

  /// Помечает уведомление прочитанным.
  Future<void> markRead(int id);

  /// Помечает прочитанными все уведомления.
  Future<void> markAllRead();

  /// Количество уведомлений в центре.
  Future<int> count();

  /// Удаляет уведомление по идентификатору.
  Future<void> delete(int id);

  /// Удаляет уведомления старше [threshold] (хранение истории 30 дней).
  /// Возвращает количество удалённых записей.
  Future<int> purgeOlderThan(DateTime threshold);

  /// Удаляет все уведомления (используется в тестах).
  Future<void> clear();
}
