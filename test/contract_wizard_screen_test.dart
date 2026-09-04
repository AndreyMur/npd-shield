import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:npd_shield/core/constants/contract_field_keys.dart';
import 'package:npd_shield/data/models/contract_draft.dart';
import 'package:npd_shield/data/pdf/contract_pdf_service.dart';
import 'package:npd_shield/data/pdf/contract_pdf_share_service.dart';
import 'package:npd_shield/data/repositories/contract_template_text_loader.dart';
import 'package:npd_shield/domain/contracts/contract_document.dart';
import 'package:npd_shield/domain/profile/contractor_profile.dart';
import 'package:npd_shield/presentation/contracts/contract_wizard_screen.dart';

import 'helpers/fake_contract_repositories.dart';

const _templateText = '''
ДОГОВОР № {{contractNumber}}
на разработку программного обеспечения

г. {{contractCity}}                                                    «{{contractDate}}»

1. ПРЕДМЕТ ДОГОВОРА

1.1. Исполнитель выполняет работы, описание предмета: {{subject}}.

2. РЕКВИЗИТЫ И ПОДПИСИ СТОРОН

Исполнитель:
ИП {{executorFullName}}
ИНН {{executorInn}}
ОГРНИП {{executorOgrnip}}
Адрес: {{executorAddress}}
Банк: {{executorBankName}}
БИК: {{executorBankBik}}
Счёт: {{executorBankAccount}}

Заказчик:
{{clientName}}
ИНН {{clientInn}}
Адрес: {{clientAddress}}

_______________________ / {{executorFullName}} /
''';

