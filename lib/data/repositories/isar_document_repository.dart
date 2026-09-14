import 'package:isar/isar.dart';

import '../models/document.dart';
import '../security/database_encryption_service.dart';
import '../security/field_encryption_service.dart';
import 'document_repository.dart';

/// Реализация архива документов поверх Isar с шифрованием персональных данных.
///
/// Чувствительные строки (контрагент, ИНН, наименование услуги, реквизиты
/// исполнителя) шифруются на уровне поля алгоритмом AES-256 — как данные
/// клиентов в транзакциях и заполненные поля черновиков договоров.
class IsarDocumentRepository implements DocumentRepository {
  final Isar isar;
  final FieldEncryptionService _encryptionService;

  IsarDocumentRepository(this.isar, {FieldEncryptionService? encryption})
    : _encryptionService = encryption ?? DatabaseEncryptionService();

  @override
  Future<int> save(Document document) {
    return isar.writeTxn(() async {
      await _encryptFields(document);
      return isar.documents.put(document);
    });
  }

  @override
  Future<Document?> getById(int id) async {
    final document = await isar.documents.where().idEqualTo(id).findFirst();
    if (document != null) {
      await _decryptFields(document);
    }
    return document;
  }

  @override
  Future<List<Document>> getAll() async {
    final documents = await isar.documents.where().sortByDateDesc().findAll();
    for (final document in documents) {
      await _decryptFields(document);
    }
    return documents;
  }

  @override
  Future<List<Document>> getByType(DocumentType type) async {
    final documents = await isar.documents
        .filter()
        .typeEqualTo(type)
        .sortByDateDesc()
        .findAll();
    for (final document in documents) {
      await _decryptFields(document);
    }
    return documents;
  }

  @override
  Future<List<Document>> getByContractDraftId(int contractDraftId) async {
    final documents = await isar.documents
        .filter()
        .contractDraftIdEqualTo(contractDraftId)
        .sortByDateDesc()
        .findAll();
    for (final document in documents) {
      await _decryptFields(document);
    }
    return documents;
  }

  @override
  Future<List<Document>> getByTransactionId(int transactionId) async {
    final documents = await isar.documents
        .filter()
        .transactionIdEqualTo(transactionId)
        .sortByDateDesc()
        .findAll();
    for (final document in documents) {
      await _decryptFields(document);
    }
    return documents;
  }

  @override
  Future<List<Document>> getByReceiptDocumentId(int receiptDocumentId) async {
    final documents = await isar.documents
        .filter()
        .receiptDocumentIdEqualTo(receiptDocumentId)
        .sortByDateDesc()
        .findAll();
    for (final document in documents) {
      await _decryptFields(document);
    }
    return documents;
  }

  @override
  Future<int> count() {
    return isar.documents.where().count();
  }

  @override
  Future<void> delete(int id) {
    return isar.writeTxn(() => isar.documents.delete(id));
  }

  @override
  Future<void> clear() {
    return isar.writeTxn(() => isar.documents.clear());
  }

  Future<void> _encryptFields(Document document) async {
    document.counterpartyName = await _encrypt(document.counterpartyName);
    document.counterpartyInn = await _encrypt(document.counterpartyInn);
    document.content = await _encrypt(document.content);
    document.serviceName = await _encrypt(document.serviceName);
    document.result = await _encrypt(document.result);
    document.executorSignatory = await _encrypt(document.executorSignatory);
    document.customerSignatory = await _encrypt(document.customerSignatory);
    document.issuerName = await _encrypt(document.issuerName);
    document.issuerInn = await _encrypt(document.issuerInn);
  }

  Future<void> _decryptFields(Document document) async {
    document.counterpartyName = await _decrypt(document.counterpartyName);
    document.counterpartyInn = await _decrypt(document.counterpartyInn);
    document.content = await _decrypt(document.content);
    document.serviceName = await _decrypt(document.serviceName);
    document.result = await _decrypt(document.result);
    document.executorSignatory = await _decrypt(document.executorSignatory);
    document.customerSignatory = await _decrypt(document.customerSignatory);
    document.issuerName = await _decrypt(document.issuerName);
    document.issuerInn = await _decrypt(document.issuerInn);
  }

  Future<String> _encrypt(String value) async {
    if (value.isEmpty) return value;
    return _encryptionService.encrypt(value);
  }

  Future<String> _decrypt(String value) async {
    if (value.isEmpty) return value;
    try {
      return await _encryptionService.decrypt(value);
    } catch (_) {
      // Если расшифровка не удалась, оставляем значение как есть:
      // так читаются данные, сохранённые до включения шифрования.
      return value;
    }
  }
}
