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
/// формулировки и безопасная альтернатива. База расширена до 50+ маркеров в
/// фазе 14; коды существующих маркеров сохранены стабильными.
///
/// Шаблоны используют границы слова `(?<![\p{L}])` / `(?![\p{L}])`, так как
/// `\b` в Dart не считает кириллицу словесными символами.
const List<RiskMarkerDescriptor> builtInRiskMarkers = [
  // ---------------------------------------------------------------------------
  // Критические — прямые указания на трудовые отношения.
  // ---------------------------------------------------------------------------
  RiskMarkerDescriptor(
    code: 'labor_contract_term',
    pattern:
        r'(?<![\p{L}])трудов(?:ой|ого|ому|ым|ая|ую|ое|ые|ых)\s+договор',
    severity: RiskSeverity.critical,
    description: 'Договор назван трудовым — прямое указание на трудовые отношения.',
    example: 'Стороны заключают трудовой договор.',
    suggestion:
        'Замените на «договор гражданско-правового характера (возмездного '
        'оказания услуг / подряда)».',
  ),
  RiskMarkerDescriptor(
    code: 'labor_relations_term',
    pattern: r'трудов(?:ые|ых|ым|ой)\s+отношени',
    severity: RiskSeverity.critical,
    description: 'Стороны вступают в трудовые отношения.',
    example: 'Стороны состоят в трудовых отношениях.',
    suggestion:
        'Укажите, что стороны заключают гражданско-правовой договор и не '
        'вступают в трудовые отношения.',
  ),
  RiskMarkerDescriptor(
    code: 'salary_term',
    pattern:
        r'заработн(?:ая|ой|ую|а|ые|ых|ым)\s+плат|(?<![\p{L}])зарплат',
    severity: RiskSeverity.critical,
    description: 'Использование термина «заработная плата» вместо вознаграждения.',
    example: 'Заказчик выплачивает Исполнителю заработную плату.',
    suggestion:
        'Используйте «вознаграждение за оказанные услуги (выполненные работы)».',
  ),
  RiskMarkerDescriptor(
    code: 'work_schedule_term',
    pattern:
        r'режим\s+рабочего\s+времени|график\s+работы|'
        r'с\s+\d{1,2}[:.]\d{2}\s+до\s+\d{1,2}[:.]\d{2}',
    severity: RiskSeverity.critical,
    description: 'Задан режим рабочего времени или график работы.',
    example: 'Устанавливается график работы с 9:00 до 18:00.',
    suggestion:
        'Укажите сроки выполнения работ, а распределение рабочего времени '
        'оставьте на усмотрение Исполнителя.',
  ),
  RiskMarkerDescriptor(
    code: 'internal_rules_term',
    pattern:
        r'правил(?:а|ам|ами|о|е)?\s+внутреннего\s+трудового\s+распорядка',
    severity: RiskSeverity.critical,
    description: 'Подчинение правилам внутреннего трудового распорядка.',
    example:
        'Исполнитель подчиняется правилам внутреннего трудового распорядка.',
    suggestion:
        'Уберите подчинение внутренним правилам; укажите, что Исполнитель '
        'самостоятельно организует свою работу.',
  ),
  RiskMarkerDescriptor(
    code: 'employment_book_term',
    pattern: r'трудов(?:ая|ой|ую|ые|ых|ым)\s+книжк',
    severity: RiskSeverity.critical,
    description: 'Упоминание трудовой книжки — атрибут трудовых отношений.',
    example: 'В трудовую книжку вносится запись о приёме на работу.',
    suggestion: 'Удалите упоминание трудовой книжки из договора.',
  ),
  RiskMarkerDescriptor(
    code: 'paid_leave_term',
    pattern:
        r'ежегодн(?:ый|ого|ому|ым|ая|ой|ую|ые|ых)\s+'
        r'(?:оплачиваем(?:ый|ого|ому|ым|ая|ой|ую|ые|ых)\s+)?отпуск|'
        r'оплата\s+больничн|'
        r'оплачиваем(?:ый|ого|ому|ым|ая|ой|ую|ые|ых)\s+отпуск',
    severity: RiskSeverity.critical,
    description: 'Оплачиваемый отпуск или больничный — трудовые гарантии.',
    example: 'Исполнителю предоставляется ежегодный оплачиваемый отпуск.',
    suggestion:
        'Уберите трудовые гарантии: отпуск и больничный не применяются к ГПХ.',
  ),
  RiskMarkerDescriptor(
    code: 'hire_dismissal_term',
    pattern:
        r'(?<![\p{L}])при[её]м(?:а|у|ом|е)?\s+на\s+работу|'
        r'при[её]м\s+и\s+увольнени|(?<![\p{L}])увольнени(?:е|я|ю|ем|и)',
    severity: RiskSeverity.critical,
    description: 'Приём на работу или увольнение — процедуры трудового права.',
    example: 'Приём на работу оформляется приказом Работодателя.',
    suggestion:
        'Говорите о заключении и расторжении гражданско-правового договора, '
        'а не о приёме на работу и увольнении.',
  ),
  RiskMarkerDescriptor(
    code: 'personnel_order_term',
    pattern:
        r'приказ(?:а|ом|е|ы)?\s+о\s+(?:при[её]ме|назначении)\s+на\s+'
        r'(?:работу|должность)',
    severity: RiskSeverity.critical,
    description: 'Кадровый приказ о приёме на работу или должность.',
    example: 'Издаётся приказ о приёме на работу.',
    suggestion: 'Замените кадровые приказы на акты приёма-передачи результата.',
  ),
  RiskMarkerDescriptor(
    code: 'staff_unit_term',
    pattern:
        r'штатн(?:ая|ой|ую|ое|ого|ому|ым|ые|ых)\s+(?:единиц|расписани)',
    severity: RiskSeverity.critical,
    description: 'Штатная единица или штатное расписание — атрибут найма.',
    example: 'Исполнитель занимает штатную единицу в штатном расписании.',
    suggestion:
        'Уберите упоминания штата; результат работ не привязан к штатному '
        'расписанию.',
  ),
  RiskMarkerDescriptor(
    code: 'probation_term',
    pattern:
        r'испытательн(?:ый|ого|ому|ым|ая|ой|ую|ые|ых)\s+срок|'
        r'испытани(?:е|я|ю|ем)\s+при\s+при[её]ме',
    severity: RiskSeverity.critical,
    description: 'Испытательный срок — институт трудового права.',
    example: 'Работнику устанавливается испытательный срок три месяца.',
    suggestion:
        'Испытание допустимо только в трудовом договоре. Для ГПХ укажите '
        'порядок приёмки результата.',
  ),
  RiskMarkerDescriptor(
    code: 'severance_term',
    pattern:
        r'выходн(?:ое|ого|ому|ым)\s+пособи|'
        r'компенсаци(?:я|и|ю|ей)\s+за\s+неиспользованн(?:ый|ого|ым)\s+отпуск',
    severity: RiskSeverity.critical,
    description: 'Выходное пособие или компенсация отпуска — трудовые выплаты.',
    example: 'При увольнении выплачивается выходное пособие.',
    suggestion:
        'Уберите трудовые компенсации; порядок расторжения ГПХ определяется '
        'договором.',
  ),
  RiskMarkerDescriptor(
    code: 'salary_twice_monthly_term',
    pattern:
        r'(?:не\s+реже\s+)?(?:два|двух|2)\s+раз(?:а)?\s+в\s+месяц|'
        r'выплат(?:а|ы|у|ой)\s+аванса',
    severity: RiskSeverity.critical,
    description: 'Выплата не реже двух раз в месяц или аванс — признак зарплаты.',
    example: 'Заработная плата выплачивается два раза в месяц.',
    suggestion:
        'Привяжите оплату к этапам и актам, избегайте авансовой схемы.',
  ),
  RiskMarkerDescriptor(
    code: 'minimum_wage_term',
    pattern:
        r'минимальн(?:ый|ого|ому|ым)\s+размер(?:а)?\s+оплаты\s+труда|'
        r'(?<![\p{L}])МРОТ(?![\p{L}])',
    severity: RiskSeverity.critical,
    description: 'Ссылка на МРОТ или минимальный размер оплаты труда.',
    example: 'Оплата не может быть ниже минимального размера оплаты труда.',
    suggestion:
        'Уберите привязку к МРОТ: вознаграждение определяется ценой договора.',
  ),
  RiskMarkerDescriptor(
    code: 'labor_function_term',
    pattern:
        r'трудов(?:ая|ой|ую|ые|ых)\s+функци|'
        r'должностн(?:ые|ых|ой|ым|ая)\s+обязанност|'
        r'принима(?:ется|ются)\s+на\s+должность',
    severity: RiskSeverity.critical,
    description: 'Трудовая функция, должностные обязанности или должность.',
    example: 'Работник принимается на должность менеджера.',
    suggestion:
        'Опишите конкретный результат и услуги вместо должности и должностных '
        'обязанностей.',
  ),
  RiskMarkerDescriptor(
    code: 'work_hours_norm_term',
    pattern:
        r'норм(?:а|ы|у|ой|е)\s+рабочего\s+времени|'
        r'нормированн(?:ый|ого|ым|ая|ой|ую)\s+'
        r'(?:рабочий\s+день|рабочее\s+время|рабочая\s+неделя)',
    severity: RiskSeverity.critical,
    description: 'Норма рабочего времени — категория трудового права.',
    example: 'Устанавливается норма рабочего времени 40 часов в неделю.',
    suggestion:
        'Опишите сроки и объём результата, а не норму рабочего времени.',
  ),
  RiskMarkerDescriptor(
    code: 'overtime_term',
    pattern:
        r'сверхурочн(?:ая|ой|ую|ые|ых|ым)\s+работ|'
        r'работа\s+в\s+сверхурочное\s+время',
    severity: RiskSeverity.critical,
    description: 'Сверхурочная работа — институт трудового права.',
    example: 'Работник привлекается к сверхурочной работе.',
    suggestion:
        'Уберите сверхурочные; дополнительный объём оформляйте отдельным '
        'этапом с оплатой по акту.',
  ),
  RiskMarkerDescriptor(
    code: 'discipline_term',
    pattern:
        r'дисциплинарн(?:ое|ого|ому|ым|ая|ой|ую|ые|ых)\s+'
        r'(?:взыскани|ответственност|проступк)',
    severity: RiskSeverity.critical,
    description: 'Дисциплинарное взыскание — признак трудовых отношений.',
    example: 'За нарушение налагается дисциплинарное взыскание.',
    suggestion:
        'Замените дисциплинарную ответственность на имущественную '
        'ответственность за результат по договору.',
  ),
  RiskMarkerDescriptor(
    code: 'labor_legislation_term',
    pattern:
        r'трудов(?:ое|ого|ому|ым|ой)\s+законодательств|'
        r'трудов(?:ой|ого|ому|ым)\s+кодекс|(?<![\p{L}])ТК\s+РФ',
    severity: RiskSeverity.critical,
    description: 'Прямая ссылка на трудовое законодательство или ТК РФ.',
    example: 'Стороны руководствуются трудовым законодательством РФ.',
    suggestion:
        'Ссылайтесь на ГК РФ и нормы о возмездном оказании услуг или подряде.',
  ),
  RiskMarkerDescriptor(
    code: 'employer_employee_term',
    pattern:
        r'(?<![\p{L}])работодател|'
        r'(?<![\p{L}])работник(?:а|у|ом|е|и|ов)?(?![\p{L}])',
    severity: RiskSeverity.critical,
    description: 'Термины «работодатель» / «работник» вместо сторон ГПХ.',
    example: 'Работодатель обязуется обеспечить работника всем необходимым.',
    suggestion:
        'Используйте «Заказчик» и «Исполнитель» вместо «работодатель» и '
        '«работник».',
  ),
  RiskMarkerDescriptor(
    code: 'seniority_term',
    pattern: r'трудов(?:ой|ого|ому|ым)\s+стаж',
    severity: RiskSeverity.critical,
    description: 'Трудовой стаж — категория трудового права.',
    example: 'Период работы засчитывается в трудовой стаж.',
    suggestion: 'Уберите упоминание трудового стажа из договора.',
  ),
  RiskMarkerDescriptor(
    code: 'personal_file_term',
    pattern: r'личн(?:ое|ого|ому|ым|ом)\s+дел(?:о|е|а|у|ом)',
    severity: RiskSeverity.critical,
    description: 'Личное дело работника — кадровый документ.',
    example: 'На работника заводится личное дело.',
    suggestion: 'Уберите упоминания личного дела из договора.',
  ),
  RiskMarkerDescriptor(
    code: 'time_tracking_term',
    pattern: r'табел(?:ь|я|ю|ем|е|и)\s+уч[её]та\s+рабочего\s+времени',
    severity: RiskSeverity.critical,
    description: 'Табель учёта рабочего времени — атрибут трудовых отношений.',
    example: 'Учёт ведётся в табеле учёта рабочего времени.',
    suggestion:
        'Уберите табель; подтверждением работ служат акты и отчёты об '
        'оказанных услугах.',
  ),
  RiskMarkerDescriptor(
    code: 'leave_schedule_term',
    pattern: r'график(?:а|у|ом|е)?\s+отпусков',
    severity: RiskSeverity.critical,
    description: 'График отпусков — документ трудового права.',
    example: 'Отпуска предоставляются согласно графику отпусков.',
    suggestion: 'Уберите график отпусков: отпуска не применяются к ГПХ.',
  ),
  RiskMarkerDescriptor(
    code: 'sick_leave_payment_term',
    pattern:
        r'пособи(?:е|я|ю|ем|и)\s+по\s+временной\s+нетрудоспособност|'
        r'оплата\s+периода\s+нетрудоспособност|'
        r'оплата\s+больничн(?:ого|ому|ым|ой)?\s*лист',
    severity: RiskSeverity.critical,
    description: 'Пособие по нетрудоспособности — социальная гарантия.',
    example: 'Работодатель оплачивает пособие по временной нетрудоспособности.',
    suggestion:
        'Уберите оплату больничных: это гарантия трудового договора.',
  ),

  // ---------------------------------------------------------------------------
  // Средние — косвенные признаки подчинённости.
  // ---------------------------------------------------------------------------
  RiskMarkerDescriptor(
    code: 'subordination_term',
    pattern:
        r'подчиня(?:ется|ться|ются)|'
        r'указани(?:я|ям|ями|е|й)\s+заказчика|'
        r'распоряжени(?:я|ям|ями|е|й)\s+заказчика',
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
        r'ежемесячн(?:о|ая|ой|ую|ый|ым|ых|ое|ого)\s+'
        r'(?:выплат|оплат|вознагражд|премиров)|'
        r'выплачива(?:ется|ются)\s+ежемесячно|'
        r'не\s+позднее\s+\d{1,2}\s+числа\s+каждого\s+месяца',
    severity: RiskSeverity.medium,
    description: 'Регулярная ежемесячная оплата напоминает зарплату.',
    example: 'Вознаграждение выплачивается ежемесячно.',
    suggestion:
        'Привяжите оплату к этапам и актам выполненных работ, а не к месяцам.',
  ),
  RiskMarkerDescriptor(
    code: 'manager_term',
    pattern:
        r'непосредственн(?:ый|ого|ому|ым|ой)\s+руководител|'
        r'менеджер(?:а|у|ом)?\s+проекта',
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
        r'полн(?:ый|ого|ым)\s+рабоч(?:ий|его)\s+день|'
        r'полн(?:ая|ой|ую)\s+занятост|'
        r'(?<![\d])40\s*час(?:ов|а)?|'
        r'пятидневн(?:ая|ой|ую)\s+рабоч(?:ая|ей)\s+недел',
    severity: RiskSeverity.medium,
    description: 'Признак полной занятости и нормированного рабочего дня.',
    example: 'Исполнитель занят полный рабочий день.',
    suggestion:
        'Опишите результат и сроки работ вместо продолжительности занятости.',
  ),
  RiskMarkerDescriptor(
    code: 'reporting_term',
    pattern:
        r'отчитыва(?:ется|ются|ться)\s+перед|'
        r'подотч[её]тн(?:ость|ым|ый|ого|ой)|'
        r'предоставля(?:ет|ть|ются)\s+'
        r'(?:ежедневн|еженедельн|ежемесячн)[\p{L}]*\s+отч[её]т',
    severity: RiskSeverity.medium,
    description: 'Обязанность отчитываться перед Заказчиком по графику.',
    example: 'Исполнитель еженедельно предоставляет отчёт о работе.',
    suggestion:
        'Отчётность допустима как приёмка этапа, но не как регулярный контроль '
        'занятости.',
  ),
  RiskMarkerDescriptor(
    code: 'kpi_term',
    pattern:
        r'ключев(?:ые|ых|ой|ым)\s+показател(?:и|ей|ям)\s+эффективност|'
        r'(?<![\p{L}])KPI(?![\p{L}])',
    severity: RiskSeverity.medium,
    description: 'KPI — инструмент оценки сотрудника, а не подрядчика.',
    example: 'Вознаграждение зависит от выполнения KPI.',
    suggestion:
        'Оценивайте результат по акту, а не по ключевым показателям '
        'эффективности.',
  ),
  RiskMarkerDescriptor(
    code: 'work_under_control_term',
    pattern:
        r'под\s+контролем\s+заказчика|'
        r'по\s+заданию\s+заказчика|'
        r'по\s+поручению\s+заказчика',
    severity: RiskSeverity.medium,
    description: 'Работы выполняются по заданию и под контролем Заказчика.',
    example: 'Исполнитель выполняет работы по заданию Заказчика.',
    suggestion:
        'Укажите самостоятельность Исполнителя в способах выполнения работ.',
  ),
  RiskMarkerDescriptor(
    code: 'mandatory_meetings_term',
    pattern:
        r'обязательн(?:ое|ого|ым|ая|ой|ую|ые|ых)\s+'
        r'участи(?:е|я|ю|ем)\s+в\s+'
        r'(?:ежедневн[\p{L}]*|еженедельн[\p{L}]*|ежемесячн[\p{L}]*)?\s*'
        r'(?:встреч|совещан|план[её]рк|планерк|созвон|мероприяти)',
    severity: RiskSeverity.medium,
    description: 'Обязательное участие во встречах и планёрках.',
    example: 'Исполнитель обязан участвовать в еженедельных планёрках.',
    suggestion:
        'Встречи должны быть необязательными и только по приёмке результата.',
  ),
  RiskMarkerDescriptor(
    code: 'attendance_term',
    pattern:
        r'присутств(?:ие|ия|ию|ием)\s+на\s+рабочем\s+месте|'
        r'явк(?:а|и|у|ой)\s+на\s+работу',
    severity: RiskSeverity.medium,
    description: 'Обязательное присутствие на рабочем месте или явка.',
    example: 'Обязательно присутствие на рабочем месте с 10 до 19.',
    suggestion:
        'Уберите требование присутствия: важен результат, а не место работы.',
  ),
  RiskMarkerDescriptor(
    code: 'lunch_break_term',
    pattern: r'перерыв\s+для\s+отдыха\s+и\s+питани',
    severity: RiskSeverity.medium,
    description: 'Перерыв для отдыха и питания — режим трудового дня.',
    example: 'Устанавливается перерыв для отдыха и питания 1 час.',
    suggestion:
        'Уберите регламент перерывов: Исполнитель сам организует свой день.',
  ),
  RiskMarkerDescriptor(
    code: 'paid_training_term',
    pattern:
        r'(?:обучени(?:е|я|ю|ем|и)?|'
        r'повышени(?:е|я|ю|ем)\s+квалификаци|курс(?:ы|ов))\s+'
        r'за\s+сч[её]т\s+заказчика',
    severity: RiskSeverity.medium,
    description: 'Обучение за счёт Заказчика — инвестиция в сотрудника.',
    example: 'Заказчик оплачивает обучение Исполнителя за свой счёт.',
    suggestion:
        'Если обучение нужно, оформите его как отдельную услугу с отдельной '
        'оплатой.',
  ),
  RiskMarkerDescriptor(
    code: 'labor_safety_term',
    pattern:
        r'инструктаж\s+по\s+охране\s+труда|'
        r'требовани(?:я|й|ям|ями)\s+охраны\s+труда|'
        r'техник(?:а|и|ой|у)\s+безопасност',
    severity: RiskSeverity.medium,
    description: 'Охрана труда и техника безопасности — трудовые нормы.',
    example: 'Исполнитель обязан пройти инструктаж по охране труда.',
    suggestion:
        'Замените трудовые инструктажи на согласованные правила безопасности '
        'на объекте Заказчика.',
  ),
  RiskMarkerDescriptor(
    code: 'schedule_approval_term',
    pattern:
        r'согласовыва(?:ть|ет|ется|ются)\s+'
        r'(?:с\s+заказчиком\s+)?(?:график|порядок|даты|отпуск)|'
        r'по\s+согласованию\s+с\s+(?:непосредственным\s+)?руководител',
    severity: RiskSeverity.medium,
    description: 'График и порядок работ согласуются с руководителем.',
    example: 'График работы согласовывается с руководителем.',
    suggestion:
        'Оставьте Исполнителю свободу в распределении времени; согласуйте '
        'только сроки этапов.',
  ),
  RiskMarkerDescriptor(
    code: 'business_trip_term',
    pattern:
        r'служебн(?:ая|ой|ую|ые|ых)\s+командировк|'
        r'направля(?:ется|ются)\s+в\s+командировк',
    severity: RiskSeverity.medium,
    description: 'Служебная командировка — понятие трудового права.',
    example: 'Исполнитель направляется в служебную командировку.',
    suggestion:
        'Говорите о выезде для оказания услуг с компенсацией расходов, а не о '
        'командировке.',
  ),
  RiskMarkerDescriptor(
    code: 'mobile_compensation_term',
    pattern:
        r'компенсаци(?:я|и|ю|ей)\s+(?:расходов\s+)?'
        r'(?:на\s+связь|за\s+использование\s+личного)|'
        r'компенсиру(?:ется|ются|ет)\s+(?:расходы\s+)?на\s+связь|'
        r'оплата\s+мобильной\s+связи',
    severity: RiskSeverity.medium,
    description: 'Компенсация связи или личного имущества — как у сотрудника.',
    example: 'Заказчик компенсирует расходы на связь.',
    suggestion:
        'Включите такие расходы в цену договора, а не выплачивайте компенсации.',
  ),
  RiskMarkerDescriptor(
    code: 'workload_term',
    pattern:
        r'загруженност(?:ь|и|ю|ью)|'
        r'объ[её]м\s+работ\s+определяется\s+заказчиком|'
        r'полная\s+загрузка',
    severity: RiskSeverity.medium,
    description: 'Заказчик определяет загруженность Исполнителя.',
    example: 'Заказчик обеспечивает полную загрузку Исполнителя.',
    suggestion:
        'Опишите конкретный объём и результат работ, а не уровень загрузки.',
  ),
  RiskMarkerDescriptor(
    code: 'client_equipment_term',
    pattern:
        r'использов(?:ание|ать|ует)\s+'
        r'(?:оборудование|технику|инструмент|материалы)\s+заказчика|'
        r'за\s+сч[её]т\s+заказчика\s+(?:приобрета|предоставля)',
    severity: RiskSeverity.medium,
    description: 'Использование техники и материалов Заказчика.',
    example: 'Исполнитель использует оборудование Заказчика.',
    suggestion:
        'Укажите, что Исполнитель использует свои материалы, либо включите их '
        'стоимость в цену.',
  ),
  RiskMarkerDescriptor(
    code: 'response_time_term',
    pattern:
        r'(?:оперативно\s+)?отвеча(?:ть|ет)\s+на\s+'
        r'(?:запросы|обращения|сообщения)\s+заказчика|'
        r'время\s+ответа\s+на\s+(?:запрос|обращение)',
    severity: RiskSeverity.medium,
    description: 'Требование оперативно отвечать на запросы Заказчика.',
    example: 'Исполнитель обязан оперативно отвечать на сообщения Заказчика.',
    suggestion:
        'Оговорите сроки только для приёмки и согласования результатов.',
  ),
  RiskMarkerDescriptor(
    code: 'integration_team_term',
    pattern:
        r'включени(?:е|я|ю|ем)\s+в\s+'
        r'(?:штат|состав\s+команды|состав\s+сотрудников)|'
        r'в\s+составе\s+команды\s+заказчика',
    severity: RiskSeverity.medium,
    description: 'Включение Исполнителя в штат или команду Заказчика.',
    example: 'Исполнитель включается в состав команды Заказчика.',
    suggestion:
        'Опишите взаимодействие по проекту без включения в штат и команду.',
  ),

  // ---------------------------------------------------------------------------
  // Низкие — формальные и незначительные риски.
  // ---------------------------------------------------------------------------
  RiskMarkerDescriptor(
    code: 'cash_payment_term',
    pattern: r'(?<![\p{L}])наличн(?:ыми|ых)|из\s+кассы',
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
        r'устн(?:ой|ая|ые|ых|о)\s+'
        r'(?:договор[её]нност|договоренност|соглашени|изменени)|'
        r'(?:договор[её]нност|соглашени|изменени)[\p{L}]*\s+'
        r'оформля(?:ются|ется|ть)\s+устно',
    severity: RiskSeverity.low,
    description: 'Устные договорённости и изменения не защищают стороны.',
    example: 'Изменения оформляются устно.',
    suggestion:
        'Все изменения оформляйте письменно дополнительным соглашением.',
  ),
  RiskMarkerDescriptor(
    code: 'indefinite_term',
    pattern:
        r'бессрочн(?:ый|ого|ому|ым|ая|ой|ую|ое|ые|ых|о)|'
        r'до\s+расторжения',
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
    suggestion: 'Предусмотрите акт приёма-передачи результата работ.',
  ),
  RiskMarkerDescriptor(
    code: 'auto_renewal_term',
    pattern:
        r'автоматическ(?:и|ая|ой|ую|ое|ого|ым)\s+(?:пролонгир|продлева)|'
        r'пролонгиру(?:ется|ются)\s+автоматическ',
    severity: RiskSeverity.low,
    description: 'Автоматическая пролонгация усиливает бессрочность.',
    example: 'Договор автоматически пролонгируется на следующий год.',
    suggestion:
        'Предусмотрите явное продление отдельным соглашением сторон.',
  ),
  RiskMarkerDescriptor(
    code: 'advance_payment_term',
    pattern:
        r'авансов(?:ый|ого|ому|ым|ыми|ая|ой|ую)\s+плат[её]ж',
    severity: RiskSeverity.low,
    description: 'Авансовая схема напоминает выплату зарплаты.',
    example: 'Предусмотрен авансовый платёж в начале месяца.',
    suggestion:
        'Оплачивайте по факту приёмки этапа, избегая регулярных авансов.',
  ),
  RiskMarkerDescriptor(
    code: 'personal_data_term',
    pattern:
        r'согласи(?:е|я|ю|ем)\s+на\s+обработку\s+персональных\s+данных',
    severity: RiskSeverity.low,
    description: 'Согласие на обработку данных оформляется как у сотрудника.',
    example: 'Исполнитель даёт согласие на обработку персональных данных.',
    suggestion:
        'Оформляйте обработку данных отдельным документом, а не пунктом '
        'договора.',
  ),
  RiskMarkerDescriptor(
    code: 'unilateral_change_term',
    pattern:
        r'в\s+одностороннем\s+порядке\s+(?:измен|расторж|отказ)',
    severity: RiskSeverity.low,
    description: 'Односторонние изменения ухудшают положение Исполнителя.',
    example: 'Заказчик вправе в одностороннем порядке изменять условия.',
    suggestion:
        'Изменения — только по письменному соглашению обеих сторон.',
  ),
  RiskMarkerDescriptor(
    code: 'implicit_acceptance_term',
    pattern:
        r'работы\s+считаются\s+(?:принятыми|выполненными)|'
        r'акт\s+не\s+подписывается|'
        r'если\s+заказчик\s+не\s+направит\s+мотивированн',
    severity: RiskSeverity.low,
    description: 'Молчаливая приёмка работ без акта.',
    example: 'Работы считаются принятыми, если Заказчик не направил претензии.',
    suggestion:
        'Предусмотрите обязательное подписание акта приёмки результата.',
  ),
  RiskMarkerDescriptor(
    code: 'electronic_exchange_term',
    pattern:
        r'обмен\s+документами\s+по\s+электронной\s+почте|'
        r'юридическ(?:ую|ая)\s+силу\s+имеют\s+документы\s+по\s+'
        r'электронной\s+почте',
    severity: RiskSeverity.low,
    description: 'Обмен документами по почте без ЭДО слабо доказуем.',
    example: 'Документы считаются полученными по электронной почте.',
    suggestion:
        'Используйте ЭДО или фиксируйте получение документов письменно.',
  ),
  RiskMarkerDescriptor(
    code: 'indexation_term',
    pattern:
        r'индексаци(?:я|и|ю|ей)\s+(?:вознагражд|заработн)|'
        r'индексиру(?:ется|ются)\s+(?:ежегодно|вознагражд|заработн|выплат)',
    severity: RiskSeverity.low,
    description: 'Индексация вознаграждения — атрибут трудовой зарплаты.',
    example: 'Вознаграждение подлежит ежегодной индексации.',
    suggestion:
        'Фиксируйте цену договора; индексацию оформляйте отдельным '
        'соглашением при необходимости.',
  ),
  RiskMarkerDescriptor(
    code: 'minimum_guaranteed_term',
    pattern:
        r'гарантирован(?:н(?:ый|ого|ому|ым|ая|ой|ую|ое))?\s+'
        r'(?:минимальн[\p{L}]*\s+)?(?:доход|объ[её]м|заказ|уровень)',
    severity: RiskSeverity.low,
    description: 'Гарантированный минимальный доход напоминает оклад.',
    example: 'Исполнителю гарантирован минимальный доход.',
    suggestion:
        'Оплата должна зависеть от фактически принятых этапов и работ.',
  ),
  RiskMarkerDescriptor(
    code: 'payment_delay_term',
    pattern:
        r'оплата\s+(?:производится\s+)?в\s+течение\s+\d{1,3}\s+'
        r'(?:дней|дня)\s+после|отсрочка\s+платежа',
    severity: RiskSeverity.low,
    description: 'Длительная отсрочка платежа повышает финансовые риски.',
    example: 'Оплата производится в течение 60 дней после подписания акта.',
    suggestion:
        'Согласуйте разумный срок оплаты и право на проценты за просрочку.',
  ),
  RiskMarkerDescriptor(
    code: 'price_undefined_term',
    pattern:
        r'стоимость\s+работ\s+не\s+фиксируется|'
        r'цена\s+договора\s+не\s+определена|'
        r'размер\s+вознаграждения\s+не\s+определ',
    severity: RiskSeverity.low,
    description: 'Неопределённая цена договора создаёт споры об оплате.',
    example: 'Стоимость работ не фиксируется и определяется по факту.',
    suggestion:
        'Укажите конкретную цену или порядок её расчёта за этап.',
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
/// Новые маркеры вставляются, а изменившиеся встроенные — обновляются, чтобы
/// после обновления приложения действовали актуальные шаблоны и описания.
/// Возвращает количество добавленных маркеров.
Future<int> seedRiskMarkers(RiskMarkerRepository repository) async {
  var added = 0;
  for (final descriptor in builtInRiskMarkers) {
    final existing = await repository.getByCode(descriptor.code);
    if (existing == null) {
      await repository.put(descriptor.toMarker());
      added++;
    } else if (!_matchesDescriptor(existing, descriptor)) {
      await repository.put(
        existing
          ..pattern = descriptor.pattern
          ..severity = descriptor.severity
          ..description = descriptor.description
          ..example = descriptor.example
          ..suggestion = descriptor.suggestion,
      );
    }
  }
  return added;
}

bool _matchesDescriptor(
  RiskMarker marker,
  RiskMarkerDescriptor descriptor,
) {
  return marker.pattern == descriptor.pattern &&
      marker.severity == descriptor.severity &&
      marker.description == descriptor.description &&
      marker.example == descriptor.example &&
      marker.suggestion == descriptor.suggestion;
}
