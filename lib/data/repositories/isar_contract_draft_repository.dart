import 'package:isar/isar.dart';

import '../models/contract_draft.dart';
import '../security/database_encryption_service.dart';
import '../security/field_encryption_service.dart';
import 'contract_draft_repository.dart';

class IsarContractDraftRepository implements ContractDraftRepository {
  final Isar isar;
  final FieldEncryptionService _encryptionService;

  IsarContractDraftRepository(this.isar, {FieldEncryptionService? encryption})
    : _encryptionService = encryption ?? DatabaseEncryptionService();

  @override
  Future<int> save(ContractDraft draft) {
    return isar.writeTxn(() async {
      await _encryptFields(draft);
      return isar.contractDrafts.put(draft);
    });
  }

  @override
  Future<ContractDraft?> getById(int id) async {
    final draft = await isar.contractDrafts.where().idEqualTo(id).findFirst();
    if (draft != null) {
      await _decryptFields(draft);
    }
    return draft;
  }

  @override
  Future<List<ContractDraft>> getAll() async {
    final drafts = await isar.contractDrafts
        .where()
        .sortByCreatedAtDesc()
        .findAll();
    for (final draft in drafts) {
      await _decryptFields(draft);
    }
    return drafts;
  }

  @override
  Future<List<ContractDraft>> getPage({
    int offset = 0,
    int limit = ContractDraftRepository.defaultPageSize,
    ContractStatus? status,
  }) async {
    final builder = status == null
        ? isar.contractDrafts.where().sortByCreatedAtDesc()
        : isar.contractDrafts
              .filter()
              .statusEqualTo(status)
              .sortByCreatedAtDesc();
    final drafts = await builder.offset(offset).limit(limit).findAll();
    for (final draft in drafts) {
      await _decryptFields(draft);
    }
    return drafts;
  }

  @override
  Future<List<ContractDraft>> getByStatus(ContractStatus status) async {
    final drafts = await isar.contractDrafts
        .filter()
        .statusEqualTo(status)
        .sortByCreatedAtDesc()
        .findAll();
    for (final draft in drafts) {
      await _decryptFields(draft);
    }
    return drafts;
  }

  @override
  Future<List<ContractDraft>> getByTemplateId(String templateId) async {
    final drafts = await isar.contractDrafts
        .where()
        .templateIdEqualTo(templateId)
        .sortByCreatedAtDesc()
        .findAll();
    for (final draft in drafts) {
      await _decryptFields(draft);
    }
    return drafts;
  }

  @override
  Future<int> count() {
    return isar.contractDrafts.where().count();
  }

  @override
  Future<void> delete(int id) {
    return isar.writeTxn(() => isar.contractDrafts.delete(id));
  }

  @override
  Future<void> clear() {
    return isar.writeTxn(() => isar.contractDrafts.clear());
  }

  /// Шифрует значения заполненных полей перед записью в БД.
  ///
  /// Черновики договоров содержат персональные данные (ИНН, банковские
  /// реквизиты), поэтому шифруются на уровне поля — как и данные клиентов
  /// в транзакциях дашборда.
  Future<void> _encryptFields(ContractDraft draft) async {
    for (final field in draft.filledFields) {
      if (field.value.isEmpty) continue;
      field.value = await _encryptionService.encrypt(field.value);
    }
  }

  /// Расшифровывает заполненные поля при чтении.
  Future<void> _decryptFields(ContractDraft draft) async {
    for (final field in draft.filledFields) {
      if (field.value.isEmpty) continue;
      try {
        field.value = await _encryptionService.decrypt(field.value);
      } catch (_) {
        // Если расшифровка не удалась, оставляем значение как есть.
        // Это возможно при чтении данных, сохранённых до включения шифрования.
      }
    }
  }
}
