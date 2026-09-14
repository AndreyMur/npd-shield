import 'receipt.dart';

/// Тип покупателя для расчёта в приложении «Мой налог».
///
/// От типа зависит код вида дохода, который передаётся в deep link:
/// доход от организации/ИП (`income_from_organization`) или от физлица
/// (`income_from_individual`).
enum ClientType {
  /// Доход от организации или индивидуального предпринимателя.
  legal,

  /// Доход от физического лица.
  individual;

  /// Человекочитаемая метка типа для интерфейса.
  String get label => switch (this) {
    ClientType.legal => 'Юрлицо / ИП',
    ClientType.individual => 'Физлицо',
  };

  /// Код вида дохода в параметрах deep link.
  String get code => switch (this) {
    ClientType.legal => 'income_from_organization',
    ClientType.individual => 'income_from_individual',
  };

  /// Определяет тип покупателя по ИНН.
  ///
  /// ИНН организации состоит из 10 цифр, ИНН физического лица — из 12.
  /// Пустое или неизвестное значение считается физлицом.
  static ClientType fromInn(String inn) {
    final digits = inn.replaceAll(RegExp(r'[^0-9]'), '');
    return digits.length == 10 ? ClientType.legal : ClientType.individual;
  }
}

/// Данные расчёта для перехода в приложение «Мой налог» через deep link.
///
/// Формирует URL вида
/// `https://mynalog.ru/issue?amount=150000.00&client=...&type=income_from_organization`
/// и текст для копирования в буфер обмена, если приложение не установлено.
class MyTaxDeepLink {
  /// Хост deep link приложения «Мой налог».
  static const String host = 'mynalog.ru';

  /// Путь формы оформления чека.
  static const String issuePath = '/issue';

  /// Сумма расчёта в рублях.
  final double amount;

  /// Наименование покупателя (организация или ФИО).
  final String clientName;

  /// ИНН покупателя (необязательно для физлиц).
  final String clientInn;

  /// Тип покупателя.
  final ClientType clientType;

  /// Наименование услуги или работы.
  final String serviceName;

  const MyTaxDeepLink({
    required this.amount,
    this.clientName = '',
    this.clientInn = '',
    this.clientType = ClientType.individual,
    this.serviceName = '',
  });

  /// Собирает deep link из готового чека, определяя тип покупателя по ИНН.
  factory MyTaxDeepLink.fromReceipt(Receipt receipt, {ClientType? clientType}) {
    return MyTaxDeepLink(
      amount: receipt.amount,
      clientName: receipt.buyerName,
      clientInn: receipt.buyerInn,
      clientType: clientType ?? ClientType.fromInn(receipt.buyerInn),
      serviceName: receipt.serviceName,
    );
  }

  /// Копия ссылки с другим типом покупателя.
  MyTaxDeepLink copyWith({ClientType? clientType}) {
    return MyTaxDeepLink(
      amount: amount,
      clientName: clientName,
      clientInn: clientInn,
      clientType: clientType ?? this.clientType,
      serviceName: serviceName,
    );
  }

  /// Сумма в формате «150 000,00 ₽».
  String get formattedAmount => formatReceiptAmount(amount);

  /// URL deep link с параметрами суммы, покупателя и вида дохода.
  Uri get uri => Uri.https(host, issuePath, {
    'amount': amount.toStringAsFixed(2),
    'type': clientType.code,
    if (clientName.trim().isNotEmpty) 'client': clientName.trim(),
    if (clientInn.trim().isNotEmpty) 'clientInn': clientInn.trim(),
    if (serviceName.trim().isNotEmpty) 'service': serviceName.trim(),
  });

  /// Текст для копирования в буфер обмена при отсутствии приложения.
  String get clipboardText {
    final buffer = StringBuffer()
      ..writeln('Расчёт для «Мой налог»')
      ..writeln('Сумма: $formattedAmount')
      ..writeln('Тип покупателя: ${clientType.label}');
    if (clientName.trim().isNotEmpty) {
      buffer.writeln('Покупатель: ${clientName.trim()}');
    }
    if (clientInn.trim().isNotEmpty) {
      buffer.writeln('ИНН покупателя: ${clientInn.trim()}');
    }
    if (serviceName.trim().isNotEmpty) {
      buffer.writeln('Услуга: ${serviceName.trim()}');
    }
    return buffer.toString().trimRight();
  }

  /// Пошаговая инструкция ручного ввода данных в «Мой налог».
  List<String> get manualSteps => [
    'Откройте приложение «Мой налог» и войдите по ИНН и паролю.',
    'Нажмите «Новая продажа» и укажите сумму $formattedAmount.',
    if (serviceName.trim().isNotEmpty)
      'Введите наименование услуги: ${serviceName.trim()}.',
    'Выберите тип покупателя: ${clientType.label}.',
    if (clientInn.trim().isNotEmpty)
      'Укажите ИНН покупателя: ${clientInn.trim()}.',
    'Сохраните чек и отправьте его покупателю.',
  ];
}
