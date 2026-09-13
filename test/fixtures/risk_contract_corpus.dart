/// Тестовая база договоров для оценки точности Risk Shield.
///
/// Каждый документ — фрагмент договора с разметкой:
/// * [RiskCorpusDocument.unsafe] — содержит ли документ реальные риски;
/// * [RiskCorpusDocument.expectedMarkerCodes] — коды маркеров, которые
///   анализатор обязан найти в небезопасном документе.
///
/// Безопасные документы написаны на языке ГПХ (услуги, подряд, вознаграждение,
/// акт, результат) и не должны давать ни одного срабатывания. Несколько
/// безопасных образцов намеренно содержат отрицания трудовых формулировок,
/// чтобы проверить калибровку окна отрицаний.
class RiskCorpusDocument {
  final String name;
  final String text;
  final bool unsafe;
  final Set<String> expectedMarkerCodes;

  const RiskCorpusDocument({
    required this.name,
    required this.text,
    required this.unsafe,
    this.expectedMarkerCodes = const {},
  });
}

/// Небезопасные образцы — должны находить все перечисленные маркеры.
const List<RiskCorpusDocument> unsafeRiskCorpus = [
  RiskCorpusDocument(
    name: 'unsafe_classic_labor',
    unsafe: true,
    expectedMarkerCodes: {
      'labor_contract_term',
      'employer_employee_term',
      'labor_function_term',
      'salary_term',
      'salary_twice_monthly_term',
      'probation_term',
      'internal_rules_term',
      'subordination_term',
      'manager_term',
      'hire_dismissal_term',
      'employment_book_term',
    },
    text:
        'Настоящий трудовой договор заключается между Работодателем и '
        'Работником. Работник принимается на должность менеджера по продажам. '
        'Работодатель обязуется выплачивать заработную плату не реже двух раз '
        'в месяц. Работнику устанавливается испытательный срок три месяца. '
        'Работник подчиняется правилам внутреннего трудового распорядка и '
        'указаниям непосредственного руководителя. В трудовую книжку вносится '
        'запись о приёме на работу.',
  ),
  RiskCorpusDocument(
    name: 'unsafe_work_schedule',
    unsafe: true,
    expectedMarkerCodes: {
      'work_schedule_term',
      'full_time_term',
      'lunch_break_term',
      'labor_safety_term',
      'time_tracking_term',
    },
    text:
        'Устанавливается режим рабочего времени: пятидневная рабочая неделя, '
        'рабочий день с 9:00 до 18:00, перерыв для отдыха и питания один час. '
        'Сотрудник обязан соблюдать требования охраны труда и проходить '
        'инструктаж по охране труда. Учёт рабочего времени ведётся в табеле '
        'учёта рабочего времени.',
  ),
  RiskCorpusDocument(
    name: 'unsafe_leave_and_sick',
    unsafe: true,
    expectedMarkerCodes: {
      'paid_leave_term',
      'sick_leave_payment_term',
      'leave_schedule_term',
      'employer_employee_term',
    },
    text:
        'Работнику предоставляется ежегодный оплачиваемый отпуск '
        'продолжительностью 28 календарных дней. Оплата больничного листа '
        'производится за счёт работодателя. Отпуска предоставляются согласно '
        'графику отпусков.',
  ),
  RiskCorpusDocument(
    name: 'unsafe_discipline',
    unsafe: true,
    expectedMarkerCodes: {
      'discipline_term',
      'overtime_term',
      'employer_employee_term',
    },
    text:
        'За нарушение обязанностей к работнику применяется дисциплинарное '
        'взыскание. Работодатель вправе привлекать работника к сверхурочной '
        'работе. Работник несёт полную материальную ответственность.',
  ),
  RiskCorpusDocument(
    name: 'unsafe_legislation_and_staff',
    unsafe: true,
    expectedMarkerCodes: {
      'labor_legislation_term',
      'seniority_term',
      'personal_file_term',
      'employer_employee_term',
    },
    text:
        'Стороны руководствуются трудовым законодательством Российской '
        'Федерации и ТК РФ. Период работы засчитывается в трудовой стаж. '
        'Сведения о работнике хранятся в личном деле.',
  ),
  RiskCorpusDocument(
    name: 'unsafe_hire_dismissal',
    unsafe: true,
    expectedMarkerCodes: {
      'hire_dismissal_term',
      'personnel_order_term',
      'severance_term',
      'employer_employee_term',
    },
    text:
        'Приём на работу оформляется приказом о приёме на работу. Увольнение '
        'производится по инициативе работодателя. При увольнении выплачивается '
        'выходное пособие и компенсация за неиспользованный отпуск.',
  ),
  RiskCorpusDocument(
    name: 'unsafe_pay_and_mrot',
    unsafe: true,
    expectedMarkerCodes: {
      'minimum_wage_term',
      'salary_term',
      'monthly_fixed_term',
      'indexation_term',
    },
    text:
        'Оплата труда производится не ниже минимального размера оплаты труда. '
        'Заработная плата индексируется ежегодно. Вознаграждение выплачивается '
        'ежемесячно не позднее 15 числа каждого месяца.',
  ),
  RiskCorpusDocument(
    name: 'unsafe_control',
    unsafe: true,
    expectedMarkerCodes: {
      'subordination_term',
      'work_under_control_term',
      'workplace_term',
      'reporting_term',
    },
    text:
        'Исполнитель подчиняется указаниям Заказчика и выполняет работы по '
        'заданию Заказчика. Заказчик предоставляет Исполнителю рабочее место. '
        'Исполнитель обязан отчитываться перед Заказчиком еженедельно.',
  ),
  RiskCorpusDocument(
    name: 'unsafe_training_and_trips',
    unsafe: true,
    expectedMarkerCodes: {
      'paid_training_term',
      'mobile_compensation_term',
      'business_trip_term',
    },
    text:
        'Заказчик оплачивает обучение за счёт заказчика. Исполнителю '
        'компенсируются расходы на связь. Исполнитель направляется в служебную '
        'командировку.',
  ),
  RiskCorpusDocument(
    name: 'unsafe_kpi_and_meetings',
    unsafe: true,
    expectedMarkerCodes: {
      'kpi_term',
      'mandatory_meetings_term',
      'attendance_term',
    },
    text:
        'Результат работы Исполнителя оценивается по ключевым показателям '
        'эффективности. Обязательное участие в еженедельных планёрках. '
        'Обязательно присутствие на рабочем месте с 10 до 19.',
  ),
  RiskCorpusDocument(
    name: 'unsafe_schedule_approval',
    unsafe: true,
    expectedMarkerCodes: {
      'work_schedule_term',
      'schedule_approval_term',
    },
    text:
        'График работы Исполнителя согласовывается с руководителем. Исполнитель '
        'обязан согласовывать даты встреч с Заказчиком.',
  ),
  RiskCorpusDocument(
    name: 'unsafe_position_and_staff',
    unsafe: true,
    expectedMarkerCodes: {
      'labor_function_term',
      'staff_unit_term',
    },
    text:
        'Исполнитель принимается на должность системного администратора. '
        'Должность вводится в штатное расписание. Оклад устанавливается согласно '
        'штатному расписанию.',
  ),
  RiskCorpusDocument(
    name: 'unsafe_guarantees',
    unsafe: true,
    expectedMarkerCodes: {
      'minimum_guaranteed_term',
      'indexation_term',
      'advance_payment_term',
    },
    text:
        'Исполнителю гарантирован минимальный доход. Предусмотрена ежегодная '
        'индексация вознаграждения. Вознаграждение выплачивается авансовыми '
        'платежами.',
  ),
  RiskCorpusDocument(
    name: 'unsafe_formal_risks',
    unsafe: true,
    expectedMarkerCodes: {
      'indefinite_term',
      'auto_renewal_term',
      'verbal_changes_term',
      'no_act_term',
    },
    text:
        'Договор заключается бессрочно и автоматически пролонгируется. '
        'Изменения оформляются устно. Оплата производится без акта выполненных '
        'работ.',
  ),
  RiskCorpusDocument(
    name: 'unsafe_implicit_acceptance',
    unsafe: true,
    expectedMarkerCodes: {
      'implicit_acceptance_term',
      'unilateral_change_term',
      'price_undefined_term',
    },
    text:
        'Работы считаются принятыми без подписания акта. Заказчик вправе в '
        'одностороннем порядке изменять условия. Стоимость работ не '
        'фиксируется.',
  ),
];

