import 'package:isar/isar.dart';

part 'document.g.dart';

/// Тип документа в едином архиве документов.
///
/// Порядок объявления задаёт группировку в архиве: чеки, затем акты,
/// затем договоры.
enum DocumentType {
  /// Кассовый чек для НПД.
  receipt,

  /// Акт выполненных работ.
  act,

  /// Договор (снимок сгенерированного договора).
  contract;

  /// Человекочитаемая метка типа для интерфейса и скринридеров.
  String get label => switch (this) {
    DocumentType.receipt => 'Чек',
    DocumentType.act => 'Акт',
    DocumentType.contract => 'Договор',
  };
}

/// Статус жизненного цикла документа.
enum DocumentStatus {
  /// Черновик — документ создан, но ещё не сформирован.
  draft,

  /// Документ сформирован (например, сгенерирован PDF).
  generated,

  /// Документ отправлен контрагенту.
  sent;

  /// Человекочитаемая метка статуса для интерфейса.
  String get label => switch (this) {
    DocumentStatus.draft => 'Черновик',
    DocumentStatus.generated => 'Сформирован',
    DocumentStatus.sent => 'Отправлен',
  };
}

/// Универсальная запись документа: чек, акт или договор.
///
/// Коллекция хранит и метаданные документа (тип, статус, привязки), и его
/// содержимое в денормализованном виде: контрагент, сумму, дату и наименование
/// услуги. Так архив документов не зависит от актуальности исходного договора
/// или транзакции и переживает их изменение.
///
/// Привязки хранятся в виде идентификаторов: [contractDraftId] ссылается на
/// `ContractDraft.id`, [transactionId] — на `Transaction.id`. Значение `0`
/// означает отсутствие привязки.
@collection
class Document {
  Id id = Isar.autoIncrement;

  /// Тип документа. Проиндексирован для фильтрации архива по типу.
  @Index()
  @enumerated
  DocumentType type;

  /// Текущий статус документа.
  @Index()
  @enumerated
  DocumentStatus status;

  /// Идентификатор договора (`ContractDraft.id`), к которому привязан документ.
  /// `0` — документ не привязан к договору.
  @Index()
  int contractDraftId;

  /// Номер договора на момент формирования документа.
  String contractNumber;

  /// Контрагент: наименование организации или ФИО.
  ///
  /// Строка шифруется на уровне поля (AES-256), поэтому не индексируется:
  /// поиск по контрагенту выполняется в памяти после расшифровки.
  String counterpartyName;

  /// Контрагент: ИНН.
  String counterpartyInn;

  /// Сумма документа в рублях.
  double amount;

  /// Дата документа (для чека — дата расчёта).
  @Index()
  DateTime date;

  /// Идентификатор транзакции (`Transaction.id`), к которой привязан документ.
  /// `0` — документ не привязан к транзакции.
  @Index()
  int transactionId;

  /// Идентификатор чека (`Document.id`), к которому привязан акт.
  /// `0` — документ не привязан к чеку.
  @Index()
  int receiptDocumentId;

  /// Полный текст договора (для экспорта договора в PDF).
  ///
  /// Для чеков и актов остаётся пустым. Строка шифруется на уровне поля.
  String content;

  /// Наименование услуги или работы (предмет расчёта).
  String serviceName;

  /// Результат выполненных работ (для акта).
  String result;

  /// Подпись исполнителя (ФИО/должность для распечатки акта).
  String executorSignatory;

  /// Подпись заказчика (ФИО/должность для распечатки акта).
  String customerSignatory;

  /// Исполнитель: ФИО (реквизит из профиля ИП).
  String issuerName;

  /// Исполнитель: ИНН.
  String issuerInn;

  /// Дата создания записи в базе.
  @Index()
  DateTime createdAt = DateTime.now();

  Document({
    required this.type,
    required this.amount,
    required this.date,
    this.status = DocumentStatus.draft,
    this.contractDraftId = 0,
    this.contractNumber = '',
    this.counterpartyName = '',
    this.counterpartyInn = '',
    this.transactionId = 0,
    this.receiptDocumentId = 0,
    this.content = '',
    this.serviceName = '',
    this.result = '',
    this.executorSignatory = '',
    this.customerSignatory = '',
    this.issuerName = '',
    this.issuerInn = '',
  });
}
