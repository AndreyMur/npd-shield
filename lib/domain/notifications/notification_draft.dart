import '../../data/models/app_notification.dart';

/// Заготовка уведомления, сформированная правилом.
///
/// Правила не зависят от хранилища и лишь описывают, что нужно показать.
/// Движок уведомлений ([NotificationEngine]) сам проставляет дату, проверяет
/// настройки и дедупликацию и сохраняет запись.
class NotificationDraft {
  /// Тип уведомления.
  final NotificationType type;

  /// Заголовок уведомления.
  final String title;

  /// Текст уведомления.
  final String body;

  /// Данные для перехода к связанному объекту (например, `invoice:42`).
  final String payload;

  /// Подпись кнопки действия. Пусто — без действия.
  final String actionLabel;

  /// Уникальный ключ события. Гарантирует отсутствие дублей при повторных
  /// проверках одного и того же условия.
  final String dedupeKey;

  const NotificationDraft({
    required this.type,
    required this.title,
    required this.body,
    required this.dedupeKey,
    this.payload = '',
    this.actionLabel = '',
  });

  /// Преобразует заготовку в сохраняемую запись центра уведомлений.
  AppNotification toNotification({required DateTime createdAt}) {
    return AppNotification(
      type: type,
      title: title,
      body: body,
      createdAt: createdAt,
      payload: payload,
      actionLabel: actionLabel,
      dedupeKey: dedupeKey,
    );
  }
}
