import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:npd_shield/data/models/transaction.dart';
import 'package:npd_shield/presentation/dashboard/dashboard_screen.dart';

import 'helpers/fake_transaction_repository.dart';

void main() {
  Transaction tx({
    double amount = 0,
    DateTime? date,
    TransactionSphere sphere = TransactionSphere.it,
    TransactionType type = TransactionType.income,
  }) {
    return Transaction(
      amount: amount,
      date: date ?? DateTime(2026, 8, 1),
      sphere: sphere,
      type: type,
      clientName: 'Клиент',
      clientInn: '123',
    );
  }

  Future<void> pumpDashboard(
    WidgetTester tester,
    FakeTransactionRepository repository, {
    DateTime? now,
    VoidCallback? onAddOperation,
  }) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: DashboardScreen(
          repository: repository,
          now: now,
          onAddOperation: onAddOperation,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows empty state when there are no operations',
      (tester) async {
    final repo = FakeTransactionRepository();
    await pumpDashboard(tester, repo, now: DateTime(2026, 8, 31));

    expect(find.byKey(const Key('dashboard_empty')), findsOneWidget);
    expect(find.text('Пока нет операций'), findsOneWidget);
    expect(find.byType(SegmentedButton<DashboardFilter>), findsOneWidget);
    expect(find.text('0,00 ₽'), findsNothing);
  });

  testWidgets('empty state offers to add the first operation', (tester) async {
    final repo = FakeTransactionRepository();
    var taps = 0;
    await pumpDashboard(
      tester,
      repo,
      now: DateTime(2026, 8, 31),
      onAddOperation: () => taps++,
    );

    await tester.tap(find.byKey(const Key('dashboard_add_operation')));
    expect(taps, 1);
  });

  testWidgets('shows totals for all spheres with data in current month and year',
      (tester) async {
    final repo = FakeTransactionRepository([
      tx(amount: 1500, date: DateTime(2026, 8, 5), sphere: TransactionSphere.it),
      tx(
        amount: 500,
        date: DateTime(2026, 8, 20),
        sphere: TransactionSphere.logistics,
      ),
    ]);
    await pumpDashboard(tester, repo, now: DateTime(2026, 8, 31));

    expect(find.text('2 000,00 ₽'), findsWidgets);
    expect(find.text('1 500,00 ₽'), findsWidgets);
    expect(find.text('500,00 ₽'), findsWidgets);
  });

  testWidgets('shows profit card with income, expense and profit',
      (tester) async {
    final repo = FakeTransactionRepository([
      tx(amount: 2000, date: DateTime(2026, 8, 5)),
      tx(
        amount: 500,
        date: DateTime(2026, 8, 10),
        type: TransactionType.expense,
      ),
    ]);
    await pumpDashboard(tester, repo, now: DateTime(2026, 8, 31));

    expect(find.text('Прибыль'), findsOneWidget);
    expect(find.text('Прибыль за месяц'), findsWidgets);
    expect(find.text('Расход за месяц'), findsWidgets);
    expect(find.text('1 500,00 ₽'), findsWidgets);
    expect(find.text('500,00 ₽'), findsWidgets);
  });

  testWidgets('shows expenses per sphere', (tester) async {
    final repo = FakeTransactionRepository([
      tx(
        amount: 300,
        date: DateTime(2026, 8, 5),
        sphere: TransactionSphere.it,
        type: TransactionType.expense,
      ),
      tx(
        amount: 700,
        date: DateTime(2026, 8, 20),
        sphere: TransactionSphere.logistics,
        type: TransactionType.expense,
      ),
    ]);
    await pumpDashboard(tester, repo, now: DateTime(2026, 8, 31));

    expect(find.text('IT'), findsWidgets);
    expect(find.text('Логистика'), findsWidgets);
    expect(find.text('300,00 ₽'), findsWidgets);
    expect(find.text('700,00 ₽'), findsWidgets);
  });

  testWidgets('filters data by sphere with one tap', (tester) async {
    final repo = FakeTransactionRepository([
      tx(amount: 1500, date: DateTime(2026, 8, 5), sphere: TransactionSphere.it),
      tx(
        amount: 700,
        date: DateTime(2026, 8, 20),
        sphere: TransactionSphere.logistics,
      ),
    ]);
    await pumpDashboard(tester, repo, now: DateTime(2026, 8, 31));

    expect(find.text('2 200,00 ₽'), findsWidgets);

    await tester.tap(find.byIcon(Icons.code));
    await tester.pumpAndSettle();
    expect(find.text('1 500,00 ₽'), findsWidgets);
    expect(find.text('700,00 ₽'), findsNothing);

    await tester.tap(find.byIcon(Icons.local_shipping));
    await tester.pumpAndSettle();
    expect(find.text('700,00 ₽'), findsWidgets);
    expect(find.text('1 500,00 ₽'), findsNothing);
  });
}
