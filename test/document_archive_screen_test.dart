import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:npd_shield/data/models/document.dart';
import 'package:npd_shield/data/pdf/contract_pdf_share_service.dart';
import 'package:npd_shield/data/pdf/generated_pdf.dart';
import 'package:npd_shield/presentation/documents/document_archive_screen.dart';
import 'package:npd_shield/presentation/documents/document_card.dart';

import 'helpers/fake_document_repository.dart';

void main() {
  Document doc({
    required int id,
    DocumentType type = DocumentType.receipt,
    DocumentStatus status = DocumentStatus.generated,
    String counterparty = 'ООО «Ромашка»',
    String inn = '7701234567',
    double amount = 150000,
    DateTime? date,
    String service = 'Разработка сайта',
    String contractNumber = '14/09',
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
    );
    document.id = id;
    document.createdAt = date ?? DateTime(2026, 9, 5);
    return document;
  }

  Future<GeneratedPdf> fakePdf(Document document) async => GeneratedPdf(
    bytes: Uint8List.fromList(const [37, 80, 68, 70]),
    pageCount: 1,
    fileName: 'doc.pdf',
    generationTime: const Duration(milliseconds: 1),
  );

  Future<void> pumpArchive(
    WidgetTester tester,
    FakeDocumentRepository documents, {
    _FakeShareService? share,
  }) async {
    tester.view.physicalSize = const Size(1000, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: DocumentArchiveScreen(
          documentRepository: documents,
          pdfGenerator: fakePdf,
          shareService: share ?? _FakeShareService(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> openDetails(WidgetTester tester, int id) async {
    await tester.tap(find.byKey(Key('document_entry_$id')));
    await tester.pumpAndSettle();
  }

  testWidgets('показывает документы с группировкой по контрагентам', (
    tester,
  ) async {
    await pumpArchive(
      tester,
      FakeDocumentRepository([
        doc(id: 1, counterparty: 'ООО «Ромашка»'),
        doc(
          id: 2,
          type: DocumentType.act,
          counterparty: 'ИП Петров',
          amount: 50000,
          date: DateTime(2026, 9, 6),
        ),
        doc(
          id: 3,
          type: DocumentType.contract,
          counterparty: 'ООО «Ромашка»',
          amount: 200000,
          date: DateTime(2026, 9, 7),
        ),
      ]),
    );

    expect(find.byType(DocumentCard), findsNWidgets(3));
    expect(
      find.byKey(const Key('document_group_ИП Петров')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('document_group_ООО «Ромашка»')),
      findsOneWidget,
    );
    // Иконки по типу документа.
    expect(find.byIcon(Icons.receipt_long_outlined), findsWidgets);
    expect(find.byIcon(Icons.assignment_turned_in_outlined), findsWidgets);
    expect(find.byIcon(Icons.description_outlined), findsWidgets);
  });

  testWidgets('поиск фильтрует список и предлагает автодополнение', (
    tester,
  ) async {
    await pumpArchive(
      tester,
      FakeDocumentRepository([
        doc(id: 1, counterparty: 'ООО «Ромашка»'),
        doc(
          id: 2,
          counterparty: 'ИП Петров',
          amount: 50000,
          date: DateTime(2026, 9, 6),
        ),
      ]),
    );

    await tester.enterText(
      find.byKey(const Key('document_search_field')),
      'ромашка',
    );
    await tester.pumpAndSettle();

    // Список отфильтрован.
    expect(find.byType(DocumentCard), findsOneWidget);
    // Показана подсказка автодополнения.
    expect(
      find.byKey(const Key('document_suggestion_0')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('document_suggestion_0')));
    await tester.pumpAndSettle();
    expect(find.byType(DocumentCard), findsOneWidget);
  });

  testWidgets('фильтрация по типу и статусу документа', (tester) async {
    await pumpArchive(
      tester,
      FakeDocumentRepository([
        doc(id: 1, type: DocumentType.receipt),
        doc(id: 2, type: DocumentType.act, status: DocumentStatus.draft),
        doc(id: 3, type: DocumentType.act, status: DocumentStatus.generated),
      ]),
    );

    await tester.tap(find.byKey(const Key('document_type_filter_act')));
    await tester.pumpAndSettle();
    expect(find.byType(DocumentCard), findsNWidgets(2));

    await tester.tap(find.byKey(const Key('document_status_filter_draft')));
    await tester.pumpAndSettle();
    expect(find.byType(DocumentCard), findsOneWidget);
    final card = tester.widget<DocumentCard>(find.byType(DocumentCard));
    expect(card.document.id, 2);
  });

  testWidgets('сортировка по сумме меняет порядок документов', (tester) async {
    await pumpArchive(
      tester,
      FakeDocumentRepository([
        doc(id: 1, amount: 100, date: DateTime(2026, 9, 1)),
        doc(id: 2, amount: 300, date: DateTime(2026, 9, 2)),
        doc(id: 3, amount: 200, date: DateTime(2026, 9, 3)),
      ]),
    );

    // Отключаем группировку, чтобы список был плоским.
    await tester.tap(find.byKey(const Key('document_group_toggle')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('document_sort_button')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const Key('document_sort_amount_ascending')),
    );
    await tester.pumpAndSettle();

    final cards = tester
        .widgetList<DocumentCard>(find.byType(DocumentCard))
        .toList();
    expect(cards.map((c) => c.document.amount), [100, 200, 300]);
  });

  testWidgets('переключение группировки скрывает заголовки групп', (
    tester,
  ) async {
    await pumpArchive(
      tester,
      FakeDocumentRepository([doc(id: 1)]),
    );

    expect(find.byKey(const Key('document_group_ООО «Ромашка»')), findsOneWidget);

    await tester.tap(find.byKey(const Key('document_group_toggle')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('document_group_ООО «Ромашка»')), findsNothing);
    expect(find.byType(DocumentCard), findsOneWidget);
  });

  testWidgets('карточка открывает Bottom sheet с деталями и действиями', (
    tester,
  ) async {
    await pumpArchive(
      tester,
      FakeDocumentRepository([doc(id: 1, service: 'Разработка сайта')]),
    );

    await openDetails(tester, 1);

    expect(find.byKey(const Key('document_details_sheet')), findsOneWidget);
    expect(find.byKey(const Key('document_send_button')), findsOneWidget);
    expect(find.byKey(const Key('document_download_button')), findsOneWidget);
    expect(find.byKey(const Key('document_delete_button')), findsOneWidget);
    expect(find.text('ООО «Ромашка»'), findsWidgets);
    expect(find.text('Разработка сайта'), findsWidgets);
  });

  testWidgets('«Скачать PDF» сохраняет файл документа', (tester) async {
    final share = _FakeShareService();
    await pumpArchive(
      tester,
      FakeDocumentRepository([doc(id: 1)]),
      share: share,
    );

    await openDetails(tester, 1);
    await tester.tap(find.byKey(const Key('document_download_button')));
    await tester.pumpAndSettle();

    expect(share.saved, 1);
    expect(find.byKey(const Key('document_details_sheet')), findsNothing);
  });

  testWidgets('«Отправить» шарит PDF документа', (tester) async {
    final share = _FakeShareService();
    await pumpArchive(
      tester,
      FakeDocumentRepository([doc(id: 1)]),
      share: share,
    );

    await openDetails(tester, 1);
    await tester.tap(find.byKey(const Key('document_send_button')));
    await tester.pumpAndSettle();

    expect(share.shared, 1);
  });

  testWidgets('«Удалить» подтверждается и удаляет документ', (tester) async {
    final documents = FakeDocumentRepository([
      doc(id: 1),
      doc(id: 2, counterparty: 'ИП Петров'),
    ]);
    await pumpArchive(tester, documents);

    await openDetails(tester, 1);
    await tester.tap(find.byKey(const Key('document_delete_button')));
    await tester.pumpAndSettle();

    expect(find.text('Удалить документ?'), findsOneWidget);
    await tester.tap(find.byKey(const Key('document_delete_confirm')));
    await tester.pumpAndSettle();

    expect(documents.documents.map((d) => d.id), [2]);
    expect(find.byType(DocumentCard), findsOneWidget);
  });

  testWidgets('пустой архив показывает заглушку', (tester) async {
    await pumpArchive(tester, FakeDocumentRepository());

    expect(find.byKey(const Key('document_archive_empty')), findsOneWidget);
    expect(find.text('Документов пока нет'), findsOneWidget);
  });

  testWidgets('элементы архива доступны для скринридеров', (tester) async {
    final handle = tester.ensureSemantics();

    await pumpArchive(
      tester,
      FakeDocumentRepository([doc(id: 1)]),
    );

    expect(
      find.byTooltip('Отключить группировку по контрагентам'),
      findsOneWidget,
    );
    expect(find.byTooltip('Сортировка'), findsOneWidget);

    await openDetails(tester, 1);
    expect(find.bySemanticsLabel('Отправить'), findsWidgets);
    expect(find.bySemanticsLabel('Скачать PDF'), findsWidgets);
    expect(find.bySemanticsLabel('Удалить'), findsWidgets);

    handle.dispose();
  });
}

class _FakeShareService implements ContractPdfShareService {
  int shared = 0;
  int saved = 0;

  @override
  Future<void> share(GeneratedPdf pdf) async {
    shared++;
  }

  @override
  Future<String> saveToDocuments(GeneratedPdf pdf) async {
    saved++;
    return 'path/${pdf.fileName}';
  }
}
