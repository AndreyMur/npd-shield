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
  }) {
    return Transaction(
      amount: amount,
      date: date ?? DateTime(2026, 8, 1),
      sphere: sphere,
      clientName: 'Клиент',
      clientInn: '123',
    );
  }

  Future<void> pumpDashboard(
    WidgetTester tester,
    FakeTransactionRepository repository, {
    DateTime? now,
  }) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: DashboardScreen(repository: repository, now: now),
      ),
    );
    await tester.pump();
  }

  testWidgets('renders summary card with zero values for 0 transactions',
      (tester) async {
    final repo = FakeTransactionRepository();
    await pumpDashboard(tester, repo, now: DateTime(2026, 8, 31));

    expect(find.text('Все сферы'), findsOneWidget);
    expect(find.byType(SegmentedButton<DashboardFilter>), findsOneWidget);
    expect(find.text('0,00 ₽'), findsNWidgets(8));
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
