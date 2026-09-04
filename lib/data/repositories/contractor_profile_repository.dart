import '../../domain/profile/contractor_profile.dart';

/// Репозиторий профиля исполнителя.
abstract class ContractorProfileRepository {
  /// Возвращает сохранённый профиль или `null`, если он ещё не заполнен.
  Future<ContractorProfile?> load();

  /// Сохраняет профиль исполнителя.
  Future<void> save(ContractorProfile profile);

  /// Удаляет профиль.
  Future<void> clear();

  /// Если профиль ещё не сохранён, заполняет его демонстрационными данными.
  ///
  /// Используется на этапе tracer-bullet, пока нет отдельного экрана профиля.
  Future<void> seedDemoIfEmpty();
}
