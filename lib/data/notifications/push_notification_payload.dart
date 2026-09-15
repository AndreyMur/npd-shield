import '../models/app_notification.dart';

/// Имя типа уведомления в данных push-сообщения.
String notificationTypeName(NotificationType type) => type.name;

/// Разбирает тип уведомления из строки push-сообщения.
///
/// Неизвестное или пустое значение трактуется как [NotificationType.digest],
/// чтобы уведомление не терялось из-за рассинхронизации версий.
NotificationType notificationTypeFromName(String? name) {
  if (name == null || name.isEmpty) return NotificationType.digest;
  return NotificationType.values.firstWhere(
    (type) => type.name == name,
    orElse: () => NotificationType.digest,
  );
}

/// Преобразует данные push-сообщения в запись центра уведомлений.
///
/// Заголовок и текст берутся из [data] (`title`, `body`), при их отсутствии —
/// из [fallbackTitle]/[fallbackBody] (например, из блока `notification`
/// FCM). Возвращает `null`, если в сообщении нет ни заголовка, ни текста.
AppNotification? notificationFromPushData(
  Map<String, dynamic> data, {
  String? fallbackTitle,
  String? fallbackBody,
  DateTime? receivedAt,
}) {
  final title = (data['title'] ?? fallbackTitle ?? '').toString().trim();
  final body = (data['body'] ?? fallbackBody ?? '').toString().trim();
  if (title.isEmpty && body.isEmpty) return null;

  return AppNotification(
    type: notificationTypeFromName(data['type']?.toString()),
    title: title,
    body: body,
    createdAt: receivedAt ?? DateTime.now(),
    payload: (data['payload'] ?? '').toString(),
    actionLabel: (data['actionLabel'] ?? '').toString(),
  );
}
