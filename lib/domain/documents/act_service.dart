import '../../data/models/document.dart';
import '../../data/repositories/document_repository.dart';
import 'act.dart';

/// Результат сохранения акта: доменная модель и запись в архиве.
class SavedAct {
  final Act act;
  final Document document;

  const SavedAct({required this.act, required this.document});
}

/// Сохранение акта выполненных работ в архив документов.
///
/// Отделяет бизнес-логику от интерфейса: акт преобразуется в запись архива
/// и сохраняется с нужным статусом. При повторном сохранении с тем же
/// [documentId] запись обновляется — это основа автосохранения при создании
/// документа.
class ActService {
  const ActService();

  /// Сохраняет акт в архив.
  ///
  /// [documentId] — идентификатор ранее сохранённого черновика акта; `0`
  /// создаёт новую запись. [status] позволяет пометить акт черновиком
  /// (автосохранение) или сформированным документом.
  Future<SavedAct> save({
    required Act act,
    required DocumentRepository documentRepository,
    int documentId = 0,
    DocumentStatus status = DocumentStatus.draft,
  }) async {
    final document = act.toDocument(status: status);
    if (documentId != 0) {
      document.id = documentId;
    }
    document.id = await documentRepository.save(document);
    return SavedAct(act: act, document: document);
  }
}
