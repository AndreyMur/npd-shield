import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:npd_shield/core/theme/app_theme.dart';
import 'package:npd_shield/core/theme/app_tokens.dart';
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
    required ThemeData theme,
    DateTime? now,
  }) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: DashboardScreen(repository: repository, now: now),
      ),
    );
    await tester.pumpAndSettle();
  }

  for (final entry in {
    'светлая': AppTheme.light(null),
    'тёмная': AppTheme.dark(null),
  }.entries) {
    final themeName = entry.key;
    final theme = entry.value;

    testWidgets('$themeName тема: пустое состояние при 0 транзакций',
        (tester) async {
      final repo = FakeTransactionRepository();
      await pumpDashboard(
        tester,
        repo,
        theme: theme,
        now: DateTime(2026, 8, 31),
      );

      expect(find.byKey(const Key('dashboard_empty')), findsOneWidget);
      expect(find.text('Пока нет операций'), findsOneWidget);
      expect(find.text('0,00 ₽'), findsNothing);
    });

    testWidgets('$themeName тема: токены доступны виджетам дашборда',
        (tester) async {
      final repo = FakeTransactionRepository();
      await pumpDashboard(
        tester,
        repo,
        theme: theme,
        now: DateTime(2026, 8, 31),
      );

      final context = tester.element(find.byType(DashboardScreen));
      final tokens = AppTokens.of(context);
      expect(tokens, AppTokens.forBrightness(theme.brightness));
      expect(tokens.sphereIt, const Color(0xFF2196F3));
      expect(tokens.sphereLogistics, const Color(0xFFFF9800));
    });

    testWidgets('$themeName тема: переключение сфер фильтрует данные',
        (tester) async {
      final repo = FakeTransactionRepository([
        tx(amount: 1500, date: DateTime(2026, 8, 5), sphere: TransactionSphere.it),
        tx(
          amount: 700,
          date: DateTime(2026, 8, 20),
          sphere: TransactionSphere.logistics,
        ),
      ]);
      await pumpDashboard(
        tester,
        repo,
        theme: theme,
        now: DateTime(2026, 8, 31),
      );

      expect(find.text('2 200,00 ₽'), findsWidgets);

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
      expect(find.text('2 200,00 ₽'), findsWidgets);
    });
  }
}
