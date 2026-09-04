import 'package:isar/isar.dart';

import '../models/contract_template.dart';
import 'contract_template_repository.dart';

class IsarContractTemplateRepository implements ContractTemplateRepository {
  final Isar isar;

  IsarContractTemplateRepository(this.isar);

  @override
  Future<List<Template>> getAll() async {
    final templates = await isar.templates.where().findAll();
    templates.sort(_compareBySphereThenTitle);
    return templates;
  }

  @override
  Future<List<Template>> getBySphere(TemplateSphere sphere) async {
    final templates = await isar.templates
        .where()
        .sphereEqualTo(sphere)
        .findAll();
    templates.sort((a, b) => a.title.compareTo(b.title));
    return templates;
  }

  @override
  Future<Template?> getByCode(String code) {
    return isar.templates.where().codeEqualTo(code).findFirst();
  }

  @override
  Future<void> put(Template template) {
    return isar.writeTxn(() => isar.templates.put(template));
  }

  @override
  Future<void> clear() {
    return isar.writeTxn(() => isar.templates.clear());
  }

  static int _compareBySphereThenTitle(Template a, Template b) {
    final bySphere = a.sphere.index.compareTo(b.sphere.index);
    return bySphere != 0 ? bySphere : a.title.compareTo(b.title);
  }
}
