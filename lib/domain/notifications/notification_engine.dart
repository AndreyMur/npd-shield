import '../../data/models/app_notification.dart';
import '../../data/repositories/notification_repository.dart';
import 'notification_check_context.dart';
import 'notification_draft.dart';
import 'notification_rule.dart';

/// Движок уведомлений: запускает правила, применяет настройки и дедупликацию
/// и сохраняет новые уведомления в центр.
///
/// Движок не показывает системные уведомления — это делает вызывающая сторона
/// (см. `NotificationCheckRunner`), поэтому движок остаётся чистым и
/// тестируемым без Flutter-плагинов.
class NotificationEngine {
  /// Хранилище центра уведомлений.
  final NotificationRepository repository;

  /// Правила, участвующие в проверке.
  final List<NotificationRule> rules;

  const NotificationEngine({required this.repository, required this.rules});

  /// Выполняет проверку и возвращает список созданных уведомлений.
  ///
  /// Уведомление пропускается, если:
  /// * его тип выключен в настройках;
  /// * сейчас тихие часы (уведомление будет создано при следующей проверке
  ///   вне тихих часов);
  /// * уведомление с таким же ключом уже есть (защита от дублей);
  /// * ключ дедупликации пуст.
  Future<List<AppNotification>> run(NotificationCheckContext context) async {
    final drafts = <NotificationDraft>[];
    for (final rule in rules) {
      drafts.addAll(rule.evaluate(context));
    }

    final created = <AppNotification>[];
    final seenKeys = <String>{};

    for (final draft in drafts) {
      if (!context.settings.isTypeEnabled(draft.type)) continue;
      if (draft.dedupeKey.isEmpty) continue;
      if (!seenKeys.add(draft.dedupeKey)) continue;
      if (context.settings.isQuietAt(context.now)) continue;

      final existing = await repository.findByDedupeKey(draft.dedupeKey);
      if (existing != null) continue;

      final notification = draft.toNotification(createdAt: context.now);
      await repository.save(notification);
      created.add(notification);
    }

    return created;
  }
}
