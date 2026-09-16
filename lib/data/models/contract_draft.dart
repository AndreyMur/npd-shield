import 'package:isar/isar.dart';

part 'contract_draft.g.dart';

/// Статус жизненного цикла договора.
enum ContractStatus {
  /// Черновик — заполнен частично или полностью, документ ещё не подписан.
  draft,

  /// Договор подписан сторонами.
  signed,

  /// Договор в архиве.
  archived,
}

/// Значение одного заполненного поля черновика договора.
///
/// Isar не хранит `Map` напрямую, поэтому набор заполненных полей
/// представляется списком встраиваемых объектов «ключ — значение».
@embedded
class DraftFieldValue {
  /// Ключ поля (совпадает с плейсхолдером в тексте шаблона).
  String key;

  /// Значение, введённое пользователем.
  String value;

  DraftFieldValue({this.key = '', this.value = ''});
}

/// Преобразует карту заполненных полей в список, хранимый в Isar.
List<DraftFieldValue> contractFieldsFromMap(Map<String, String> fields) {
  return [
    for (final entry in fields.entries)
      DraftFieldValue(key: entry.key, value: entry.value),
  ];
}

/// Преобразует хранимый список полей обратно в карту.
Map<String, String> contractFieldsToMap(List<DraftFieldValue> fields) {
  return {for (final field in fields) field.key: field.value};
}

/// Черновик договора: результат выбора шаблона и заполнения формы.
///
/// [templateId] ссылается на стабильный код шаблона (`Template.code`),
/// [filledFields] содержит значения полей формы, ключи которых совпадают
/// с плейсхолдерами `{{...}}` в тексте шаблона.
@collection
class ContractDraft {
  Id id = Isar.autoIncrement;

  /// Код выбранного шаблона (`Template.code`).
  @Index()
  late String templateId;

  /// Заполненные поля договора.
  List<DraftFieldValue> filledFields = [];

  /// Текущий статус договора.
  ///
  /// Проиндексирован: архив фильтрует договоры по статусу без полного
  /// сканирования коллекции.
  @Index()
  @enumerated
  ContractStatus status = ContractStatus.draft;

  /// Идентификатор клиента (`Client.id`) из справочника, выбранного заказчиком.
  /// `0` — заказчик не выбран из справочника. Удаление клиента не затрагивает
  /// договор: связь остаётся в истории.
  @Index()
  int clientId = 0;

  /// Дата создания черновика.
  @Index()
  DateTime createdAt = DateTime.now();

  ContractDraft({
    required this.templateId,
    required this.filledFields,
    this.status = ContractStatus.draft,
    this.clientId = 0,
  });
}
