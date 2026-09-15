import 'package:flutter/material.dart';

import '../../data/models/app_notification.dart';
import '../../data/notifications/notification_service.dart';
import '../../data/repositories/notification_repository.dart';
import '../../domain/notifications/notification_center.dart';
import 'notification_card.dart';

/// Диапазон дат для фильтра центра уведомлений.
enum NotificationDateFilter {
  /// Без ограничения по дате.
  all('Все время'),

  /// Только сегодняшние уведомления.
  today('Сегодня'),

  /// Уведомления за последние 7 дней.
  week('7 дней'),

  /// Уведомления за последние 30 дней.
  month('30 дней');

  const NotificationDateFilter(this.label);

  /// Подпись фильтра для чипа и скринридеров.
  final String label;

  /// Начало диапазона фильтра относительно [now]. `null` — без ограничения.
  DateTime? from(DateTime now) => switch (this) {
    NotificationDateFilter.all => null,
    NotificationDateFilter.today => startOfNotificationDay(now),
    NotificationDateFilter.week => startOfNotificationDay(
      now,
    ).subtract(const Duration(days: 6)),
    NotificationDateFilter.month => startOfNotificationDay(
      now,
    ).subtract(const Duration(days: 29)),
  };
}

/// Центр уведомлений: история за последние 30 дней.
///
/// Список группируется по дате (сегодня, вчера, на этой неделе, ранее) и
/// фильтруется по типу, статусу прочтения и диапазону дат. Уведомления можно
/// отмечать прочитанными (по нажатию) и непрочитанными, удалять с
/// возможностью отмены. При загрузке история старше 30 дней вычищается.
class NotificationCenterScreen extends StatefulWidget {
  final NotificationRepository repository;

  /// Сервис локальных уведомлений: отменяет системные уведомления при
  /// прочтении и удалении. По умолчанию — заглушка.
  final NotificationService notificationService;

  /// Источник текущего времени (для тестов). По умолчанию — [DateTime.now].
  final DateTime Function()? clock;

  /// Нажатие на карточку уведомления (переход к связанному объекту).
  final ValueChanged<AppNotification>? onNotificationTap;

  /// Нажатие на кнопку действия в карточке уведомления.
  final ValueChanged<AppNotification>? onNotificationAction;

  /// Изменение количества непрочитанных (для значка в навигации).
  final ValueChanged<int>? onUnreadCountChanged;

  const NotificationCenterScreen({
    super.key,
    required this.repository,
    this.notificationService = const NoopNotificationService(),
    this.clock,
    this.onNotificationTap,
    this.onNotificationAction,
    this.onUnreadCountChanged,
  });

  @override
  State<NotificationCenterScreen> createState() =>
      _NotificationCenterScreenState();
}

class _NotificationCenterScreenState extends State<NotificationCenterScreen> {
  List<AppNotification> _notifications = [];
  NotificationType? _typeFilter;
  NotificationStatus? _statusFilter;
  NotificationDateFilter _dateFilter = NotificationDateFilter.all;
  bool _grouped = true;
  bool _loading = true;
  Object? _error;

