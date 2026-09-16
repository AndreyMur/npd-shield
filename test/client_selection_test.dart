import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:npd_shield/core/constants/contract_field_keys.dart';
import 'package:npd_shield/data/models/client.dart';
import 'package:npd_shield/data/models/contract_draft.dart';
import 'package:npd_shield/data/models/document.dart';
import 'package:npd_shield/data/pdf/contract_pdf_service.dart';
import 'package:npd_shield/data/pdf/contract_pdf_share_service.dart';
import 'package:npd_shield/data/pdf/generated_pdf.dart';
import 'package:npd_shield/data/repositories/contract_template_text_loader.dart';
import 'package:npd_shield/domain/contracts/contract_document.dart';
import 'package:npd_shield/domain/documents/my_tax_deep_link.dart';
import 'package:npd_shield/domain/profile/contractor_profile.dart';
import 'package:npd_shield/presentation/contracts/contract_wizard_screen.dart';
import 'package:npd_shield/presentation/documents/deal_completion_screen.dart';
import 'package:npd_shield/presentation/operations/transaction_form_screen.dart';

import 'helpers/fake_client_repository.dart';
import 'helpers/fake_contract_repositories.dart';
import 'helpers/fake_document_repository.dart';
import 'helpers/fake_transaction_repository.dart';

const _templateText = '''
ДОГОВОР № {{contractNumber}}
Заказчик: {{clientName}}
ИНН {{clientInn}}
Предмет: {{subject}}
Сумма: {{amount}}
''';

