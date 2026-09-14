import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:npd_shield/core/constants/contract_field_keys.dart';
import 'package:npd_shield/data/models/document.dart';
import 'package:npd_shield/data/models/transaction.dart';
import 'package:npd_shield/data/pdf/contract_pdf_share_service.dart';
import 'package:npd_shield/data/pdf/generated_pdf.dart';
import 'package:npd_shield/domain/documents/act.dart';
import 'package:npd_shield/domain/documents/act_service.dart';
import 'package:npd_shield/domain/documents/deal_completion_service.dart';
import 'package:npd_shield/domain/documents/document_archive.dart';
import 'package:npd_shield/domain/documents/document_transaction_linker.dart';
import 'package:npd_shield/domain/documents/document_transaction_matcher.dart';
import 'package:npd_shield/domain/documents/legal_disclaimer.dart';
import 'package:npd_shield/domain/documents/my_tax_deep_link.dart';
import 'package:npd_shield/domain/profile/contractor_profile.dart';
import 'package:npd_shield/presentation/documents/document_archive_screen.dart';

import 'helpers/fake_document_repository.dart';
import 'helpers/fake_transaction_repository.dart';

/// Сквозной smoke-тест фазы 20.
///
/// Путь пользователя: сделка → чек → акт → deep link → архив → поиск →
/// привязка к транзакции. Проверяет все критерии готовности PRD, доступные
/// без реального устройства.
void main() {
  const fields = {
    ContractFieldKeys.contractNumber: '14/09',
    ContractFieldKeys.contractDate: '05.09.2026',
    ContractFieldKeys.clientName: 'ООО «Ромашка»',
    ContractFieldKeys.clientInn: '7701234567',
    ContractFieldKeys.subject: 'Разработка сайта',
    ContractFieldKeys.amount: '150000',
  };

  test('smoke: сделка → чек → акт → deep link → архив → поиск → привязка', () async {
    final documents = FakeDocumentRepository();
    final transactions = FakeTransactionRepository();
    const profile = ContractorProfile.demo;

    // 1. Завершение сделки: чек формируется автоматически.
    final completed = await const DealCompletionService().completeDeal(
      profile: profile,
      documentRepository: documents,
      contractFields: fields,
      contractDraftId: 1,
      date: DateTime(2026, 9, 5),
    );
    expect(completed.document.type, DocumentType.receipt);
    expect(completed.document.amount, 150000);
    expect(completed.document.transactionId, 0);

    // 2. Транзакция дашборда с теми же реквизитами расчёта.
    final transaction = Transaction(
      amount: 150000,
      date: DateTime(2026, 9, 5),
      sphere: TransactionSphere.it,
      clientName: 'ООО «Ромашка»',
      clientInn: '7701234567',
    );
    transaction.id = 1;
    await transactions.add(transaction);

    // 3. Акт выполненных работ формируется из чека и договора.
    final act = const ActGenerator().generate(
      profile: profile,
      contractFields: fields,
      receipt: completed.receipt,
      contractDraftId: 1,
      receiptDocumentId: completed.document.id,
    );
    final savedAct = await const ActService().save(
      act: act,
      documentRepository: documents,
      status: DocumentStatus.generated,
    );
    expect(savedAct.document.type, DocumentType.act);
    expect(savedAct.document.receiptDocumentId, completed.document.id);

    // 4. Deep link на «Мой налог» с предзаполненными данными.
    final link = MyTaxDeepLink.fromReceipt(completed.receipt);
    expect(link.uri.host, 'mynalog.ru');
    expect(link.uri.queryParameters['type'], ClientType.legal.code);
    expect(link.uri.queryParameters['amount'], '150000.00');
    expect(link.clipboardText, contains('150 000,00'));

    // 5. Архив: оба документа сохранены, поиск находит их.
    final archive = await documents.getAll();
    expect(archive, hasLength(2));
    expect(
      archive.where((d) => matchesDocumentQuery(d, 'ромашка')),
      hasLength(2),
    );
    expect(
      archive.where((d) => matchesDocumentQuery(d, '150000')),
      isNotEmpty,
    );

    // 6. Автоматическое сопоставление и фиксация привязки к транзакции.
    expect(documentMatchesTransaction(completed.document, transaction), isTrue);
    final linked = await const DocumentTransactionLinker().link(
      documentRepository: documents,
      transactions: transactions.transactions,
      documents: archive,
    );
    expect(linked, 2);
    final matches = matchDocumentsToTransactions(
      transactions: transactions.transactions,
      documents: await documents.getAll(),
    );
    expect(matches.single.documents, hasLength(2));
    expect(
      matches.single.documents.every((d) => d.transactionId == 1),
      isTrue,
    );

    // 7. Дисклеймер об ЭЦП доступен приложению.
    expect(kNoLegalForceDisclaimer, contains('ЭЦП'));
  });

  testWidgets('smoke: архив показывает дисклеймер и экспортирует документы', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1000, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final documents = FakeDocumentRepository([
      Document(
        type: DocumentType.receipt,
        status: DocumentStatus.generated,
        amount: 150000,
        date: DateTime(2026, 9, 5),
        contractNumber: '14/09',
        counterpartyName: 'ООО «Ромашка»',
        counterpartyInn: '7701234567',
        serviceName: 'Разработка сайта',
      )..id = 1,
      Document(
        type: DocumentType.contract,
        status: DocumentStatus.generated,
        amount: 150000,
        date: DateTime(2026, 9, 5),
        contractNumber: '14/09',
        counterpartyName: 'ООО «Ромашка»',
        serviceName: 'Разработка сайта',
        content: 'ДОГОВОР № 14/09\n\n1. ПРЕДМЕТ ДОГОВОРА\n\nРазработка сайта.',
      )..id = 2,
    ]);
    final share = _FakeShareService();

    await tester.pumpWidget(
      MaterialApp(
        home: DocumentArchiveScreen(
          documentRepository: documents,
          pdfGenerator: _fakePdf,
          shareService: share,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('document_archive_disclaimer')),
      findsOneWidget,
    );
    expect(find.textContaining('ЭЦП'), findsWidgets);

    // Экспорт договора из карточки документа.
    await tester.tap(find.byKey(const Key('document_entry_2')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('document_send_button')));
    await tester.pumpAndSettle();

    expect(share.shared, 1);
  });
}

Future<GeneratedPdf> _fakePdf(Document document) async => GeneratedPdf(
  bytes: Uint8List.fromList(const [37, 80, 68, 70]),
  pageCount: 1,
  fileName: 'doc.pdf',
  generationTime: const Duration(milliseconds: 1),
);

class _FakeShareService implements ContractPdfShareService {
  int shared = 0;
  int saved = 0;

  @override
  Future<void> share(GeneratedPdf pdf) async {
    shared++;
  }

  @override
  Future<String> saveToDocuments(GeneratedPdf pdf) async {
    saved++;
    return 'path/${pdf.fileName}';
  }
}