void main() {
  FakeContractorProfileRepository? usedProfile;
  FakeContractDraftRepository? usedDrafts;
  _FakePdfGenerator? pdfGenerator;
  _FakeShareService? shareService;
  bool? popResult;

  Future<void> pumpWizard(
    WidgetTester tester, {
    FakeContractorProfileRepository? profile,
    FakeContractDraftRepository? drafts,
    bool failingRepository = false,
  }) async {
    usedProfile = profile ?? FakeContractorProfileRepository(ContractorProfile.demo);
    usedDrafts = drafts ?? (failingRepository ? FakeContractDraftRepository.failing() : FakeContractDraftRepository());
    pdfGenerator = _FakePdfGenerator();
    shareService = _FakeShareService();
    popResult = null;

    tester.view.physicalSize = const Size(1000, 2200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: _WizardHost(
          onOpened: (context) => ContractWizardScreen(
            template: template(),
            draftRepository: usedDrafts!,
            profileRepository: usedProfile!,
            templateTextLoader: const _FakeTemplateTextLoader(_templateText),
            pdfGenerator: pdfGenerator!.generate,
            shareService: shareService,
            previewBuilder: () => Container(
              key: const Key('fake_pdf_preview'),
              color: Colors.white,
              child: const Center(child: Text('PDF рендер')),
            ),
          ),
          onResult: (value) => popResult = value,
        ),
      ),
    );
    await tester.tap(find.byKey(const Key('open_wizard')));
    await tester.pumpAndSettle();
  }

  Future<void> goNext(WidgetTester tester) async {
    final button = find.byKey(const Key('wizard_next_button'));
    await tester.ensureVisible(button);
    await tester.pumpAndSettle();
    await tester.tap(button);
    await tester.pumpAndSettle();
  }

  Future<void> fillClientAndSubject(WidgetTester tester) async {
    // Шаг 0 (Параметры) — всё опционально.
    await goNext(tester);

    // Шаг 1 (Исполнитель) — реквизиты уже подставлены из профиля.
    await goNext(tester);

    // Шаг 2 (Заказчик).
    await tester.enterText(
      find.byKey(const Key('field_clientName')),
      'ООО «Ромашка»',
    );
    await tester.enterText(
      find.byKey(const Key('field_clientInn')),
      '7701234567',
    );
    await goNext(tester);

    // Шаг 3 (Предмет и стоимость).
    await tester.enterText(
      find.byKey(const Key('field_subject')),
      'разработка сайта и приложения',
    );
    await tester.enterText(find.byKey(const Key('field_amount')), '150000');
    await goNext(tester);
  }

  testWidgets('показывает 5 шагов с индикатором прогресса', (tester) async {
    await pumpWizard(tester);

    expect(find.text('Шаг 1 из 5'), findsOneWidget);
    expect(find.byKey(const Key('wizard_progress')), findsOneWidget);
    final progress = tester.widget<LinearProgressIndicator>(
      find.byKey(const Key('wizard_progress')),
    );
    expect(progress.value, 0);

    expect(find.byKey(const Key('field_contractNumber')), findsOneWidget);
    expect(find.byKey(const Key('field_contractDate')), findsOneWidget);
    expect(find.byKey(const Key('field_contractCity')), findsOneWidget);
  });

  testWidgets('показывает подсказки для полей каждого шага', (tester) async {
    await pumpWizard(tester);

    expect(
      find.textContaining('Оставьте пустым, если нумерация не нужна'),
      findsOneWidget,
    );

    await goNext(tester);
    expect(find.text('Шаг 2 из 5'), findsOneWidget);
    expect(
      find.textContaining('12 цифр — ИНН индивидуального предпринимателя'),
      findsOneWidget,
    );
    expect(
      find.textContaining('реквизиты подставляются из профиля'),
      findsOneWidget,
    );
  });

  testWidgets('автозаполняет реквизиты исполнителя из профиля', (tester) async {
    await pumpWizard(tester);
    await goNext(tester);

    expect(
      find.text(ContractorProfile.demo.fullName),
      findsWidgets,
    );
    expect(find.byKey(const Key('field_executorInn')), findsOneWidget);
    final inn = tester.widget<TextFormField>(
      find.byKey(const Key('field_executorInn')),
    );
    expect(inn.controller!.text, ContractorProfile.demo.inn);
  });

  testWidgets('валидирует обязательные поля шага «Исполнитель»', (tester) async {
    await pumpWizard(
      tester,
      profile: FakeContractorProfileRepository(null),
    );
    await goNext(tester);

    await goNext(tester);
    expect(find.text('Укажите ФИО исполнителя'), findsOneWidget);
    expect(find.text('Укажите ОГРНИП'), findsOneWidget);
    expect(find.text('Шаг 2 из 5'), findsOneWidget);
  });

  testWidgets('валидирует ИНН заказчика и стоимость', (tester) async {
    await pumpWizard(tester);
    await goNext(tester);
    await goNext(tester);

    await tester.enterText(
      find.byKey(const Key('field_clientName')),
      'ООО «Ромашка»',
    );
    await tester.enterText(find.byKey(const Key('field_clientInn')), '7701234');
    await goNext(tester);

    expect(find.text('ИНН: 10 или 12 цифр'), findsOneWidget);
    expect(find.text('Шаг 3 из 5'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('field_clientInn')),
      '7701234567',
    );
    await goNext(tester);

    await tester.enterText(find.byKey(const Key('field_amount')), '0');
    await goNext(tester);

    expect(find.text('Стоимость должна быть больше нуля'), findsOneWidget);
    expect(find.text('Шаг 4 из 5'), findsOneWidget);
  });

  testWidgets(
    'показывает живой предпросмотр документа с подставленными полями',
    (tester) async {
      await pumpWizard(tester);
      await fillClientAndSubject(tester);

      // Шаг 4 — предпросмотр: документ собран из заполненных полей.
      expect(find.text('Шаг 5 из 5'), findsOneWidget);
      expect(
        find.textContaining('описание предмета: разработка сайта и приложения'),
        findsWidgets,
      );
      expect(find.textContaining('{{'), findsNothing);
      expect(find.textContaining('ООО «Ромашка»'), findsWidgets);
      expect(find.textContaining('Иванов Иван Иванович'), findsWidgets);
    },
  );

  testWidgets('предпросмотр обновляется при изменении полей', (tester) async {
    await pumpWizard(tester);

    // Открываем живой предпросмотр с первого шага.
    await tester.enterText(
      find.byKey(const Key('field_contractCity')),
      'Казань',
    );
    await tester.tap(find.byKey(const Key('wizard_live_preview_button')));
    await tester.pumpAndSettle();

    expect(find.text('Предпросмотр договора'), findsOneWidget);
    expect(find.textContaining('г. Казань'), findsWidgets);

    // Закрываем лист и меняем поле — контент предпросмотра меняется.
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('field_contractCity')),
      'Москва',
    );
    await tester.tap(find.byKey(const Key('wizard_live_preview_button')));
    await tester.pumpAndSettle();

    expect(find.textContaining('г. Москва'), findsWidgets);
    expect(find.textContaining('г. Казань'), findsNothing);
  });

  testWidgets(
    'создаёт черновик и PDF: показывает лист предпросмотра, сохраняет',
    (tester) async {
      await pumpWizard(tester);
      await fillClientAndSubject(tester);

      final createButton = find.byKey(const Key('wizard_create_pdf_button'));
      await tester.ensureVisible(createButton);
      await tester.pumpAndSettle();
      await tester.tap(createButton);
      await tester.pumpAndSettle();

      // Bottom sheet предпросмотра готового PDF.
      expect(find.byKey(const Key('pdf_preview_sheet')), findsOneWidget);
      expect(find.text('Предпросмотр PDF'), findsOneWidget);
      expect(find.byKey(const Key('pdf_share_button')), findsOneWidget);
      expect(find.byKey(const Key('pdf_save_button')), findsOneWidget);

      // Генератор получил документ с подставленными полями.
      expect(pdfGenerator!.documents, hasLength(1));
      expect(pdfGenerator!.documents.single.plainText, contains('ООО «Ромашка»'));
      expect(pdfGenerator!.documents.single.plainText, isNot(contains('{{')));

      // Сохраняем PDF через кнопку листа.
      await tester.tap(find.byKey(const Key('pdf_save_button')));
      await tester.pumpAndSettle();

      expect(shareService!.saved, 1);
      expect(popResult, isTrue);
      expect(usedDrafts!.drafts, hasLength(1));
      final draft = usedDrafts!.drafts.single;
      expect(draft.templateId, 'it_software_development');
      expect(draft.status, ContractStatus.draft);
      final fields = contractFieldsToMap(draft.filledFields);
      expect(fields[ContractFieldKeys.clientName], 'ООО «Ромашка»');
      expect(fields[ContractFieldKeys.executorBankAccount],
          ContractorProfile.demo.bankAccount);
    },
  );

  testWidgets('показывает ошибку и разблокирует кнопку при сбое сохранения', (
    tester,
  ) async {
    await pumpWizard(tester, failingRepository: true);
    await fillClientAndSubject(tester);

    final createButton = find.byKey(const Key('wizard_create_pdf_button'));
    await tester.ensureVisible(createButton);
    await tester.pumpAndSettle();
    await tester.tap(createButton);
    await tester.pumpAndSettle();

    expect(
      find.text('Не удалось сохранить черновик. Попробуйте ещё раз.'),
      findsOneWidget,
    );
    final button = tester.widget<FilledButton>(createButton);
    expect(button.onPressed, isNotNull);
  });
}

