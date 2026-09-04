import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:npd_shield/core/constants/contract_field_keys.dart';
import 'package:npd_shield/data/models/contract_draft.dart';
import 'package:npd_shield/domain/profile/contractor_profile.dart';
import 'package:npd_shield/presentation/contracts/contract_form_screen.dart';

import 'helpers/fake_contract_repositories.dart';

void main() {
  bool? popResult;

  Future<void> openForm(
    WidgetTester tester, {
    FakeContractorProfileRepository? profile,
    FakeContractDraftRepository? drafts,
  }) async {
    final draftRepository = drafts ?? FakeContractDraftRepository();
    final contract = template(
      code: 'it_software_development',
      title: 'Разработка ПО',
    );
    tester.view.physicalSize = const Size(800, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    popResult = null;
    await tester.pumpWidget(
      MaterialApp(
        home: _FormHost(
          onOpened: (context) => ContractFormScreen(
            template: contract,
            draftRepository: draftRepository,
            profileRepository: profile ?? FakeContractorProfileRepository(null),
          ),
          onResult: (value) => popResult = value,
        ),
      ),
    );
    await tester.tap(find.byKey(const Key('open_form')));
    await tester.pumpAndSettle();
  }

  Future<void> tapSave(WidgetTester tester) async {
    final button = find.byKey(const Key('save_draft_button'));
    await tester.ensureVisible(button);
    await tester.pumpAndSettle();
    await tester.tap(button);
    await tester.pumpAndSettle();
  }

  testWidgets('автозаполняет реквизиты исполнителя из профиля', (tester) async {
    final profile = FakeContractorProfileRepository(ContractorProfile.demo);

    await openForm(tester, profile: profile);

    expect(find.text(ContractorProfile.demo.fullName), findsOneWidget);
    expect(find.text(ContractorProfile.demo.inn), findsOneWidget);
    expect(find.text(ContractorProfile.demo.ogrnip), findsOneWidget);
    expect(
      find.text(ContractorProfile.demo.registrationAddress),
      findsOneWidget,
    );
    expect(
      find.textContaining('Реквизиты из профиля подставлены'),
      findsOneWidget,
    );
  });

  testWidgets('показывает подсказку при отсутствии профиля', (tester) async {
    await openForm(tester, profile: FakeContractorProfileRepository(null));

    expect(find.textContaining('Заполните профиль'), findsOneWidget);
  });

  testWidgets('блокирует сохранение при пустых обязательных полях', (
    tester,
  ) async {
    final drafts = FakeContractDraftRepository();

    await openForm(tester, drafts: drafts);
    await tapSave(tester);

    expect(find.text('Укажите заказчика'), findsOneWidget);
    expect(find.text('Опишите предмет договора'), findsOneWidget);
    expect(find.text('Укажите стоимость'), findsOneWidget);
    expect(drafts.drafts, isEmpty);
  });

  testWidgets('валидирует формат ИНН и стоимость', (tester) async {
    final drafts = FakeContractDraftRepository();

    await openForm(tester, drafts: drafts);
    await tester.enterText(find.byKey(const Key('field_clientInn')), '7701234');
    await tester.enterText(find.byKey(const Key('field_amount')), '0');
    await tapSave(tester);

    expect(find.text('ИНН: 10 или 12 цифр'), findsWidgets);
    expect(find.text('Стоимость должна быть больше нуля'), findsOneWidget);
    expect(drafts.drafts, isEmpty);
  });

  testWidgets(
    'сохраняет черновик с заполненными полями и возвращает результат',
    (tester) async {
      final drafts = FakeContractDraftRepository();
      final profile = FakeContractorProfileRepository(ContractorProfile.demo);

      await openForm(tester, drafts: drafts, profile: profile);

      await tester.enterText(
        find.byKey(const Key('field_contractNumber')),
        '14/09',
      );
      await tester.enterText(
        find.byKey(const Key('field_contractCity')),
        'Москва',
      );
      await tester.enterText(
        find.byKey(const Key('field_clientName')),
        'ООО «Ромашка»',
      );
      await tester.enterText(
        find.byKey(const Key('field_clientInn')),
        '7701234567',
      );
      await tester.enterText(
        find.byKey(const Key('field_subject')),
        'Разработка сайта и мобильного приложения',
      );
      await tester.enterText(find.byKey(const Key('field_amount')), '150000');
      await tapSave(tester);

      expect(popResult, isTrue);
      expect(drafts.drafts, hasLength(1));

      final draft = drafts.drafts.single;
      expect(draft.templateId, 'it_software_development');
      expect(draft.status, ContractStatus.draft);

      final fields = contractFieldsToMap(draft.filledFields);
      expect(fields[ContractFieldKeys.contractNumber], '14/09');
      expect(fields[ContractFieldKeys.contractCity], 'Москва');
      expect(fields[ContractFieldKeys.clientName], 'ООО «Ромашка»');
      expect(fields[ContractFieldKeys.clientInn], '7701234567');
      expect(
        fields[ContractFieldKeys.subject],
        'Разработка сайта и мобильного приложения',
      );
      expect(fields[ContractFieldKeys.amount], '150000');
      expect(fields[ContractFieldKeys.contractDate], isNotEmpty);

      expect(
        fields[ContractFieldKeys.executorFullName],
        ContractorProfile.demo.fullName,
      );
      expect(
        fields[ContractFieldKeys.executorBankAccount],
        ContractorProfile.demo.bankAccount,
      );
    },
  );
}

class _FormHost extends StatelessWidget {
  final Widget Function(BuildContext context) onOpened;
  final void Function(bool? value) onResult;

  const _FormHost({required this.onOpened, required this.onResult});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          key: const Key('open_form'),
          onPressed: () async {
            final result = await Navigator.of(context)
                .push<bool>(MaterialPageRoute(builder: onOpened));
            onResult(result);
          },
          child: const Text('Открыть форму'),
        ),
      ),
    );
  }
}
