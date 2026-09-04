import 'package:isar/isar.dart';

import '../models/contract_draft.dart';
import 'contract_draft_repository.dart';

class IsarContractDraftRepository implements ContractDraftRepository {
  final Isar isar;

  IsarContractDraftRepository(this.isar);

  @override
  Future<int> save(ContractDraft draft) {
    return isar.writeTxn(() => isar.contractDrafts.put(draft));
  }

  @override
  Future<ContractDraft?> getById(int id) {
    return isar.contractDrafts.where().idEqualTo(id).findFirst();
  }

  @override
  Future<List<ContractDraft>> getAll() {
    return isar.contractDrafts.where().sortByCreatedAtDesc().findAll();
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
}
