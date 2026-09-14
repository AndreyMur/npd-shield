import 'package:flutter_test/flutter_test.dart';
import 'package:npd_shield/data/models/document.dart';
import 'package:npd_shield/domain/documents/document_archive.dart';

void main() {
  Document makeDocument({
    int id = 0,
    DocumentType type = DocumentType.receipt,
    DocumentStatus status = DocumentStatus.generated,
    String counterparty = 'ООО «Ромашка»',
    String inn = '7701234567',
    double amount = 150000,
    DateTime? date,
    String contractNumber = '14/09',
    String service = 'Разработка сайта',
    String result = '',
    DateTime? createdAt,
  }) {
    final document = Document(
      type: type,
      status: status,
      amount: amount,
      date: date ?? DateTime(2026, 9, 5),
      contractNumber: contractNumber,
      counterpartyName: counterparty,
      counterpartyInn: inn,
      serviceName: service,
      result: result,
    );
    document.id = id;
    document.createdAt = createdAt ?? DateTime(2026, 9, 5);
    return document;
  }

  group('matchesDocumentQuery', () {
    test('пустой запрос соответствует любому документу', () {
      expect(matchesDocumentQuery(makeDocument(), '   '), isTrue);
    });

    test('находит по наименованию контрагента без учёта регистра', () {
      final document = makeDocument(counterparty: 'ООО «Ромашка»');
      expect(matchesDocumentQuery(document, 'ромашка'), isTrue);
      expect(matchesDocumentQuery(document, 'РОМАШКА'), isTrue);
      expect(matchesDocumentQuery(document, 'Вектор'), isFalse);
    });

    test('находит по сумме как в сыром, так и в форматированном виде', () {
      final document = makeDocument(amount: 150000);
      expect(matchesDocumentQuery(document, '150000'), isTrue);
      expect(matchesDocumentQuery(document, '150 000'), isTrue);
      expect(matchesDocumentQuery(document, '200000'), isFalse);
    });

    test('находит по дате в формате ДД.ММ.ГГГГ', () {
      final document = makeDocument(date: DateTime(2026, 9, 5));
      expect(matchesDocumentQuery(document, '05.09.2026'), isTrue);
      expect(matchesDocumentQuery(document, '06.09.2026'), isFalse);
    });
  });

  group('filterDocuments', () {
    test('фильтрует по типу документа', () {
      final documents = [
        makeDocument(id: 1, type: DocumentType.receipt),
        makeDocument(id: 2, type: DocumentType.act),
        makeDocument(id: 3, type: DocumentType.contract),
      ];

      final receipts = filterDocuments(
        documents: documents,
        filter: const DocumentArchiveFilter(type: DocumentType.receipt),
      );

      expect(receipts.map((d) => d.id), [1]);
    });

    test('фильтрует по статусу документа', () {
      final documents = [
        makeDocument(id: 1, status: DocumentStatus.draft),
        makeDocument(id: 2, status: DocumentStatus.generated),
        makeDocument(id: 3, status: DocumentStatus.sent),
      ];

      final generated = filterDocuments(
        documents: documents,
        filter: const DocumentArchiveFilter(status: DocumentStatus.generated),
      );

      expect(generated.map((d) => d.id), [2]);
    });

    test('комбинирует запрос, тип и статус', () {
      final documents = [
        makeDocument(id: 1, type: DocumentType.receipt),
        makeDocument(
          id: 2,
          type: DocumentType.act,
          status: DocumentStatus.sent,
          counterparty: 'ИП Петров',
        ),
        makeDocument(
          id: 3,
          type: DocumentType.act,
          status: DocumentStatus.generated,
          counterparty: 'ИП Петров',
        ),
      ];

      final result = filterDocuments(
        documents: documents,
        filter: const DocumentArchiveFilter(
          query: 'петров',
          type: DocumentType.act,
          status: DocumentStatus.sent,
        ),
      );

      expect(result.map((d) => d.id), [2]);
    });
  });

  group('sortDocuments', () {
    final older = makeDocument(id: 1, date: DateTime(2026, 9, 1), amount: 100);
    final newer = makeDocument(id: 2, date: DateTime(2026, 9, 10), amount: 300);
    final middle = makeDocument(id: 3, date: DateTime(2026, 9, 5), amount: 200);
    final documents = [older, newer, middle];

    test('сортирует по дате от новых к старым по умолчанию', () {
      final sorted = sortDocuments(
        documents: documents,
        sort: const DocumentSort(),
      );
      expect(sorted.map((d) => d.id), [2, 3, 1]);
    });

    test('сортирует по дате по возрастанию', () {
      final sorted = sortDocuments(
        documents: documents,
        sort: const DocumentSort(direction: SortDirection.ascending),
      );
      expect(sorted.map((d) => d.id), [1, 3, 2]);
    });

    test('сортирует по сумме по убыванию и возрастанию', () {
      final descending = sortDocuments(
        documents: documents,
        sort: const DocumentSort(
          field: DocumentSortField.amount,
          direction: SortDirection.descending,
        ),
      );
      expect(descending.map((d) => d.amount), [300, 200, 100]);

      final ascending = sortDocuments(
        documents: documents,
        sort: const DocumentSort(
          field: DocumentSortField.amount,
          direction: SortDirection.ascending,
        ),
      );
      expect(ascending.map((d) => d.amount), [100, 200, 300]);
    });

    test('сортирует по типу документа: чеки, акты, договоры', () {
      final mixed = [
        makeDocument(id: 1, type: DocumentType.contract),
        makeDocument(id: 2, type: DocumentType.receipt),
        makeDocument(id: 3, type: DocumentType.act),
      ];

      final sorted = sortDocuments(
        documents: mixed,
        sort: const DocumentSort(
          field: DocumentSortField.type,
          direction: SortDirection.ascending,
        ),
      );

      expect(sorted.map((d) => d.type), [
        DocumentType.receipt,
        DocumentType.act,
        DocumentType.contract,
      ]);
    });

    test('не изменяет исходный список', () {
      final original = List<Document>.of(documents);
      sortDocuments(
        documents: documents,
        sort: const DocumentSort(
          field: DocumentSortField.amount,
          direction: SortDirection.descending,
        ),
      );
      expect(documents, original);
    });
  });

  group('groupDocumentsByCounterparty', () {
    test('группирует по контрагенту в алфавитном порядке', () {
      final documents = [
        makeDocument(id: 1, counterparty: 'ООО «Вектор»'),
        makeDocument(id: 2, counterparty: 'ИП Петров'),
        makeDocument(id: 3, counterparty: 'ООО «Вектор»'),
      ];

      final groups = groupDocumentsByCounterparty(documents);

      expect(groups.map((g) => g.counterpartyName), [
        'ИП Петров',
        'ООО «Вектор»',
      ]);
      expect(groups.last.documents.map((d) => d.id), [1, 3]);
    });

    test('пустое имя контрагента попадает в группу «Без контрагента»', () {
      final documents = [
        makeDocument(id: 1, counterparty: ''),
        makeDocument(id: 2, counterparty: '  '),
      ];

      final groups = groupDocumentsByCounterparty(documents);

      expect(groups, hasLength(1));
      expect(groups.single.counterpartyName, 'Без контрагента');
      expect(groups.single.documents, hasLength(2));
    });
  });

  group('documentSearchSuggestions', () {
    test('возвращает подсказки по контрагенту, сумме и дате', () {
      final documents = [
        makeDocument(
          id: 1,
          counterparty: 'ООО «Ромашка»',
          amount: 150000,
          date: DateTime(2026, 9, 5),
        ),
        makeDocument(
          id: 2,
          counterparty: 'ООО «Ромашка-2»',
          amount: 200000,
          date: DateTime(2026, 9, 6),
        ),
      ];

      expect(
        documentSearchSuggestions(documents: documents, query: 'ромашка'),
        ['ООО «Ромашка»', 'ООО «Ромашка-2»'],
      );
      expect(
        documentSearchSuggestions(documents: documents, query: '150 000'),
        contains('150 000,00 ₽'),
      );
      expect(
        documentSearchSuggestions(documents: documents, query: '06.09.2026'),
        ['06.09.2026'],
      );
    });

    test('ограничивает число подсказок и убирает дубликаты', () {
      final documents = [
        for (var i = 0; i < 20; i++)
          makeDocument(id: i + 1, counterparty: 'ООО «Ромашка»'),
      ];

      final suggestions = documentSearchSuggestions(
        documents: documents,
        query: 'ромашка',
        limit: 3,
      );

      expect(suggestions, ['ООО «Ромашка»']);
    });

    test('пустой запрос не даёт подсказок', () {
      expect(
        documentSearchSuggestions(
          documents: [makeDocument()],
          query: '   ',
        ),
        isEmpty,
      );
    });
  });

  test('поиск и сортировка 1000 документов укладываются в 500 мс', () {
    final documents = [
      for (var i = 0; i < 1000; i++)
        makeDocument(
          id: i + 1,
          type: DocumentType.values[i % DocumentType.values.length],
          status: DocumentStatus.values[i % DocumentStatus.values.length],
          counterparty: 'Контрагент ${i % 50}',
          amount: (i + 1) * 1000.0,
          date: DateTime(2026, 1, 1).add(Duration(days: i % 365)),
          contractNumber: '${i + 1}/2026',
        ),
    ];

    final stopwatch = Stopwatch()..start();
    final visible = applyDocumentArchive(
      documents: documents,
      filter: const DocumentArchiveFilter(query: 'Контрагент 7'),
      sort: const DocumentSort(field: DocumentSortField.amount),
    );
    final groups = groupDocumentsByCounterparty(visible);
    stopwatch.stop();

    expect(visible, isNotEmpty);
    expect(groups, isNotEmpty);
    expect(stopwatch.elapsedMilliseconds, lessThan(500));
  });
}
