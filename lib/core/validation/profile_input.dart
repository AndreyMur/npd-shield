/// Валидация реквизитов профиля ИП.
///
/// Профиль заполняется в онбординге и на экране редактирования, а значения
/// подставляются в договоры, чеки и акты, поэтому проверка ввода вынесена в
/// одно место.
class ProfileInput {
  ProfileInput._();

  /// Проверяет необязательное цифровое поле.
  ///
  /// Пустое значение допустимо. Иначе поле должно содержать только цифры и
  /// иметь длину из [lengths]. Возвращает сообщение об ошибке или `null`.
  static String? validateDigits(String? value, {required List<int> lengths}) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return null;
    if (!lengths.contains(text.length) || int.tryParse(text) == null) {
      return 'Введите ${lengths.join(' или ')} цифр';
    }
    return null;
  }
}
