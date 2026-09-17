import '../../core/constants/tax_constants.dart';
import '../../data/models/app_notification.dart';
import '../limit/limit_calculator.dart';
import 'notification_check_context.dart';
import 'notification_draft.dart';
import 'notification_rule.dart';

/// Правило уведомлений о приближении к лимиту НПД.
///
/// Формирует уведомления при пересечении порогов (по умолчанию 80/90/95/100%)
/// и в контрольные сроки — за 60 и 30 дней до прогнозируемого исчерпания
/// лимита. Текст — «До лимита осталось X руб. (Y дней)».
///
/// За одну проверку формируется не более одного уведомления о пороге (самый
/// высокий пересечённый) и не более одного уведомления о сроке (самый близкий),
/// чтобы не заваливать пользователя. От повторных срабатываний защищает
/// уникальный ключ дедупликации.
class LimitMonitor implements NotificationRule {
  /// Калькулятор лимита. По умолчанию — годовой лимит НПД из констант.
  final LimitCalculator calculator;

  const LimitMonitor({this.calculator = const LimitCalculator()});

  @override
  List<NotificationDraft> evaluate(NotificationCheckContext context) {
    final year = context.now.year;
    final result = calculator.calculate(
      usedAmount: context.incomeForYear(year),
      averageMonthlyIncome: context.averageMonthlyIncome,
    );

    final drafts = <NotificationDraft>[];

    final threshold = _highestCrossedThreshold(
      result.ratio,
      context.settings.limitThresholds,
    );
    if (threshold != null) {
      final percent = (threshold * 100).round();
      drafts.add(
        NotificationDraft(
          type: NotificationType.limit,
          title: percent >= 100
              ? 'Лимит НПД исчерпан'
              : 'Доход достиг $percent% лимита НПД',
          body: _thresholdBody(result),
          payload: 'limit',
          dedupeKey: 'limit:threshold:$percent:$year',
        ),
      );
    }

    final days = result.daysRemaining;
    if (days != null && result.amountRemaining > 0) {
      if (days <= 30) {
        drafts.add(
          NotificationDraft(
            type: NotificationType.limit,
            title: 'До исчерпания лимита менее 30 дней',
            body: result.text,
            payload: 'limit',
            dedupeKey: 'limit:days:30:$year',
          ),
        );
      } else if (days <= 60) {
        drafts.add(
          NotificationDraft(
            type: NotificationType.limit,
            title: 'До исчерпания лимита менее 60 дней',
            body: result.text,
            payload: 'limit',
            dedupeKey: 'limit:days:60:$year',
          ),
        );
      }
    }

    return drafts;
  }

  String _thresholdBody(LimitResult result) {
    if (result.amountRemaining > 0) return result.text;
    final limit = LimitCalculator.formatAmount(TaxConstants.limit);
    return 'Годовой доход достиг $limit руб. Режим НПД может быть недоступен.';
  }

  /// Самый высокий порог, который пересечён при доле [ratio].
  static double? _highestCrossedThreshold(
    double ratio,
    List<double> thresholds,
  ) {
    const epsilon = 1e-9;
    double? highest;
    for (final threshold in thresholds) {
      if (ratio + epsilon < threshold) continue;
      if (highest == null || threshold > highest) highest = threshold;
    }
    return highest;
  }
}
