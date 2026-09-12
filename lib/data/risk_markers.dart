import 'models/risk_marker.dart';
import 'repositories/risk_marker_repository.dart';

/// Базовая база маркеров риска переквалификации договора в трудовой.
///
/// Маркеры разделены на три уровня:
/// * критические — прямые указания на трудовые отношения;
/// * средние — косвенные признаки подчинённости Заказчику;
/// * низкие — формальные и незначительные риски.
///
/// Для каждого маркера заданы RegExp-шаблон, описание, пример небезопасной
/// формулировки и безопасная альтернатива. В фазе 14 база расширяется до 50+.
const List<RiskMarkerDescriptor> builtInRiskMarkers = [
  // Критические — прямые указания на трудовые отношения.
  RiskMarkerDescriptor(
    code: 'labor_contract_term',
    pattern: r'трудов(?:ой|ого|ому|ым|ая|ую)?\s+договор',
    severity: RiskSeverity.critical,
    description: 'Договор назван трудовым — прямое указание на трудовые отношения.',
    example: 'Стороны заключают трудовой договор.',
    suggestion:
        'Замените на «договор гражданско-правового характера (возмездного '
        'оказания услуг / подряда)».',
  ),
  RiskMarkerDescriptor(
    code: 'salary_term',
    pattern: r'заработн(?:ая|ой|ую|а)?\s+плат',
    severity: RiskSeverity.critical,
    description: 'Использование термина «заработная плата» вместо вознаграждения.',
    example: 'Заказчик выплачивает Исполнителю заработную плату.',
    suggestion:
        'Используйте «вознаграждение за оказанные услуги (выполненные работы)».',
  ),
  RiskMarkerDescriptor(
    code: 'work_schedule_term',
    pattern:
        r'режим\s+рабочего\s+времени|график\s+работы|с\s+\d{1,2}[:.]\d{2}\s+до\s+\d{1,2}[:.]\d{2}',
    severity: RiskSeverity.critical,
    description: 'Задан режим рабочего времени или график работы.',
    example: 'Устанавливается график работы с 9:00 до 18:00.',
    suggestion:
        'Укажите сроки выполнения работ, а распределение рабочего времени '
        'оставьте на усмотрение Исполнителя.',
  ),
  RiskMarkerDescriptor(
    code: 'internal_rules_term',
    pattern: r'правил(?:а|ам|ами)?\s+внутреннего\s+трудового\s+распорядка',
    severity: RiskSeverity.critical,
    description: 'Подчинение правилам внутреннего трудового распорядка.',
    example: 'Исполнитель подчиняется правилам внутреннего трудового распорядка.',
    suggestion:
        'Уберите подчинение внутренним правилам; укажите, что Исполнитель '
        'самостоятельно организует свою работу.',
  ),
  RiskMarkerDescriptor(
    code: 'employment_book_term',
    pattern: r'трудов(?:ая|ой|ую)?\s+книжк',
    severity: RiskSeverity.critical,
    description: 'Упоминание трудовой книжки — атрибут трудовых отношений.',
    example: 'В трудовую книжку вносится запись о приёме на работу.',
    suggestion: 'Удалите упоминание трудовой книжки из договора.',
  ),
  RiskMarkerDescriptor(
    code: 'paid_leave_term',
    pattern:
        r'ежегодн(?:ый|ого|ому)?\s+(?:оплачиваем(?:ый|ого|ому)?\s+)?отпуск|оплата\s+больничн',
    severity: RiskSeverity.critical,
    description: 'Оплачиваемый отпуск или больничный — трудовые гарантии.',
    example: 'Исполнителю предоставляется ежегодный оплачиваемый отпуск.',
    suggestion:
        'Уберите трудовые гарантии: отпуск и больничный не применяются к ГПХ.',
  ),

  // Средние — косвенные признаки подчинённости.
  RiskMarkerDescriptor(
    code: 'subordination_term',
    pattern:
        r'подчиня(?:ется|ться)|указани(?:я|ям|ями|е)\s+заказчика|распоряжени(?:я|ям|ями|е)\s+заказчика',
    severity: RiskSeverity.medium,
    description: 'Исполнитель подчиняется указаниям Заказчика.',
    example: 'Исполнитель выполняет указания Заказчика.',
    suggestion:
        'Замените на «Исполнитель самостоятельно определяет порядок и способы '
        'выполнения работ».',
  ),
  RiskMarkerDescriptor(
    code: 'workplace_term',
    pattern: r'рабочее\s+место|предоставля(?:ет|ются)\s+оборудован',
    severity: RiskSeverity.medium,
    description: 'Заказчик предоставляет рабочее место или оборудование.',
    example: 'Заказчик предоставляет Исполнителю рабочее место.',
    suggestion:
        'Укажите, что Исполнитель использует собственные средства и '
        'оборудование.',
  ),
  RiskMarkerDescriptor(
    code: 'monthly_fixed_term',
    pattern:
        r'ежемесячн(?:о|ая|ой|ую|ый)|не\s+позднее\s+\d{1,2}\s+числа\s+каждого\s+месяца',
    severity: RiskSeverity.medium,
    description: 'Регулярная ежемесячная оплата напоминает зарплату.',
    example: 'Вознаграждение выплачивается ежемесячно.',
    suggestion:
        'Привяжите оплату к этапам и актам выполненных работ, а не к месяцам.',
  ),
  RiskMarkerDescriptor(
    code: 'manager_term',
    pattern:
        r'непосредственн(?:ый|ого|ому|ым)\s+руководител|менеджер(?:а|у|ом)?\s+проекта',
    severity: RiskSeverity.medium,
    description: 'Наличие непосредственного руководителя — признак подчинённости.',
    example: 'Работы выполняются под руководством менеджера проекта.',
    suggestion:
        'Уберите прямое руководство; взаимодействие идёт через Заказчика по '
        'вопросам приёмки результата.',
  ),
  RiskMarkerDescriptor(
    code: 'full_time_term',
    pattern:
        r'полн(?:ый|ого|ым)\s+рабоч(?:ий|его)\s+день|полн(?:ая|ой|ую)\s+занятост|\b40\s*час',
    severity: RiskSeverity.medium,
    description: 'Признак полной занятости и нормированного рабочего дня.',
    example: 'Исполнитель занят полный рабочий день.',
    suggestion:
        'Опишите результат и сроки работ вместо продолжительности занятости.',
  ),

  // Низкие — формальные и незначительные риски.
  RiskMarkerDescriptor(
    code: 'cash_payment_term',
    pattern: r'наличн(?:ыми|ых)|из\s+кассы',
    severity: RiskSeverity.low,
    description: 'Расчёты наличными усложняют подтверждение доходов.',
    example: 'Оплата производится наличными.',
    suggestion:
        'Укажите безналичный расчёт на счёт Исполнителя — так проще '
        'подтвердить доход.',
  ),
  RiskMarkerDescriptor(
    code: 'verbal_changes_term',
    pattern:
        r'устн(?:ой|ая|ые|ых)\s+(?:договорённост|договоренност|соглашени|изменени)',
    severity: RiskSeverity.low,
    description: 'Устные договорённости и изменения не защищают стороны.',
    example: 'Изменения оформляются устно.',
    suggestion:
        'Все изменения оформляйте письменно дополнительным соглашением.',
  ),
  RiskMarkerDescriptor(
    code: 'indefinite_term',
    pattern: r'бессрочн(?:ый|ого|ым)|до\s+расторжения',
    severity: RiskSeverity.low,
    description: 'Бессрочный характер договора повышает риск переквалификации.',
    example: 'Договор заключается бессрочно.',
    suggestion:
        'Укажите конкретный срок или срок выполнения работ с датой окончания.',
  ),
  RiskMarkerDescriptor(
    code: 'no_act_term',
    pattern: r'без\s+(?:оформления\s+)?акта|без\s+акта',
    severity: RiskSeverity.low,
    description: 'Оплата без акта затрудняет подтверждение результата работ.',
    example: 'Оплата производится без акта выполненных работ.',
    suggestion:
        'Предусмотрите акт приёма-передачи результата работ.',
  ),
];

/// Описание встроенного маркера риска из каталога [builtInRiskMarkers].
class RiskMarkerDescriptor {
  final String code;
  final String pattern;
  final RiskSeverity severity;
  final String description;
  final String example;
  final String suggestion;

  const RiskMarkerDescriptor({
    required this.code,
    required this.pattern,
    required this.severity,
    required this.description,
    required this.example,
    required this.suggestion,
  });

  RiskMarker toMarker() => RiskMarker(
    code: code,
    pattern: pattern,
    severity: severity,
    description: description,
    example: example,
    suggestion: suggestion,
  );
}

/// Наполняет репозиторий встроенными маркерами риска.
///
/// Идемпотентно: маркер вставляется только если его кода ещё нет в базе,
/// чтобы не перезаписывать возможные пользовательские изменения.
/// Возвращает количество добавленных маркеров.
Future<int> seedRiskMarkers(RiskMarkerRepository repository) async {
  var added = 0;
  for (final descriptor in builtInRiskMarkers) {
    final existing = await repository.getByCode(descriptor.code);
    if (existing == null) {
      await repository.put(descriptor.toMarker());
      added++;
    }
  }
  return added;
}
