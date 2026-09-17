import '../../core/constants/contract_field_keys.dart';
import '../../data/models/app_notification.dart';
import '../../data/models/invoice.dart';
import '../limit/limit_calculator.dart';
import 'notification_check_context.dart';
import 'notification_draft.dart';
import 'notification_rule.dart';

/// Правило напоминаний о неоплаченных счетах.
///
/// Формирует напоминания за 3/7/14 дней до срока оплаты (сроки настраиваются)
/// и отдельное уведомление о просрочке. Черновики, отменённые и полностью
/// оплаченные счета игнорируются. Каждое напоминание имеет уникальный ключ,
/// поэтому повторные проверки не создают дублей.
class InvoiceReminderRule implements NotificationRule {
  /// Подпись кнопки действия в уведомлении о счёте.
  static const String actionLabel = 'Отметить оплаченным';

  const InvoiceReminderRule();

  @override
  List<NotificationDraft> evaluate(NotificationCheckContext context) {
    final drafts = <NotificationDraft>[];
    final now = context.now;
    final today = DateTime(now.year, now.month, now.day);

    final invoices = List<Invoice>.of(context.invoices)
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));

    for (final invoice in invoices) {
      if (!_isPayable(invoice)) continue;

      final due = DateTime(
        invoice.dueDate.year,
        invoice.dueDate.month,
        invoice.dueDate.day,
      );
      final daysUntilDue = due.difference(today).inDays;

      if (daysUntilDue < 0) {
        drafts.add(_overdueDraft(invoice, -daysUntilDue));
        continue;
      }

      if (context.settings.invoiceReminderDays.contains(daysUntilDue)) {
        drafts.add(_reminderDraft(invoice, daysUntilDue));
      }
    }

    return drafts;
  }

  /// Счёт участвует в напоминаниях: выставлен (не черновик), не оплачен
  /// полностью, не отменён и имеет остаток к оплате.
  bool _isPayable(Invoice invoice) {
    if (invoice.status == InvoiceStatus.draft) return false;
    if (invoice.status == InvoiceStatus.cancelled) return false;
    if (invoice.status == InvoiceStatus.paid) return false;
    return invoice.outstanding > 0;
  }

  NotificationDraft _reminderDraft(Invoice invoice, int days) {
    final amount = LimitCalculator.formatAmount(invoice.outstanding);
    final date = formatContractDate(invoice.dueDate);
    final left = LimitCalculator.pluralDays(days);
    return NotificationDraft(
      type: NotificationType.invoice,
      title: 'Скоро срок оплаты счёта',
      body: 'Счёт №${invoice.number} на $amount руб. '
          'нужно оплатить до $date. Осталось $left.',
      payload: 'invoice:${invoice.id}',
      actionLabel: actionLabel,
      dedupeKey: 'invoice:${invoice.id}:reminder:$days',
    );
  }

  NotificationDraft _overdueDraft(Invoice invoice, int days) {
    final amount = LimitCalculator.formatAmount(invoice.outstanding);
    final late = LimitCalculator.pluralDays(days);
    return NotificationDraft(
      type: NotificationType.invoice,
      title: 'Счёт просрочен',
      body: 'Счёт №${invoice.number} на $amount руб. '
          'просрочен на $late.',
      payload: 'invoice:${invoice.id}',
      actionLabel: actionLabel,
      dedupeKey: 'invoice:${invoice.id}:overdue',
    );
  }
}
