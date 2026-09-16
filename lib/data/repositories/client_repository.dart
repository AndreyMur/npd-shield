import '../models/client.dart';

/// Хранилище справочника клиентов.
///
/// Поиск выполняется по наименованию и ИНН без учёта регистра: строки
/// зашифрованы при хранении, поэтому фильтрация идёт в памяти после расшифровки.
abstract class ClientRepository {
  Future<int> add(Client client);

  Future<Client?> getById(int id);

  Future<int> update(Client client);

  Future<bool> delete(int id);

  Future<int> count();

  /// Возвращает клиентов, отсортированных по наименованию.
  ///
  /// [search] ищет подстроку (без учёта регистра) по наименованию и ИНН.
  Future<List<Client>> getAll({String? search});

  Future<void> clear();
}