  DateTime get _now => (widget.clock ?? DateTime.now)();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final now = _now;
      await widget.repository.purgeOlderThan(now.subtract(notificationRetention));
      final notifications = await widget.repository.getAll();
      if (!mounted) return;
      setState(() {
        _notifications = notifications;
        _loading = false;
        _error = null;
      });
      _emitUnreadCount();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error;
        _loading = false;
      });
    }
  }

  NotificationFilter get _filter => NotificationFilter(
    type: _typeFilter,
    status: _statusFilter,
    from: _dateFilter.from(_now),
  );

  List<AppNotification> get _visible => applyNotificationCenter(
    notifications: _notifications,
    filter: _filter,
  );

  int get _unreadCount => unreadNotificationCount(_notifications);

  void _emitUnreadCount() {
    widget.onUnreadCountChanged?.call(_unreadCount);
  }

  void _selectType(NotificationType? type) {
    setState(() => _typeFilter = type);
  }

  void _selectStatus(NotificationStatus? status) {
    setState(() => _statusFilter = status);
  }

  void _selectDateFilter(NotificationDateFilter filter) {
    setState(() => _dateFilter = filter);
  }

  Future<void> _openNotification(AppNotification notification) async {
    await _markRead(notification);
    widget.onNotificationTap?.call(notification);
  }

  Future<void> _handleAction(AppNotification notification) async {
    await _markRead(notification);
    widget.onNotificationAction?.call(notification);
  }

  Future<void> _markRead(AppNotification notification) async {
    if (notification.isRead) return;
    await widget.repository.markRead(notification.id);
    await widget.notificationService.cancel(notification.id);
    if (!mounted) return;
    setState(() => notification.markRead(_now));
    _emitUnreadCount();
  }

  Future<void> _toggleRead(AppNotification notification) async {
    if (!notification.isRead) {
      await _markRead(notification);
      return;
    }
    notification.markUnread();
    await widget.repository.save(notification);
    if (!mounted) return;
    setState(() {});
    _emitUnreadCount();
  }

  Future<void> _markAllRead() async {
    await widget.repository.markAllRead();
    await widget.notificationService.cancelAll();
    if (!mounted) return;
    final now = _now;
    setState(() {
      for (final notification in _notifications) {
        if (!notification.isRead) notification.markRead(now);
      }
    });
    _emitUnreadCount();
  }

  Future<void> _delete(AppNotification notification) async {
    await widget.repository.delete(notification.id);
    await widget.notificationService.cancel(notification.id);
    if (!mounted) return;
    setState(() {
      _notifications.removeWhere((item) => item.id == notification.id);
    });
    _emitUnreadCount();

    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        content: const Text('Уведомление удалено'),
        action: SnackBarAction(
          label: 'Отменить',
          onPressed: () => _restore(notification),
        ),
      ),
    );
  }

  Future<void> _restore(AppNotification notification) async {
    await widget.repository.save(notification);
    if (!mounted) return;
    setState(() => _notifications.add(notification));
    _emitUnreadCount();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Уведомления'),
        actions: [
          if (_unreadCount > 0)
            IconButton(
              key: const Key('notification_mark_all_read'),
              tooltip: 'Прочитать все',
              icon: const Icon(Icons.done_all),
              onPressed: _markAllRead,
            ),
          IconButton(
            key: const Key('notification_group_toggle'),
            tooltip: _grouped
                ? 'Отключить группировку по дате'
                : 'Группировать по дате',
            isSelected: _grouped,
            icon: const Icon(Icons.workspaces_outline),
            selectedIcon: const Icon(Icons.workspaces),
            onPressed: () => setState(() => _grouped = !_grouped),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildTypeFilters(),
          _buildStatusFilters(),
          _buildDateFilters(),
          const Divider(height: 1),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildTypeFilters() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          _FilterChip(
            key: const Key('notification_type_filter_all'),
            label: 'Все',
            selected: _typeFilter == null,
            onSelected: () => _selectType(null),
          ),
          for (final type in NotificationType.values)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: _FilterChip(
                key: Key('notification_type_filter_${type.name}'),
                label: type.label,
                selected: _typeFilter == type,
                onSelected: () => _selectType(type),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatusFilters() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        children: [
          _FilterChip(
            key: const Key('notification_status_filter_all'),
            label: 'Все статусы',
            selected: _statusFilter == null,
            onSelected: () => _selectStatus(null),
          ),
          _FilterChip(
            key: const Key('notification_status_filter_unread'),
            label: 'Непрочитанные',
            selected: _statusFilter == NotificationStatus.unread,
            onSelected: () => _selectStatus(NotificationStatus.unread),
          ),
          _FilterChip(
            key: const Key('notification_status_filter_read'),
            label: 'Прочитанные',
            selected: _statusFilter == NotificationStatus.read,
            onSelected: () => _selectStatus(NotificationStatus.read),
          ),
        ],
      ),
    );
  }

  Widget _buildDateFilters() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        children: [
          for (final filter in NotificationDateFilter.values)
            Padding(
              padding: EdgeInsets.only(
                left: filter == NotificationDateFilter.all ? 0 : 8,
              ),
              child: _FilterChip(
                key: Key('notification_date_filter_${filter.name}'),
                label: filter.label,
                selected: _dateFilter == filter,
                onSelected: () => _selectDateFilter(filter),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Не удалось загрузить уведомления'),
            const SizedBox(height: 12),
            OutlinedButton(
              key: const Key('notification_center_retry'),
              onPressed: _load,
              child: const Text('Повторить'),
            ),
          ],
        ),
      );
    }
    final entries = _buildEntries();
    if (entries.isEmpty) {
      return Center(
        child: Text(
          _notifications.isEmpty ? 'Уведомлений пока нет' : 'Ничего не найдено',
          key: const Key('notification_center_empty'),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: () => _load(silent: true),
      child: ListView.builder(
        key: const Key('notification_center_list'),
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        itemCount: entries.length,
        itemBuilder: (context, index) {
          final entry = entries[index];
          if (entry.group != null) return _buildGroupHeader(entry.group!);
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildCard(entry.notification!),
          );
        },
      ),
    );
  }

  Widget _buildCard(AppNotification notification) {
    return NotificationCard(
      notification: notification,
      now: _now,
      onTap: () => _openNotification(notification),
      onAction: notification.hasAction
          ? () => _handleAction(notification)
          : null,
      onToggleRead: () => _toggleRead(notification),
      onDelete: () => _delete(notification),
    );
  }

  Widget _buildGroupHeader(NotificationGroup group) {
    final theme = Theme.of(context);
    return Padding(
      key: Key('notification_group_${group.group.name}'),
      padding: const EdgeInsets.fromLTRB(4, 12, 4, 8),
      child: Semantics(
        header: true,
        child: Row(
          children: [
            Expanded(
              child: Text(
                group.group.label,
                style: theme.textTheme.titleSmall,
              ),
            ),
            Text(
              '${group.notifications.length}',
              style: theme.textTheme.labelSmall,
            ),
          ],
        ),
      ),
    );
  }

  List<_CenterEntry> _buildEntries() {
    final visible = _visible;
    if (!_grouped) {
      return [for (final notification in visible) _CenterEntry(notification)];
    }
    return [
      for (final group in groupNotificationsByDate(visible, now: _now)) ...[
        _CenterEntry.group(group),
        for (final notification in group.notifications)
          _CenterEntry(notification),
      ],
    ];
  }
}

/// Элемент плоского списка центра: заголовок группы или уведомление.
class _CenterEntry {
  final NotificationGroup? group;
  final AppNotification? notification;

  const _CenterEntry(this.notification) : group = null;

  const _CenterEntry.group(this.group) : notification = null;
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onSelected;

  const _FilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
    );
  }
}