/// Безопасные образцы — анализатор не должен найти в них ни одного риска.
const List<RiskCorpusDocument> safeRiskCorpus = [
  RiskCorpusDocument(
    name: 'safe_services',
    unsafe: false,
    text:
        'Договор возмездного оказания услуг. Заказчик поручает, а Исполнитель '
        'обязуется оказать услуги по разработке программного обеспечения. '
        'Услуги оказываются в срок до 31 декабря. Исполнитель самостоятельно '
        'определяет порядок и способы оказания услуг. Вознаграждение '
        'составляет 100 000 рублей.',
  ),
  RiskCorpusDocument(
    name: 'safe_acceptance',
    unsafe: false,
    text:
        'По завершении этапа стороны подписывают акт сдачи-приёмки оказанных '
        'услуг. Оплата производится в течение 10 рабочих дней после подписания '
        'акта. Результат работ передаётся по акту.',
  ),
  RiskCorpusDocument(
    name: 'safe_independent_contractor',
    unsafe: false,
    text:
        'Исполнитель не является работником Заказчика и действует как '
        'независимый подрядчик. Договор не является трудовым договором. '
        'Исполнитель не подчиняется указаниям Заказчика и самостоятельно '
        'организует свою работу.',
  ),
  RiskCorpusDocument(
    name: 'safe_own_equipment',
    unsafe: false,
    text:
        'Исполнитель использует собственное оборудование и материалы. Расходы, '
        'связанные с оказанием услуг, включены в стоимость. Заказчик не '
        'предоставляет рабочее место.',
  ),
  RiskCorpusDocument(
    name: 'safe_payment_by_stages',
    unsafe: false,
    text:
        'Оплата производится поэтапно по факту приёмки. Каждый этап оформляется '
        'отдельным актом. Размер вознаграждения за этап фиксируется в '
        'приложении.',
  ),
  RiskCorpusDocument(
    name: 'safe_written_changes',
    unsafe: false,
    text:
        'Стороны несут ответственность за неисполнение обязательств. Срок '
        'оказания услуг может быть продлён по письменному соглашению сторон. '
        'Изменения оформляются дополнительным соглашением.',
  ),
  RiskCorpusDocument(
    name: 'safe_civil_law',
    unsafe: false,
    text:
        'Настоящий договор регулируется гражданским законодательством '
        'Российской Федерации. К отношениям сторон применяются нормы о '
        'подряде. Споры разрешаются в суде.',
  ),
  RiskCorpusDocument(
    name: 'safe_remote_consultant',
    unsafe: false,
    text:
        'Консультант оказывает услуги дистанционно. Место оказания услуг '
        'определяется Исполнителем. Заказчик оплачивает результат, а не '
        'процесс.',
  ),
  RiskCorpusDocument(
    name: 'safe_test_stand',
    unsafe: false,
    text:
        'Заказчик предоставляет доступ к тестовому стенду. Стенд используется '
        'исключительно для оказания услуг по договору.',
  ),
  RiskCorpusDocument(
    name: 'safe_fixed_term',
    unsafe: false,
    text:
        'Договор вступает в силу с момента подписания и действует до 31 декабря '
        '2026 года. По истечении срока стороны вправе заключить новый договор.',
  ),
  RiskCorpusDocument(
    name: 'safe_invoice_payment',
    unsafe: false,
    text:
        'Оплата производится на основании счёта, выставленного Исполнителем, '
        'безналичным переводом. Датой оплаты считается дата зачисления '
        'средств.',
  ),
  RiskCorpusDocument(
    name: 'safe_edo',
    unsafe: false,
    text:
        'Стороны обмениваются документами через систему электронного '
        'документооборота. Документы, подписанные электронной подписью, имеют '
        'юридическую силу.',
  ),
  RiskCorpusDocument(
    name: 'safe_personal_data',
    unsafe: false,
    text:
        'Обработка персональных данных осуществляется в соответствии с '
        'отдельным согласием, подписанным Исполнителем.',
  ),
  RiskCorpusDocument(
    name: 'safe_reports_on_request',
    unsafe: false,
    text:
        'Исполнитель передаёт результат работ по акту. Промежуточные отчёты '
        'предоставляются по запросу Заказчика, но не чаще одного раза в месяц.',
  ),
  RiskCorpusDocument(
    name: 'safe_no_guarantees',
    unsafe: false,
    text:
        'Вознаграждение зависит от фактически принятых этапов. Минимальный '
        'размер вознаграждения не гарантируется. Стороны не связаны KPI.',
  ),
];

/// Все документы тестовой базы.
List<RiskCorpusDocument> get riskContractCorpus => [
  ...unsafeRiskCorpus,
  ...safeRiskCorpus,
];
