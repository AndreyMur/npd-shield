import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:npd_shield/data/models/transaction.dart';
import 'package:npd_shield/data/repositories/transaction_repository.dart';
import 'package:npd_shield/presentation/dashboard/dashboard_screen.dart';

class FakeTransactionRepository implements TransactionRepository {
  final List<Transaction> transactions;

  FakeTransactionRepository([List<Transaction>? transactions])
      : transactions = transactions ?? [];

  @override
  Future<int> add(Transaction transaction) async {
    transactions.add(transaction);
    return transactions.length;
  }

  @override
  Future<List<Transaction>> getAll() async => List.of(transactions);

  @override
  Future<List<Transaction>> getAllForSphere(TransactionSphere sphere) async {
    return transactions.where((t) => t.sphere == sphere).toList();
  }

  @override
  Future<IncomeSummary> getIncomeSummary({
    TransactionSphere? sphere,
    DateTime? now,
  }) async {
    final today = now ?? DateTime.now();
    final monthStart = DateTime(today.year, today.month);
    final yearStart = DateTime(today.year);

    final filtered =
        sphere == null ? transactions : transactions.where((t) => t.sphere == sphere);

    double month = 0;
    double year = 0;
    for (final t in filtered) {
      if (!t.date.isBefore(monthStart)) month += t.amount;
      if (!t.date.isBefore(yearStart)) year += t.amount;
    }
    return IncomeSummary(month: month, year: year);
  }

  @override
  Future<void> clear() async => transactions.clear();
}

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
    await tester.binding.setSurfaceSize(const Size(800, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
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