class _WizardHost extends StatelessWidget {
  final Widget Function(BuildContext context) onOpened;
  final void Function(bool? value) onResult;

  const _WizardHost({required this.onOpened, required this.onResult});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          key: const Key('open_wizard'),
          onPressed: () async {
            final result = await Navigator.of(context)
                .push<bool>(MaterialPageRoute(builder: onOpened));
            onResult(result);
          },
          child: const Text('Открыть мастер'),
        ),
      ),
    );
  }
}

class _FakeTemplateTextLoader implements ContractTemplateTextLoader {
  final String text;
  const _FakeTemplateTextLoader(this.text);

  @override
  Future<String> load(String code) async => text;
}

class _FakePdfGenerator {
  final List<ComposedContract> documents = [];
  final List<String> fileNames = [];

  Future<GeneratedContractPdf> generate(
    ComposedContract document,
    String fileName,
  ) async {
    documents.add(document);
    fileNames.add(fileName);
    return GeneratedContractPdf(
      bytes: Uint8List.fromList([37, 80, 68, 70]),
      pageCount: 2,
      fileName: fileName,
      generationTime: const Duration(milliseconds: 10),
    );
  }
}

class _FakeShareService implements ContractPdfShareService {
  int shared = 0;
  int saved = 0;

  @override
  Future<void> share(GeneratedContractPdf pdf) async {
    shared++;
  }

  @override
  Future<String> saveToDocuments(GeneratedContractPdf pdf) async {
    saved++;
    return 'path/${pdf.fileName}';
  }
}
