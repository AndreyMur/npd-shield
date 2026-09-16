import 'package:isar/isar.dart';

part 'invoice.g.dart';

/// Статус счёта.
///
/// [overdue] — вычисляемый статус: он не хранится в базе и не может быть
/// выставлен вручную. Просрочка определяется по сроку оплаты ([Invoice.dueDate])
/// и текущей дате ([Invoice.effectiveStatus]), поэтому счёт «становится»
/// просроченным сам, без участия пользователя.
enum InvoiceStatus {
  /// Черновик — счёт создан, но ещё не отправлен клиенту.
  draft,

  /// Счёт отправлен клиенту и ожидает оплаты.
  sent,

  /// Счёт полностью оплачен.
  paid,

  /// Срок оплаты прошёл, а счёт не оплачен полностью.
  overdue,

  /// Счёт отменён.
  cancelled;

  /// Человекочитаемая метка статуса для интерфейса.
  String get label => switch (this) {
    InvoiceStatus.draft => 'Черновик',
    InvoiceStatus.sent => 'Отправлен',
    InvoiceStatus.paid => 'Оплачен',
    InvoiceStatus.overdue => 'Просрочен',
    InvoiceStatus.cancelled => 'Отменён',
  };

  /// Статусы, которые пользователь может выбрать вручную.
  ///
  /// «Просрочен» в список не входит: он определяется автоматически по сроку
  /// оплаты, и попытка сохранить его отклоняется репозиторием.
  static const List<InvoiceStatus> manualValues = [
    InvoiceStatus.draft,
    InvoiceStatus.sent,
    InvoiceStatus.paid,
    InvoiceStatus.cancelled,
  ];

  /// Счёт полностью оплачен.
  bool get isPaid => this == InvoiceStatus.paid;

  /// Счёт отменён.
  bool get isCancelled => this == InvoiceStatus.cancelled;

  /// Счёт просрочен.
  bool get isOverdue => this == InvoiceStatus.overdue;
}

/// Счёт на оплату с учётом статуса и частичных оплат.
///
/// Счёт ссылается на клиента из справочника ([clientId]) и хранит его
/// денормализованные реквизиты (наименование и ИНН) на момент выставления:
/// строки шифруются на уровне поля (AES-256), поэтому поиск и сортировка по ним
/// выполняются в памяти после расшифровки. Удаление клиента счёт не затрагивает.
///
/// При полной оплате создаётся доход-операция, а её идентификатор сохраняется в
/// [transactionId]. Сумма частичных оплат накапливается в [paidAmount], остаток
/// к оплате — [outstanding].
@collection
class Invoice {
  Id id = Isar.autoIncrement;

  /// Номер счёта.
  String number;

  /// Идентификатор клиента (`Client.id`) из справочника. `0` — без привязки.
  @Index()
  int clientId;

  /// Контрагент: наименование организации или ФИО. Шифруется при хранении.
  String clientName;

  /// Контрагент: ИНН. Шифруется при хранении.
  String clientInn;

  /// Сумма счёта в рублях.
  double amount;

  /// Дата выставления счёта.
  @Index()
  DateTime issuedAt;

  /// Срок оплаты. По нему автоматически определяется просрочка.
  @Index()
  DateTime dueDate;

  /// Текущий статус счёта. «Просрочен» в базе не хранится.
  @Index()
  @enumerated
  InvoiceStatus status;

  /// Сумма, оплаченная по счёту. Частичные оплаты суммируются.
  double paidAmount;

  /// Дата последней оплаты. `null` — по счёту ещё не было платежей.
  DateTime? paidAt;

  /// Идентификатор дохода-операции (`Transaction.id`), созданной при полной
  /// оплате. `0` — доход ещё не создан.
  @Index()
  int transactionId;

  /// Произвольный комментарий пользователя. Шифруется при хранении.
  String comment;

  /// Дата создания записи в базе.
  @Index()
  DateTime createdAt = DateTime.now();

  Invoice({
    required this.number,
    required this.amount,
    required this.issuedAt,
    required this.dueDate,
    this.clientId = 0,
    this.clientName = '',
    this.clientInn = '',
    this.status = InvoiceStatus.draft,
    this.paidAmount = 0,
    this.paidAt,
    this.transactionId = 0,
    this.comment = '',
  });

  /// Допуск сравнения сумм в копейках: гасит погрешность дробных вычислений.
  static const double _cent = 0.005;

  /// Остаток к оплате. Никогда не бывает отрицательным.
  double get outstanding {
    final value = amount - paidAmount;
    return value > _cent ? value : 0;
  }

  /// Полностью ли оплачен счёт.
  bool get isFullyPaid => outstanding == 0;

  /// Статус счёта с учётом автоматической просрочки.
  ///
  /// Просроченным может стать только отправленный счёт ([InvoiceStatus.sent]):
  /// черновик ещё не выставлен клиенту, а оплаченный и отменённый счета
  /// просроченными не считаются. Счёт просрочен, если срок оплаты раньше начала
  /// текущего дня.
  InvoiceStatus effectiveStatus({DateTime? now}) {
    if (status != InvoiceStatus.sent) return status;
    final today = _startOfDay(now ?? DateTime.now());
    return _startOfDay(dueDate).isBefore(today)
        ? InvoiceStatus.overdue
        : status;
  }

  /// Просрочен ли счёт на дату [now] (по умолчанию — сейчас).
  bool isOverdue({DateTime? now}) =>
      effectiveStatus(now: now) == InvoiceStatus.overdue;

  static DateTime _startOfDay(DateTime date) =>
      DateTime(date.year, date.month, date.day);
}
