import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:npd_shield/data/models/contract_draft.dart';
import 'package:npd_shield/data/models/contract_template.dart';
import 'package:npd_shield/data/repositories/isar_contract_draft_repository.dart';
import 'package:npd_shield/data/security/field_encryption_service.dart';

void main() {
  late Isar isar;
  late IsarContractDraftRepository repository;

  setUp(() async {
    final dir = await Directory.systemTemp.createTemp('npd_draft_test');
    isar = await Isar.open(
      [ContractDraftSchema, TemplateSchema],
      directory: dir.path,
      name: 'draft_test_${dir.path.hashCode}',
    );
    repository = IsarContractDraftRepository(
      isar,
      encryption: const _PassthroughEncryption(),
    );
  });

  tearDown(() async {
    await isar.close(deleteFromDisk: true);
  });

  ContractDraft draft({
    String templateId = 'it_software_development',
    Map<String, String> fields = const {},
    ContractStatus status = ContractStatus.draft,
    DateTime? createdAt,
  }) {
    final result = ContractDraft(
      templateId: templateId,
      filledFields: contractFieldsFromMap(fields),
      status: status,
    );
    result.createdAt = createdAt ?? result.createdAt;
    return result;
  }

  group('IsarContractDraftRepository', () {
    test('save присваивает id и позволяет найти черновик по id', () async {
      final id = await repository.save(draft());

      expect(id, isNot(0));
      final found = await repository.getById(id);
      expect(found, isNotNull);
      expect(found!.templateId, 'it_software_development');
    });

    test('save сохраняет filledFields как карту ключ-значение', () async {
      final id = await repository.save(
        draft(
          fields: {
            'clientName': 'ООО «Ромашка»',
            'clientInn': '7701234567',
            'subject': 'Разработка сайта',
            'amount': '150000',
          },
        ),
      );

      final found = await repository.getById(id);

      expect(contractFieldsToMap(found!.filledFields), {
        'clientName': 'ООО «Ромашка»',
        'clientInn': '7701234567',
        'subject': 'Разработка сайта',
        'amount': '150000',
      });
    });

    test('save сохраняет статус и createdAt', () async {
      final createdAt = DateTime(2026, 9, 1, 10, 30);
      final id = await repository.save(
        draft(status: ContractStatus.signed, createdAt: createdAt),
      );

      final found = await repository.getById(id);

      expect(found!.status, ContractStatus.signed);
      expect(found.createdAt, createdAt);
    });

    test('getAll возвращает черновики от новых к старым', () async {
      final now = DateTime(2026, 9, 4);
      await repository.save(
        draft(
          templateId: 'a',
          createdAt: now.subtract(const Duration(days: 2)),
        ),
      );
      await repository.save(draft(templateId: 'b', createdAt: now));
      await repository.save(
        draft(
          templateId: 'c',
          createdAt: now.subtract(const Duration(days: 1)),
        ),
      );

      final all = await repository.getAll();

      expect(all.map((d) => d.templateId).toList(), ['b', 'c', 'a']);
    });

    test('save обновляет существующий черновик вместо дублирования', () async {
      final id = await repository.save(draft(templateId: 'a'));
      final saved = await repository.getById(id);
      saved!.filledFields = contractFieldsFromMap(const {
        'subject': 'Обновлено',
      });
      await repository.save(saved);

      expect(await repository.count(), 1);
      final updated = await repository.getById(id);
      expect(contractFieldsToMap(updated!.filledFields), {
        'subject': 'Обновлено',
      });
    });

    test('delete и clear удаляют черновики', () async {
      final id1 = await repository.save(draft(templateId: 'a'));
      await repository.save(draft(templateId: 'b'));

      await repository.delete(id1);
      expect(await repository.getById(id1), isNull);
      expect(await repository.count(), 1);

      await repository.clear();
      expect(await repository.count(), 0);
    });
  });

  group('contract field helpers', () {
    test('contractFieldsFromMap и contractFieldsToMap обратимы', () {
      const source = {'contractNumber': '1/9', 'clientName': 'Клиент'};
      final fields = contractFieldsFromMap(source);
      expect(fields, hasLength(2));
      expect(contractFieldsToMap(fields), source);
    });
  });

  group('шифрование полей', () {
    test(
      'filledFields шифруются перед записью и расшифровываются при чтении',
      () async {
        final encryptedRepo = IsarContractDraftRepository(
          isar,
          encryption: const _PrefixEncryption(),
        );
        final id = await encryptedRepo.save(
          draft(fields: {'clientName': 'ООО «Ромашка»', 'amount': '150000'}),
        );

        final raw = await isar.contractDrafts.where().idEqualTo(id).findFirst();
        expect(
          contractFieldsToMap(raw!.filledFields)['clientName'],
          startsWith('enc:'),
        );

        final loaded = await encryptedRepo.getById(id);
        final map = contractFieldsToMap(loaded!.filledFields);
        expect(map['clientName'], 'ООО «Ромашка»');
        expect(map['amount'], '150000');
      },
    );
  });
}

/// Шифрование-заглушка: хранит значение как есть (для тестов механики репозитория).
class _PassthroughEncryption implements FieldEncryptionService {
  const _PassthroughEncryption();

  @override
  Future<String> encrypt(String plainText) async => plainText;

  @override
  Future<String> decrypt(String encryptedText) async => encryptedText;
}

/// Детерминированное шифрование: добавляет префикс `enc:`.
class _PrefixEncryption implements FieldEncryptionService {
  const _PrefixEncryption();

  static const _marker = 'enc:';

  @override
  Future<String> encrypt(String plainText) async => '$_marker$plainText';

  @override
  Future<String> decrypt(String encryptedText) async =>
      encryptedText.startsWith(_marker)
      ? encryptedText.substring(_marker.length)
      : encryptedText;
}
