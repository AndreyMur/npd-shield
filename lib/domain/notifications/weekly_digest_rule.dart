import '../../core/constants/tax_constants.dart';
import '../../data/models/app_notification.dart';
import '../limit/limit_calculator.dart';
import 'notification_check_context.dart';
import 'notification_draft.dart';
import 'notification_rule.dart';

/// Правило еженедельного дайджеста.
///
/// Формируется по воскресеньям после [deliveryHour] (по умолчанию 10:00) и
/// содержит доход за последнюю неделю, налог, остаток до лимита и число сделок.
/// Ключ дедупликации привязан к дате воскресенья, поэтому за день создаётся
/// ровно одно уведомление.
class WeeklyDigestRule implements NotificationRule {
  /// Час дня, начиная с которого формируется дайджест.
  final int deliveryHour;

  const WeeklyDigestRule({this.deliveryHour = 10});

  @override
  List<NotificationDraft> evaluate(NotificationCheckContext context) {
    final now = context.now;
    if (now.weekday != DateTime.sunday) return const [];
    if (now.hour < deliveryHour) return const [];

    final today = DateTime(now.year, now.month, now.day);
    final weekStart = today.subtract(const Duration(days: 6));
    final weekEnd = today.add(const Duration(days: 1));

    final income = context.incomeInRange(weekStart, weekEnd);
    final tax = income * TaxConstants.rate;

    final deals = context.incomes
        .where(
          (transaction) =>
              !transaction.date.isBefore(weekStart) &&
              transaction.date.isBefore(weekEnd),
        )
        .length;

    final remaining = TaxConstants.limit - context.incomeForYear(now.year);
    final remainingText = remaining > 0
        ? '${LimitCalculator.formatAmount(remaining)} руб.'
        : 'лимит исчерпан';

    final incomeText = LimitCalculator.formatAmount(income);
    final taxText = LimitCalculator.formatAmount(tax);

    final key = 'digest:${today.year}-'
        '${today.month.toString().padLeft(2, '0')}-'
        '${today.day.toString().padLeft(2, '0')}';

    return [
      NotificationDraft(
        type: NotificationType.digest,
        title: 'Еженедельный дайджест',
        body: 'За неделю: доход $incomeText руб., налог $taxText руб., '
            'сделок: $deals. До лимита осталось $remainingText',
        payload: 'digest',
        actionLabel: 'Подробнее',
        dedupeKey: key,
      ),
    ];
  }
}
