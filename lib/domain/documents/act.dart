import '../../core/constants/contract_field_keys.dart';
import '../../data/models/document.dart';
import '../profile/contractor_profile.dart';
import 'receipt.dart';

/// Готовые данные акта выполненных работ, собранные из профиля ИП,
/// договора и чека.
///
/// [sellerName] и [sellerInn] — реквизиты исполнителя, [buyerName] и
/// [buyerInn] — заказчика, [worksDescription] — описание работ,
/// [result] — результат выполненных работ, [amount] — сумма,
/// [completionDate] — дата выполнения работ.
class Act {
  final String sellerName;
  final String sellerInn;
  final String buyerName;
  final String buyerInn;

  /// Описание выполненных работ (предмет договора).
  final String worksDescription;

  /// Результат выполненных работ.
  final String result;

  /// Стоимость выполненных работ.
  final double amount;

  /// Дата выполнения работ.
  final DateTime completionDate;

  /// Привязка к договору (`ContractDraft.id`); `0` — без привязки.
  final int contractDraftId;

  /// Номер договора на момент формирования акта.
  final String contractNumber;

  /// Привязка к чеку (`Document.id`); `0` — без привязки.
  final int receiptDocumentId;

  /// Подпись исполнителя (ФИО/должность для распечатки).
  final String executorSignatory;

  /// Подпись заказчика (ФИО/должность для распечатки).
  final String customerSignatory;

  const Act({
    required this.sellerName,
    required this.sellerInn,
    required this.worksDescription,
    required this.amount,
    required this.completionDate,
    this.buyerName = '',
    this.buyerInn = '',
    this.result = defaultActResult,
    this.contractDraftId = 0,
    this.contractNumber = '',
    this.receiptDocumentId = 0,
    this.executorSignatory = '',
    this.customerSignatory = '',
  });

  /// Восстанавливает акт из записи архива документов.
  ///
  /// Используется архивом для повторной генерации PDF-версии уже
  /// сформированного акта.
  factory Act.fromDocument(Document document) {
    return Act(
      sellerName: document.issuerName,
      sellerInn: document.issuerInn,
      worksDescription: document.serviceName,
      amount: document.amount,
      completionDate: document.date,
      buyerName: document.counterpartyName,
      buyerInn: document.counterpartyInn,
      result: document.result,
      contractDraftId: document.contractDraftId,
      contractNumber: document.contractNumber,
      receiptDocumentId: document.receiptDocumentId,
      executorSignatory: document.executorSignatory,
      customerSignatory: document.customerSignatory,
    );
  }

  /// Указан ли ИНН заказчика.
  bool get hasBuyerInn => buyerInn.trim().isNotEmpty;

  /// Указан ли результат работ.
  bool get hasResult => result.trim().isNotEmpty;

  /// Заполнены ли подписи обеих сторон.
  bool get hasSignatures =>
      executorSignatory.trim().isNotEmpty && customerSignatory.trim().isNotEmpty;

  /// Сумма в формате «150 000,00 ₽».
  String get formattedAmount => formatReceiptAmount(amount);

  /// Дата выполнения в формате ДД.ММ.ГГГГ.
  String get formattedDate => formatContractDate(completionDate);

  /// Преобразует акт в запись архива документов.
  Document toDocument({DocumentStatus status = DocumentStatus.generated}) {
    return Document(
      type: DocumentType.act,
      status: status,
      amount: amount,
      date: completionDate,
      contractDraftId: contractDraftId,
      contractNumber: contractNumber,
      receiptDocumentId: receiptDocumentId,
      counterpartyName: buyerName,
      counterpartyInn: buyerInn,
      serviceName: worksDescription,
      result: result,
      executorSignatory: executorSignatory,
      customerSignatory: customerSignatory,
      issuerName: sellerName,
      issuerInn: sellerInn,
    );
  }
}

/// Результат работ по умолчанию: работы выполнены в полном объёме.
const String defaultActResult =
    'Работы выполнены в полном объёме, в срок и с надлежащим качеством. '
    'Заказчик претензий по объёму, качеству и срокам выполнения работ '
    'не имеет.';

/// Собирает данные акта с автозаполнением из профиля ИП, договора и чека.
///
/// Реквизиты исполнителя всегда берутся из профиля ИП, описание работ — из
/// предмета договора. Если передан [receipt], сумма, заказчик и дата
/// выполнения берутся из чека как из фактического расчёта; иначе — из полей
/// договора.
class ActGenerator {
  const ActGenerator();

  Act generate({
    required ContractorProfile profile,
    Map<String, String> contractFields = const {},
    Receipt? receipt,
    int contractDraftId = 0,
    int receiptDocumentId = 0,
    DateTime? completionDate,
  }) {
    final contractAmount = parseReceiptAmount(
      contractFields[ContractFieldKeys.amount] ?? '',
    );
    final amount = receipt != null && receipt.amount > 0
        ? receipt.amount
        : contractAmount;

    final buyerName = _prefer(
      receipt?.buyerName,
      contractFields[ContractFieldKeys.clientName],
    );
    final buyerInn = _prefer(
      receipt?.buyerInn,
      contractFields[ContractFieldKeys.clientInn],
    );
    final worksDescription = _prefer(
      contractFields[ContractFieldKeys.subject],
      receipt?.serviceName,
    );

    final resolvedDate =
        completionDate ??
        receipt?.date ??
        parseContractDate(contractFields[ContractFieldKeys.contractDate] ?? '') ??
        DateTime.now();

    return Act(
      sellerName: profile.fullName,
      sellerInn: profile.inn,
      worksDescription: worksDescription,
      amount: amount,
      completionDate: resolvedDate,
      buyerName: buyerName,
      buyerInn: buyerInn,
      contractDraftId: contractDraftId,
      contractNumber: contractFields[ContractFieldKeys.contractNumber] ?? '',
      receiptDocumentId: receiptDocumentId,
      executorSignatory: profile.fullName,
      customerSignatory: buyerName,
    );
  }

  static String _prefer(String? primary, String? fallback) {
    final value = primary?.trim() ?? '';
    if (value.isNotEmpty) return value;
    return fallback?.trim() ?? '';
  }
}
