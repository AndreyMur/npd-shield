import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:npd_shield/data/models/document.dart';
import 'package:npd_shield/data/models/transaction.dart';
import 'package:npd_shield/data/pdf/contract_pdf_share_service.dart';
import 'package:npd_shield/data/pdf/generated_pdf.dart';
import 'package:npd_shield/presentation/dashboard/transaction_documents_card.dart';

import 'helpers/fake_document_repository.dart';
import 'helpers/fake_transaction_repository.dart';

/// Тесты карточки транзакций дашборда: индикация документов (issue 96)
/// и переход к документу из карточки транзакции (issue 97).
void main() {
  Transaction tx({
    required int id,
    double amount = 1000,
    DateTime? date,
    String name = 'ООО «Ромашка»',
    String inn = '7701234567',
    TransactionSphere sphere = TransactionSphere.it,
  }) {
    final transaction = Transaction(
      amount: amount,
      date: date ?? DateTime(2026, 9, 5),
      sphere: sphere,
      clientName: name,
      clientInn: inn,
    );
    transaction.id = id;
    return transaction;
  }

  Document doc({
    required int id,
    DocumentType type = DocumentType.receipt,
    int transactionId = 0,
    double amount = 1000,
    DateTime? date,
    String name = 'ООО «Ромашка»',
    String inn = '7701234567',
  }) {
    final document = Document(
      type: type,
      amount: amount,
      date: date ?? DateTime(2026, 9, 5),
      transactionId: transactionId,
      counterpartyName: name,
      counterpartyInn: inn,
    );
    document.id = id;
    return document;
  }

  Future<GeneratedPdf> fakePdf(Document document) async => GeneratedPdf(
    bytes: Uint8List.fromList(const [37, 80, 68, 70]),
    pageCount: 1,
    fileName: 'doc.pdf',
    generationTime: const Duration(milliseconds: 1),
  );

  Future<void> pumpCard(
    WidgetTester tester, {
    required FakeTransactionRepository transactions,
    required FakeDocumentRepository documents,
  }) async {
    tester.view.physicalSize = const Size(900, 1800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: TransactionDocumentsCard(
              transactionRepository: transactions,
              documentRepository: documents,
              pdfGenerator: fakePdf,
              shareService: _FakeShareService(),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('показывает значок документа только у связанных транзакций', (
    tester,
  ) async {
    await pumpCard(
      tester,
      transactions: FakeTransactionRepository([
        tx(id: 1),
        tx(id: 2, amount: 5000, name: 'ИП Петров'),
      ]),
      documents: FakeDocumentRepository([
        doc(id: 10, transactionId: 1),
      ]),
    );

    expect(find.byKey(const Key('transaction_entry_1')), findsOneWidget);
    expect(find.byKey(const Key('transaction_entry_2')), findsOneWidget);
    expect(find.byKey(const Key('transaction_document_badge_1')), findsOneWidget);
    expect(find.byKey(const Key('transaction_document_badge_2')), findsNothing);
  });

  testWidgets('автоматически связывает документ с транзакцией по реквизитам', (
    tester,
  ) async {
    final documents = FakeDocumentRepository([
      doc(id: 10, transactionId: 0),
    ]);
    await pumpCard(
      tester,
      transactions: FakeTransactionRepository([tx(id: 3)]),
      documents: documents,
    );

    expect(documents.documents.single.transactionId, 3);
    expect(find.byKey(const Key('transaction_document_badge_3')), findsOneWidget);
  });

  testWidgets('нажатие на транзакцию открывает карточку документа', (
    tester,
  ) async {
    await pumpCard(
      tester,
      transactions: FakeTransactionRepository([tx(id: 1)]),
      documents: FakeDocumentRepository([
        doc(id: 10, transactionId: 1),
      ]),
    );

    await tester.tap(find.byKey(const Key('transaction_entry_1')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('document_details_sheet')), findsOneWidget);
  });

  testWidgets('при нескольких документах показывает выбор документа', (
    tester,
  ) async {
    await pumpCard(
      tester,
      transactions: FakeTransactionRepository([tx(id: 1)]),
      documents: FakeDocumentRepository([
        doc(id: 10, transactionId: 1),
        doc(id: 11, type: DocumentType.act, transactionId: 1),
      ]),
    );

    await tester.tap(find.byKey(const Key('transaction_entry_1')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('transaction_document_option_10')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('transaction_document_option_11')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('transaction_document_option_11')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('document_details_sheet')), findsOneWidget);
  });

  testWidgets('пустой список транзакций показывает заглушку', (tester) async {
    await pumpCard(
      tester,
      transactions: FakeTransactionRepository(),
      documents: FakeDocumentRepository(),
    );

    expect(
      find.byKey(const Key('transaction_documents_empty')),
      findsOneWidget,
    );
  });
}

class _FakeShareService implements ContractPdfShareService {
  @override
  Future<void> share(GeneratedPdf pdf) async {}

  @override
  Future<String> saveToDocuments(GeneratedPdf pdf) async => 'path/${pdf.fileName}';
}
