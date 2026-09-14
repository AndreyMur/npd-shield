import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:npd_shield/domain/documents/my_tax_deep_link.dart';
import 'package:npd_shield/domain/documents/my_tax_deep_link_service.dart';
import 'package:npd_shield/presentation/documents/my_tax_deep_link_screen.dart';

import 'helpers/fake_my_tax.dart';

void main() {
  const link = MyTaxDeepLink(
    amount: 150000,
    clientName: 'ООО «Ромашка»',
    clientInn: '7701234567',
    clientType: ClientType.legal,
    serviceName: 'Разработка сайта',
  );

  Widget wrap({
    required FakeExternalAppLauncher launcher,
    required FakeClipboardWriter clipboard,
  }) {
    return MaterialApp(
      home: MyTaxDeepLinkScreen(
        link: link,
        service: MyTaxDeepLinkService(
          launcher: launcher,
          clipboard: clipboard,
        ),
      ),
    );
  }

  testWidgets('показывает данные расчёта и инструкцию ручного ввода', (
    tester,
  ) async {
    _setViewport(tester);
    await tester.pumpWidget(
      wrap(
        launcher: FakeExternalAppLauncher(),
        clipboard: FakeClipboardWriter(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('my_tax_summary_amount')), findsOneWidget);
    expect(find.text('Сумма: 150 000,00 ₽'), findsOneWidget);
    expect(find.byKey(const Key('my_tax_instruction')), findsOneWidget);
    expect(find.text('Как ввести данные вручную'), findsOneWidget);
    expect(
      find.byKey(const Key('my_tax_fallback_notice')),
      findsNothing,
    );
  });

  testWidgets('открывает приложение, если оно установлено', (tester) async {
    _setViewport(tester);
    final launcher = FakeExternalAppLauncher();
    final clipboard = FakeClipboardWriter();
    await tester.pumpWidget(wrap(launcher: launcher, clipboard: clipboard));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('my_tax_open_button')));
    await tester.pumpAndSettle();

    expect(launcher.opened.single, link.uri);
    expect(clipboard.writes, isEmpty);
    expect(find.byKey(const Key('my_tax_fallback_notice')), findsNothing);
    expect(find.text('Открываем «Мой налог»…'), findsOneWidget);
  });

  testWidgets('при отсутствии приложения копирует данные и показывает fallback', (
    tester,
  ) async {
    _setViewport(tester);
    final launcher = FakeExternalAppLauncher(installed: false);
    final clipboard = FakeClipboardWriter();
    await tester.pumpWidget(wrap(launcher: launcher, clipboard: clipboard));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('my_tax_open_button')));
    await tester.pumpAndSettle();

    expect(clipboard.writes.single, link.clipboardText);
    expect(find.byKey(const Key('my_tax_fallback_notice')), findsOneWidget);
    expect(find.byKey(const Key('my_tax_instruction')), findsOneWidget);
  });

  testWidgets('кнопка «Скопировать данные» копирует в буфер обмена', (
    tester,
  ) async {
    _setViewport(tester);
    final clipboard = FakeClipboardWriter();
    await tester.pumpWidget(
      wrap(launcher: FakeExternalAppLauncher(), clipboard: clipboard),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('my_tax_copy_button')));
    await tester.pumpAndSettle();

    expect(clipboard.writes.single, link.clipboardText);
    expect(find.byKey(const Key('my_tax_fallback_notice')), findsOneWidget);
  });

  testWidgets('смена типа покупателя меняет ссылку deep link', (tester) async {
    _setViewport(tester);
    final launcher = FakeExternalAppLauncher();
    await tester.pumpWidget(
      wrap(launcher: launcher, clipboard: FakeClipboardWriter()),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Физлицо'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('my_tax_open_button')));
    await tester.pumpAndSettle();

    expect(
      launcher.opened.single.queryParameters['type'],
      'income_from_individual',
    );
  });
}

void _setViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(1000, 2600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}
