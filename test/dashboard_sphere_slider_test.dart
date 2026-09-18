import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:npd_shield/core/theme/app_theme.dart';
import 'package:npd_shield/core/widgets/widgets.dart';
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

  FakeTransactionRepository twoSpheres() => FakeTransactionRepository([
        tx(
          amount: 1500,
          date: DateTime(2026, 8, 5),
          sphere: TransactionSphere.it,
        ),
        tx(
          amount: 700,
          date: DateTime(2026, 8, 20),
          sphere: TransactionSphere.logistics,
        ),
      ]);

  List<AppSegmentOption<DashboardFilter>> sphereOptions() => [
        const AppSegmentOption(
          value: DashboardFilter.all,
          label: 'Все',
          icon: Icons.all_inclusive,
        ),
        const AppSegmentOption(
          value: DashboardFilter.it,
          label: 'IT',
          icon: Icons.code,
        ),
        const AppSegmentOption(
          value: DashboardFilter.logistics,
          label: 'Логистика',
          icon: Icons.local_shipping,
        ),
      ];

  final slider = find.byKey(const Key('dashboard_sphere_slider'));

  Future<void> pumpDashboard(
    WidgetTester tester,
    FakeTransactionRepository repository, {
    ThemeData? theme,
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

  Future<void> pumpSlider(
    WidgetTester tester, {
    required Size size,
    ThemeData? theme,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    var selected = DashboardFilter.all;
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => AppChipSlider<DashboardFilter>(
              key: const Key('dashboard_sphere_slider'),
              selected: selected,
              onChanged: (value) => setState(() => selected = value),
              options: sphereOptions(),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('слайдер сфер прокручивается по горизонтали', (tester) async {
    await pumpSlider(tester, size: const Size(320, 400));

    final scrollable = find.descendant(
      of: slider,
      matching: find.byType(Scrollable),
    );
    expect(scrollable, findsOneWidget);

    final position = tester.state<ScrollableState>(scrollable).position;
    expect(position.maxScrollExtent, greaterThan(0));

    await tester.drag(scrollable, const Offset(-120, 0));
    await tester.pumpAndSettle();
    expect(position.pixels, greaterThan(0));
  });

  testWidgets('на ширине 320 px слайдер не переполняется', (tester) async {
    await pumpSlider(tester, size: const Size(320, 400));

    expect(tester.takeException(), isNull);
    expect(slider, findsOneWidget);
  });

  testWidgets('все три значения сфер доступны в слайдере', (tester) async {
    await pumpDashboard(
      tester,
      twoSpheres(),
      now: DateTime(2026, 8, 31),
    );

    for (final label in ['Все', 'IT', 'Логистика']) {
      expect(
        find.descendant(of: slider, matching: find.text(label)),
        findsOneWidget,
        reason: 'В слайдере нет значения «$label»',
      );
    }
  });

  testWidgets('выбор сферы меняет данные идентично прежнему поведению',
      (tester) async {
    await pumpDashboard(
      tester,
      twoSpheres(),
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

  for (final entry in {
    'светлая': AppTheme.light(null),
    'тёмная': AppTheme.dark(null),
  }.entries) {
    final themeName = entry.key;
    final theme = entry.value;

    testWidgets('$themeName тема: слайдер сфер отображается корректно',
        (tester) async {
      await pumpDashboard(
        tester,
        twoSpheres(),
        theme: theme,
        now: DateTime(2026, 8, 31),
      );

      expect(tester.takeException(), isNull);
      expect(slider, findsOneWidget);
      expect(
        find.descendant(of: slider, matching: find.text('Все')),
        findsOneWidget,
      );
    });
  }
}
