import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:npd_shield/core/constants/contract_field_keys.dart';
import 'package:npd_shield/data/models/contract_draft.dart';
import 'package:npd_shield/data/models/contract_template.dart';
import 'package:npd_shield/presentation/contracts/contract_archive_screen.dart';

import 'helpers/fake_contract_repositories.dart';

void main() {
  ContractDraft makeDraft({
    required int id,
    required String code,
    ContractStatus status = ContractStatus.draft,
    String client = 'ООО «Ромашка»',
    String number = '14/09',
    String date = '05.09.2026',
    DateTime? createdAt,
  }) {
    final draft = ContractDraft(
      templateId: code,
      filledFields: contractFieldsFromMap({
        ContractFieldKeys.clientName: client,
        ContractFieldKeys.contractNumber: number,
        ContractFieldKeys.contractDate: date,
      }),
      status: status,
    );
    draft.id = id;
    draft.createdAt = createdAt ?? DateTime(2026, 9, 5);
    return draft;
  }

  final templates = FakeContractTemplateRepository([
    template(code: 'it_dev', title: 'Разработка ПО'),
    template(
      code: 'logistics',
      sphere: TemplateSphere.logistics,
      title: 'Перевозка груза',
    ),
  ]);

  Future<void> pumpArchive(
    WidgetTester tester,
    FakeContractDraftRepository drafts,
  ) async {
    tester.view.physicalSize = const Size(900, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: ContractArchiveScreen(
          draftRepository: drafts,
          templateRepository: templates,
          profileRepository: FakeContractorProfileRepository(null),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> openMenu(WidgetTester tester, int id) async {
    await tester.tap(find.byKey(Key('contract_menu_$id')));
    await tester.pumpAndSettle();
  }

  testWidgets('показывает договоры с названием, контрагентом и статусом', (
    tester,
  ) async {
    final drafts = FakeContractDraftRepository([
      makeDraft(id: 1, code: 'it_dev'),
      makeDraft(
        id: 2,
        code: 'logistics',
        status: ContractStatus.signed,
        client: 'ИП Петров',
        number: '7/9',
        createdAt: DateTime(2026, 9, 6),
      ),
      makeDraft(
        id: 3,
        code: 'it_dev',
        status: ContractStatus.archived,
        client: 'ООО «Вектор»',
        createdAt: DateTime(2026, 9, 4),
      ),
    ]);

    await pumpArchive(tester, drafts);

    expect(find.byKey(const Key('contract_archive_list')), findsOneWidget);
    expect(find.text('Разработка ПО'), findsNWidgets(2));
    expect(find.text('Перевозка груза'), findsOneWidget);
    expect(find.textContaining('ИП Петров'), findsOneWidget);

    Finder statusIn(int id, String label) => find.descendant(
      of: find.byKey(Key('contract_card_$id')),
      matching: find.text(label),
    );
    expect(statusIn(1, 'Черновик'), findsOneWidget);
    expect(statusIn(2, 'Подписан'), findsOneWidget);
    expect(statusIn(3, 'Архив'), findsOneWidget);
  });

  testWidgets('показывает заглушку при отсутствии договоров', (tester) async {
    await pumpArchive(tester, FakeContractDraftRepository());

    expect(find.text('Договоров пока нет'), findsOneWidget);
  });

  testWidgets('ищет по контрагенту, названию и дате', (tester) async {
    final drafts = FakeContractDraftRepository([
      makeDraft(id: 1, code: 'it_dev', client: 'ООО «Ромашка»'),
      makeDraft(
        id: 2,
        code: 'logistics',
        client: 'ИП Петров',
        createdAt: DateTime(2026, 9, 6),
      ),
    ]);
    await pumpArchive(tester, drafts);

    await tester.enterText(
      find.byKey(const Key('contract_search_field')),
      'Петров',
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('contract_card_1')), findsNothing);
    expect(find.byKey(const Key('contract_card_2')), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('contract_search_field')),
      'Перевозка',
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('contract_card_1')), findsNothing);
    expect(find.byKey(const Key('contract_card_2')), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('contract_search_field')),
      '06.09.2026',
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('contract_card_2')), findsOneWidget);
    expect(find.byKey(const Key('contract_card_1')), findsNothing);

    await tester.enterText(
      find.byKey(const Key('contract_search_field')),
      'несуществующий',
    );
    await tester.pumpAndSettle();
    expect(find.text('Ничего не найдено'), findsOneWidget);
  });

  testWidgets('фильтрует договоры по статусу', (tester) async {
    final drafts = FakeContractDraftRepository([
      makeDraft(id: 1, code: 'it_dev'),
      makeDraft(
        id: 2,
        code: 'logistics',
        status: ContractStatus.signed,
        createdAt: DateTime(2026, 9, 6),
      ),
    ]);
    await pumpArchive(tester, drafts);

    await tester.tap(find.byKey(const Key('status_filter_signed')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('contract_card_1')), findsNothing);
    expect(find.byKey(const Key('contract_card_2')), findsOneWidget);

    await tester.tap(find.byKey(const Key('status_filter_all')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('contract_card_1')), findsOneWidget);
    expect(find.byKey(const Key('contract_card_2')), findsOneWidget);
  });

  testWidgets('дублирует договор', (tester) async {
    final drafts = FakeContractDraftRepository([
      makeDraft(id: 1, code: 'it_dev'),
    ]);
    await pumpArchive(tester, drafts);

    await openMenu(tester, 1);
    await tester.tap(find.text('Дублировать'));
    await tester.pumpAndSettle();

    expect(drafts.drafts, hasLength(2));
    expect(find.text('Договор продублирован'), findsOneWidget);
    expect(drafts.drafts.any((d) => d.status == ContractStatus.draft), isTrue);
  });

  testWidgets('переводит договор в подписанный и в архив', (tester) async {
    final drafts = FakeContractDraftRepository([
      makeDraft(id: 1, code: 'it_dev'),
    ]);
    await pumpArchive(tester, drafts);

    await openMenu(tester, 1);
    await tester.tap(find.text('Отметить подписанным'));
    await tester.pumpAndSettle();

    expect(drafts.drafts.single.status, ContractStatus.signed);
    expect(find.text('Статус изменён: Подписан'), findsOneWidget);

    await openMenu(tester, 1);
    await tester.tap(find.text('В архив'));
    await tester.pumpAndSettle();

    expect(drafts.drafts.single.status, ContractStatus.archived);

    await openMenu(tester, 1);
    await tester.tap(find.text('Вернуть из архива'));
    await tester.pumpAndSettle();

    expect(drafts.drafts.single.status, ContractStatus.signed);
  });

  testWidgets('открывает мастер редактирования', (tester) async {
    final drafts = FakeContractDraftRepository([
      makeDraft(id: 1, code: 'it_dev'),
    ]);
    await pumpArchive(tester, drafts);

    await openMenu(tester, 1);
    await tester.tap(find.text('Редактировать'));
    await tester.pumpAndSettle();

    expect(find.text('Редактирование договора'), findsOneWidget);
  });

  testWidgets('подгружает следующую страницу при прокрутке', (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final drafts = FakeContractDraftRepository([
      for (var i = 1; i <= 25; i++)
        makeDraft(
          id: i,
          code: 'it_dev',
          client: 'Клиент $i',
          createdAt: DateTime(2026, 9, 1).add(Duration(days: 25 - i)),
        ),
    ]);

    await tester.pumpWidget(
      MaterialApp(
        home: ContractArchiveScreen(
          draftRepository: drafts,
          templateRepository: templates,
          profileRepository: FakeContractorProfileRepository(null),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(drafts.requestedOffsets, contains(0));
    expect(drafts.drafts.length, 25);
    expect(find.byKey(const Key('contract_card_1')), findsOneWidget);
    expect(find.byKey(const Key('contract_card_21')), findsNothing);

    await tester.drag(
      find.byKey(const Key('contract_archive_list')),
      const Offset(0, -4000),
    );
    await tester.pumpAndSettle();

    expect(drafts.requestedOffsets, contains(20));

    // Вторая страница добавлена в конец списка — доскролливаем до неё.
    await tester.drag(
      find.byKey(const Key('contract_archive_list')),
      const Offset(0, -4000),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('contract_card_25')), findsOneWidget);
  });
}
