import '../models/document.dart';

/// Репозиторий единого архива документов (чеки, акты, договоры).
abstract class DocumentRepository {
  /// Сохраняет (вставляет или обновляет) документ и возвращает его `id`.
  Future<int> save(Document document);

  /// Возвращает документ по идентификатору или `null`.
  Future<Document?> getById(int id);

  /// Возвращает все документы, самые новые — первыми.
  Future<List<Document>> getAll();

  /// Возвращает документы указанного типа, самые новые — первыми.
  Future<List<Document>> getByType(DocumentType type);

  /// Возвращает документы, привязанные к договору.
  Future<List<Document>> getByContractDraftId(int contractDraftId);

  /// Возвращает документы, привязанные к транзакции.
  Future<List<Document>> getByTransactionId(int transactionId);

  /// Возвращает документы, привязанные к чеку (например, акт к чеку).
  Future<List<Document>> getByReceiptDocumentId(int receiptDocumentId);

  /// Возвращает документы, привязанные к карточке клиента из справочника.
  Future<List<Document>> getByClientId(int clientId);

  /// Количество документов в архиве.
  Future<int> count();

  /// Удаляет документ по идентификатору.
  Future<void> delete(int id);

  /// Удаляет все документы (используется в тестах).
  Future<void> clear();
}
