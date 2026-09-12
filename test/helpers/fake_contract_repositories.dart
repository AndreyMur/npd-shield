import 'package:npd_shield/data/models/contract_draft.dart';
import 'package:npd_shield/data/models/contract_template.dart';
import 'package:npd_shield/data/repositories/contract_draft_repository.dart';
import 'package:npd_shield/data/repositories/contract_template_repository.dart';
import 'package:npd_shield/data/repositories/contractor_profile_repository.dart';
import 'package:npd_shield/domain/profile/contractor_profile.dart';

Template template({
  String code = 'it_software_development',
  TemplateSphere sphere = TemplateSphere.it,
  String title = 'Разработка программного обеспечения',
  String description = 'Описание шаблона',
}) {
  return Template(
    code: code,
    sphere: sphere,
    title: title,
    description: description,
  );
}

/// Фейковый репозиторий шаблонов для widget-тестов.
class FakeContractTemplateRepository implements ContractTemplateRepository {
  final List<Template> templates;

  FakeContractTemplateRepository([List<Template>? initial])
    : templates = initial ?? [];

  @override
  Future<List<Template>> getAll() async {
    final result = List.of(templates);
    result.sort(
      (a, b) => a.sphere.index != b.sphere.index
          ? a.sphere.index.compareTo(b.sphere.index)
          : a.title.compareTo(b.title),
    );
    return result;
  }

  @override
  Future<List<Template>> getBySphere(TemplateSphere sphere) async {
    return templates.where((t) => t.sphere == sphere).toList();
  }

  @override
  Future<Template?> getByCode(String code) async {
    for (final t in templates) {
      if (t.code == code) return t;
    }
    return null;
  }

  @override
  Future<void> put(Template value) async {
    final index = templates.indexWhere((t) => t.code == value.code);
    if (index >= 0) {
      templates[index] = value;
    } else {
      templates.add(value);
    }
  }

  @override
  Future<void> clear() async => templates.clear();
}

/// Фейковый репозиторий черновиков для widget-тестов.
class FakeContractDraftRepository implements ContractDraftRepository {
  final List<ContractDraft> drafts;
  final bool failOnSave;
  int _nextId = 1;

  FakeContractDraftRepository([
    List<ContractDraft>? initial,
    this.failOnSave = false,
  ]) : drafts = initial ?? [];

  factory FakeContractDraftRepository.failing() =>
      FakeContractDraftRepository(null, true);

  @override
  Future<int> save(ContractDraft draft) async {
    if (failOnSave) {
      throw Exception('save failed');
    }
    final index = drafts.indexWhere((d) => d.id == draft.id && draft.id != 0);
    if (index >= 0) {
      drafts[index] = draft;
      return draft.id;
    }
    draft.id = _nextId++;
    drafts.add(draft);
    return draft.id;
  }

  @override
  Future<ContractDraft?> getById(int id) async {
    for (final d in drafts) {
      if (d.id == id) return d;
    }
    return null;
  }

  @override
  Future<List<ContractDraft>> getAll() async {
    final result = List.of(drafts);
    result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return result;
  }

  @override
  Future<List<ContractDraft>> getByStatus(ContractStatus status) async {
    final result = drafts.where((d) => d.status == status).toList();
    result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return result;
  }

  @override
  Future<List<ContractDraft>> getByTemplateId(String templateId) async {
    final result = drafts.where((d) => d.templateId == templateId).toList();
    result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return result;
  }

  @override
  Future<int> count() async => drafts.length;

  @override
  Future<void> delete(int id) async {
    drafts.removeWhere((d) => d.id == id);
  }

  @override
  Future<void> clear() async => drafts.clear();
}

/// Фейковый репозиторий профиля для widget-тестов.
class FakeContractorProfileRepository implements ContractorProfileRepository {
  ContractorProfile? profile;

  FakeContractorProfileRepository([this.profile]);

  @override
  Future<ContractorProfile?> load() async => profile;

  @override
  Future<void> save(ContractorProfile value) async => profile = value;

  @override
  Future<void> clear() async => profile = null;

  @override
  Future<void> seedDemoIfEmpty() async {
    profile ??= ContractorProfile.demo;
  }
}
