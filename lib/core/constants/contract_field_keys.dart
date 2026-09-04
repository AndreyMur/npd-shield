/// Ключи полей договора.
///
/// Используются как ключи в `ContractDraft.filledFields`, как плейсхолдеры
/// `{{...}}` в тексте шаблонов в Assets и как метки полей формы.
/// Ключи должны совпадать в этих трёх местах, чтобы подстановка значений
/// при генерации документа работала без преобразований.
abstract final class ContractFieldKeys {
  /// Номер договора (например, «14/09»).
  static const contractNumber = 'contractNumber';

  /// Дата договора в формате ДД.ММ.ГГГГ.
  static const contractDate = 'contractDate';

  /// Город заключения договора.
  static const contractCity = 'contractCity';

  /// Заказчик: наименование (организация или ФИО ИП).
  static const clientName = 'clientName';

  /// Заказчик: ИНН.
  static const clientInn = 'clientInn';

  /// Заказчик: адрес.
  static const clientAddress = 'clientAddress';

  /// Исполнитель: ФИО.
  static const executorFullName = 'executorFullName';

  /// Исполнитель: ИНН.
  static const executorInn = 'executorInn';

  /// Исполнитель: ОГРНИП.
  static const executorOgrnip = 'executorOgrnip';

  /// Исполнитель: адрес регистрации.
  static const executorAddress = 'executorAddress';

  /// Исполнитель: наименование банка.
  static const executorBankName = 'executorBankName';

  /// Исполнитель: БИК банка.
  static const executorBankBik = 'executorBankBik';

  /// Исполнитель: расчётный счёт.
  static const executorBankAccount = 'executorBankAccount';

  /// Предмет договора (краткое описание услуг/работ).
  static const subject = 'subject';

  /// Стоимость по договору в рублях.
  static const amount = 'amount';
}

/// Форматирует дату для договора в виде ДД.ММ.ГГГГ.
String formatContractDate(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return '$day.$month.${date.year}';
}
