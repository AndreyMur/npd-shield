import '../models/contract_draft.dart';

/// Репозиторий черновиков договоров.
abstract class ContractDraftRepository {
  /// Сохраняет (вставляет или обновляет) черновик и возвращает его `id`.
  Future<int> save(ContractDraft draft);

  /// Возвращает черновик по идентификатору или `null`.
  Future<ContractDraft?> getById(int id);

  /// Возвращает черновики, самые новые — первыми.
  Future<List<ContractDraft>> getAll();

  /// Количество сохранённых черновиков.
  Future<int> count();

  /// Удаляет черновик по идентификатору.
  Future<void> delete(int id);

  /// Удаляет все черновики (используется в тестах).
  Future<void> clear();
}
