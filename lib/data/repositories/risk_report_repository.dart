import '../models/risk_marker.dart';

/// Репозиторий результатов проверок договоров.
abstract class RiskReportRepository {
  /// Сохраняет отчёт и возвращает его `id`.
  Future<int> save(RiskReport report);

  /// Возвращает отчёт по идентификатору или `null`.
  Future<RiskReport?> getById(int id);

  /// Возвращает все отчёты, самые новые — первыми.
  Future<List<RiskReport>> getAll();

  /// Удаляет отчёт по идентификатору.
  Future<void> delete(int id);

  /// Удаляет все отчёты (используется в тестах).
  Future<void> clear();
}
