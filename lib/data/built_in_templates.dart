import 'models/contract_template.dart';
import 'repositories/contract_template_repository.dart';

/// Встроенные шаблоны договоров, поставляемые вместе с приложением.
///
/// Метаданные (код, сфера, название, описание, ОКВЭД) хранятся в Isar, а
/// тексты шаблонов — в Assets (`assets/templates/<code>.txt`, см.
/// [templateAssetPath]). Каждый текст не превышает 50 КБ.
///
/// Каталог содержит 20+ шаблонов: 10 для IT (ОКВЭД 62.01/62.02), 10 для
/// логистики (ОКВЭД 49.41) и 2 универсальных.
const List<BuiltInTemplateDescriptor> builtInTemplates = [
  // IT — разработка (ОКВЭД 62.01).
  BuiltInTemplateDescriptor(
    code: 'it_software_development',
    sphere: TemplateSphere.it,
    title: 'Разработка программного обеспечения',
    description:
        'Для заказчиков, которым нужен сайт, мобильное приложение или '
        'программный продукт. Оплата по этапам сдачи работ.',
    okved: '62.01',
    recommended: true,
    example: 'Разработка CRM-системы для ООО «Ромашка», 250 000 ₽, 2 этапа.',
  ),
  BuiltInTemplateDescriptor(
    code: 'it_mobile_app_development',
    sphere: TemplateSphere.it,
    title: 'Разработка мобильного приложения',
    description:
        'Создание приложения под iOS и Android с публикацией в магазинах '
        'и передачей исходного кода заказчику.',
    okved: '62.01',
    example: 'Мобильное приложение доставки, 400 000 ₽, публикация в сторах.',
  ),
  BuiltInTemplateDescriptor(
    code: 'it_website_development',
    sphere: TemplateSphere.it,
    title: 'Разработка и поддержка сайта',
    description:
        'Корпоративный сайт, интернет-магазин или лендинг: вёрстка, '
        'интеграции, наполнение и техническая поддержка.',
    okved: '62.01',
    example: 'Интернет-магазин с оплатой, 180 000 ₽, поддержка 3 месяца.',
  ),
  BuiltInTemplateDescriptor(
    code: 'it_qa_testing',
    sphere: TemplateSphere.it,
    title: 'Тестирование и контроль качества ПО',
    description:
        'Ручное и автоматизированное тестирование, баг-репорты, '
        'регрессия и приёмочные испытания перед релизом.',
    okved: '62.01',
    example: 'QA-тестирование релиза, 120 000 ₽, отчёт и баг-трекер.',
  ),
  BuiltInTemplateDescriptor(
    code: 'it_ui_ux_design',
    sphere: TemplateSphere.it,
    title: 'Дизайн интерфейсов (UI/UX)',
    description:
        'Проектирование пользовательских сценариев, макеты и дизайн-система '
        'для сайта или приложения с передачей в разработку.',
    okved: '62.01',
    example: 'Дизайн личного кабинета, 150 000 ₽, макеты и UI-кит.',
  ),
  // IT — консалтинг и сопровождение (ОКВЭД 62.02).
  BuiltInTemplateDescriptor(
    code: 'it_tech_support',
    sphere: TemplateSphere.it,
    title: 'Техническая поддержка и сопровождение ПО',
    description:
        'Абонентское обслуживание и поддержка информационных систем '
        'заказчика: настройка, обновления, консультации.',
    okved: '62.02',
    recommended: true,
    example: 'Абонентское сопровождение 1С, 60 000 ₽/мес, SLA 4 часа.',
  ),
  BuiltInTemplateDescriptor(
    code: 'it_system_integration',
    sphere: TemplateSphere.it,
    title: 'Внедрение и интеграция информационных систем',
    description:
        'Настройка и связка CRM, ERP и внутренних сервисов заказчика, '
        'миграция данных и обучение сотрудников.',
    okved: '62.02',
    example: 'Внедрение CRM и интеграция с сайтом, 320 000 ₽.',
  ),
  BuiltInTemplateDescriptor(
    code: 'it_devops_infrastructure',
    sphere: TemplateSphere.it,
    title: 'Настройка серверов и DevOps-инфраструктуры',
    description:
        'Развёртывание и обслуживание серверов, CI/CD, мониторинг, '
        'резервное копирование и защита инфраструктуры.',
    okved: '62.02',
    example: 'Настройка CI/CD и мониторинга, 140 000 ₽, Docker/Kubernetes.',
  ),
  BuiltInTemplateDescriptor(
    code: 'it_data_analytics',
    sphere: TemplateSphere.it,
    title: 'Аналитика данных и отчётность',
    description:
        'Сбор и обработка данных, дашборды, аналитические отчёты '
        'и автоматизация бизнес-метрик заказчика.',
    okved: '62.02',
    example: 'Дашборд продаж в Power BI, 110 000 ₽, 3 источника данных.',
  ),
  BuiltInTemplateDescriptor(
    code: 'it_it_consulting',
    sphere: TemplateSphere.it,
    title: 'IT-консалтинг и аудит',
    description:
        'Аудит IT-инфраструктуры и процессов, рекомендации по архитектуре, '
        'безопасности и выбору технологий.',
    okved: '62.02',
    example: 'Аудит IT-инфраструктуры, 90 000 ₽, отчёт и план развития.',
  ),

  // Логистика (ОКВЭД 49.41).
  BuiltInTemplateDescriptor(
    code: 'logistics_cargo_transport',
    sphere: TemplateSphere.logistics,
    title: 'Перевозка груза автомобильным транспортом',
    description:
        'Разовая перевозка груза по маршруту. Подходит для заказчиков, '
        'которым нужно доставить партию груза в срок.',
    okved: '49.41',
    recommended: true,
    example: 'Перевозка 20 т стройматериалов Москва → Казань, 80 000 ₽.',
  ),
  BuiltInTemplateDescriptor(
    code: 'logistics_transport_expedition',
    sphere: TemplateSphere.logistics,
    title: 'Транспортная экспедиция и доставка',
    description:
        'Организация доставки груза «под ключ»: экспедирование, оформление '
        'сопроводительных документов, контроль сроков.',
    okved: '49.41',
    recommended: true,
    example: 'Экспедирование сборного груза, 45 000 ₽, документы под ключ.',
  ),
  BuiltInTemplateDescriptor(
    code: 'logistics_courier_delivery',
    sphere: TemplateSphere.logistics,
    title: 'Курьерская доставка документов и грузов',
    description:
        'Срочная доставка документов и небольших отправлений по городу '
        'и между городами с подтверждением получения.',
    okved: '49.41',
    example: 'Доставка документов по городу, 15 000 ₽/мес, 40 адресов.',
  ),
  BuiltInTemplateDescriptor(
    code: 'logistics_consolidated_cargo',
    sphere: TemplateSphere.logistics,
    title: 'Перевозка сборных грузов',
    description:
        'Консолидация партий разных отправителей в один рейс, экономия '
        'на доставке и контроль погрузки-выгрузки.',
    okved: '49.41',
    example: 'Сборный груз 5 паллет Москва → СПб, 32 000 ₽.',
  ),
  BuiltInTemplateDescriptor(
    code: 'logistics_refrigerated_transport',
    sphere: TemplateSphere.logistics,
    title: 'Перевозка скоропортящихся грузов',
    description:
        'Доставка продуктов и товаров с соблюдением температурного режима '
        'рефрижератором, с контролем температуры в пути.',
    okved: '49.41',
    example: 'Доставка продуктов +2…+6 °C, 120 км, 28 000 ₽.',
  ),
  BuiltInTemplateDescriptor(
    code: 'logistics_oversized_cargo',
    sphere: TemplateSphere.logistics,
    title: 'Перевозка крупногабаритных грузов',
    description:
        'Перевозка негабаритных и тяжеловесных грузов с подбором транспорта, '
        'оформлением разрешений и сопровождением.',
    okved: '49.41',
    example: 'Перевозка спецтехники 24 т, разрешение и сопровождение.',
  ),
  BuiltInTemplateDescriptor(
    code: 'logistics_intercity_transport',
    sphere: TemplateSphere.logistics,
    title: 'Междугородние перевозки',
    description:
        'Регулярные и разовые перевозки между городами с отслеживанием '
        'местоположения и сроками доставки.',
    okved: '49.41',
    example: 'Регулярный рейс Москва → Нижний Новгород, 2 раза в неделю.',
  ),
  BuiltInTemplateDescriptor(
    code: 'logistics_loading_unloading',
    sphere: TemplateSphere.logistics,
    title: 'Погрузочно-разгрузочные работы',
    description:
        'Погрузка, разгрузка, перемещение и крепление груза силами '
        'исполнителя с соблюдением требований безопасности.',
    okved: '49.41',
    example: 'Разгрузка фуры 20 т, 3 грузчика, 12 000 ₽.',
  ),
  BuiltInTemplateDescriptor(
    code: 'logistics_dangerous_goods',
    sphere: TemplateSphere.logistics,
    title: 'Перевозка опасных грузов',
    description:
        'Доставка опасных грузов с соблюдением требований ДОПОГ, '
        'подготовкой документов и специальным транспортом.',
    okved: '49.41',
    example: 'Перевозка ЛВЖ класс 3, Москва → Тула, 55 000 ₽.',
  ),
  BuiltInTemplateDescriptor(
    code: 'logistics_last_mile',
    sphere: TemplateSphere.logistics,
    title: 'Доставка «последней мили»',
    description:
        'Доставка отправлений от распределительного центра до конечного '
        'получателя с фотофиксацией и уведомлениями.',
    okved: '49.41',
    example: 'Доставка 300 заказов/день по городу, 95 ₽ за заказ.',
  ),

  // Универсальные шаблоны.
  BuiltInTemplateDescriptor(
    code: 'universal_services',
    sphere: TemplateSphere.universal,
    title: 'Возмездное оказание услуг',
    description:
        'Универсальный шаблон для любых услуг на НПД: консультации, '
        'дизайн, репетиторство, клининг и другие.',
    okved: '96.99',
    recommended: true,
    example: 'Консультации по маркетингу, 40 000 ₽/мес, 10 часов.',
  ),
  BuiltInTemplateDescriptor(
    code: 'universal_work_contract',
    sphere: TemplateSphere.universal,
    title: 'Выполнение работ (подряд)',
    description:
        'Для разовых работ с материальным результатом: монтаж, ремонт, '
        'изготовление изделий по заданию заказчика.',
    okved: '43.99',
    recommended: true,
    example: 'Ремонт офиса 60 м², 180 000 ₽, материалы заказчика.',
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
  final String okved;
  final bool recommended;
  final String example;

  const BuiltInTemplateDescriptor({
    required this.code,
    required this.sphere,
    required this.title,
    required this.description,
    this.okved = '',
    this.recommended = false,
    this.example = '',
  });

  Template toTemplate() => Template(
    code: code,
    sphere: sphere,
    title: title,
    description: description,
    okved: okved,
    recommended: recommended,
    example: example,
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
