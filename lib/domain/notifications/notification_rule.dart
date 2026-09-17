import 'notification_check_context.dart';
import 'notification_draft.dart';

/// Правило формирования уведомлений.
///
/// Правило получает данные проверки и возвращает список заготовок. Оно не
/// обращается к хранилищу и не учитывает настройки и дедупликацию — это
/// ответственность движка [NotificationEngine].
abstract class NotificationRule {
  /// Вычисляет уведомления по текущим данным.
  List<NotificationDraft> evaluate(NotificationCheckContext context);
}
