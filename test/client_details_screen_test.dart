import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:npd_shield/data/models/client.dart';
import 'package:npd_shield/data/models/document.dart';
import 'package:npd_shield/data/models/transaction.dart';
import 'package:npd_shield/domain/documents/my_tax_deep_link.dart';
import 'package:npd_shield/presentation/clients/client_details_screen.dart';

import 'helpers/fake_client_repository.dart';
import 'helpers/fake_document_repository.dart';
import 'helpers/fake_transaction_repository.dart';

void main() {
  Client client({int id = 1, String name = 'ООО «Альфа»'}) {
    final value = Client(
      name: name,
      inn: '7701234567',
      type: ClientType.legal,
      contacts: 'sales@alfa.ru',
      notes: 'Постоянный клиент',
    );
    value.id = id;
    return value;
  }

  Transaction transaction({required int id, required int clientId}) {
    final value = Transaction(
      amount: 1500,
      date: DateTime(2026, 9, 10),
      sphere: TransactionSphere.it,
      clientName: 'ООО «Альфа»',
      clientInn: '7701234567',
      clientId: clientId,
    );
    value.id = id;
    return value;
  }

  Document document({required int id, required int clientId}) {
    final value = Document(
      type: DocumentType.receipt,
      amount: 2000,
      date: DateTime(2026, 9, 11),
      counterpartyName: 'ООО «Альфа»',
      clientId: clientId,
    );
    value.id = id;
    return value;
  }

  Future<void> pumpDetails(
    WidgetTester tester, {
    required FakeTransactionRepository transactions,
    required FakeDocumentRepository documents,
    Client? value,
  }) async {
    tester.view.physicalSize = const Size(1000, 1800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: ClientDetailsScreen(
          client: value ?? client(),
          clientRepository: FakeClientRepository([value ?? client()]),
          transactionRepository: transactions,
          documentRepository: documents,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows client details', (tester) async {
    await pumpDetails(
      tester,
      transactions: FakeTransactionRepository(),
      documents: FakeDocumentRepository(),
    );

    expect(find.byKey(const Key('client_details_name')), findsOneWidget);
    expect(find.text('ООО «Альфа»'), findsOneWidget);
    expect(find.text('Юрлицо / ИП'), findsOneWidget);
    expect(find.text('sales@alfa.ru'), findsOneWidget);
    expect(find.text('Постоянный клиент'), findsOneWidget);
  });

  testWidgets('shows only operations and documents of this client', (
    tester,
  ) async {
    await pumpDetails(
      tester,
      transactions: FakeTransactionRepository([
        transaction(id: 1, clientId: 1),
        transaction(id: 2, clientId: 2),
      ]),
      documents: FakeDocumentRepository([
        document(id: 1, clientId: 1),
        document(id: 2, clientId: 2),
      ]),
    );

    expect(
      find.byKey(const Key('client_details_operation_1')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('client_details_operation_2')),
      findsNothing,
    );
    expect(
      find.byKey(const Key('client_details_document_1')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('client_details_document_2')),
      findsNothing,
    );
  });

  testWidgets('shows empty history placeholders', (tester) async {
    await pumpDetails(
      tester,
      transactions: FakeTransactionRepository(),
      documents: FakeDocumentRepository(),
    );

    expect(
      find.byKey(const Key('client_details_operations_empty')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('client_details_documents_empty')),
      findsOneWidget,
    );
  });
}
