import 'models/contract_template.dart';
import 'repositories/contract_template_repository.dart';

/// Встроенные шаблоны договоров, поставляемые вместе с приложением.
///
/// Метаданные (код, сфера, название, описание) хранятся в Isar, а тексты
/// шаблонов — в Assets (`assets/templates/<code>.txt`, см. [templateAssetPath]).
/// Каждый текст не превышает 50 КБ.
const List<BuiltInTemplateDescriptor> builtInTemplates = [
  BuiltInTemplateDescriptor(
    code: 'it_software_development',
    sphere: TemplateSphere.it,
    title: 'Разработка программного обеспечения',
    description:
        'Для заказчиков, которым нужен сайт, мобильное приложение или '
        'программный продукт. Оплата по этапам сдачи работ.',
  ),
  BuiltInTemplateDescriptor(
    code: 'it_tech_support',
    sphere: TemplateSphere.it,
    title: 'Техническая поддержка и сопровождение ПО',
    description:
        'Абонентское обслуживание и поддержка информационных систем '
        'заказчика: настройка, обновления, консультации.',
  ),
  BuiltInTemplateDescriptor(
    code: 'logistics_cargo_transport',
    sphere: TemplateSphere.logistics,
    title: 'Перевозка груза автомобильным транспортом',
    description:
        'Разовая перевозка груза по маршруту. Подходит для заказчиков, '
        'которым нужно доставить партию груза в срок.',
  ),
  BuiltInTemplateDescriptor(
    code: 'logistics_transport_expedition',
    sphere: TemplateSphere.logistics,
    title: 'Транспортная экспедиция и доставка',
    description:
        'Организация доставки груза «под ключ»: экспедирование, оформление '
        'сопроводительных документов, контроль сроков.',
  ),
  BuiltInTemplateDescriptor(
    code: 'universal_services',
    sphere: TemplateSphere.universal,
    title: 'Возмездное оказание услуг',
    description:
        'Универсальный шаблон для любых услуг на НПД: консультации, '
        'дизайн, репетиторство, клининг и другие.',
  ),
  BuiltInTemplateDescriptor(
    code: 'universal_work_contract',
    sphere: TemplateSphere.universal,
    title: 'Выполнение работ (подряд)',
    description:
        'Для разовых работ с материальным результатом: монтаж, ремонт, '
        'изготовление изделий по заданию заказчика.',
  ),
];

/// Путь к тексту шаблона в Assets приложения.
String templateAssetPath(String code) => 'assets/templates/$code.txt';

/// Описание встроенного шаблона из каталога [builtInTemplates].
class BuiltInTemplateDescriptor {
  final String code;
  final TemplateSphere sphere;
  final String title;
  final String description;

  const BuiltInTemplateDescriptor({
    required this.code,
    required this.sphere,
    required this.title,
    required this.description,
  });

  Template toTemplate() => Template(
    code: code,
    sphere: sphere,
    title: title,
    description: description,
  );
}

/// Наполняет репозиторий встроенными шаблонами.
///
/// Идемпотентно: шаблон вставляется только если его кода ещё нет в базе,
/// чтобы не перезаписывать возможные пользовательские изменения.
/// Возвращает количество добавленных шаблонов.
Future<int> seedBuiltInTemplates(ContractTemplateRepository repository) async {
  var added = 0;
  for (final descriptor in builtInTemplates) {
    final existing = await repository.getByCode(descriptor.code);
    if (existing == null) {
      await repository.put(descriptor.toTemplate());
      added++;
    }
  }
  return added;
}
