import '../../core/constants/contract_field_keys.dart';
import '../../data/models/contract_draft.dart';

/// Проверяет, соответствует ли договор поисковому запросу.
///
/// Поиск идёт по названию шаблона, контрагенту, номеру и дате договора,
/// сумме, предмету и дате создания записи. Регистр не учитывается.
bool matchesContractQuery({
  required ContractDraft draft,
  required String templateTitle,
  required String query,
}) {
  final normalized = query.trim().toLowerCase();
  if (normalized.isEmpty) return true;

  final fields = contractFieldsToMap(draft.filledFields);
  final haystack = <String>[
    templateTitle,
    fields[ContractFieldKeys.clientName] ?? '',
    fields[ContractFieldKeys.clientInn] ?? '',
    fields[ContractFieldKeys.contractNumber] ?? '',
    fields[ContractFieldKeys.contractDate] ?? '',
    fields[ContractFieldKeys.amount] ?? '',
    fields[ContractFieldKeys.subject] ?? '',
    formatContractDate(draft.createdAt),
  ].join(' ').toLowerCase();

  return haystack.contains(normalized);
}

/// Фильтрует [drafts] по запросу [query] и названию шаблона.
List<ContractDraft> filterContractsByQuery({
  required List<ContractDraft> drafts,
  required String Function(ContractDraft draft) titleOf,
  required String query,
}) {
  return drafts
      .where(
        (draft) => matchesContractQuery(
          draft: draft,
          templateTitle: titleOf(draft),
          query: query,
        ),
      )
      .toList(growable: false);
}
