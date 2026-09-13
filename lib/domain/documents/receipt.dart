import '../../core/constants/contract_field_keys.dart';
import '../../data/models/document.dart';
import '../../data/models/transaction.dart';
import '../profile/contractor_profile.dart';

/// Готовые данные чека для НПД, собранные из профиля ИП и договора/транзакции.
///
/// [sellerName] и [sellerInn] — реквизиты исполнителя (ИП на НПД),
/// [buyerName] и [buyerInn] — реквизиты покупателя, [serviceName] — предмет
/// расчёта, [amount] — сумма, [date] — дата расчёта.
class Receipt {
  final String sellerName;
  final String sellerInn;
  final String serviceName;
  final double amount;
  final DateTime date;
  final String buyerName;
  final String buyerInn;

  /// Привязка к договору (`ContractDraft.id`); `0` — без привязки.
  final int contractDraftId;

  /// Номер договора на момент формирования чека.
  final String contractNumber;

  /// Привязка к транзакции (`Transaction.id`); `0` — без привязки.
  final int transactionId;

  const Receipt({
    required this.sellerName,
    required this.sellerInn,
    required this.serviceName,
    required this.amount,
    required this.date,
    this.buyerName = '',
    this.buyerInn = '',
    this.contractDraftId = 0,
    this.contractNumber = '',
    this.transactionId = 0,
  });

  /// Восстанавливает чек из записи архива документов.
  ///
  /// Используется, когда чек уже сохранён, а его данные нужны для
  /// автозаполнения связанного акта.
  factory Receipt.fromDocument(Document document) {
    return Receipt(
      sellerName: document.issuerName,
      sellerInn: document.issuerInn,
      serviceName: document.serviceName,
      amount: document.amount,
      date: document.date,
      buyerName: document.counterpartyName,
      buyerInn: document.counterpartyInn,
      contractDraftId: document.contractDraftId,
      contractNumber: document.contractNumber,
      transactionId: document.transactionId,
    );
  }

  /// Указан ли ИНН покупателя (для чеков организациям/ИП).
  bool get hasBuyerInn => buyerInn.trim().isNotEmpty;

  /// Сумма в формате «150 000,00 ₽».
  String get formattedAmount => formatReceiptAmount(amount);

  /// Дата расчёта в формате ДД.ММ.ГГГГ.
  String get formattedDate => formatContractDate(date);

  /// Преобразует чек в запись архива документов.
  Document toDocument({DocumentStatus status = DocumentStatus.generated}) {
    return Document(
      type: DocumentType.receipt,
      status: status,
      amount: amount,
      date: date,
      contractDraftId: contractDraftId,
      contractNumber: contractNumber,
      counterpartyName: buyerName,
      counterpartyInn: buyerInn,
      transactionId: transactionId,
      serviceName: serviceName,
      issuerName: sellerName,
      issuerInn: sellerInn,
    );
  }
}

/// Форматирует сумму чека: разряды разделяются пробелом, копейки — запятой.
String formatReceiptAmount(double value) {
  final fixed = value.toStringAsFixed(2);
  final parts = fixed.split('.');
  final sign = parts[0].startsWith('-') ? '-' : '';
  final digits = parts[0].replaceFirst('-', '');
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(' ');
    buffer.write(digits[i]);
  }
  return '$sign$buffer,${parts[1]} ₽';
}

/// Собирает данные чека с автозаполнением из профиля ИП и договора/транзакции.
///
/// Реквизиты исполнителя всегда берутся из профиля ИП, поля чека — из
/// заполненных полей договора ([contractFields]) с приоритетом транзакции
/// ([transaction]), если она передана: транзакция отражает фактический расчёт.
class ReceiptGenerator {
  const ReceiptGenerator();

  Receipt generate({
    required ContractorProfile profile,
    Map<String, String> contractFields = const {},
    Transaction? transaction,
    int contractDraftId = 0,
    int transactionId = 0,
    DateTime? date,
  }) {
    final contractAmount = parseReceiptAmount(
      contractFields[ContractFieldKeys.amount] ?? '',
    );
    final amount = transaction != null && transaction.amount > 0
        ? transaction.amount
        : contractAmount;

    final resolvedDate =
        date ??
        transaction?.date ??
        parseContractDate(contractFields[ContractFieldKeys.contractDate] ?? '') ??
        DateTime.now();

    final buyerName = _prefer(
      transaction?.clientName,
      contractFields[ContractFieldKeys.clientName],
    );
    final buyerInn = _prefer(
      transaction?.clientInn,
      contractFields[ContractFieldKeys.clientInn],
    );
    final serviceName = _prefer(
      contractFields[ContractFieldKeys.subject],
      _fallbackServiceName(transaction),
    );

    return Receipt(
      sellerName: profile.fullName,
      sellerInn: profile.inn,
      serviceName: serviceName,
      amount: amount,
      date: resolvedDate,
      buyerName: buyerName,
      buyerInn: buyerInn,
      contractDraftId: contractDraftId,
      contractNumber: contractFields[ContractFieldKeys.contractNumber] ?? '',
      transactionId: transactionId,
    );
  }

  static String _prefer(String? primary, String? fallback) {
    final value = primary?.trim() ?? '';
    if (value.isNotEmpty) return value;
    return fallback?.trim() ?? '';
  }

  static String _fallbackServiceName(Transaction? transaction) {
    return switch (transaction?.sphere) {
      TransactionSphere.it => 'IT-услуги',
      TransactionSphere.logistics => 'Логистические услуги',
      null => 'Оказание услуг',
    };
  }
}

/// Разбирает сумму из поля договора: пробелы-разделители и запятая допустимы.
double parseReceiptAmount(String raw) {
  final cleaned = raw
      .replaceAll(RegExp(r'[^0-9,.\-]'), '')
      .replaceAll(',', '.');
  return double.tryParse(cleaned) ?? 0;
}

/// Разбирает дату договора в формате ДД.ММ.ГГГГ; `null`, если формат неверный.
DateTime? parseContractDate(String raw) {
  final match = RegExp(r'^(\d{2})\.(\d{2})\.(\d{4})$').firstMatch(raw.trim());
  if (match == null) return null;
  final day = int.parse(match.group(1)!);
  final month = int.parse(match.group(2)!);
  final year = int.parse(match.group(3)!);
  if (month < 1 || month > 12 || day < 1 || day > 31) return null;
  return DateTime(year, month, day);
}
