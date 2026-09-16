import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:npd_shield/data/models/transaction.dart';
import 'package:npd_shield/presentation/operations/transaction_form_screen.dart';

import 'helpers/fake_transaction_repository.dart';

void main() {
  Future<void> pumpForm(
    WidgetTester tester,
    FakeTransactionRepository repository, {
    Transaction? transaction,
    DateTime? now,
  }) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                key: const Key('open_form'),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => TransactionFormScreen(
                      repository: repository,
                      transaction: transaction,
                      now: now,
                    ),
                  ),
                ),
                child: const Text('Открыть'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const Key('open_form')));
    await tester.pumpAndSettle();
  }

  testWidgets('creates a new income operation with all fields', (tester) async {
    final repo = FakeTransactionRepository();
    await pumpForm(tester, repo, now: DateTime(2026, 9, 16));

    expect(find.text('Новая операция'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('transaction_amount_field')),
      '15 000,50',
    );
    await tester.enterText(
      find.byKey(const Key('transaction_client_name_field')),
      'ООО Ромашка',
    );
    await tester.enterText(
      find.byKey(const Key('transaction_client_inn_field')),
      '7701234567',
    );
    await tester.enterText(
      find.byKey(const Key('transaction_category_field')),
      'Разработка',
    );
    await tester.enterText(
      find.byKey(const Key('transaction_comment_field')),
      'Оплата по счёту',
    );
    await tester.tap(find.byKey(const Key('transaction_save_button')));
    await tester.pumpAndSettle();

    expect(repo.transactions, hasLength(1));
    final transaction = repo.transactions.single;
    expect(transaction.amount, 15000.50);
    expect(transaction.type, TransactionType.income);
    expect(transaction.sphere, TransactionSphere.it);
    expect(transaction.clientName, 'ООО Ромашка');
    expect(transaction.clientInn, '7701234567');
    expect(transaction.category, 'Разработка');
    expect(transaction.comment, 'Оплата по счёту');
    expect(transaction.date, DateTime(2026, 9, 16));
  });

  testWidgets('creates an expense with the selected sphere and type',
      (tester) async {
    final repo = FakeTransactionRepository();
    await pumpForm(tester, repo, now: DateTime(2026, 9, 16));

    await tester.tap(find.text('Расход'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Логистика'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('transaction_amount_field')),
      '700',
    );
    await tester.tap(find.byKey(const Key('transaction_save_button')));
    await tester.pumpAndSettle();

    final transaction = repo.transactions.single;
    expect(transaction.type, TransactionType.expense);
    expect(transaction.sphere, TransactionSphere.logistics);
    expect(transaction.amount, 700);
  });

  testWidgets('validates that the amount is a positive number',
      (tester) async {
    final repo = FakeTransactionRepository();
    await pumpForm(tester, repo, now: DateTime(2026, 9, 16));

    await tester.tap(find.byKey(const Key('transaction_save_button')));
    await tester.pumpAndSettle();

    expect(find.text('Укажите сумму больше нуля'), findsOneWidget);
    expect(repo.transactions, isEmpty);
  });

  testWidgets('validates the date format', (tester) async {
    final repo = FakeTransactionRepository();
    await pumpForm(tester, repo, now: DateTime(2026, 9, 16));

    await tester.enterText(
      find.byKey(const Key('transaction_amount_field')),
      '100',
    );
    await tester.enterText(
      find.byKey(const Key('transaction_date_field')),
      '16/09/2026',
    );
    await tester.tap(find.byKey(const Key('transaction_save_button')));
    await tester.pumpAndSettle();

    expect(find.text('Укажите дату в формате ДД.ММ.ГГГГ'), findsOneWidget);
    expect(repo.transactions, isEmpty);
  });

  testWidgets('edits an existing operation keeping its id', (tester) async {
    final existing = Transaction(
      amount: 1000,
      date: DateTime(2026, 9, 1),
      sphere: TransactionSphere.logistics,
      type: TransactionType.expense,
      clientName: 'ИП Петров',
      clientInn: '123',
      category: 'Топливо',
    )..id = 7;
    final repo = FakeTransactionRepository([existing]);

    await pumpForm(tester, repo, transaction: existing);

    expect(find.text('Операция'), findsOneWidget);
    expect(find.text('ИП Петров'), findsOneWidget);
    expect(find.text('Топливо'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('transaction_amount_field')),
      '2500',
    );
    await tester.enterText(
      find.byKey(const Key('transaction_client_name_field')),
      'ИП Сидоров',
    );
    await tester.tap(find.byKey(const Key('transaction_save_button')));
    await tester.pumpAndSettle();

    expect(repo.transactions, hasLength(1));
    final updated = repo.transactions.single;
    expect(updated.id, 7);
    expect(updated.amount, 2500);
    expect(updated.clientName, 'ИП Сидоров');
    expect(updated.type, TransactionType.expense);
    expect(updated.sphere, TransactionSphere.logistics);
  });
}
