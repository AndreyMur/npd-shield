import 'package:npd_shield/data/models/document.dart';
import 'package:npd_shield/data/repositories/document_repository.dart';

/// Фейковый репозиторий архива документов для widget- и unit-тестов.
class FakeDocumentRepository implements DocumentRepository {
  final List<Document> documents;
  final bool failOnSave;
  int _nextId = 1;

  FakeDocumentRepository([List<Document>? initial, this.failOnSave = false])
    : documents = initial ?? [];

  factory FakeDocumentRepository.failing() =>
      FakeDocumentRepository(null, true);

  @override
  Future<int> save(Document document) async {
    if (failOnSave) {
      throw Exception('save failed');
    }
    final index = documents.indexWhere(
      (d) => d.id == document.id && document.id != 0,
    );
    if (index >= 0) {
      documents[index] = document;
      return document.id;
    }
    document.id = _nextId++;
    documents.add(document);
    return document.id;
  }

  @override
  Future<Document?> getById(int id) async {
    for (final document in documents) {
      if (document.id == id) return document;
    }
    return null;
  }

  @override
  Future<List<Document>> getAll() async {
    final result = List.of(documents);
    result.sort((a, b) => b.date.compareTo(a.date));
    return result;
  }

  @override
  Future<List<Document>> getByType(DocumentType type) async {
    final result = documents.where((d) => d.type == type).toList();
    result.sort((a, b) => b.date.compareTo(a.date));
    return result;
  }

  @override
  Future<List<Document>> getByContractDraftId(int contractDraftId) async {
    return documents
        .where((d) => d.contractDraftId == contractDraftId)
        .toList();
  }

  @override
  Future<List<Document>> getByTransactionId(int transactionId) async {
    return documents.where((d) => d.transactionId == transactionId).toList();
  }

  @override
  Future<int> count() async => documents.length;

  @override
  Future<void> delete(int id) async {
    documents.removeWhere((d) => d.id == id);
  }

  @override
  Future<void> clear() async => documents.clear();
}
