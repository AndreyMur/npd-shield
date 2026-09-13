import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:npd_shield/core/constants/contract_field_keys.dart';
import 'package:npd_shield/data/models/contract_draft.dart';
import 'package:npd_shield/data/models/document.dart';
import 'package:npd_shield/data/pdf/contract_pdf_share_service.dart';
import 'package:npd_shield/data/pdf/generated_pdf.dart';
import 'package:npd_shield/domain/documents/act.dart';
import 'package:npd_shield/domain/profile/contractor_profile.dart';
import 'package:npd_shield/presentation/documents/act_screen.dart';

import 'helpers/fake_contract_repositories.dart';
import 'helpers/fake_document_repository.dart';

void main() {
  ContractDraft signedDraft() {
    final draft = ContractDraft(
      templateId: 'it_software_development',
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

  Document receiptDocument() {
    return Document(
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
    );
  }

  Widget wrap({
    required FakeDocumentRepository documents,
    _FakeShareService? share,
  }) {
    return MaterialApp(
      home: ActScreen(
        draft: signedDraft(),
        templateTitle: 'Разработка ПО',
        profileRepository: FakeContractorProfileRepository(
          ContractorProfile.demo,
        ),
        documentRepository: documents,
        pdfGenerator: (act, fileName) async => GeneratedPdf(
          bytes: Uint8List.fromList(const [37, 80, 68, 70]),
          pageCount: 1,
          fileName: fileName,
          generationTime: const Duration(milliseconds: 5),
        ),
        shareService: share ?? _FakeShareService(),
        previewBuilder: () => const SizedBox(key: Key('fake_act_preview')),
        autosaveDebounce: Duration.zero,
        now: DateTime(2026, 9, 5),
      ),
    );
  }

  testWidgets('поля акта предзаполняются из профиля ИП и договора', (
    tester,
  ) async {
    _setViewport(tester);
    await tester.pumpWidget(wrap(documents: FakeDocumentRepository()));
    await tester.pumpAndSettle();

    expect(_fieldText(tester, 'act_works_field'), 'Разработка сайта');
    expect(_fieldText(tester, 'act_result_field'), defaultActResult);
    expect(_fieldText(tester, 'act_amount_field'), '150000.00');
    expect(_fieldText(tester, 'act_date_field'), '05.09.2026');
    expect(
      _fieldText(tester, 'act_executor_signatory_field'),
      ContractorProfile.demo.fullName,
    );
    expect(_fieldText(tester, 'act_customer_signatory_field'), 'ООО «Ромашка»');
  });

  testWidgets('акт автосохраняется при создании с привязками к договору и чеку',
      (tester) async {
    _setViewport(tester);
    final documents = FakeDocumentRepository();
    final receiptId = await documents.save(receiptDocument());

    await tester.pumpWidget(wrap(documents: documents));
    await tester.pumpAndSettle();

    final acts = documents.documents.where((d) => d.type == DocumentType.act);
    expect(acts, hasLength(1));
    final act = acts.single;
    expect(act.status, DocumentStatus.draft);
    expect(act.contractDraftId, 1);
    expect(act.contractNumber, '14/09');
    expect(act.receiptDocumentId, receiptId);
    expect(act.amount, 150000);
    expect(act.executorSignatory, ContractorProfile.demo.fullName);
    expect(act.customerSignatory, 'ООО «Ромашка»');

    // В карточке документа видны связи с договором и чеком.
    expect(find.byKey(const Key('document_link_contract')), findsOneWidget);
    expect(find.byKey(const Key('document_link_receipt')), findsOneWidget);
  });

  testWidgets('редактирование поля обновляет автосохранённый акт без дублей', (
    tester,
  ) async {
    _setViewport(tester);
    final documents = FakeDocumentRepository();
    await tester.pumpWidget(wrap(documents: documents));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('act_amount_field')),
      '200000',
    );
    await tester.pumpAndSettle();

    final acts = documents.documents.where((d) => d.type == DocumentType.act);
    expect(acts, hasLength(1));
    expect(acts.single.amount, 200000);
  });

  testWidgets('формирование акта сохраняет статус и показывает PDF', (
    tester,
  ) async {
    _setViewport(tester);
    final documents = FakeDocumentRepository();
    await tester.pumpWidget(wrap(documents: documents));
    await tester.pumpAndSettle();

    final button = find.byKey(const Key('act_finalize_button'));
    await tester.ensureVisible(button);
    await tester.pumpAndSettle();
    await tester.tap(button);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('fake_act_preview')), findsOneWidget);
    final act = documents.documents.singleWhere(
      (d) => d.type == DocumentType.act,
    );
    expect(act.status, DocumentStatus.generated);
  });

  testWidgets('пустое описание работ не проходит валидацию', (tester) async {
    _setViewport(tester);
    final documents = FakeDocumentRepository();
    await tester.pumpWidget(wrap(documents: documents));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('act_works_field')), '');
    final button = find.byKey(const Key('act_finalize_button'));
    await tester.ensureVisible(button);
    await tester.pumpAndSettle();
    await tester.tap(button);
    await tester.pumpAndSettle();

    expect(find.text('Укажите описание работ'), findsOneWidget);
    expect(find.byKey(const Key('fake_act_preview')), findsNothing);
    final act = documents.documents.singleWhere(
      (d) => d.type == DocumentType.act,
    );
    expect(act.status, DocumentStatus.draft);
  });
}

void _setViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(1000, 2600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

String _fieldText(WidgetTester tester, String key) {
  final field = tester.widget<TextFormField>(find.byKey(Key(key)));
  return field.controller?.text ?? '';
}

class _FakeShareService implements ContractPdfShareService {
  @override
  Future<void> share(GeneratedPdf pdf) async {}

  @override
  Future<String> saveToDocuments(GeneratedPdf pdf) async =>
      'path/${pdf.fileName}';
}
