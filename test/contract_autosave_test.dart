import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:npd_shield/core/constants/contract_field_keys.dart';
import 'package:npd_shield/data/models/contract_draft.dart';
import 'package:npd_shield/data/repositories/contract_template_text_loader.dart';
import 'package:npd_shield/domain/profile/contractor_profile.dart';
import 'package:npd_shield/presentation/contracts/contract_wizard_screen.dart';

import 'helpers/fake_contract_repositories.dart';

const _templateText = '''
ДОГОВОР № {{contractNumber}}
тестовый шаблон

1. ПРЕДМЕТ ДОГОВОРА

1.1. {{subject}}.

2. РЕКВИЗИТЫ И ПОДПИСИ СТОРОН

Исполнитель:
ИП {{executorFullName}}
ИНН {{executorInn}}
ОГРНИП {{executorOgrnip}}
Адрес: {{executorAddress}}

Заказчик:
{{clientName}}
ИНН {{clientInn}}
Адрес: {{clientAddress}}

_______________________ / {{executorFullName}} /
''';

void main() {
  Future<void> pumpWizard(
    WidgetTester tester, {
    required FakeContractDraftRepository drafts,
    ContractDraft? initialDraft,
    Duration autosaveInterval = const Duration(seconds: 30),
  }) async {
    tester.view.physicalSize = const Size(1000, 2200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: ContractWizardScreen(
          template: template(),
          draftRepository: drafts,
          profileRepository: FakeContractorProfileRepository(
            ContractorProfile.demo,
          ),
          templateTextLoader: const _FakeTemplateTextLoader(_templateText),
          initialDraft: initialDraft,
          autosaveInterval: autosaveInterval,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  ContractDraft savedDraft({
    int id = 0,
    String client = 'ООО «Ромашка»',
    String number = '14/09',
    ContractStatus status = ContractStatus.draft,
  }) {
    final draft = ContractDraft(
      templateId: 'it_software_development',
      filledFields: contractFieldsFromMap({
        ContractFieldKeys.clientName: client,
        ContractFieldKeys.contractNumber: number,
        ContractFieldKeys.contractDate: '05.09.2026',
      }),
      status: status,
    );
    draft.id = id;
    draft.createdAt = DateTime(2026, 9, 5);
    return draft;
  }

  testWidgets('автосохранение создаёт черновик и показывает индикатор', (
    tester,
  ) async {
    final drafts = FakeContractDraftRepository();
    await pumpWizard(
      tester,
      drafts: drafts,
      autosaveInterval: const Duration(seconds: 5),
    );

    await tester.enterText(
      find.byKey(const Key('field_contractNumber')),
      '14/09',
    );
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();

    expect(drafts.drafts, hasLength(1));
    expect(drafts.drafts.single.status, ContractStatus.draft);
    expect(
      contractFieldsToMap(drafts.drafts.single.filledFields)[
          ContractFieldKeys.contractNumber],
      '14/09',
    );
    expect(find.byKey(const Key('autosave_indicator')), findsOneWidget);
  });

  testWidgets('повторное автосохранение обновляет, а не дублирует черновик', (
    tester,
  ) async {
    final drafts = FakeContractDraftRepository();
    await pumpWizard(
      tester,
      drafts: drafts,
      autosaveInterval: const Duration(seconds: 5),
    );

    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();

    expect(drafts.drafts, hasLength(1));
  });

  testWidgets('восстанавливает незавершённый черновик при открытии', (
    tester,
  ) async {
    final drafts = FakeContractDraftRepository([savedDraft(id: 3)]);
    await pumpWizard(tester, drafts: drafts);

    expect(find.text('Восстановлен незавершённый черновик'), findsOneWidget);
    final numberField = tester.widget<TextFormField>(
      find.byKey(const Key('field_contractNumber')),
    );
    expect(numberField.controller!.text, '14/09');
  });

  testWidgets('режим редактирования заполняет поля и сохраняет тот же id', (
    tester,
  ) async {
    final drafts = FakeContractDraftRepository([
      savedDraft(id: 7, status: ContractStatus.signed),
    ]);
    await pumpWizard(
      tester,
      drafts: drafts,
      initialDraft: drafts.drafts.single,
      autosaveInterval: const Duration(seconds: 5),
    );

    expect(find.text('Редактирование договора'), findsOneWidget);
    final numberField = tester.widget<TextFormField>(
      find.byKey(const Key('field_contractNumber')),
    );
    expect(numberField.controller!.text, '14/09');

    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();

    expect(drafts.drafts, hasLength(1));
    expect(drafts.drafts.single.id, 7);
    expect(drafts.drafts.single.status, ContractStatus.signed);
  });
}

class _FakeTemplateTextLoader implements ContractTemplateTextLoader {
  final String text;
  const _FakeTemplateTextLoader(this.text);

  @override
  Future<String> load(String code) async => text;
}
