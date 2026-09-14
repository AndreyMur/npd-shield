import 'package:flutter_test/flutter_test.dart';
import 'package:npd_shield/domain/documents/my_tax_deep_link.dart';
import 'package:npd_shield/domain/documents/my_tax_deep_link_service.dart';

import 'helpers/fake_my_tax.dart';

void main() {
  group('MyTaxDeepLink.uri', () {
    test('формирует URL с суммой, типом и покупателем', () {
      const link = MyTaxDeepLink(
        amount: 150000,
        clientName: 'ООО «Ромашка»',
        clientInn: '7701234567',
        clientType: ClientType.legal,
        serviceName: 'Разработка сайта',
      );

      final uri = link.uri;
      expect(uri.scheme, 'https');
      expect(uri.host, 'mynalog.ru');
      expect(uri.path, '/issue');
      expect(uri.queryParameters['amount'], '150000.00');
      expect(uri.queryParameters['type'], 'income_from_organization');
      expect(uri.queryParameters['client'], 'ООО «Ромашка»');
      expect(uri.queryParameters['clientInn'], '7701234567');
      expect(uri.queryParameters['service'], 'Разработка сайта');
    });

    test('физлицо передаёт код дохода от физического лица', () {
      const link = MyTaxDeepLink(
        amount: 5000,
        clientType: ClientType.individual,
      );

      expect(link.uri.queryParameters['type'], 'income_from_individual');
      expect(link.uri.queryParameters['amount'], '5000.00');
    });

    test('опускает пустые необязательные параметры', () {
      const link = MyTaxDeepLink(amount: 1000);

      expect(link.uri.queryParameters.containsKey('client'), isFalse);
      expect(link.uri.queryParameters.containsKey('clientInn'), isFalse);
      expect(link.uri.queryParameters.containsKey('service'), isFalse);
    });

    test('copyWith меняет только тип покупателя', () {
      const link = MyTaxDeepLink(
        amount: 1000,
        clientName: 'Иванов И.И.',
        clientType: ClientType.individual,
      );

      final legal = link.copyWith(clientType: ClientType.legal);
      expect(legal.amount, 1000);
      expect(legal.clientName, 'Иванов И.И.');
      expect(legal.clientType, ClientType.legal);
      expect(legal.uri.queryParameters['type'], 'income_from_organization');
    });
  });

  group('ClientType.fromInn', () {
    test('10 цифр — юрлицо', () {
      expect(ClientType.fromInn('7701234567'), ClientType.legal);
    });

    test('12 цифр — физлицо', () {
      expect(ClientType.fromInn('771234567890'), ClientType.individual);
    });

    test('пустой ИНН — физлицо', () {
      expect(ClientType.fromInn(''), ClientType.individual);
    });
  });

  group('MyTaxDeepLink.clipboardText', () {
    test('содержит сумму, тип и реквизиты покупателя', () {
      const link = MyTaxDeepLink(
        amount: 150000,
        clientName: 'ООО «Ромашка»',
        clientInn: '7701234567',
        clientType: ClientType.legal,
        serviceName: 'Разработка сайта',
      );

      final text = link.clipboardText;
      expect(text, contains('150 000,00 ₽'));
      expect(text, contains('Юрлицо / ИП'));
      expect(text, contains('ООО «Ромашка»'));
      expect(text, contains('7701234567'));
      expect(text, contains('Разработка сайта'));
    });

    test('инструкция содержит пошаговые действия', () {
      const link = MyTaxDeepLink(amount: 1500, serviceName: 'Консультация');

      final steps = link.manualSteps;
      expect(steps, isNotEmpty);
      expect(steps.first, contains('Мой налог'));
      expect(steps.any((s) => s.contains('1 500,00 ₽')), isTrue);
      expect(steps.any((s) => s.contains('Консультация')), isTrue);
    });
  });

  group('MyTaxDeepLinkService', () {
    test('открывает приложение, если оно установлено', () async {
      final launcher = FakeExternalAppLauncher();
      final clipboard = FakeClipboardWriter();
      final service = MyTaxDeepLinkService(
        launcher: launcher,
        clipboard: clipboard,
      );
      const link = MyTaxDeepLink(amount: 1000);

      final result = await service.open(link);

      expect(result.opened, isTrue);
      expect(launcher.opened.single, link.uri);
      expect(clipboard.writes, isEmpty);
    });

    test('копирует данные, если приложение не установлено', () async {
      final launcher = FakeExternalAppLauncher(installed: false);
      final clipboard = FakeClipboardWriter();
      final service = MyTaxDeepLinkService(
        launcher: launcher,
        clipboard: clipboard,
      );
      const link = MyTaxDeepLink(amount: 1000);

      final result = await service.open(link);

      expect(result.copied, isTrue);
      expect(launcher.opened, isEmpty);
      expect(clipboard.writes.single, link.clipboardText);
    });

    test('копирует данные, если запуск не удался', () async {
      final launcher = FakeExternalAppLauncher(launchResult: false);
      final clipboard = FakeClipboardWriter();
      final service = MyTaxDeepLinkService(
        launcher: launcher,
        clipboard: clipboard,
      );
      const link = MyTaxDeepLink(amount: 1000);

      final result = await service.open(link);

      expect(result.copied, isTrue);
      expect(clipboard.writes.single, link.clipboardText);
    });
  });
}
