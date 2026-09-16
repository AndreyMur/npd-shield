import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:npd_shield/data/models/transaction.dart';
import 'package:npd_shield/presentation/operations/operations_screen.dart';

import 'helpers/fake_transaction_repository.dart';

void main() {
  Transaction tx({
    int? id,
    double amount = 0,
    DateTime? date,
    TransactionSphere sphere = TransactionSphere.it,
    TransactionType type = TransactionType.income,
    String client = '',
    String inn = '',
    String category = '',
    String comment = '',
  }) {
    final transaction = Transaction(
      amount: amount,
      date: date ?? DateTime(2026, 9, 1),
      sphere: sphere,
      type: type,
      clientName: client,
      clientInn: inn,
      category: category,
      comment: comment,
    );
    if (id != null) transaction.id = id;
    return transaction;
  }

  Future<void> pumpOperations(
    WidgetTester tester,
    FakeTransactionRepository repository, {
    DateTime? now,
  }) async {
    tester.view.physicalSize = const Size(1000, 1800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: OperationsScreen(
          repository: repository,
          now: now ?? DateTime(2026, 9, 16),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows empty state when there are no operations',
      (tester) async {
    final repo = FakeTransactionRepository();
    await pumpOperations(tester, repo);

    expect(find.byKey(const Key('operations_empty')), findsOneWidget);
    expect(find.text('Операций пока нет'), findsOneWidget);
  });

  testWidgets('lists operations and shows period totals', (tester) async {
    final repo = FakeTransactionRepository([
      tx(id: 1, amount: 1000, date: DateTime(2026, 9, 10), client: 'Альфа'),
      tx(
        id: 2,
        amount: 400,
        date: DateTime(2026, 9, 12),
        type: TransactionType.expense,
        client: 'Бета',
        category: 'Материалы',
      ),
    ]);
    await pumpOperations(tester, repo);

    expect(find.text('Альфа'), findsOneWidget);
    expect(find.text('Бета'), findsOneWidget);
    expect(find.byKey(const Key('operation_entry_1')), findsOneWidget);
    expect(find.byKey(const Key('operation_entry_2')), findsOneWidget);

    expect(find.byKey(const Key('operations_summary_income')), findsOneWidget);
    expect(find.text('1 000,00 ₽'), findsWidgets);
    expect(find.text('400,00 ₽'), findsWidgets);
    expect(find.text('600,00 ₽'), findsOneWidget);
  });

  testWidgets('filters operations by type', (tester) async {
    final repo = FakeTransactionRepository([
      tx(id: 1, amount: 1000, client: 'Альфа'),
      tx(id: 2, amount: 400, type: TransactionType.expense, client: 'Бета'),
    ]);
    await pumpOperations(tester, repo);

    await tester.tap(find.byKey(const Key('operation_type_filter_income')));
    await tester.pumpAndSettle();
    expect(find.text('Альфа'), findsOneWidget);
    expect(find.text('Бета'), findsNothing);

    await tester.tap(find.byKey(const Key('operation_type_filter_expense')));
    await tester.pumpAndSettle();
    expect(find.text('Бета'), findsOneWidget);
    expect(find.text('Альфа'), findsNothing);
  });

  testWidgets('filters operations by sphere', (tester) async {
    final repo = FakeTransactionRepository([
      tx(id: 1, amount: 1000, client: 'Альфа', sphere: TransactionSphere.it),
      tx(
        id: 2,
        amount: 400,
        client: 'Бета',
        sphere: TransactionSphere.logistics,
      ),
    ]);
    await pumpOperations(tester, repo);

    await tester.tap(find.byKey(const Key('operation_sphere_filter_it')));
    await tester.pumpAndSettle();
    expect(find.text('Альфа'), findsOneWidget);
    expect(find.text('Бета'), findsNothing);

    await tester
        .tap(find.byKey(const Key('operation_sphere_filter_logistics')));
    await tester.pumpAndSettle();
    expect(find.text('Бета'), findsOneWidget);
    expect(find.text('Альфа'), findsNothing);
  });

  testWidgets('searches by client, category and comment', (tester) async {
    final repo = FakeTransactionRepository([
      tx(id: 1, amount: 1000, client: 'Альфа', category: 'Разработка'),
      tx(id: 2, amount: 400, client: 'Бета', comment: 'Заправка'),
    ]);
    await pumpOperations(tester, repo);

    await tester.enterText(
      find.byKey(const Key('operations_search_field')),
      'разраб',
    );
    await tester.pumpAndSettle();
    expect(find.text('Альфа'), findsOneWidget);
    expect(find.text('Бета'), findsNothing);

    await tester.enterText(
      find.byKey(const Key('operations_search_field')),
      'заправка',
    );
    await tester.pumpAndSettle();
    expect(find.text('Бета'), findsOneWidget);
    expect(find.text('Альфа'), findsNothing);

    await tester.enterText(
      find.byKey(const Key('operations_search_field')),
      'несуществующий',
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('operations_empty')), findsOneWidget);
    expect(find.text('Ничего не найдено'), findsOneWidget);
  });

  testWidgets('filters operations by period', (tester) async {
    final repo = FakeTransactionRepository([
      tx(id: 1, amount: 1000, date: DateTime(2026, 8, 5), client: 'Август'),
      tx(id: 2, amount: 400, date: DateTime(2026, 9, 5), client: 'Сентябрь'),
    ]);
    await pumpOperations(tester, repo, now: DateTime(2026, 9, 16));

    expect(find.text('Август'), findsOneWidget);
    expect(find.text('Сентябрь'), findsOneWidget);

    await tester.tap(find.text('Месяц'));
    await tester.pumpAndSettle();
    expect(find.text('Сентябрь'), findsOneWidget);
    expect(find.text('Август'), findsNothing);
  });

  testWidgets('creates an operation from the form and refreshes the list',
      (tester) async {
    final repo = FakeTransactionRepository();
    await pumpOperations(tester, repo);

    await tester.tap(find.byKey(const Key('operations_add_button')));
    await tester.pumpAndSettle();
    expect(find.text('Новая операция'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('transaction_amount_field')),
      '1500',
    );
    await tester.enterText(
      find.byKey(const Key('transaction_client_name_field')),
      'Новый клиент',
    );
    await tester.tap(find.byKey(const Key('transaction_save_button')));
    await tester.pumpAndSettle();

    expect(repo.transactions, hasLength(1));
    expect(find.text('Новый клиент'), findsOneWidget);
    expect(find.text('+1 500,00 ₽'), findsOneWidget);
  });

  testWidgets('edits an operation by tapping its card', (tester) async {
    final repo = FakeTransactionRepository([
      tx(id: 1, amount: 1000, client: 'Альфа'),
    ]);
    await pumpOperations(tester, repo);

    await tester.tap(find.byKey(const Key('operation_entry_1')));
    await tester.pumpAndSettle();
    expect(find.text('Операция'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('transaction_amount_field')),
      '2000',
    );
    await tester.tap(find.byKey(const Key('transaction_save_button')));
    await tester.pumpAndSettle();

    expect(repo.transactions.single.amount, 2000);
    expect(find.text('+2 000,00 ₽'), findsOneWidget);
  });

  testWidgets('deletes an operation after confirmation', (tester) async {
    final repo = FakeTransactionRepository([
      tx(id: 1, amount: 1000, client: 'Альфа'),
    ]);
    await pumpOperations(tester, repo);

    await tester.tap(find.byKey(const Key('operation_delete_1')));
    await tester.pumpAndSettle();
    expect(find.text('Удалить операцию?'), findsOneWidget);

    await tester.tap(find.byKey(const Key('operation_delete_cancel')));
    await tester.pumpAndSettle();
    expect(repo.transactions, hasLength(1));

    await tester.tap(find.byKey(const Key('operation_delete_1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('operation_delete_confirm')));
    await tester.pumpAndSettle();

    expect(repo.transactions, isEmpty);
    expect(find.byKey(const Key('operations_empty')), findsOneWidget);
    expect(find.text('Операция удалена'), findsOneWidget);
  });

  testWidgets('restores a deleted operation with undo', (tester) async {
    final repo = FakeTransactionRepository([
      tx(id: 1, amount: 1000, client: 'Альфа'),
    ]);
    await pumpOperations(tester, repo);

    await tester.tap(find.byKey(const Key('operation_delete_1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('operation_delete_confirm')));
    await tester.pumpAndSettle();
    expect(repo.transactions, isEmpty);

    await tester.tap(find.text('Отменить'));
    await tester.pumpAndSettle();

    expect(repo.transactions, hasLength(1));
    expect(find.text('Альфа'), findsOneWidget);
    expect(find.text('+1 000,00 ₽'), findsOneWidget);
  });
}
