import '../models/app_notification.dart';

/// Статус разрешения на показ уведомлений.
enum NotificationPermissionStatus {
  /// Разрешение выдано.
  granted,

  /// Разрешение отклонено пользователем.
  denied,

  /// Платформа не поддерживает уведомления.
  unsupported;

  /// Можно ли показывать уведомления.
  bool get isGranted => this == NotificationPermissionStatus.granted;
}

/// Сервис локальных уведомлений: разрешения, показ и отмена.
///
/// Абстракция отделяет приложение от `flutter_local_notifications`, чтобы
/// тесты и платформы без поддержки уведомлений работали через заглушку.
abstract class NotificationService {
  /// Инициализирует канал уведомлений. Безопасно вызывать повторно.
  Future<void> initialize();

  /// Запрашивает разрешение на показ уведомлений.
  Future<NotificationPermissionStatus> requestPermission();

  /// Показывает локальное уведомление.
  Future<void> show(AppNotification notification);

  /// Отменяет ранее показанное уведомление по [id].
  Future<void> cancel(int id);

  /// Отменяет все показанные уведомления.
  Future<void> cancelAll();
}

/// Заглушка сервиса уведомлений: ничего не показывает.
///
/// Используется в тестах и на платформах без поддержки уведомлений.
class NoopNotificationService implements NotificationService {
  const NoopNotificationService();

  @override
  Future<void> initialize() async {}

  @override
  Future<NotificationPermissionStatus> requestPermission() async =>
      NotificationPermissionStatus.unsupported;

  @override
  Future<void> show(AppNotification notification) async {}

  @override
  Future<void> cancel(int id) async {}

  @override
  Future<void> cancelAll() async {}
}
