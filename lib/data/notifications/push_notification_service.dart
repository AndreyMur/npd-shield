import '../models/app_notification.dart';

/// Абстракция push-инфраструктуры: FCM для Android, APNs для iOS.
///
/// Конкретная реализация (Firebase) подключается на уровне приложения, а
/// тесты и платформы без push используют [NoopPushNotificationService].
abstract class PushNotificationService {
  /// Инициализирует push-канал и запрашивает разрешение.
  Future<void> initialize();

  /// Возвращает токен устройства (FCM/APNs) или `null`, если он недоступен.
  Future<String?> getToken();

  /// Поток входящих push-сообщений, приведённых к [AppNotification].
  Stream<AppNotification> get onMessage;

  /// Подписывает устройство на тему (например, тип уведомлений).
  Future<void> subscribeToTopic(String topic);

  /// Отписывает устройство от темы.
  Future<void> unsubscribeFromTopic(String topic);
}

/// Заглушка push-инфраструктуры: сообщений нет, токен отсутствует.
class NoopPushNotificationService implements PushNotificationService {
  const NoopPushNotificationService();

  @override
  Future<void> initialize() async {}

  @override
  Future<String?> getToken() async => null;

  @override
  Stream<AppNotification> get onMessage => const Stream<AppNotification>.empty();

  @override
  Future<void> subscribeToTopic(String topic) async {}

  @override
  Future<void> unsubscribeFromTopic(String topic) async {}
}
