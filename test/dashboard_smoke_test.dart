import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:npd_shield/data/models/transaction.dart';
import 'package:npd_shield/data/repositories/transaction_repository.dart';
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

  group('Smoke-тест дашборда end-to-end', () {
    testWidgets('полный workflow: ввод, переключение, график, налог, лимит',
        (tester) async {
      final repo = FakeTransactionRepository([
        tx(amount: 1500, date: DateTime(2026, 8, 5), sphere: TransactionSphere.it),
        tx(
          amount: 700,
          date: DateTime(2026, 8, 20),
          sphere: TransactionSphere.logistics,
        ),
        tx(amount: 2000, date: DateTime(2026, 7, 15), sphere: TransactionSphere.it),
        tx(
          amount: 1000,
          date: DateTime(2026, 7, 10),
          sphere: TransactionSphere.logistics,
        ),
      ]);

      await pumpDashboard(tester, repo, now: DateTime(2026, 8, 31));

      expect(find.text('Все сферы'), findsOneWidget);
      expect(find.byKey(const Key('dashboard_sphere_slider')), findsOneWidget);
      expect(find.text('2 200,00 ₽'), findsWidgets);
      expect(find.text('1 500,00 ₽'), findsWidgets);
      expect(find.text('700,00 ₽'), findsWidgets);

      await tester.tap(find.byIcon(Icons.code));
      await tester.pumpAndSettle();
      expect(find.text('1 500,00 ₽'), findsWidgets);
      expect(find.text('700,00 ₽'), findsNothing);

      await tester.tap(find.byIcon(Icons.local_shipping));
      await tester.pumpAndSettle();
      expect(find.text('700,00 ₽'), findsWidgets);
      expect(find.text('1 500,00 ₽'), findsNothing);

      await tester.tap(find.byIcon(Icons.all_inclusive));
      await tester.pumpAndSettle();
      expect(find.text('Все сферы'), findsOneWidget);

      expect(find.byKey(const Key('income_chart')), findsOneWidget);

      expect(find.byKey(const Key('limit_progress')), findsOneWidget);
      expect(find.byKey(const Key('limit_text')), findsOneWidget);

      expect(find.text('Налог (НПД 6%)'), findsOneWidget);
      expect(find.text('К уплате за период'), findsWidgets);
      expect(find.text('Начислено (6%)'), findsWidgets);
      expect(find.text('До лимита НПД'), findsWidgets);
    });

    testWidgets('отображение карточек сфер при фильтре "Все"', (tester) async {
      final repo = FakeTransactionRepository([
        tx(amount: 1500, date: DateTime(2026, 8, 5), sphere: TransactionSphere.it),
        tx(
          amount: 700,
          date: DateTime(2026, 8, 20),
          sphere: TransactionSphere.logistics,
        ),
      ]);

      await pumpDashboard(tester, repo, now: DateTime(2026, 8, 31));

      expect(find.text('IT'), findsWidgets);
      expect(find.text('Логистика'), findsWidgets);
      expect(find.text('1 500,00 ₽'), findsWidgets);
      expect(find.text('700,00 ₽'), findsWidgets);
    });

    testWidgets('переключение периода графика', (tester) async {
      final repo = FakeTransactionRepository([
        for (var i = 0; i < 12; i++)
          tx(
            amount: 1000 + i * 100,
            date: DateTime(2026, i + 1, 15),
            sphere: TransactionSphere.it,
          ),
      ]);

      await pumpDashboard(tester, repo, now: DateTime(2026, 8, 31));

      expect(find.byType(SegmentedButton<SeriesPeriod>), findsWidgets);

      await tester.tap(find.text('Неделя'));
      await tester.pumpAndSettle();
      expect(find.byType(SegmentedButton<SeriesPeriod>), findsWidgets);

      await tester.tap(find.text('Квартал'));
      await tester.pumpAndSettle();
      expect(find.byType(SegmentedButton<SeriesPeriod>), findsWidgets);

      await tester.tap(find.text('Год'));
      await tester.pumpAndSettle();
      expect(find.byType(SegmentedButton<SeriesPeriod>), findsWidgets);

      await tester.tap(find.text('Месяц'));
      await tester.pumpAndSettle();
      expect(find.byType(SegmentedButton<SeriesPeriod>), findsWidgets);
    });

    testWidgets('прогресс-бар лимита отображается корректно', (tester) async {
      final repo = FakeTransactionRepository([
        for (var i = 0; i < 50; i++)
          tx(
          amount: 10000,
          date: DateTime(2026, 1, 15),
          sphere: TransactionSphere.it,
        ),
      ]);

      await pumpDashboard(tester, repo, now: DateTime(2026, 8, 31));

      expect(find.byKey(const Key('limit_progress')), findsOneWidget);
      expect(find.byKey(const Key('limit_text')), findsOneWidget);
    });
  });
}
