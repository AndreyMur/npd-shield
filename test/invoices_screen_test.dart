import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:npd_shield/data/models/client.dart';
import 'package:npd_shield/data/models/invoice.dart';
import 'package:npd_shield/data/models/transaction.dart';
import 'package:npd_shield/domain/documents/my_tax_deep_link.dart';
import 'package:npd_shield/presentation/invoices/invoices_screen.dart';

import 'helpers/fake_client_repository.dart';
import 'helpers/fake_invoice_repository.dart';
import 'helpers/fake_transaction_repository.dart';

void main() {
  final now = DateTime(2026, 9, 16);

  Invoice invoice({
    int? id,
    String number = '14/09',
    int clientId = 0,
    String clientName = 'ООО «Альфа»',
    double amount = 50000,
    DateTime? issuedAt,
    DateTime? dueDate,
    InvoiceStatus status = InvoiceStatus.sent,
    double paidAmount = 0,
  }) {
    final value = Invoice(
      number: number,
      amount: amount,
      issuedAt: issuedAt ?? DateTime(2026, 9, 1),
      dueDate: dueDate ?? DateTime(2026, 9, 30),
      clientId: clientId,
      clientName: clientName,
      status: status,
      paidAmount: paidAmount,
    );
    if (id != null) value.id = id;
    return value;
  }

  Future<void> pumpInvoices(
    WidgetTester tester,
    FakeInvoiceRepository repository, {
    FakeClientRepository? clients,
  }) async {
    tester.view.physicalSize = const Size(1000, 1800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: InvoicesScreen(
          repository: repository,
          clientRepository: clients,
          now: now,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows empty state when there are no invoices', (tester) async {
    await pumpInvoices(tester, FakeInvoiceRepository());

    expect(find.byKey(const Key('invoices_empty')), findsOneWidget);
    expect(find.text('Счетов пока нет'), findsOneWidget);
    expect(find.text('0,00 ₽'), findsOneWidget);
  });

  testWidgets('lists invoices, shows outstanding total and overdue highlight', (
    tester,
  ) async {
    final repo = FakeInvoiceRepository([
      invoice(
        id: 1,
        number: '1',
        amount: 50000,
        dueDate: DateTime(2026, 9, 10),
      ),
      invoice(
        id: 2,
        number: '2',
        amount: 30000,
        dueDate: DateTime(2026, 9, 30),
        status: InvoiceStatus.draft,
      ),
    ]);
    await pumpInvoices(tester, repo);

    expect(find.byKey(const Key('invoices_list')), findsOneWidget);
    expect(find.text('Счёт № 1'), findsOneWidget);
    expect(find.text('Счёт № 2'), findsOneWidget);

    // Дебиторка считается только по выставленным счетам, без черновиков.
    expect(
      tester
          .widget<Text>(find.byKey(const Key('invoices_outstanding_total')))
          .data,
      '50 000,00 ₽',
    );

    // Просроченный счёт выделен статусом и сводкой.
    expect(
      find.descendant(
        of: find.byKey(const Key('invoice_status_1')),
        matching: find.text('Просрочен'),
      ),
      findsOneWidget,
    );
    expect(find.byKey(const Key('invoices_overdue_summary')), findsOneWidget);
    expect(find.textContaining('Просрочено 1'), findsOneWidget);
  });

  testWidgets('marks an invoice fully paid and creates an income', (
    tester,
  ) async {
    final transactions = FakeTransactionRepository();
    final repo = FakeInvoiceRepository([
      invoice(id: 1, amount: 50000, clientName: 'ООО «Альфа»'),
    ], transactions);
    await pumpInvoices(tester, repo);

    await tester.tap(find.byKey(const Key('invoice_menu_1')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Отметить оплаченным'));
    await tester.pumpAndSettle();

    expect(find.text('Оплата счёта'), findsOneWidget);
    await tester.tap(find.byKey(const Key('invoice_payment_confirm')));
    await tester.pumpAndSettle();

    expect(repo.invoices.single.status, InvoiceStatus.paid);
    expect(repo.invoices.single.paidAmount, 50000);
    expect(transactions.transactions, hasLength(1));
    final income = transactions.transactions.single;
    expect(income.type, TransactionType.income);
    expect(income.amount, 50000);
    expect(find.text('Счёт оплачен'), findsOneWidget);
  });

  testWidgets('records a partial payment and keeps the outstanding amount', (
    tester,
  ) async {
    final transactions = FakeTransactionRepository();
    final repo = FakeInvoiceRepository([
      invoice(id: 1, amount: 50000),
    ], transactions);
    await pumpInvoices(tester, repo);

    await tester.tap(find.byKey(const Key('invoice_menu_1')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Отметить оплаченным'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('invoice_payment_amount_field')),
      '20000',
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('invoice_payment_partial_hint')), findsOneWidget);

    await tester.tap(find.byKey(const Key('invoice_payment_confirm')));
    await tester.pumpAndSettle();

    expect(repo.invoices.single.status, InvoiceStatus.sent);
    expect(repo.invoices.single.paidAmount, 20000);
    expect(transactions.transactions, isEmpty);
    expect(find.text('Платёж учтён'), findsOneWidget);
    expect(find.textContaining('Оплачено 20 000,00 ₽'), findsOneWidget);

    expect(
      tester
          .widget<Text>(find.byKey(const Key('invoices_outstanding_total')))
          .data,
      '30 000,00 ₽',
    );
  });

  testWidgets('deletes an invoice after confirmation and restores with undo', (
    tester,
  ) async {
    final repo = FakeInvoiceRepository([invoice(id: 1, number: '7')]);
    await pumpInvoices(tester, repo);

    await tester.tap(find.byKey(const Key('invoice_menu_1')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Удалить'));
    await tester.pumpAndSettle();
    expect(find.text('Удалить счёт?'), findsOneWidget);

    await tester.tap(find.byKey(const Key('invoice_delete_cancel')));
    await tester.pumpAndSettle();
    expect(repo.invoices, hasLength(1));

    await tester.tap(find.byKey(const Key('invoice_menu_1')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Удалить'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('invoice_delete_confirm')));
    await tester.pumpAndSettle();

    expect(repo.invoices, isEmpty);
    expect(find.byKey(const Key('invoices_empty')), findsOneWidget);
    expect(find.text('Счёт удалён'), findsOneWidget);

    await tester.tap(find.text('Отменить'));
    await tester.pumpAndSettle();
    expect(repo.invoices, hasLength(1));
    expect(find.text('Счёт № 7'), findsOneWidget);
  });

  testWidgets('creates an invoice from the form', (tester) async {
    final repo = FakeInvoiceRepository();
    final client = Client(
      name: 'ООО «Ромашка»',
      inn: '7701234567',
      type: ClientType.legal,
    )..id = 5;
    final clients = FakeClientRepository([client]);
    await pumpInvoices(tester, repo, clients: clients);

    await tester.tap(find.byKey(const Key('invoices_add_button')));
    await tester.pumpAndSettle();
    expect(find.text('Новый счёт'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('invoice_number_field')),
      '21/09',
    );
    await tester.enterText(
      find.byKey(const Key('invoice_amount_field')),
      '120000',
    );
    await tester.tap(find.byKey(const Key('invoice_pick_client_button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('client_picker_option_5')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('invoice_save_button')));
    await tester.pumpAndSettle();

    expect(repo.invoices, hasLength(1));
    final created = repo.invoices.single;
    expect(created.number, '21/09');
    expect(created.amount, 120000);
    expect(created.clientId, 5);
    expect(created.clientName, 'ООО «Ромашка»');
    expect(find.text('Счёт № 21/09'), findsOneWidget);
  });
}
