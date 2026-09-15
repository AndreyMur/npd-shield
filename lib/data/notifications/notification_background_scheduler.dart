import 'package:flutter/foundation.dart';
import 'package:workmanager/workmanager.dart';

/// Имя периодической фоновой задачи проверки условий уведомлений.
///
/// Используется и как уникальное имя задачи (в планировщике), и как имя,
/// которое получает обработчик в [notificationBackgroundDispatcher].
const String notificationBackgroundTaskName = 'npd_shield_notification_check';

/// Точка входа фоновой задачи workmanager.
///
/// Запускается платформой в отдельном изоляте, поэтому не имеет доступа к
/// объектам основного приложения. Здесь выполняется периодическая проверка
/// условий (лимит, счета, аномалии, дайджест); формирование и отправка
/// уведомлений подключаются в следующих фазах. Сейчас задача подтверждает
/// работоспособность инфраструктуры и всегда сообщает об успехе, чтобы
/// планировщик не повторял её бесконечно.
@pragma('vm:entry-point')
void notificationBackgroundDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    return taskName == notificationBackgroundTaskName;
  });
}

/// Планировщик периодической проверки условий уведомлений.
///
/// Абстракция отделяет приложение от `workmanager`, чтобы тесты и платформы
/// без поддержки фоновых задач работали через [NoopNotificationBackgroundScheduler].
abstract class NotificationBackgroundScheduler {
  /// Инициализирует планировщик и регистрирует точку входа.
  Future<void> initialize();

  /// Планирует периодическую проверку условий с заданной [frequency].
  Future<void> schedulePeriodicCheck({Duration? frequency});

  /// Отменяет ранее запланированную проверку.
  Future<void> cancel();
}

/// Заглушка планировщика: задачи не планируются.
class NoopNotificationBackgroundScheduler
    implements NotificationBackgroundScheduler {
  const NoopNotificationBackgroundScheduler();

  @override
  Future<void> initialize() async {}

  @override
  Future<void> schedulePeriodicCheck({Duration? frequency}) async {}

  @override
  Future<void> cancel() async {}
}

/// Планировщик на базе `workmanager`.
///
/// Платформы без поддержки фоновых задач (например, Windows) переводят
/// планировщик в недоступное состояние: ошибки не пробрасываются наружу,
/// чтобы не ронять приложение.
class WorkmanagerNotificationBackgroundScheduler
    implements NotificationBackgroundScheduler {
  WorkmanagerNotificationBackgroundScheduler({
    this.defaultFrequency = const Duration(hours: 1),
  });

  /// Частота проверки по умолчанию, если она не задана явно.
  final Duration defaultFrequency;

  bool _available = false;

  /// Доступны ли фоновые задачи после инициализации.
  bool get isAvailable => _available;

  @override
  Future<void> initialize() async {
    try {
      await Workmanager().initialize(notificationBackgroundDispatcher);
      _available = true;
    } catch (error) {
      debugPrint('Фоновые задачи недоступны: $error');
      _available = false;
    }
  }

  @override
  Future<void> schedulePeriodicCheck({Duration? frequency}) async {
    if (!_available) return;
    try {
      await Workmanager().registerPeriodicTask(
        notificationBackgroundTaskName,
        notificationBackgroundTaskName,
        frequency: frequency ?? defaultFrequency,
        constraints: Constraints(networkType: NetworkType.notRequired),
        existingWorkPolicy: ExistingPeriodicWorkPolicy.update,
      );
    } catch (error) {
      debugPrint('Не удалось запланировать фоновую задачу: $error');
    }
  }

  @override
  Future<void> cancel() async {
    if (!_available) return;
    try {
      await Workmanager().cancelByUniqueName(notificationBackgroundTaskName);
    } catch (_) {
      // Отмена не критична: задачи могло не быть.
    }
  }
}
