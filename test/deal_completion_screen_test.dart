import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:npd_shield/core/constants/contract_field_keys.dart';
import 'package:npd_shield/data/models/contract_draft.dart';
import 'package:npd_shield/data/models/document.dart';
import 'package:npd_shield/data/models/transaction.dart';
import 'package:npd_shield/data/pdf/contract_pdf_share_service.dart';
import 'package:npd_shield/data/pdf/generated_pdf.dart';
import 'package:npd_shield/domain/documents/my_tax_deep_link_service.dart';
import 'package:npd_shield/domain/profile/contractor_profile.dart';
import 'package:npd_shield/presentation/documents/deal_completion_screen.dart';

import 'helpers/fake_contract_repositories.dart';
import 'helpers/fake_document_repository.dart';
import 'helpers/fake_my_tax.dart';
import 'helpers/fake_transaction_repository.dart';

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

  Widget wrap({
    required FakeDocumentRepository documents,
    required FakeTransactionRepository transactions,
    FakeContractorProfileRepository? profiles,
    _FakeShareService? share,
    MyTaxDeepLinkService? myTaxService,
  }) {
    return MaterialApp(
      home: DealCompletionScreen(
        draft: signedDraft(),
        templateTitle: 'Разработка ПО',
        profileRepository: profiles ?? FakeContractorProfileRepository(
          ContractorProfile.demo,
        ),
        documentRepository: documents,
        transactionRepository: transactions,
        sphere: TransactionSphere.it,
        pdfGenerator: (receipt, fileName) async => GeneratedPdf(
          bytes: Uint8List.fromList(const [37, 80, 68, 70]),
          pageCount: 1,
          fileName: fileName,
          generationTime: const Duration(milliseconds: 5),
        ),
        shareService: share ?? _FakeShareService(),
        previewBuilder: () => const SizedBox(key: Key('fake_receipt_preview')),
        myTaxService: myTaxService ?? const MyTaxDeepLinkService(),
        now: DateTime(2026, 9, 5),
      ),
    );
  }

  testWidgets('поля чека предзаполняются из профиля ИП и договора', (
    tester,
  ) async {
    _setViewport(tester);
    await tester.pumpWidget(
      wrap(
        documents: FakeDocumentRepository(),
        transactions: FakeTransactionRepository(),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      _fieldText(tester, 'receipt_service_field'),
      'Разработка сайта',
    );
    expect(_fieldText(tester, 'receipt_amount_field'), '150000.00');
    expect(_fieldText(tester, 'receipt_buyer_name_field'), 'ООО «Ромашка»');
    expect(_fieldText(tester, 'receipt_buyer_inn_field'), '7701234567');
    expect(_fieldText(tester, 'receipt_date_field'), '05.09.2026');
  });

  testWidgets(
    'завершение сделки сохраняет чек, записывает доход и показывает PDF',
    (tester) async {
      _setViewport(tester);
      final documents = FakeDocumentRepository();
      final transactions = FakeTransactionRepository();
      final share = _FakeShareService();

      await tester.pumpWidget(
        wrap(
          documents: documents,
          transactions: transactions,
          share: share,
        ),
      );
      await tester.pumpAndSettle();

      final button = find.byKey(const Key('complete_deal_button'));
      await tester.ensureVisible(button);
      await tester.pumpAndSettle();
      await tester.tap(button);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('fake_receipt_preview')), findsOneWidget);
      expect(documents.documents, hasLength(1));

      final document = documents.documents.single;
      expect(document.type, DocumentType.receipt);
      expect(document.status, DocumentStatus.generated);
      expect(document.contractDraftId, 1);
      expect(document.contractNumber, '14/09');
      expect(document.amount, 150000);
      expect(document.counterpartyName, 'ООО «Ромашка»');
      expect(document.issuerInn, ContractorProfile.demo.inn);
      expect(document.transactionId, isNot(0));

      expect(transactions.transactions, hasLength(1));
      final transaction = transactions.transactions.single;
      expect(transaction.amount, 150000);
      expect(transaction.clientName, 'ООО «Ромашка»');
      expect(transaction.sphere, TransactionSphere.it);
    },
  );

  testWidgets('редактирование суммы отражается в сохранённом чеке', (
    tester,
  ) async {
    _setViewport(tester);
    final documents = FakeDocumentRepository();
    await tester.pumpWidget(
      wrap(
        documents: documents,
        transactions: FakeTransactionRepository(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('receipt_amount_field')),
      '200000',
    );
    await tester.tap(find.byKey(const Key('complete_deal_button')));
    await tester.pumpAndSettle();

    expect(documents.documents.single.amount, 200000);
  });

  testWidgets('пустое наименование услуги не проходит валидацию', (
    tester,
  ) async {
    _setViewport(tester);
    final documents = FakeDocumentRepository();
    await tester.pumpWidget(
      wrap(
        documents: documents,
        transactions: FakeTransactionRepository(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('receipt_service_field')), '');
    await tester.tap(find.byKey(const Key('complete_deal_button')));
    await tester.pumpAndSettle();

    expect(find.text('Укажите наименование услуги'), findsOneWidget);
    expect(documents.documents, isEmpty);
  });

  testWidgets('кнопка «Мой налог» открывает deep link с данными чека', (
    tester,
  ) async {
    _setViewport(tester);
    final launcher = FakeExternalAppLauncher();
    final clipboard = FakeClipboardWriter();
    await tester.pumpWidget(
      wrap(
        documents: FakeDocumentRepository(),
        transactions: FakeTransactionRepository(),
        myTaxService: MyTaxDeepLinkService(
          launcher: launcher,
          clipboard: clipboard,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('open_my_tax_button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('my_tax_open_button')), findsOneWidget);
    await tester.tap(find.byKey(const Key('my_tax_open_button')));
    await tester.pumpAndSettle();

    final uri = launcher.opened.single;
    expect(uri.queryParameters['amount'], '150000.00');
    expect(uri.queryParameters['client'], 'ООО «Ромашка»');
    expect(uri.queryParameters['type'], 'income_from_organization');
  });
}

void _setViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(1000, 2400);
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
