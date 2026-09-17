import 'package:flutter/foundation.dart';
import 'package:workmanager/workmanager.dart';

import '../database.dart';
import '../models/app_notification.dart';
import '../repositories/isar_invoice_repository.dart';
import '../repositories/isar_notification_repository.dart';
import '../repositories/isar_transaction_repository.dart';
import '../repositories/notification_settings_repository.dart';
import 'flutter_local_notification_service.dart';
import 'notification_check_runner.dart';

/// Имя периодической фоновой задачи проверки условий уведомлений.
///
/// Используется и как уникальное имя задачи (в планировщике), и как имя,
/// которое получает обработчик в [notificationBackgroundDispatcher].
const String notificationBackgroundTaskName = 'npd_shield_notification_check';

/// Точка входа фоновой задачи workmanager.
///
/// Запускается платформой в отдельном изоляте. Открывает базу данных, прогоняет
/// правила уведомлений и показывает новые уведомления. Ошибки подавляются,
/// чтобы планировщик не повторял задачу бесконечно.
@pragma('vm:entry-point')
void notificationBackgroundDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    if (taskName != notificationBackgroundTaskName) return true;
    try {
      await runBackgroundNotificationCheck();
    } catch (error) {
      debugPrint('Фоновая проверка уведомлений не удалась: $error');
    }
    return true;
  });
}

/// Прогоняет проверку уведомлений на реальных репозиториях.
///
/// Отдельная функция нужна, чтобы фоновый изоляте мог собрать зависимости без
/// доступа к объектам основного приложения.
Future<List<AppNotification>> runBackgroundNotificationCheck({
  DateTime? now,
}) async {
  final isar = await AppDatabase.open();
  final transactionRepository = IsarTransactionRepository(isar);
  final invoiceRepository = IsarInvoiceRepository(isar, transactionRepository);
  final notificationRepository = IsarNotificationRepository(isar);
  final settingsRepository = SharedPrefsNotificationSettingsRepository();
  final notificationService = FlutterLocalNotificationService();
  await notificationService.initialize();

  final runner = NotificationCheckRunner(
    transactionRepository: transactionRepository,
    invoiceRepository: invoiceRepository,
    notificationRepository: notificationRepository,
    settingsRepository: settingsRepository,
    notificationService: notificationService,
  );
  return runner.run(now: now);
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
