import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:npd_shield/data/models/transaction.dart';
import 'package:npd_shield/presentation/dashboard/income_chart_card.dart';

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

  Future<void> pumpChart(
    WidgetTester tester,
    FakeTransactionRepository repository, {
    DateTime? now,
    TransactionSphere? sphere,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: IncomeChartCard(repository: repository, now: now, sphere: sphere),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  String chartLabel(WidgetTester tester) {
    final node = tester.getSemantics(find.byKey(const Key('income_chart')));
    return node.label;
  }

  testWidgets('renders monthly income chart for both spheres', (tester) async {
    final handle = tester.ensureSemantics();
    final repo = FakeTransactionRepository([
      tx(amount: 1000, date: DateTime(2026, 8, 5), sphere: TransactionSphere.it),
      tx(
        amount: 2500,
        date: DateTime(2026, 1, 20),
        sphere: TransactionSphere.logistics,
      ),
      tx(amount: 300, date: DateTime(2025, 11, 10), sphere: TransactionSphere.it),
    ]);
    await pumpChart(tester, repo, now: DateTime(2026, 8, 31));

    expect(find.text('Динамика доходов'), findsOneWidget);
    expect(find.text('IT'), findsWidgets);
    expect(find.text('Логистика'), findsWidgets);

    final label = chartLabel(tester);
    expect(label, contains('по месяцам'));
    expect(label, contains('Август 2026 — IT: 1 000 ₽, Логистика: 0 ₽'));
    expect(label, contains('Январь 2026 — IT: 0 ₽, Логистика: 2 500 ₽'));
    expect(label, contains('Ноябрь 2025 — IT: 300 ₽, Логистика: 0 ₽'));
    handle.dispose();
  });

  testWidgets('renders single sphere when filter is selected', (tester) async {
    final handle = tester.ensureSemantics();
    final repo = FakeTransactionRepository([
      tx(amount: 1000, date: DateTime(2026, 8, 5), sphere: TransactionSphere.it),
      tx(
        amount: 2500,
        date: DateTime(2026, 1, 20),
        sphere: TransactionSphere.logistics,
      ),
    ]);
    await pumpChart(
      tester,
      repo,
      now: DateTime(2026, 8, 31),
      sphere: TransactionSphere.it,
    );

    final label = chartLabel(tester);
    expect(label, contains('IT: 1 000 ₽'));
    expect(label, isNot(contains('Логистика')));
    expect(find.text('Логистика'), findsNothing);
    handle.dispose();
  });

  testWidgets('switches period to week and reloads weekly buckets', (tester) async {
    final handle = tester.ensureSemantics();
    final repo = FakeTransactionRepository([
      tx(amount: 1000, date: DateTime(2026, 8, 3), sphere: TransactionSphere.it),
    ]);
    await pumpChart(tester, repo, now: DateTime(2026, 8, 31));

    expect(chartLabel(tester), contains('по месяцам'));
    expect(chartLabel(tester), contains('Август 2026 — IT: 1 000 ₽'));

    await tester.tap(find.text('Неделя'));
    await tester.pumpAndSettle();

    final label = chartLabel(tester);
    expect(label, contains('по неделям'));
    expect(label, contains('неделя с 3.8.2026 — IT: 1 000 ₽'));
    handle.dispose();
  });

  testWidgets('switches period to quarter and reloads quarterly buckets',
      (tester) async {
    final handle = tester.ensureSemantics();
    final repo = FakeTransactionRepository([
      tx(amount: 1000, date: DateTime(2026, 8, 3), sphere: TransactionSphere.it),
    ]);
    await pumpChart(tester, repo, now: DateTime(2026, 8, 31));

    await tester.tap(find.text('Квартал'));
    await tester.pumpAndSettle();

    final label = chartLabel(tester);
    expect(label, contains('по кварталам'));
    expect(label, contains('3 квартал 2026 — IT: 1 000 ₽'));
    handle.dispose();
  });
}