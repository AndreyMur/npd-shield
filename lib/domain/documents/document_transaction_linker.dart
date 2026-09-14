import '../../data/models/document.dart';
import '../../data/models/transaction.dart';
import '../../data/repositories/document_repository.dart';
import 'document_transaction_matcher.dart';

/// Проставляет явную привязку документов к транзакциям дашборда.
///
/// Документы, совпавшие с транзакцией по сумме, дате и контрагенту, но без
/// явной привязки, сохраняются с заполненным `transactionId`. Так сопоставление
/// фиксируется в архиве и не выполняется повторно при каждом открытии
/// дашборда.
class DocumentTransactionLinker {
  const DocumentTransactionLinker();

  /// Связывает документы [documents] с транзакциями [transactions].
  ///
  /// Возвращает число сохранённых привязок. Транзакции и документы без
  /// идентификатора ([Transaction.id] == 0) пропускаются.
  Future<int> link({
    required DocumentRepository documentRepository,
    required List<Transaction> transactions,
    required List<Document> documents,
  }) async {
    var linked = 0;
    for (final transaction in transactions) {
      if (transaction.id == 0) continue;
      for (final document
          in linkableDocumentsForTransaction(transaction, documents)) {
        document.transactionId = transaction.id;
        await documentRepository.save(document);
        linked++;
      }
    }
    return linked;
  }
}
