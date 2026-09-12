import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:npd_shield/core/constants/contract_field_keys.dart';
import 'package:npd_shield/data/models/contract_draft.dart';
import 'package:npd_shield/data/pdf/contract_pdf_service.dart';
import 'package:npd_shield/data/pdf/contract_pdf_share_service.dart';
import 'package:npd_shield/data/repositories/contract_template_text_loader.dart';
import 'package:npd_shield/domain/profile/contractor_profile.dart';
import 'package:npd_shield/presentation/contracts/contract_archive_screen.dart';
import 'package:npd_shield/presentation/contracts/contract_library_screen.dart';

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

Заказчик:
{{clientName}}
ИНН {{clientInn}}
Адрес: {{clientAddress}}

_______________________ / {{executorFullName}} /
''';

/// Сквозной smoke-тест модуля генератора договоров.
///
/// Проходит весь путь пользователя на реальных экранах с общими
/// репозиториями: выбор шаблона в библиотеке → заполнение мастера →
/// генерация настоящего PDF → сохранение → поиск в архиве.
void main() {
  late ContractPdfFonts fonts;

  setUpAll(() async {
    fonts = ContractPdfFonts(
      regular: await File('assets/fonts/Roboto-Regular.ttf').readAsBytes(),
      bold: await File('assets/fonts/Roboto-Bold.ttf').readAsBytes(),
    );
  });

  testWidgets(
    'smoke: выбор шаблона → заполнение → PDF → сохранение → поиск',
    (tester) async {
      tester.view.physicalSize = const Size(1000, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final drafts = FakeContractDraftRepository();
      final templates = FakeContractTemplateRepository([
        template(
          code: 'it_software_development',
          title: 'Разработка ПО',
          okved: '62.01',
          recommended: true,
        ),
      ]);
      final share = _FakeShareService();

      // 1. Библиотека шаблонов — выбор шаблона.
      await tester.pumpWidget(
        MaterialApp(
          home: ContractLibraryScreen(
            templateRepository: templates,
            draftRepository: drafts,
            profileRepository: FakeContractorProfileRepository(
              ContractorProfile.demo,
            ),
            templateTextLoader: const _FakeTemplateTextLoader(_templateText),
            pdfGenerator: (document, fileName) => ContractPdfService().generate(
              document: document,
              fonts: fonts,
              fileName: fileName,
            ),
            shareService: share,
            previewBuilder: () =>
                const SizedBox(key: Key('fake_pdf_preview')),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const Key('template_card_it_software_development')),
      );
      await tester.pumpAndSettle();
      expect(find.text('Новый договор'), findsOneWidget);

      // 2. Заполнение мастера (5 шагов).
      Future<void> next() async {
        final button = find.byKey(const Key('wizard_next_button'));
        await tester.ensureVisible(button);
        await tester.pumpAndSettle();
        await tester.tap(button);
        await tester.pumpAndSettle();
      }

      await next(); // Параметры → Исполнитель (реквизиты из профиля).
      await next(); // Исполнитель → Заказчик.
      await tester.enterText(
        find.byKey(const Key('field_clientName')),
        'ООО «Ромашка»',
      );
      await tester.enterText(
        find.byKey(const Key('field_clientInn')),
        '7701234567',
      );
      await next(); // Заказчик → Предмет и стоимость.
      await tester.enterText(
        find.byKey(const Key('field_subject')),
        'разработка сайта',
      );
      await tester.enterText(find.byKey(const Key('field_amount')), '150000');
      await next(); // Предмет → Предпросмотр.

      // 3. Генерация PDF из реального сервиса.
      final createButton = find.byKey(const Key('wizard_create_pdf_button'));
      await tester.ensureVisible(createButton);
      await tester.pumpAndSettle();
      await tester.tap(createButton);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('pdf_preview_sheet')), findsOneWidget);

      // 4. Сохранение PDF и черновика.
      await tester.tap(find.byKey(const Key('pdf_save_button')));
      await tester.pumpAndSettle();

      expect(share.saved, 1);
      expect(share.lastPdf, isNotNull);
      expect(share.lastPdf!.bytes, isNotEmpty);
      expect(
        String.fromCharCodes(share.lastPdf!.bytes.take(4)),
        '%PDF',
      );
      expect(drafts.drafts, hasLength(1));
      final fields = contractFieldsToMap(drafts.drafts.single.filledFields);
      expect(fields[ContractFieldKeys.clientName], 'ООО «Ромашка»');
      expect(fields[ContractFieldKeys.subject], 'разработка сайта');

      // 5. Архив — поиск по созданному договору.
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

      expect(find.text('Разработка ПО'), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('contract_search_field')),
        'Ромашка',
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('ООО «Ромашка»'), findsOneWidget);
    },
  );
}

class _FakeTemplateTextLoader implements ContractTemplateTextLoader {
  final String text;
  const _FakeTemplateTextLoader(this.text);

  @override
  Future<String> load(String code) async => text;
}

class _FakeShareService implements ContractPdfShareService {
  int saved = 0;
  GeneratedContractPdf? lastPdf;

  @override
  Future<void> share(GeneratedContractPdf pdf) async {}

  @override
  Future<String> saveToDocuments(GeneratedContractPdf pdf) async {
    saved++;
    lastPdf = pdf;
    return 'path/${pdf.fileName}';
  }
}
