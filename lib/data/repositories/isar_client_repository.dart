import 'package:isar/isar.dart';

import '../models/client.dart';
import '../security/database_encryption_service.dart';
import '../security/field_encryption_service.dart';
import 'client_repository.dart';

/// Реализация справочника клиентов поверх Isar с шифрованием персональных
/// данных.
///
/// Чувствительные строки (наименование, ИНН, контакты, заметки) шифруются на
/// уровне поля алгоритмом AES-256 — как данные контрагентов в операциях и
/// документах. Поэтому коллекция не индексируется по этим полям, а поиск и
/// сортировка выполняются в памяти после расшифровки.
class IsarClientRepository implements ClientRepository {
  final Isar isar;
  final FieldEncryptionService _encryptionService;

  IsarClientRepository(this.isar, {FieldEncryptionService? encryption})
    : _encryptionService = encryption ?? DatabaseEncryptionService();

  @override
  Future<int> add(Client client) {
    return isar.writeTxn(() async {
      await _encryptFields(client);
      return isar.clients.put(client);
    });
  }

  @override
  Future<int> update(Client client) {
    return isar.writeTxn(() async {
      await _encryptFields(client);
      return isar.clients.put(client);
    });
  }

  @override
  Future<Client?> getById(int id) async {
    final client = await isar.clients.get(id);
    if (client != null) {
      await _decryptFields(client);
    }
    return client;
  }

  @override
  Future<bool> delete(int id) {
    return isar.writeTxn(() => isar.clients.delete(id));
  }

  @override
  Future<int> count() {
    return isar.clients.count();
  }

  @override
  Future<List<Client>> getAll({String? search}) async {
    final clients = await isar.clients.where().findAll();
    for (final client in clients) {
      await _decryptFields(client);
    }

    final query = search?.trim().toLowerCase();
    final filtered = (query == null || query.isEmpty)
        ? clients
        : clients
              .where(
                (client) =>
                    client.name.toLowerCase().contains(query) ||
                    client.inn.toLowerCase().contains(query),
              )
              .toList();

    filtered.sort(
      (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    );
    return filtered;
  }

  @override
  Future<void> clear() {
    return isar.writeTxn(() => isar.clients.clear());
  }

  Future<void> _encryptFields(Client client) async {
    client.name = await _encrypt(client.name);
    client.inn = await _encrypt(client.inn);
    client.contacts = await _encrypt(client.contacts);
    client.notes = await _encrypt(client.notes);
  }

  Future<void> _decryptFields(Client client) async {
    client.name = await _decrypt(client.name);
    client.inn = await _decrypt(client.inn);
    client.contacts = await _decrypt(client.contacts);
    client.notes = await _decrypt(client.notes);
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
