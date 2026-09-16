import 'package:npd_shield/data/models/client.dart';
import 'package:npd_shield/data/repositories/client_repository.dart';

class FakeClientRepository implements ClientRepository {
  final List<Client> clients;
  int _nextId = 1;

  FakeClientRepository([List<Client>? clients]) : clients = clients ?? [] {
    for (final client in this.clients) {
      if (client.id >= _nextId) _nextId = client.id + 1;
    }
  }

  @override
  Future<int> add(Client client) async {
    if (client.id <= 0) {
      client.id = _nextId++;
    } else if (client.id >= _nextId) {
      _nextId = client.id + 1;
    }
    clients.add(client);
    return client.id;
  }

  @override
  Future<int> update(Client client) async {
    final index = clients.indexWhere((c) => c.id == client.id);
    if (index >= 0) {
      clients[index] = client;
    } else {
      clients.add(client);
    }
    return client.id;
  }

  @override
  Future<Client?> getById(int id) async {
    for (final client in clients) {
      if (client.id == id) return client;
    }
    return null;
  }

  @override
  Future<bool> delete(int id) async {
    final index = clients.indexWhere((c) => c.id == id);
    if (index < 0) return false;
    clients.removeAt(index);
    return true;
  }

  @override
  Future<int> count() async => clients.length;

  @override
  Future<List<Client>> getAll({String? search}) async {
    final query = search?.trim().toLowerCase();
    final filtered = (query == null || query.isEmpty)
        ? List.of(clients)
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
  Future<void> clear() async => clients.clear();
}
