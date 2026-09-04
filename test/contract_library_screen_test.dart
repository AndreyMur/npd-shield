import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:npd_shield/data/models/contract_template.dart';
import 'package:npd_shield/presentation/contracts/contract_library_screen.dart';

import 'helpers/fake_contract_repositories.dart';

void main() {
  Future<void> pumpLibrary(
    WidgetTester tester,
    FakeContractTemplateRepository templateRepository, {
    FakeContractDraftRepository? drafts,
    FakeContractorProfileRepository? profile,
  }) async {
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: ContractLibraryScreen(
          templateRepository: templateRepository,
          draftRepository: drafts ?? FakeContractDraftRepository(),
          profileRepository: profile ?? FakeContractorProfileRepository(null),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'показывает карточки шаблонов: название, описание, категория и сфера',
    (tester) async {
      final repo = FakeContractTemplateRepository([
        template(
          code: 'it_dev',
          sphere: TemplateSphere.it,
          title: 'Разработка ПО',
          description: 'Описание разработки ПО для заказчика.',
        ),
        template(
          code: 'logistics_cargo',
          sphere: TemplateSphere.logistics,
          title: 'Перевозка груза',
          description: 'Разовая перевозка груза по маршруту.',
        ),
        template(
          code: 'universal_services',
          sphere: TemplateSphere.universal,
          title: 'Оказание услуг',
          description: 'Универсальный шаблон оказания услуг.',
        ),
      ]);

      await pumpLibrary(tester, repo);

      expect(find.byKey(const Key('template_library')), findsOneWidget);

      expect(find.text('Разработка ПО'), findsOneWidget);
      expect(find.text('Перевозка груза'), findsOneWidget);
      expect(find.text('Оказание услуг'), findsOneWidget);

      expect(
        find.text('Описание разработки ПО для заказчика.'),
        findsOneWidget,
      );
      expect(find.text('Разовая перевозка груза по маршруту.'), findsOneWidget);

      expect(find.text('Категория: IT-услуги'), findsOneWidget);
      expect(find.text('Категория: Логистика'), findsOneWidget);
      expect(find.text('Категория: Универсальные'), findsOneWidget);

      expect(find.text('Сфера: IT'), findsOneWidget);
      expect(find.text('Сфера: Логистика'), findsOneWidget);
      expect(find.text('Сфера: Универсальная'), findsOneWidget);
    },
  );

  testWidgets('показывает заглушку, когда шаблонов нет', (tester) async {
    final repo = FakeContractTemplateRepository();

    await pumpLibrary(tester, repo);

    expect(find.text('Шаблонов пока нет'), findsOneWidget);
  });

  testWidgets('открывает форму по нажатию на карточку', (tester) async {
    final repo = FakeContractTemplateRepository([
      template(
        code: 'it_dev',
        sphere: TemplateSphere.it,
        title: 'Разработка ПО',
      ),
    ]);

    await pumpLibrary(tester, repo);

    await tester.tap(find.byKey(const Key('template_card_it_dev')));
    await tester.pumpAndSettle();

    expect(find.text('Новый договор'), findsOneWidget);
    expect(find.text('Разработка ПО'), findsWidgets);
  });
}
