import '../models/risk_marker.dart';

/// Репозиторий базы маркеров риска.
abstract class RiskMarkerRepository {
  /// Возвращает все маркеры: сначала критические, затем средние и низкие.
  Future<List<RiskMarker>> getAll();

  /// Возвращает маркер по стабильному коду или `null`.
  Future<RiskMarker?> getByCode(String code);

  /// Вставляет новый маркер или обновляет существующий.
  Future<void> put(RiskMarker marker);

  /// Удаляет все маркеры (используется в тестах).
  Future<void> clear();
}
