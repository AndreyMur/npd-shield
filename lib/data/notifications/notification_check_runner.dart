import '../../domain/notifications/anomaly_detector.dart';
import '../../domain/notifications/invoice_reminder_rule.dart';
import '../../domain/notifications/limit_monitor.dart';
import '../../domain/notifications/notification_check_context.dart';
import '../../domain/notifications/notification_engine.dart';
import '../../domain/notifications/notification_rule.dart';
import '../../domain/notifications/weekly_digest_rule.dart';
import '../../domain/notifications/notification_center.dart';
import '../models/app_notification.dart';
import '../repositories/invoice_repository.dart';
import '../repositories/notification_repository.dart';
import '../repositories/notification_settings_repository.dart';
import '../repositories/transaction_repository.dart';
import 'notification_service.dart';

/// Связывает репозитории, правила и доставку уведомлений в один прогон
/// фоновой проверки.
///
/// Используется и при старте приложения, и из фонового обработчика
/// `workmanager`, поэтому не зависит от UI.
class NotificationCheckRunner {
  final TransactionRepository transactionRepository;
  final InvoiceRepository invoiceRepository;
  final NotificationRepository notificationRepository;
  final NotificationSettingsRepository settingsRepository;
  final NotificationService notificationService;

  /// Правила проверки. Если не заданы — используется стандартный набор.
  final List<NotificationRule> rules;

  /// Часы для получения текущего времени (подменяются в тестах).
  final DateTime Function() clock;

  NotificationCheckRunner({
    required this.transactionRepository,
    required this.invoiceRepository,
    required this.notificationRepository,
    required this.settingsRepository,
    required this.notificationService,
    List<NotificationRule>? rules,
    DateTime Function()? clock,
  })  : rules = rules ?? defaultNotificationRules,
        clock = clock ?? DateTime.now;

  /// Стандартный набор правил: лимит, счета, аномалии, дайджест.
  static List<NotificationRule> get defaultNotificationRules => const [
    LimitMonitor(),
    InvoiceReminderRule(),
    AnomalyDetector(),
    WeeklyDigestRule(),
  ];

  /// Выполняет проверку условий и показывает созданные уведомления.
  ///
  /// Возвращает список новых уведомлений (для тестов и логирования).
  Future<List<AppNotification>> run({DateTime? now}) async {
    final moment = now ?? clock();
    final settings = await settingsRepository.load();
    final transactions = await transactionRepository.getAll();
    final invoices = await invoiceRepository.getAll();

    final context = NotificationCheckContext(
      now: moment,
      transactions: transactions,
      invoices: invoices,
      settings: settings,
    );

    final engine = NotificationEngine(
      repository: notificationRepository,
      rules: rules,
    );
    final created = await engine.run(context);

    await notificationRepository.purgeOlderThan(
      moment.subtract(notificationRetention),
    );

    for (final notification in created) {
      await notificationService.show(notification);
    }

    return created;
  }
}
