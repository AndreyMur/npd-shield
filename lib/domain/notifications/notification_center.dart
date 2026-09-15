import '../../data/models/app_notification.dart';

/// Срок хранения истории уведомлений в центре (30 дней).
const Duration notificationRetention = Duration(days: 30);

/// Временная группа уведомлений в центре.
enum NotificationDateGroup {
  /// Сегодняшние уведомления.
  today,

  /// Вчерашние уведомления.
  yesterday,

  /// Уведомления текущей недели (кроме сегодня и вчера).
  thisWeek,

  /// Уведомления старше текущей недели.
  earlier;

  /// Человекочитаемая метка группы для заголовка списка и скринридеров.
  String get label => switch (this) {
    NotificationDateGroup.today => 'Сегодня',
    NotificationDateGroup.yesterday => 'Вчера',
    NotificationDateGroup.thisWeek => 'На этой неделе',
    NotificationDateGroup.earlier => 'Ранее',
  };
}

/// Фильтр центра уведомлений: тип, статус, диапазон дат и поисковый запрос.
///
/// `null` в [type] и [status] означает «без фильтра». `null` в [from]/[to] —
/// отсутствие ограничения по дате. Пустой [query] не ограничивает выборку.
class NotificationFilter {
  final NotificationType? type;
  final NotificationStatus? status;

  /// Начало диапазона дат (включительно).
  final DateTime? from;

  /// Конец диапазона дат (включительно).
  final DateTime? to;

  /// Поисковый запрос по заголовку и тексту.
  final String query;

  const NotificationFilter({
    this.type,
    this.status,
    this.from,
    this.to,
    this.query = '',
  });

  /// Не задан ли ни один из фильтров.
  bool get isEmpty =>
      type == null &&
      status == null &&
      from == null &&
      to == null &&
      query.trim().isEmpty;

  /// Копия фильтра с изменёнными полями.
  ///
  /// Флаги `clear*` позволяют снять фильтр, потому что `null` в параметре
  /// означает «оставить как есть».
  NotificationFilter copyWith({
    NotificationType? type,
    NotificationStatus? status,
    DateTime? from,
    DateTime? to,
    String? query,
    bool clearType = false,
    bool clearStatus = false,
    bool clearDateRange = false,
  }) {
    return NotificationFilter(
      type: clearType ? null : (type ?? this.type),
      status: clearStatus ? null : (status ?? this.status),
      from: clearDateRange ? null : (from ?? this.from),
      to: clearDateRange ? null : (to ?? this.to),
      query: query ?? this.query,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is NotificationFilter &&
      other.type == type &&
      other.status == status &&
      other.from == from &&
      other.to == to &&
      other.query == query;

  @override
  int get hashCode => Object.hash(type, status, from, to, query);
}

/// Проверяет, соответствует ли уведомление поисковому запросу.
///
/// Поиск идёт по заголовку, тексту и метке типа. Регистр не учитывается.
bool matchesNotificationQuery(AppNotification notification, String query) {
  final normalized = query.trim().toLowerCase();
  if (normalized.isEmpty) return true;
  final haystack = [
    notification.title,
    notification.body,
    notification.type.label,
    notification.actionLabel,
  ].join(' ').toLowerCase();
  return haystack.contains(normalized);
}

/// Проверяет, попадает ли дата уведомления в диапазон фильтра.
bool _matchesDateRange(DateTime date, NotificationFilter filter) {
  if (filter.from != null && date.isBefore(filter.from!)) return false;
  if (filter.to != null && date.isAfter(filter.to!)) return false;
  return true;
}

/// Фильтрует уведомления по типу, статусу, диапазону дат и запросу.
List<AppNotification> filterNotifications({
  required List<AppNotification> notifications,
  required NotificationFilter filter,
}) {
  return notifications.where((notification) {
    if (filter.type != null && notification.type != filter.type) return false;
    if (filter.status != null && notification.status != filter.status) {
      return false;
    }
    if (!_matchesDateRange(notification.createdAt, filter)) return false;
    return matchesNotificationQuery(notification, filter.query);
  }).toList(growable: false);
}

/// Сортирует уведомления от новых к старым, не изменяя исходный список.
List<AppNotification> sortNotifications(
  List<AppNotification> notifications,
) {
  final result = List<AppNotification>.of(notifications);
  result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  return result;
}

/// Применяет фильтр и сортировку к центру уведомлений.
List<AppNotification> applyNotificationCenter({
  required List<AppNotification> notifications,
  NotificationFilter filter = const NotificationFilter(),
}) {
  final filtered = filterNotifications(
    notifications: notifications,
    filter: filter,
  );
  return sortNotifications(filtered);
}

/// Количество непрочитанных уведомлений.
int unreadNotificationCount(List<AppNotification> notifications) {
  return notifications.where((notification) => !notification.isRead).length;
}

/// Удаляет уведомления старше [notificationRetention] от [now].
///
/// Возвращает новый список; исходный не изменяется.
List<AppNotification> purgeExpiredNotifications({
  required List<AppNotification> notifications,
  DateTime? now,
}) {
  final threshold = (now ?? DateTime.now()).subtract(notificationRetention);
  return notifications
      .where((notification) => !notification.createdAt.isBefore(threshold))
      .toList(growable: false);
}

/// Начало дня для [date] — используется при группировке по дате.
DateTime startOfNotificationDay(DateTime date) =>
    DateTime(date.year, date.month, date.day);

/// Определяет временную группу уведомления относительно [now].
NotificationDateGroup notificationDateGroup(
  DateTime date, {
  required DateTime now,
}) {
  final day = startOfNotificationDay(date);
  final today = startOfNotificationDay(now);
  if (!day.isBefore(today)) return NotificationDateGroup.today;

  final yesterday = today.subtract(const Duration(days: 1));
  if (day == yesterday) return NotificationDateGroup.yesterday;

  // Начало текущей недели — понедельник.
  final weekStart = today.subtract(Duration(days: today.weekday - 1));
  if (!day.isBefore(weekStart)) return NotificationDateGroup.thisWeek;

  return NotificationDateGroup.earlier;
}

/// Группа уведомлений одного временного периода.
class NotificationGroup {
  /// Временная группа.
  final NotificationDateGroup group;

  /// Уведомления группы в порядке сортировки.
  final List<AppNotification> notifications;

  const NotificationGroup({required this.group, required this.notifications});
}

/// Группирует уведомления по дате, сохраняя порядок внутри групп.
///
/// Сами группы идут в хронологическом порядке: сегодня, вчера, на этой неделе,
/// ранее. Пустые группы не возвращаются.
List<NotificationGroup> groupNotificationsByDate(
  List<AppNotification> notifications, {
  required DateTime now,
}) {
  final grouped = <NotificationDateGroup, List<AppNotification>>{};
  for (final notification in notifications) {
    final group = notificationDateGroup(notification.createdAt, now: now);
    grouped.putIfAbsent(group, () => <AppNotification>[]).add(notification);
  }
  return [
    for (final group in NotificationDateGroup.values)
      if (grouped[group] != null)
        NotificationGroup(group: group, notifications: grouped[group]!),
  ];
}
