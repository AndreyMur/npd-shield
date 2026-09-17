import 'package:flutter/material.dart';

import '../../core/theme/app_tokens.dart';
import '../../core/widgets/widgets.dart';
import '../../data/models/app_notification.dart';
import 'notification_time.dart';
import 'notification_type_visuals.dart';

/// Действия в меню карточки уведомления.
enum NotificationCardAction {
  /// Переключить статус прочтения.
  toggleRead,

  /// Удалить уведомление.
  delete,
}

/// Карточка одного уведомления в центре.
///
/// Показывает иконку типа, заголовок, текст, время и (при наличии) кнопку
/// действия. Непрочитанные уведомления выделяются жирным заголовком и
/// цветной точкой. Меню карточки позволяет сменить статус прочтения и
/// удалить уведомление.
class NotificationCard extends StatelessWidget {
  final AppNotification notification;

  /// Опорное время для относительных подписей (по умолчанию — текущее).
  final DateTime? now;

  final VoidCallback? onTap;

  /// Нажатие на кнопку действия уведомления (например, «Отметить как оплаченный»).
  final VoidCallback? onAction;

  /// Переключение статуса прочтения из меню карточки.
  final VoidCallback? onToggleRead;

  /// Удаление уведомления из меню карточки.
  final VoidCallback? onDelete;

  const NotificationCard({
    super.key,
    required this.notification,
    this.now,
    this.onTap,
    this.onAction,
    this.onToggleRead,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = AppTokens.of(context);
    final color = notification.type.color(tokens);
    final unread = !notification.isRead;

    return AppCard(
      key: Key('notification_card_${notification.id}'),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.xxs,
        AppSpacing.sm,
      ),
      onTap: onTap,
      semanticLabel: _semanticsLabel(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: color.withValues(alpha: 0.14),
            child: Icon(notification.type.icon, color: color, size: 20),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (unread)
                      Padding(
                        key: Key('notification_unread_${notification.id}'),
                        padding: const EdgeInsets.only(top: 6, right: 6),
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: color,
                          ),
                        ),
                      ),
                    Expanded(
                      child: Text(
                        notification.title,
                        style: unread
                            ? theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              )
                            : theme.textTheme.titleSmall,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        formatNotificationTime(
                          notification.createdAt,
                          now: now,
                        ),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: tokens.muted,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(notification.body, style: theme.textTheme.bodyMedium),
                if (notification.hasAction) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: AppButton(
                      key: Key('notification_action_${notification.id}'),
                      label: notification.actionLabel,
                      variant: AppButtonVariant.secondary,
                      onPressed: onAction,
                    ),
                  ),
                ],
              ],
            ),
          ),
          PopupMenuButton<NotificationCardAction>(
            key: Key('notification_menu_${notification.id}'),
            tooltip: 'Действия с уведомлением',
            onSelected: (action) {
              switch (action) {
                case NotificationCardAction.toggleRead:
                  onToggleRead?.call();
                case NotificationCardAction.delete:
                  onDelete?.call();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem<NotificationCardAction>(
                value: NotificationCardAction.toggleRead,
                child: Text(
                  unread
                      ? 'Отметить прочитанным'
                      : 'Отметить непрочитанным',
                ),
              ),
              const PopupMenuItem<NotificationCardAction>(
                value: NotificationCardAction.delete,
                child: Text('Удалить'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _semanticsLabel() {
    final status = notification.isRead ? 'прочитано' : 'не прочитано';
    final time = formatNotificationTime(notification.createdAt, now: now);
    return '${notification.type.label}. ${notification.title}. '
        '${notification.body}. $time. $status';
  }
}
