import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:npd_shield/data/models/client.dart';
import 'package:npd_shield/data/models/invoice.dart';
import 'package:npd_shield/domain/documents/my_tax_deep_link.dart';
import 'package:npd_shield/presentation/invoices/invoice_form_screen.dart';

import 'helpers/fake_client_repository.dart';
import 'helpers/fake_invoice_repository.dart';

void main() {
  final now = DateTime(2026, 9, 16);

  Future<void> pumpForm(WidgetTester tester, Widget form) async {
    tester.view.physicalSize = const Size(1000, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: ElevatedButton(
                key: const Key('open_form'),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => form),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const Key('open_form')));
    await tester.pumpAndSettle();
  }

  testWidgets('creates an invoice with defaults', (tester) async {
    final repo = FakeInvoiceRepository();
    await pumpForm(
      tester,
      InvoiceFormScreen(repository: repo, now: now),
    );

    await tester.enterText(
      find.byKey(const Key('invoice_number_field')),
      '14/09',
    );
    await tester.enterText(
      find.byKey(const Key('invoice_amount_field')),
      '50000',
    );
    await tester.tap(find.byKey(const Key('invoice_save_button')));
    await tester.pumpAndSettle();

    expect(repo.invoices, hasLength(1));
    final created = repo.invoices.single;
    expect(created.number, '14/09');
    expect(created.amount, 50000);
    expect(created.status, InvoiceStatus.draft);
    expect(created.issuedAt, DateTime(2026, 9, 16));
    expect(created.dueDate, DateTime(2026, 9, 30));
  });

  testWidgets('validates required number and amount', (tester) async {
    final repo = FakeInvoiceRepository();
    await pumpForm(
      tester,
      InvoiceFormScreen(repository: repo, now: now),
    );

    await tester.tap(find.byKey(const Key('invoice_save_button')));
    await tester.pumpAndSettle();

    expect(find.text('Укажите номер счёта'), findsOneWidget);
    expect(find.text('Укажите сумму больше нуля'), findsOneWidget);
    expect(repo.invoices, isEmpty);
  });

  testWidgets('rejects a due date before the issue date', (tester) async {
    final repo = FakeInvoiceRepository();
    await pumpForm(
      tester,
      InvoiceFormScreen(repository: repo, now: now),
    );

    await tester.enterText(
      find.byKey(const Key('invoice_number_field')),
      '14/09',
    );
    await tester.enterText(
      find.byKey(const Key('invoice_amount_field')),
      '50000',
    );
    await tester.enterText(
      find.byKey(const Key('invoice_issued_at_field')),
      '20.09.2026',
    );
    await tester.enterText(
      find.byKey(const Key('invoice_due_date_field')),
      '10.09.2026',
    );
    await tester.tap(find.byKey(const Key('invoice_save_button')));
    await tester.pumpAndSettle();

    expect(
      find.text('Срок не может быть раньше даты выставления'),
      findsOneWidget,
    );
    expect(repo.invoices, isEmpty);
  });

  testWidgets('edits an existing invoice preserving its id and payments', (
    tester,
  ) async {
    final existing = Invoice(
      number: '3',
      amount: 10000,
      issuedAt: DateTime(2026, 9, 1),
      dueDate: DateTime(2026, 9, 20),
      status: InvoiceStatus.sent,
      paidAmount: 4000,
    )..id = 3;
    final repo = FakeInvoiceRepository([existing]);
    await pumpForm(
      tester,
      InvoiceFormScreen(repository: repo, invoice: existing, now: now),
    );

    expect(find.text('3'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('invoice_amount_field')),
      '20000',
    );
    await tester.tap(find.byKey(const Key('invoice_save_button')));
    await tester.pumpAndSettle();

    expect(repo.invoices, hasLength(1));
    final updated = repo.invoices.single;
    expect(updated.id, 3);
    expect(updated.amount, 20000);
    expect(updated.paidAmount, 4000);
    expect(updated.status, InvoiceStatus.sent);
  });

  testWidgets('picks a client from the catalog', (tester) async {
    final repo = FakeInvoiceRepository();
    final client = Client(
      name: 'ООО «Ромашка»',
      inn: '7701234567',
      type: ClientType.legal,
    )..id = 7;
    final clients = FakeClientRepository([client]);
    await pumpForm(
      tester,
      InvoiceFormScreen(
        repository: repo,
        clientRepository: clients,
        now: now,
      ),
    );

    await tester.tap(find.byKey(const Key('invoice_pick_client_button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('client_picker_option_7')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('invoice_number_field')),
      '15/09',
    );
    await tester.enterText(
      find.byKey(const Key('invoice_amount_field')),
      '30000',
    );
    await tester.tap(find.byKey(const Key('invoice_save_button')));
    await tester.pumpAndSettle();

    final created = repo.invoices.single;
    expect(created.clientId, 7);
    expect(created.clientName, 'ООО «Ромашка»');
    expect(created.clientInn, '7701234567');
  });
}
