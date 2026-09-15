import '../../domain/profile/contractor_profile.dart';

/// Репозиторий профиля исполнителя.
abstract class ContractorProfileRepository {
  /// Возвращает сохранённый профиль или `null`, если он ещё не заполнен.
  Future<ContractorProfile?> load();

  /// Сохраняет профиль исполнителя.
  Future<void> save(ContractorProfile profile);

  /// Удаляет профиль.
  Future<void> clear();
}
