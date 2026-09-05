import '../models/contract_template.dart';

/// Репозиторий встроенных шаблонов договоров.
abstract class ContractTemplateRepository {
  /// Возвращает все шаблоны, упорядоченные по сфере и названию.
  Future<List<Template>> getAll();

  /// Возвращает шаблоны указанной сферы.
  Future<List<Template>> getBySphere(TemplateSphere sphere);

  /// Возвращает шаблон по стабильному коду или `null`.
  Future<Template?> getByCode(String code);

  /// Вставляет новый шаблон или обновляет существующий по его Isar `id`.
  ///
  /// Уникальность по [Template.code] не гарантируется схемой БД, поэтому
  /// вставку встроенных шаблонов выполняет идемпотентный
  /// `seedBuiltInTemplates`, проверяющий наличие кода перед вставкой.
  Future<void> put(Template template);

  /// Удаляет все шаблоны (используется в тестах и при пересоздании библиотеки).
  Future<void> clear();
}
