import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:npd_shield/core/constants/contract_field_keys.dart';
import 'package:npd_shield/data/models/contract_draft.dart';
import 'package:npd_shield/data/models/document.dart';
import 'package:npd_shield/data/pdf/contract_pdf_share_service.dart';
import 'package:npd_shield/data/pdf/generated_pdf.dart';
import 'package:npd_shield/domain/profile/contractor_profile.dart';
import 'package:npd_shield/presentation/contracts/contract_archive_screen.dart';

import 'helpers/fake_contract_repositories.dart';
import 'helpers/fake_document_repository.dart';

/// Сквозной smoke-тест фазы 17.
///
/// Путь пользователя: договор в архиве → «Создать акт» → автозаполнение из
/// договора и чека → автосохранение в архив → формирование PDF с подписями.
void main() {
  ContractDraft signedDraft() {
    final draft = ContractDraft(
      templateId: 'it_dev',
      filledFields: contractFieldsFromMap({
        ContractFieldKeys.contractNumber: '14/09',
        ContractFieldKeys.contractDate: '05.09.2026',
        ContractFieldKeys.clientName: 'ООО «Ромашка»',
        ContractFieldKeys.clientInn: '7701234567',
        ContractFieldKeys.subject: 'Разработка сайта',
        ContractFieldKeys.amount: '150000',
      }),
      status: ContractStatus.signed,
    );
    draft.id = 1;
    return draft;
  }

  testWidgets('smoke: договор → создание акта → автосохранение → PDF', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final drafts = FakeContractDraftRepository([signedDraft()]);
    final documents = FakeDocumentRepository();
    final receiptId = await documents.save(
      Document(
        type: DocumentType.receipt,
        status: DocumentStatus.generated,
        amount: 150000,
        date: DateTime(2026, 9, 5),
        contractDraftId: 1,
        contractNumber: '14/09',
        counterpartyName: 'ООО «Ромашка»',
        counterpartyInn: '7701234567',
        serviceName: 'Разработка сайта',
        issuerName: ContractorProfile.demo.fullName,
        issuerInn: ContractorProfile.demo.inn,
      ),
    );
    final share = _FakeShareService();
    GeneratedPdf? generatedPdf;

    await tester.pumpWidget(
      MaterialApp(
        home: ContractArchiveScreen(
          draftRepository: drafts,
          templateRepository: FakeContractTemplateRepository([
            template(code: 'it_dev', title: 'Разработка ПО'),
          ]),
          profileRepository: FakeContractorProfileRepository(
            ContractorProfile.demo,
          ),
          documentRepository: documents,
          actPdfGenerator: (act, fileName) async {
            generatedPdf = GeneratedPdf(
              bytes: Uint8List.fromList(const [37, 80, 68, 70]),
              pageCount: 1,
              fileName: fileName,
              generationTime: const Duration(milliseconds: 5),
            );
            return generatedPdf!;
          },
          shareService: share,
          previewBuilder: () => const SizedBox(key: Key('fake_act_preview')),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 1. Открываем действие «Создать акт» в карточке договора.
    await tester.tap(find.byKey(const Key('contract_menu_1')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Создать акт'));
    await tester.pumpAndSettle();

    expect(find.text('Акт выполненных работ'), findsOneWidget);

    // 2. Акт уже автосохранён в архив с привязками к договору и чеку.
    final acts = documents.documents.where((d) => d.type == DocumentType.act);
    expect(acts, hasLength(1));
    final act = acts.single;
    expect(act.status, DocumentStatus.draft);
    expect(act.contractDraftId, 1);
    expect(act.receiptDocumentId, receiptId);

    // 3. Формируем акт: PDF генерируется, статус меняется на «Сформирован».
    final button = find.byKey(const Key('act_finalize_button'));
    await tester.ensureVisible(button);
    await tester.pumpAndSettle();
    await tester.tap(button);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('fake_act_preview')), findsOneWidget);
    expect(generatedPdf, isNotNull);
    expect(generatedPdf!.fileName, startsWith('act_'));
    expect(
      documents.documents
          .singleWhere((d) => d.type == DocumentType.act)
          .status,
      DocumentStatus.generated,
    );

    // 4. Закрываем лист предпросмотра — снова виден архив.
    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();

    expect(find.text('Мои договоры'), findsOneWidget);
    expect(share.saved, 0);
  });
}

class _FakeShareService implements ContractPdfShareService {
  int saved = 0;

  @override
  Future<void> share(GeneratedPdf pdf) async {}

  @override
  Future<String> saveToDocuments(GeneratedPdf pdf) async {
    saved++;
    return 'path/${pdf.fileName}';
  }
}
