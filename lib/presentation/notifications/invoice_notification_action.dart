import '../../data/models/app_notification.dart';
import '../../data/repositories/invoice_repository.dart';

/// Результат выполнения действия из уведомления.
class NotificationActionResult {
  /// Действие выполнено и уведомление больше не актуально.
  final bool resolved;

  /// Сообщение для пользователя. `null` — без сообщения.
  final String? message;

  const NotificationActionResult({required this.resolved, this.message});

  /// Действие выполнено: уведомление можно убрать из центра.
  const NotificationActionResult.resolved([this.message]) : resolved = true;

  /// Действие не выполнено: уведомление остаётся в центре.
  const NotificationActionResult.keep([this.message]) : resolved = false;
}

/// Выполняет действия из уведомлений о счетах.
///
/// Разбирает [AppNotification.payload] вида `invoice:42` и отмечает счёт
/// полностью оплаченным. Класс не зависит от UI, поэтому действие можно
/// проверить виджет-тестом и переиспользовать в разных экранах.
class InvoiceNotificationAction {
  final InvoiceRepository invoiceRepository;

  /// Часы для даты оплаты (подменяются в тестах).
  final DateTime Function() clock;

  InvoiceNotificationAction({
    required this.invoiceRepository,
    DateTime Function()? clock,
  }) : clock = clock ?? DateTime.now;

  static const String _prefix = 'invoice:';

  /// Идентификатор счёта из [payload] вида `invoice:42` или `null`.
  static int? invoiceIdFromPayload(String payload) {
    if (!payload.startsWith(_prefix)) return null;
    return int.tryParse(payload.substring(_prefix.length));
  }

  /// Отмечает счёт из уведомления оплаченным.
  ///
  /// Счёт гасится полностью. Если счёт уже оплачен или не найден, уведомление
  /// всё равно считается неактуальным.
  Future<NotificationActionResult> markPaid(
    AppNotification notification,
  ) async {
    final invoiceId = invoiceIdFromPayload(notification.payload);
    if (invoiceId == null) return const NotificationActionResult.keep();

    try {
      final invoice = await invoiceRepository.getById(invoiceId);
      if (invoice == null) {
        return const NotificationActionResult.resolved('Счёт не найден');
      }
      if (invoice.isFullyPaid) {
        return const NotificationActionResult.resolved('Счёт уже оплачен');
      }
      final updated = await invoiceRepository.markPaid(
        invoiceId,
        paidAt: clock(),
      );
      return NotificationActionResult.resolved(
        updated.isFullyPaid ? 'Счёт оплачен' : 'Платёж учтён',
      );
    } catch (_) {
      return const NotificationActionResult.keep('Не удалось отметить оплату');
    }
  }
}
