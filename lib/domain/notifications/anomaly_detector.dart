import '../../data/models/app_notification.dart';
import '../../data/models/transaction.dart';
import '../limit/limit_calculator.dart';
import 'notification_check_context.dart';
import 'notification_draft.dart';
import 'notification_rule.dart';

/// Правило обнаружения нестандартных операций.
///
/// Срабатывает по трём признакам:
/// 1. сумма операции превышает среднюю по операциям того же типа в
///    [amountMultiplier] раз и более (нужна история минимум из [minHistory]
///    операций);
/// 2. новый контрагент с крупной суммой (не меньше [largeAmountThreshold]);
/// 3. операция в необычное время (поздно вечером или ночью).
///
/// Анализируются только операции за последние [lookback], чтобы не поднимать
/// историю при первом запуске. Уникальный ключ по идентификатору операции
/// исключает повторные уведомления.
class AnomalyDetector implements NotificationRule {
  /// Окно анализа: операции не старше этого срока.
  final Duration lookback;

  /// Минимальное число операций того же типа для расчёта средней.
  final int minHistory;

  /// Во сколько раз сумма должна превышать среднюю, чтобы считаться аномалией.
  final double amountMultiplier;

  /// Порог крупной суммы для нового контрагента (в рублях).
  final double largeAmountThreshold;

  const AnomalyDetector({
    this.lookback = const Duration(days: 1),
    this.minHistory = 5,
    this.amountMultiplier = 3,
    this.largeAmountThreshold = 100000,
  });

  @override
  List<NotificationDraft> evaluate(NotificationCheckContext context) {
    final windowStart = context.now.subtract(lookback);
    final drafts = <NotificationDraft>[];

    final recent = context.transactions
        .where(
          (transaction) =>
              !transaction.date.isBefore(windowStart) &&
              !transaction.date.isAfter(context.now),
        )
        .toList(growable: false);

    for (final transaction in recent) {
      final history = context.transactionsExcept(transaction);

      final amountDraft = _amountDraft(transaction, history);
      if (amountDraft != null) drafts.add(amountDraft);

      final counterpartyDraft = _counterpartyDraft(transaction, history);
      if (counterpartyDraft != null) drafts.add(counterpartyDraft);

      final timeDraft = _timeDraft(transaction);
      if (timeDraft != null) drafts.add(timeDraft);
    }

    return drafts;
  }

  NotificationDraft? _amountDraft(
    Transaction transaction,
    List<Transaction> history,
  ) {
    final sameType = history
        .where((other) => other.type == transaction.type)
        .toList(growable: false);
    if (sameType.length < minHistory) return null;

    var total = 0.0;
    for (final other in sameType) {
      total += other.amount;
    }
    final average = total / sameType.length;
    if (average <= 0) return null;
    if (transaction.amount < average * amountMultiplier) return null;

    final times = (transaction.amount / average).floor();
    final amount = LimitCalculator.formatAmount(transaction.amount);
    return NotificationDraft(
      type: NotificationType.anomaly,
      title: 'Нестандартная сумма операции',
      body: 'Сумма $amount руб. превышает вашу среднюю примерно в $times раз. '
          'Проверьте корректность операции.',
      payload: 'transaction:${transaction.id}',
      dedupeKey: 'anomaly:tx:${transaction.id}:amount',
    );
  }

  NotificationDraft? _counterpartyDraft(
    Transaction transaction,
    List<Transaction> history,
  ) {
    if (transaction.amount < largeAmountThreshold) return null;
    final key = _counterpartyKey(transaction);
    if (key.isEmpty) return null;

    final known = history.any((other) => _counterpartyKey(other) == key);
    if (known) return null;

    final name = transaction.clientName.trim().isEmpty
        ? 'Без названия'
        : transaction.clientName.trim();
    final amount = LimitCalculator.formatAmount(transaction.amount);
    return NotificationDraft(
      type: NotificationType.anomaly,
      title: 'Новый контрагент с крупной суммой',
      body: 'Первая операция с «$name» на сумму $amount руб. '
          'Проверьте контрагента.',
      payload: 'transaction:${transaction.id}',
      dedupeKey: 'anomaly:tx:${transaction.id}:counterparty',
    );
  }

  NotificationDraft? _timeDraft(Transaction transaction) {
    final hour = transaction.date.hour;
    final minute = transaction.date.minute;
    // Только дата без времени (00:00) не считается необычным временем.
    if (hour == 0 && minute == 0) return null;
    final unusual = hour >= 23 || hour < 6;
    if (!unusual) return null;

    final time =
        '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
    return NotificationDraft(
      type: NotificationType.anomaly,
      title: 'Операция в необычное время',
      body: 'Операция добавлена в $time. Проверьте, всё ли верно.',
      payload: 'transaction:${transaction.id}',
      dedupeKey: 'anomaly:tx:${transaction.id}:time',
    );
  }

  /// Ключ контрагента: ИНН, а при его отсутствии — наименование без регистра.
  String _counterpartyKey(Transaction transaction) {
    final inn = transaction.clientInn.trim();
    if (inn.isNotEmpty) return 'inn:$inn';
    final name = transaction.clientName.trim().toLowerCase();
    return name.isEmpty ? '' : 'name:$name';
  }
}
