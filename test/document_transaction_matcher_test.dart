import 'package:flutter_test/flutter_test.dart';
import 'package:npd_shield/data/models/document.dart';
import 'package:npd_shield/data/models/transaction.dart';
import 'package:npd_shield/domain/documents/document_transaction_linker.dart';
import 'package:npd_shield/domain/documents/document_transaction_matcher.dart';

import 'helpers/fake_document_repository.dart';

void main() {
  Document doc({
    int id = 0,
    int transactionId = 0,
    DocumentType type = DocumentType.receipt,
    double amount = 1000,
    DateTime? date,
    String name = 'ООО «Ромашка»',
    String inn = '7701234567',
  }) {
    final document = Document(
      type: type,
      amount: amount,
      date: date ?? DateTime(2026, 9, 5),
      transactionId: transactionId,
      counterpartyName: name,
      counterpartyInn: inn,
    );
    document.id = id;
    return document;
  }

  Transaction tx({
    int id = 0,
    double amount = 1000,
    DateTime? date,
    String name = 'ООО «Ромашка»',
    String inn = '7701234567',
  }) {
    final transaction = Transaction(
      amount: amount,
      date: date ?? DateTime(2026, 9, 5),
      sphere: TransactionSphere.it,
      clientName: name,
      clientInn: inn,
    );
    transaction.id = id;
    return transaction;
  }

  group('documentMatchesTransaction', () {
    test('явная привязка по transactionId', () {
      final document = doc(transactionId: 7);
      expect(documentMatchesTransaction(document, tx(id: 7)), isTrue);
    });

    test('явная привязка к другой транзакции не совпадает', () {
      final document = doc(transactionId: 7);
      expect(documentMatchesTransaction(document, tx(id: 8)), isFalse);
    });

    test('совпадение по сумме, дате и ИНН', () {
      expect(documentMatchesTransaction(doc(), tx()), isTrue);
    });

    test('разная сумма не совпадает', () {
      expect(documentMatchesTransaction(doc(amount: 1000), tx(amount: 2000)), isFalse);
    });

    test('разная дата не совпадает', () {
      expect(
        documentMatchesTransaction(
          doc(date: DateTime(2026, 9, 5)),
          tx(date: DateTime(2026, 9, 6)),
        ),
        isFalse,
      );
    });

    test('разный ИНН не совпадает', () {
      expect(
        documentMatchesTransaction(doc(inn: '111'), tx(inn: '222')),
        isFalse,
      );
    });

    test('без ИНН сопоставление идёт по наименованию контрагента', () {
      expect(
        documentMatchesTransaction(
          doc(name: 'ИП Петров', inn: ''),
          tx(name: 'ИП Петров', inn: ''),
        ),
        isTrue,
      );
      expect(
        documentMatchesTransaction(
          doc(name: 'ИП Петров', inn: ''),
          tx(name: 'ИП Сидоров', inn: ''),
        ),
        isFalse,
      );
    });

    test('разное время в один день считается совпадением', () {
      expect(
        documentMatchesTransaction(
          doc(date: DateTime(2026, 9, 5, 8)),
          tx(date: DateTime(2026, 9, 5, 21)),
        ),
        isTrue,
      );
    });
  });

  group('matchDocumentsToTransactions', () {
    test('возвращает запись для каждой транзакции', () {
      final matches = matchDocumentsToTransactions(
        transactions: [tx(id: 1), tx(id: 2, amount: 5000)],
        documents: [doc(id: 10, transactionId: 1)],
      );

      expect(matches, hasLength(2));
      expect(matches.first.hasDocuments, isTrue);
      expect(matches.first.primary!.id, 10);
      expect(matches.last.hasDocuments, isFalse);
    });

    test('сопоставляет несколько документов с одной транзакцией', () {
      final matches = matchDocumentsToTransactions(
        transactions: [tx(id: 1)],
        documents: [
          doc(id: 10, transactionId: 1),
          doc(id: 11, type: DocumentType.act, transactionId: 1),
        ],
      );

      expect(matches.single.documents.map((d) => d.id), [10, 11]);
    });
  });

  group('DocumentTransactionLinker', () {
    test('проставляет привязку документам без явной связи', () async {
      final documents = FakeDocumentRepository([
        doc(id: 10, transactionId: 0),
        doc(id: 11, transactionId: 0, amount: 5000),
      ]);
      const linker = DocumentTransactionLinker();

      final linked = await linker.link(
        documentRepository: documents,
        transactions: [tx(id: 3)],
        documents: documents.documents,
      );

      expect(linked, 1);
      expect(documents.documents.first.transactionId, 3);
      expect(documents.documents.last.transactionId, 0);
    });

    test('не трогает уже привязанные документы', () async {
      final documents = FakeDocumentRepository([
        doc(id: 10, transactionId: 99),
      ]);
      const linker = DocumentTransactionLinker();

      final linked = await linker.link(
        documentRepository: documents,
        transactions: [tx(id: 3)],
        documents: documents.documents,
      );

      expect(linked, 0);
      expect(documents.documents.single.transactionId, 99);
    });

    test('пропускает транзакции без идентификатора', () async {
      final documents = FakeDocumentRepository([doc(id: 10)]);
      const linker = DocumentTransactionLinker();

      final linked = await linker.link(
        documentRepository: documents,
        transactions: [tx(id: 0)],
        documents: documents.documents,
      );

      expect(linked, 0);
      expect(documents.documents.single.transactionId, 0);
    });
  });
}
