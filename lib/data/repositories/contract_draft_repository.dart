import '../models/contract_draft.dart';

/// Репозиторий черновиков договоров.
abstract class ContractDraftRepository {
  /// Размер страницы по умолчанию для постраничной загрузки архива.
  ///
  /// Архив подгружает договоры порциями, чтобы не держать в памяти и не
  /// верстать весь список при большом количестве записей.
  static const int defaultPageSize = 20;

  /// Сохраняет (вставляет или обновляет) черновик и возвращает его `id`.
  Future<int> save(ContractDraft draft);

  /// Возвращает черновик по идентификатору или `null`.
  Future<ContractDraft?> getById(int id);

  /// Возвращает черновики, самые новые — первыми.
  Future<List<ContractDraft>> getAll();

  /// Возвращает страницу черновиков, самые новые — первыми.
  ///
  /// [offset] — сколько записей пропустить, [limit] — размер страницы.
  /// [status] — необязательный фильтр по статусу (на уровне БД).
  Future<List<ContractDraft>> getPage({
    int offset = 0,
    int limit = defaultPageSize,
    ContractStatus? status,
  });

  /// Возвращает договоры с указанным статусом, самые новые — первыми.
  Future<List<ContractDraft>> getByStatus(ContractStatus status);

  /// Возвращает договоры по коду шаблона, самые новые — первыми.
  Future<List<ContractDraft>> getByTemplateId(String templateId);

  /// Количество сохранённых черновиков.
  Future<int> count();

  /// Удаляет черновик по идентификатору.
  Future<void> delete(int id);

  /// Удаляет все черновики (используется в тестах).
  Future<void> clear();
}
