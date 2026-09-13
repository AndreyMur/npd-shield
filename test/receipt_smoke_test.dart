import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:npd_shield/core/constants/contract_field_keys.dart';
import 'package:npd_shield/data/models/contract_draft.dart';
import 'package:npd_shield/data/models/document.dart';
import 'package:npd_shield/data/models/transaction.dart';
import 'package:npd_shield/data/pdf/contract_pdf_share_service.dart';
import 'package:npd_shield/data/pdf/generated_pdf.dart';
import 'package:npd_shield/domain/profile/contractor_profile.dart';
import 'package:npd_shield/presentation/contracts/contract_archive_screen.dart';

import 'helpers/fake_contract_repositories.dart';
import 'helpers/fake_document_repository.dart';
import 'helpers/fake_transaction_repository.dart';

/// Сквозной smoke-тест трассирующей пули фазы 16.
///
/// Путь пользователя: договор в архиве → завершение сделки →
/// автоформирование чека → сохранение документа → генерация PDF.
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

  testWidgets(
    'smoke: договор → завершение сделки → чек в архиве → PDF',
    (tester) async {
      tester.view.physicalSize = const Size(900, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final drafts = FakeContractDraftRepository([signedDraft()]);
      final documents = FakeDocumentRepository();
      final transactions = FakeTransactionRepository();
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
            transactionRepository: transactions,
            receiptPdfGenerator: (receipt, fileName) async {
              generatedPdf = GeneratedPdf(
                bytes: Uint8List.fromList(const [37, 80, 68, 70]),
                pageCount: 1,
                fileName: fileName,
                generationTime: const Duration(milliseconds: 5),
              );
              return generatedPdf!;
            },
            shareService: share,
            previewBuilder: () =>
                const SizedBox(key: Key('fake_receipt_preview')),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Открываем действие «Завершить сделку» в карточке договора.
      await tester.tap(find.byKey(const Key('contract_menu_1')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Завершить сделку'));
      await tester.pumpAndSettle();

      expect(find.text('Завершение сделки'), findsOneWidget);

      // 2. Завершаем сделку: чек формируется автоматически.
      final completeButton = find.byKey(const Key('complete_deal_button'));
      await tester.ensureVisible(completeButton);
      await tester.pumpAndSettle();
      await tester.tap(completeButton);
      await tester.pumpAndSettle();

      // 3. PDF показан, документ и транзакция сохранены.
      expect(find.byKey(const Key('fake_receipt_preview')), findsOneWidget);
      expect(generatedPdf, isNotNull);
      expect(generatedPdf!.fileName, startsWith('receipt_'));

      expect(documents.documents, hasLength(1));
      final document = documents.documents.single;
      expect(document.type, DocumentType.receipt);
      expect(document.contractDraftId, 1);
      expect(document.counterpartyName, 'ООО «Ромашка»');
      expect(document.amount, 150000);
      expect(document.transactionId, isNot(0));

      expect(transactions.transactions, hasLength(1));
      expect(transactions.transactions.single.amount, 150000);
      expect(
        transactions.transactions.single.sphere,
        TransactionSphere.it,
      );

      // 4. Закрываем лист предпросмотра PDF — экран завершения закрывается,
      //    снова виден архив.
      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();

      expect(find.text('Мои договоры'), findsOneWidget);
      expect(find.text('Завершение сделки'), findsNothing);
      expect(share.saved, 0);
    },
  );
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
