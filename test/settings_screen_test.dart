import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:npd_shield/presentation/settings/settings_screen.dart';

void main() {
  Future<void> pumpSettings(
    WidgetTester tester, {
    required Future<void> Function() onLoadDemoData,
    required Future<void> Function() onClearAllData,
  }) async {
    tester.view.physicalSize = const Size(1000, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: SettingsScreen(
          onLoadDemoData: onLoadDemoData,
          onClearAllData: onClearAllData,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('очистка данных требует подтверждения и вызывает callback', (
    tester,
  ) async {
    var cleared = 0;
    await pumpSettings(
      tester,
      onLoadDemoData: () async {},
      onClearAllData: () async => cleared++,
    );

    await tester.tap(find.byKey(const Key('settings_clear_data')));
    await tester.pumpAndSettle();

    expect(find.text('Очистить все данные?'), findsOneWidget);

    await tester.tap(find.byKey(const Key('data_reset_confirm')));
    await tester.pumpAndSettle();

    expect(cleared, 1);
  });

  testWidgets('отмена подтверждения не очищает данные', (tester) async {
    var cleared = 0;
    await pumpSettings(
      tester,
      onLoadDemoData: () async {},
      onClearAllData: () async => cleared++,
    );

    await tester.tap(find.byKey(const Key('settings_clear_data')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('data_reset_cancel')));
    await tester.pumpAndSettle();

    expect(cleared, 0);
    expect(find.text('Очистить все данные?'), findsNothing);
  });

  testWidgets('загрузка демо требует подтверждения и показывает снекбар', (
    tester,
  ) async {
    var loads = 0;
    await pumpSettings(
      tester,
      onLoadDemoData: () async => loads++,
      onClearAllData: () async {},
    );

    await tester.tap(find.byKey(const Key('settings_load_demo')));
    await tester.pumpAndSettle();

    expect(find.text('Загрузить демо-данные?'), findsOneWidget);
    await tester.tap(find.byKey(const Key('demo_load_confirm')));
    await tester.pumpAndSettle();

    expect(loads, 1);
    expect(find.text('Демо-данные загружены'), findsOneWidget);
  });

  testWidgets('отмена подтверждения не загружает демо', (tester) async {
    var loads = 0;
    await pumpSettings(
      tester,
      onLoadDemoData: () async => loads++,
      onClearAllData: () async {},
    );

    await tester.tap(find.byKey(const Key('settings_load_demo')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('demo_load_cancel')));
    await tester.pumpAndSettle();

    expect(loads, 0);
  });
}
