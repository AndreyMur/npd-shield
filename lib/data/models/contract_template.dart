import 'package:isar/isar.dart';

part 'contract_template.g.dart';

/// Сфера деятельности, для которой предназначен шаблон договора.
///
/// Помимо реальных сфер ([it] и [logistics]) существует [universal] —
/// универсальные шаблоны, подходящие любому исполнителю на НПД.
enum TemplateSphere {
  it,
  logistics,
  universal;

  /// Короткое название сферы для карточек библиотеки.
  String get label => switch (this) {
    TemplateSphere.it => 'IT',
    TemplateSphere.logistics => 'Логистика',
    TemplateSphere.universal => 'Универсальная',
  };

  /// Название категории библиотеки шаблонов.
  String get category => switch (this) {
    TemplateSphere.it => 'IT-услуги',
    TemplateSphere.logistics => 'Логистика',
    TemplateSphere.universal => 'Универсальные',
  };
}

/// Шаблон договора из встроенной библиотеки.
///
/// Текст шаблона хранится в Assets приложения и загружается по [code]
/// (файл `assets/templates/<code>.txt`). В коллекции хранятся только метаданные
/// для экрана библиотеки. Поле [code] — стабильный строковый идентификатор
/// шаблона, на который ссылается `ContractDraft.templateId`; он не зависит от
/// автоинкрементного [id] и переживает пересоздание базы данных.
@collection
class Template {
  /// Внутренний автоинкрементный идентификатор записи в Isar.
  Id id = Isar.autoIncrement;

  /// Стабильный код шаблона (например, `it_software_development`).
  /// Используется для ссылок из черновиков и для загрузки текста из Assets.
  @Index()
  late String code;

  /// Сфера деятельности, под которую адаптирован шаблон.
  @Index()
  @enumerated
  late TemplateSphere sphere;

  /// Человекочитаемое название шаблона.
  late String title;

  /// Краткое описание: когда и для каких сделок подходит шаблон.
  late String description;

  /// Код ОКВЭД, под который адаптирован шаблон
  /// (например, `62.01` для IT или `49.41` для логистики).
  late String okved;

  /// Пометка «Рекомендовано» для наиболее безопасных шаблонов.
  @Index()
  late bool recommended;

  /// Пример заполнения ключевых полей шаблона для карточки библиотеки.
  late String example;

  Template({
    required this.code,
    required this.sphere,
    required this.title,
    required this.description,
    this.okved = '',
    this.recommended = false,
    this.example = '',
  });
}
