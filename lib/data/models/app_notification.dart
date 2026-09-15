import 'package:isar/isar.dart';

part 'app_notification.g.dart';

/// Тип уведомления в центре уведомлений.
///
/// Порядок объявления задаёт группировку и порядок фильтров в интерфейсе.
enum NotificationType {
  /// Приближение к лимиту 2.4 млн и прогноз исчерпания.
  limit,

  /// Напоминание о неоплаченном счёте.
  invoice,

  /// Предупреждение о нестандартной транзакции.
  anomaly,

  /// Еженедельный дайджест.
  digest;

  /// Человекочитаемая метка типа для интерфейса и скринридеров.
  String get label => switch (this) {
    NotificationType.limit => 'Лимит',
    NotificationType.invoice => 'Счёт',
    NotificationType.anomaly => 'Аномалия',
    NotificationType.digest => 'Дайджест',
  };

  /// Краткое описание типа — подсказка в фильтрах и настройках.
  String get description => switch (this) {
    NotificationType.limit => 'Приближение к лимиту 2.4 млн',
    NotificationType.invoice => 'Напоминания о неоплаченных счетах',
    NotificationType.anomaly => 'Нестандартные транзакции',
    NotificationType.digest => 'Еженедельная сводка',
  };
}

/// Статус прочтения уведомления.
enum NotificationStatus {
  /// Уведомление ещё не прочитано.
  unread,

  /// Уведомление прочитано пользователем.
  read;

  /// Человекочитаемая метка статуса для интерфейса и скринридеров.
  String get label => switch (this) {
    NotificationStatus.unread => 'Непрочитанное',
    NotificationStatus.read => 'Прочитанное',
  };
}

/// Запись центра уведомлений: одно доставленное пользователю уведомление.
///
/// Коллекция хранит и содержимое уведомления (тип, заголовок, текст, дату),
/// и его состояние (прочитано/непрочитано). [payload] — строковые данные для
/// перехода к связанному объекту (например, идентификатор счёта), [actionLabel]
/// — подпись кнопки действия в карточке.
///
/// Уведомления не содержат конфиденциальных данных (сумм и реквизитов),
/// поэтому поля не шифруются.
@collection
class AppNotification {
  Id id = Isar.autoIncrement;

  /// Тип уведомления. Проиндексирован для фильтрации центра по типу.
  @Index()
  @enumerated
  NotificationType type;

  /// Статус прочтения. Проиндексирован для выборки непрочитанных.
  @Index()
  @enumerated
  NotificationStatus status;

  /// Заголовок уведомления.
  String title;

  /// Текст уведомления.
  String body;

  /// Дата и время получения уведомления. Проиндексирована для сортировки
  /// и фильтрации по дате.
  @Index()
  DateTime createdAt;

  /// Данные для перехода к связанному объекту (например, `invoice:42`).
  String payload;

  /// Подпись кнопки действия в карточке уведомления. Пусто — без действия.
  String actionLabel;

  /// Дата и время прочтения. `null` — уведомление не прочитано.
  DateTime? readAt;

  AppNotification({
    required this.type,
    required this.title,
    required this.body,
    required this.createdAt,
    this.status = NotificationStatus.unread,
    this.payload = '',
    this.actionLabel = '',
    this.readAt,
  });

  /// Прочитано ли уведомление.
  bool get isRead => status == NotificationStatus.read;

  /// Есть ли у уведомления действие.
  bool get hasAction => actionLabel.trim().isNotEmpty;

  /// Помечает уведомление прочитанным.
  void markRead([DateTime? at]) {
    status = NotificationStatus.read;
    readAt = at ?? DateTime.now();
  }

  /// Помечает уведомление непрочитанным.
  void markUnread() {
    status = NotificationStatus.unread;
    readAt = null;
  }
}