void main() {
  Client client() {
    final value = Client(
      name: 'ООО «Альфа»',
      inn: '7701234567',
      type: ClientType.legal,
    );
    value.id = 1;
    return value;
  }

  String fieldText(WidgetTester tester, String key) {
    final field = tester.widget<TextFormField>(find.byKey(Key(key)));
    return field.controller?.text ?? '';
  }

  void setViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(1000, 2200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
  }

  testWidgets('операция: клиент выбирается из справочника и сохраняется связь', (
    tester,
  ) async {
    setViewport(tester);
    final clients = FakeClientRepository([client()]);
    final transactions = FakeTransactionRepository();

    await tester.pumpWidget(
      MaterialApp(
        home: TransactionFormScreen(
          repository: transactions,
          clientRepository: clients,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('transaction_pick_client_button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('client_picker_option_1')));
    await tester.pumpAndSettle();

    expect(fieldText(tester, 'transaction_client_name_field'), 'ООО «Альфа»');
    expect(fieldText(tester, 'transaction_client_inn_field'), '7701234567');

    await tester.enterText(
      find.byKey(const Key('transaction_amount_field')),
      '1000',
    );
    await tester.tap(find.byKey(const Key('transaction_save_button')));
    await tester.pumpAndSettle();

    expect(transactions.transactions, hasLength(1));
    expect(transactions.transactions.single.clientId, 1);
    expect(transactions.transactions.single.clientName, 'ООО «Альфа»');
  });

  testWidgets('договор: заказчик выбирается из справочника и сохраняется связь', (
    tester,
  ) async {
    setViewport(tester);
    final clients = FakeClientRepository([client()]);
    final drafts = FakeContractDraftRepository();
    final documents = FakeDocumentRepository();
    final pdfGenerator = _FakePdfGenerator();
    final shareService = _FakeShareService();

    await tester.pumpWidget(
      MaterialApp(
        home: ContractWizardScreen(
          template: template(),
          draftRepository: drafts,
          profileRepository: FakeContractorProfileRepository(
            ContractorProfile.demo,
          ),
          templateTextLoader: const _FakeTemplateTextLoader(_templateText),
          pdfGenerator: pdfGenerator.generate,
          shareService: shareService,
          documentRepository: documents,
          clientRepository: clients,
          previewBuilder: () => const SizedBox(key: Key('fake_pdf_preview')),
        ),
      ),
    );
    await tester.pumpAndSettle();

    Future<void> goNext() async {
      final button = find.byKey(const Key('wizard_next_button'));
      await tester.ensureVisible(button);
      await tester.pumpAndSettle();
      await tester.tap(button);
      await tester.pumpAndSettle();
    }

    await goNext(); // Параметры договора
    await goNext(); // Исполнитель

    // Шаг «Заказчик»: выбираем клиента из справочника.
    await tester.tap(find.byKey(const Key('wizard_pick_client_button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('client_picker_option_1')));
    await tester.pumpAndSettle();

    expect(fieldText(tester, 'field_clientName'), 'ООО «Альфа»');
    expect(fieldText(tester, 'field_clientInn'), '7701234567');

    await goNext(); // Предмет и стоимость
    await tester.enterText(find.byKey(const Key('field_subject')), 'Услуги');
    await tester.enterText(find.byKey(const Key('field_amount')), '150000');
    await goNext(); // Предпросмотр

    final createButton = find.byKey(const Key('wizard_create_pdf_button'));
    await tester.ensureVisible(createButton);
    await tester.pumpAndSettle();
    await tester.tap(createButton);
    await tester.pumpAndSettle();

    expect(drafts.drafts, hasLength(1));
    expect(drafts.drafts.single.clientId, 1);

    final contract = documents.documents.firstWhere(
      (d) => d.type == DocumentType.contract,
    );
    expect(contract.clientId, 1);
    expect(contract.counterpartyName, 'ООО «Альфа»');
  });

  testWidgets('чек: покупатель выбирается из справочника и сохраняется связь', (
    tester,
  ) async {
    setViewport(tester);
    final clients = FakeClientRepository([client()]);
    final documents = FakeDocumentRepository();
    final transactions = FakeTransactionRepository();

    final draft = ContractDraft(
      templateId: 'it_software_development',
      filledFields: contractFieldsFromMap({
        ContractFieldKeys.clientName: 'Черновик',
        ContractFieldKeys.subject: 'Разработка сайта',
        ContractFieldKeys.amount: '150000',
      }),
      status: ContractStatus.signed,
    );
    draft.id = 1;

    await tester.pumpWidget(
      MaterialApp(
        home: DealCompletionScreen(
          draft: draft,
          templateTitle: 'Разработка ПО',
          profileRepository: FakeContractorProfileRepository(
            ContractorProfile.demo,
          ),
          documentRepository: documents,
          transactionRepository: transactions,
          clientRepository: clients,
          pdfGenerator: (receipt, fileName) async => GeneratedPdf(
            bytes: Uint8List.fromList(const [37, 80, 68, 70]),
            pageCount: 1,
            fileName: fileName,
            generationTime: const Duration(milliseconds: 5),
          ),
          shareService: _FakeShareService(),
          previewBuilder: () =>
              const SizedBox(key: Key('fake_receipt_preview')),
          now: DateTime(2026, 9, 5),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('receipt_pick_client_button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('client_picker_option_1')));
    await tester.pumpAndSettle();

    expect(fieldText(tester, 'receipt_buyer_name_field'), 'ООО «Альфа»');
    expect(fieldText(tester, 'receipt_buyer_inn_field'), '7701234567');

    final button = find.byKey(const Key('complete_deal_button'));
    await tester.ensureVisible(button);
    await tester.pumpAndSettle();
    await tester.tap(button);
    await tester.pumpAndSettle();

    expect(transactions.transactions.single.clientId, 1);
    final receipt = documents.documents.firstWhere(
      (d) => d.type == DocumentType.receipt,
    );
    expect(receipt.clientId, 1);
    expect(receipt.counterpartyName, 'ООО «Альфа»');
  });
}

class _FakeTemplateTextLoader implements ContractTemplateTextLoader {
  final String text;
  const _FakeTemplateTextLoader(this.text);

  @override
  Future<String> load(String code) async => text;
}

class _FakePdfGenerator {
  Future<GeneratedContractPdf> generate(
    ComposedContract document,
    String fileName,
  ) async {
    return GeneratedContractPdf(
      bytes: Uint8List.fromList(const [37, 80, 68, 70]),
      pageCount: 1,
      fileName: fileName,
      generationTime: const Duration(milliseconds: 5),
    );
  }
}

class _FakeShareService implements ContractPdfShareService {
  @override
  Future<void> share(GeneratedContractPdf pdf) async {}

  @override
  Future<String> saveToDocuments(GeneratedContractPdf pdf) async =>
      'path/${pdf.fileName}';
}
