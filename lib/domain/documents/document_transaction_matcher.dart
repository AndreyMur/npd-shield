import '../../data/models/document.dart';
import '../../data/models/transaction.dart';

/// Сопоставление документа архива с транзакцией дашборда.
///
/// Документ считается относящимся к транзакции, если он привязан к ней явно
/// ([Document.transactionId] равен [Transaction.id]) или совпадает с ней по
/// фактическим реквизитам расчёта: сумме, дате и контрагенту.
class TransactionDocumentMatch {
  final Transaction transaction;

  /// Документы, сопоставленные с транзакцией.
  final List<Document> documents;

  const TransactionDocumentMatch({
    required this.transaction,
    required this.documents,
  });

  /// Есть ли у транзакции хотя бы один документ.
  bool get hasDocuments => documents.isNotEmpty;

  /// Основной документ (чек, затем акт) для перехода из карточки.
  Document? get primary => documents.isEmpty ? null : documents.first;
}

/// Привязан ли документ к транзакции явно.
bool isDocumentLinkedToTransaction(Document document, Transaction transaction) {
  return document.transactionId != 0 &&
      document.transactionId == transaction.id;
}

/// Совпадает ли документ с транзакцией по реквизитам расчёта.
///
/// Сопоставление «сумма + дата + контрагент» применяется к документам без
/// явной привязки, чтобы связать уже существующие записи с транзакциями,
/// созданными вручную. Совпадение только суммы и даты допускается, когда
/// контрагент не указан хотя бы с одной стороны.
bool documentMatchesTransaction(Document document, Transaction transaction) {
  if (document.transactionId != 0) {
    return isDocumentLinkedToTransaction(document, transaction);
  }
  if (!_sameAmount(document.amount, transaction.amount)) return false;
  if (!_sameDay(document.date, transaction.date)) return false;

  final documentInn = document.counterpartyInn.trim();
  final transactionInn = transaction.clientInn.trim();
  if (documentInn.isNotEmpty && transactionInn.isNotEmpty) {
    return documentInn == transactionInn;
  }

  final documentName = _normalize(document.counterpartyName);
  final transactionName = _normalize(transaction.clientName);
  if (documentName.isEmpty || transactionName.isEmpty) return true;
  return documentName == transactionName;
}

/// Документы, сопоставленные с транзакцией [transaction].
///
/// Порядок документов сохраняется: чеки и акты идут в порядке выборки архива.
List<Document> documentsForTransaction(
  Transaction transaction,
  List<Document> documents,
) {
  return [
    for (final document in documents)
      if (documentMatchesTransaction(document, transaction)) document,
  ];
}

/// Сопоставляет транзакции дашборда с документами архива.
///
/// Возвращает запись для каждой транзакции — даже если документов нет, чтобы
/// интерфейс мог показать транзакцию без значка документа.
List<TransactionDocumentMatch> matchDocumentsToTransactions({
  required List<Transaction> transactions,
  required List<Document> documents,
}) {
  return [
    for (final transaction in transactions)
      TransactionDocumentMatch(
        transaction: transaction,
        documents: documentsForTransaction(transaction, documents),
      ),
  ];
}

/// Документы, которым следует проставить привязку к транзакции [transaction].
///
/// Возвращаются только документы без явной привязки, совпавшие по реквизитам.
List<Document> linkableDocumentsForTransaction(
  Transaction transaction,
  List<Document> documents,
) {
  return [
    for (final document in documents)
      if (document.transactionId == 0 &&
          documentMatchesTransaction(document, transaction))
        document,
  ];
}

bool _sameAmount(double a, double b) => (a - b).abs() < 0.01;

bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

String _normalize(String value) => value.trim().toLowerCase();
