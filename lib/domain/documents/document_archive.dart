import '../../core/constants/contract_field_keys.dart';
import '../../data/models/document.dart';
import 'receipt.dart';

/// Поле сортировки архива документов.
enum DocumentSortField {
  /// По дате документа.
  date,

  /// По сумме документа.
  amount,

  /// По типу документа (чеки → акты → договоры).
  type;

  /// Человекочитаемая метка поля для интерфейса.
  String get label => switch (this) {
    DocumentSortField.date => 'По дате',
    DocumentSortField.amount => 'По сумме',
    DocumentSortField.type => 'По типу',
  };
}

/// Направление сортировки архива.
enum SortDirection {
  /// По возрастанию.
  ascending,

  /// По убыванию.
  descending;

  /// Человекочитаемая метка направления для интерфейса.
  String get label => switch (this) {
    SortDirection.ascending => 'возр.',
    SortDirection.descending => 'убыв.',
  };
}

/// Текущая сортировка архива: поле и направление.
class DocumentSort {
  final DocumentSortField field;
  final SortDirection direction;

  const DocumentSort({
    this.field = DocumentSortField.date,
    this.direction = SortDirection.descending,
  });

  /// Метка сортировки для интерфейса, например «По дате · убыв.».
  String get label => '${field.label} · ${direction.label}';

  DocumentSort copyWith({DocumentSortField? field, SortDirection? direction}) {
    return DocumentSort(
      field: field ?? this.field,
      direction: direction ?? this.direction,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is DocumentSort &&
      other.field == field &&
      other.direction == direction;

  @override
  int get hashCode => Object.hash(field, direction);
}

/// Фильтр архива документов: поисковый запрос, тип и статус.
///
/// `null` в [type] и [status] означает «без фильтра». Пустой [query] также
/// не ограничивает выборку.
class DocumentArchiveFilter {
  final String query;
  final DocumentType? type;
  final DocumentStatus? status;

  const DocumentArchiveFilter({
    this.query = '',
    this.type,
    this.status,
  });

  /// Не задан ли ни один из фильтров.
  bool get isEmpty => query.trim().isEmpty && type == null && status == null;

  /// Копия фильтра с изменёнными полями.
  ///
  /// Флаги [clearType] и [clearStatus] позволяют снять фильтр, потому что
  /// `null` в параметре означает «оставить как есть».
  DocumentArchiveFilter copyWith({
    String? query,
    DocumentType? type,
    DocumentStatus? status,
    bool clearType = false,
    bool clearStatus = false,
  }) {
    return DocumentArchiveFilter(
      query: query ?? this.query,
      type: clearType ? null : (type ?? this.type),
      status: clearStatus ? null : (status ?? this.status),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is DocumentArchiveFilter &&
      other.query == query &&
      other.type == type &&
      other.status == status;

  @override
  int get hashCode => Object.hash(query, type, status);
}

/// Проверяет, соответствует ли документ поисковому запросу.
///
/// Поиск идёт по контрагенту и его ИНН, наименованию услуги, результату
/// работ, номеру договора, типу и статусу, сумме и дате. Регистр не
/// учитывается, форматирование суммы и даты распознаётся.
bool matchesDocumentQuery(Document document, String query) {
  final normalized = query.trim().toLowerCase();
  if (normalized.isEmpty) return true;

  final haystack = <String>[
    document.counterpartyName,
    document.counterpartyInn,
    document.serviceName,
    document.result,
    document.contractNumber,
    document.type.label,
    document.status.label,
    formatReceiptAmount(document.amount),
    document.amount.toStringAsFixed(2),
    document.amount.toString(),
    formatContractDate(document.date),
  ].join(' ').toLowerCase();

  return haystack.contains(normalized);
}

/// Фильтрует документы по запросу, типу и статусу.
List<Document> filterDocuments({
  required List<Document> documents,
  required DocumentArchiveFilter filter,
}) {
  return documents.where((document) {
    if (filter.type != null && document.type != filter.type) return false;
    if (filter.status != null && document.status != filter.status) return false;
    return matchesDocumentQuery(document, filter.query);
  }).toList(growable: false);
}

/// Сортирует документы согласно [sort], не изменяя исходный список.
///
/// При равных значениях сортировки документы упорядочиваются от новых
/// к старым, чтобы порядок был предсказуемым.
List<Document> sortDocuments({
  required List<Document> documents,
  required DocumentSort sort,
}) {
  final result = List<Document>.of(documents);
  result.sort((a, b) {
    final comparison = switch (sort.field) {
      DocumentSortField.date => a.date.compareTo(b.date),
      DocumentSortField.amount => a.amount.compareTo(b.amount),
      DocumentSortField.type => _compareByType(a, b),
    };
    if (comparison != 0) {
      return sort.direction == SortDirection.ascending
          ? comparison
          : -comparison;
    }
    return b.date.compareTo(a.date);
  });
  return result;
}

/// Применяет фильтр и сортировку к архиву документов.
List<Document> applyDocumentArchive({
  required List<Document> documents,
  DocumentArchiveFilter filter = const DocumentArchiveFilter(),
  DocumentSort sort = const DocumentSort(),
}) {
  final filtered = filterDocuments(documents: documents, filter: filter);
  return sortDocuments(documents: filtered, sort: sort);
}

/// Группа документов одного контрагента.
class DocumentGroup {
  /// Наименование контрагента (или «Без контрагента»).
  final String counterpartyName;

  /// Документы группы в порядке сортировки.
  final List<Document> documents;

  const DocumentGroup({
    required this.counterpartyName,
    required this.documents,
  });
}

/// Наименование контрагента для группировки; пустое имя заменяется заглушкой.
String documentCounterpartyLabel(Document document) {
  final name = document.counterpartyName.trim();
  return name.isEmpty ? 'Без контрагента' : name;
}

/// Группирует документы по контрагенту, сохраняя порядок внутри групп.
///
/// Сами группы упорядочены по алфавиту (регистр не учитывается), чтобы
/// список был стабильным независимо от текущей сортировки документов.
List<DocumentGroup> groupDocumentsByCounterparty(List<Document> documents) {
  final grouped = <String, List<Document>>{};
  for (final document in documents) {
    grouped
        .putIfAbsent(documentCounterpartyLabel(document), () => <Document>[])
        .add(document);
  }
  final labels = grouped.keys.toList()
    ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
  return [
    for (final label in labels)
      DocumentGroup(counterpartyName: label, documents: grouped[label]!),
  ];
}

/// Подсказки для поиска с автодополнением: контрагенты, суммы и даты.
///
/// Возвращает не более [limit] уникальных значений, содержащих [query].
/// Сначала предлагаются контрагенты, затем суммы и даты.
List<String> documentSearchSuggestions({
  required List<Document> documents,
  required String query,
  int limit = 6,
}) {
  final normalized = query.trim().toLowerCase();
  if (normalized.isEmpty) return const [];

  final seen = <String>{};
  final suggestions = <String>[];

  void add(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return;
    if (!trimmed.toLowerCase().contains(normalized)) return;
    if (seen.add(trimmed)) suggestions.add(trimmed);
  }

  for (final document in documents) {
    add(document.counterpartyName);
  }
  for (final document in documents) {
    add(formatReceiptAmount(document.amount));
    add(formatContractDate(document.date));
  }

  return suggestions.take(limit).toList(growable: false);
}

int _compareByType(Document a, Document b) {
  final byIndex = a.type.index.compareTo(b.type.index);
  if (byIndex != 0) return byIndex;
  return a.date.compareTo(b.date);
}
