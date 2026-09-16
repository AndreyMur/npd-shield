import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:npd_shield/data/models/client.dart';
import 'package:npd_shield/data/repositories/isar_client_repository.dart';
import 'package:npd_shield/data/security/field_encryption_service.dart';
import 'package:npd_shield/domain/documents/my_tax_deep_link.dart';

/// Детерминированное шифрование для проверки, что данные шифруются при
/// хранении и расшифровываются при чтении.
class _PrefixEncryption implements FieldEncryptionService {
  const _PrefixEncryption();

  @override
  Future<String> encrypt(String plainText) async => 'enc:$plainText';

  @override
  Future<String> decrypt(String encryptedText) async => encryptedText.startsWith('enc:')
      ? encryptedText.substring(4)
      : encryptedText;
}

void main() {
  late Isar isar;
  late IsarClientRepository repository;

  setUp(() async {
    final dir = await Directory.systemTemp.createTemp('npd_client_test');
    isar = await Isar.open(
      [ClientSchema],
      directory: dir.path,
      name: 'test_${dir.path.hashCode}',
    );
    repository = IsarClientRepository(
      isar,
      encryption: const _PrefixEncryption(),
    );
  });

  tearDown(() async {
    await isar.close(deleteFromDisk: true);
  });

  Client client({
    String name = 'ООО Ромашка',
    String inn = '7701234567',
    ClientType type = ClientType.legal,
    String contacts = '+7 900 000-00-00',
    String notes = '',
  }) {
    return Client(
      name: name,
      inn: inn,
      type: type,
      contacts: contacts,
      notes: notes,
    );
  }

  group('CRUD', () {
    test('add returns id and getById retrieves the client', () async {
      final id = await repository.add(client(name: 'ИП Петров'));

      final loaded = await repository.getById(id);

      expect(loaded, isNotNull);
      expect(loaded!.name, 'ИП Петров');
      expect(loaded.inn, '7701234567');
      expect(loaded.type, ClientType.legal);
      expect(loaded.contacts, '+7 900 000-00-00');
    });

    test('getById returns null for unknown id', () async {
      expect(await repository.getById(999), isNull);
    });

    test('update persists changed fields', () async {
      final id = await repository.add(client(name: 'ООО Ромашка'));

      final loaded = await repository.getById(id);
      loaded!.name = 'ООО Лютик';
      loaded.contacts = 'info@lyutik.ru';
      loaded.notes = 'Постоянный клиент';
      loaded.type = ClientType.individual;
      await repository.update(loaded);

      final updated = await repository.getById(id);
      expect(updated!.name, 'ООО Лютик');
      expect(updated.contacts, 'info@lyutik.ru');
      expect(updated.notes, 'Постоянный клиент');
      expect(updated.type, ClientType.individual);
    });

    test('delete removes the client and reports success', () async {
      final id = await repository.add(client());

      final deleted = await repository.delete(id);

      expect(deleted, isTrue);
      expect(await repository.getById(id), isNull);
      expect(await repository.getAll(), isEmpty);
    });

    test('delete reports false for unknown id', () async {
      expect(await repository.delete(123), isFalse);
    });

    test('count returns the number of clients', () async {
      await repository.add(client(name: 'А'));
      await repository.add(client(name: 'Б'));

      expect(await repository.count(), 2);
    });

    test('clear removes every client', () async {
      await repository.add(client(name: 'А'));
      await repository.add(client(name: 'Б'));

      await repository.clear();

      expect(await repository.count(), 0);
      expect(await repository.getAll(), isEmpty);
    });
  });

  group('search', () {
    setUp(() async {
      await repository.add(
        client(name: 'ООО Ромашка', inn: '7701234567'),
      );
      await repository.add(
        client(
          name: 'ИП Петров',
          inn: '500100200300',
          type: ClientType.individual,
        ),
      );
      await repository.add(
        client(name: 'ООО Ромашка-Строй', inn: '7809876543'),
      );
    });

    test('getAll returns clients sorted by name', () async {
      final all = await repository.getAll();

      expect(all, hasLength(3));
      expect(all.map((c) => c.name).toList(), [
        'ИП Петров',
        'ООО Ромашка',
        'ООО Ромашка-Строй',
      ]);
    });

    test('searches by partial name without case sensitivity', () async {
      final result = await repository.getAll(search: 'ромашка');

      expect(result, hasLength(2));
      expect(result.every((c) => c.name.contains('Ромашка')), isTrue);
    });

    test('searches by partial INN', () async {
      final result = await repository.getAll(search: '500100');

      expect(result, hasLength(1));
      expect(result.single.name, 'ИП Петров');
    });

    test('returns empty list when nothing matches', () async {
      expect(await repository.getAll(search: 'неизвестно'), isEmpty);
    });

    test('blank search returns every client', () async {
      expect(await repository.getAll(search: '   '), hasLength(3));
    });
  });

  group('encryption at rest', () {
    test('stores encrypted values and decrypts on read', () async {
      final id = await repository.add(
        client(
          name: 'ООО Ромашка',
          inn: '7701234567',
          contacts: 'info@romashka.ru',
          notes: 'VIP',
        ),
      );

      final raw = await isar.clients.get(id);
      expect(raw!.name, 'enc:ООО Ромашка');
      expect(raw.inn, 'enc:7701234567');
      expect(raw.contacts, 'enc:info@romashka.ru');
      expect(raw.notes, 'enc:VIP');

      final loaded = await repository.getById(id);
      expect(loaded!.name, 'ООО Ромашка');
      expect(loaded.inn, '7701234567');
      expect(loaded.contacts, 'info@romashka.ru');
      expect(loaded.notes, 'VIP');
    });

    test('keeps empty strings empty', () async {
      final id = await repository.add(client(notes: ''));

      final raw = await isar.clients.get(id);
      expect(raw!.notes, isEmpty);
    });
  });
}
