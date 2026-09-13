import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:npd_shield/data/models/document.dart';
import 'package:npd_shield/data/repositories/isar_document_repository.dart';
import 'package:npd_shield/data/security/field_encryption_service.dart';

void main() {
  late Isar isar;
  late IsarDocumentRepository repository;

  setUp(() async {
    final dir = await Directory.systemTemp.createTemp('npd_document_test');
    isar = await Isar.open(
      [DocumentSchema],
      directory: dir.path,
      name: 'document_test_${dir.path.hashCode}',
    );
    repository = IsarDocumentRepository(
      isar,
      encryption: const _PassthroughEncryption(),
    );
  });

  tearDown(() async {
    await isar.close(deleteFromDisk: true);
  });

  Document receipt({
    DocumentType type = DocumentType.receipt,
    String counterpartyName = 'ООО «Ромашка»',
    String counterpartyInn = '7701234567',
    double amount = 150000,
    DateTime? date,
    int contractDraftId = 0,
    int transactionId = 0,
    int receiptDocumentId = 0,
    String serviceName = 'Разработка ПО',
    String result = '',
    String executorSignatory = '',
    String customerSignatory = '',
  }) {
    return Document(
      type: type,
      status: DocumentStatus.generated,
      amount: amount,
      date: date ?? DateTime(2026, 9, 5),
      contractDraftId: contractDraftId,
      contractNumber: '14/09',
      counterpartyName: counterpartyName,
      counterpartyInn: counterpartyInn,
      transactionId: transactionId,
      receiptDocumentId: receiptDocumentId,
      serviceName: serviceName,
      result: result,
      executorSignatory: executorSignatory,
      customerSignatory: customerSignatory,
      issuerName: 'Иванов Иван Иванович',
      issuerInn: '771234567890',
    );
  }

  group('IsarDocumentRepository', () {
    test('save присваивает id и позволяет прочитать документ', () async {
      final id = await repository.save(receipt());

      final found = await repository.getById(id);

      expect(id, isNot(0));
      expect(found, isNotNull);
      expect(found!.type, DocumentType.receipt);
      expect(found.status, DocumentStatus.generated);
      expect(found.counterpartyName, 'ООО «Ромашка»');
      expect(found.amount, 150000);
      expect(found.contractNumber, '14/09');
    });

    test('getAll возвращает документы от новых к старым', () async {
      final now = DateTime(2026, 9, 10);
      await repository.save(receipt(date: now.subtract(const Duration(days: 1))));
      await repository.save(receipt(date: now));
      await repository.save(receipt(date: now.subtract(const Duration(days: 2))));

      final all = await repository.getAll();

      expect(all.map((d) => d.date).toList(), [
        now,
        now.subtract(const Duration(days: 1)),
        now.subtract(const Duration(days: 2)),
      ]);
    });

    test('getByType фильтрует документы по типу', () async {
      await repository.save(receipt(type: DocumentType.receipt));
      await repository.save(receipt(type: DocumentType.act));
      await repository.save(receipt(type: DocumentType.contract));

      final receipts = await repository.getByType(DocumentType.receipt);

      expect(receipts, hasLength(1));
      expect(receipts.single.type, DocumentType.receipt);
    });

    test('getByContractDraftId и getByTransactionId находят привязки', () async {
      await repository.save(receipt(contractDraftId: 7, transactionId: 0));
      await repository.save(receipt(contractDraftId: 8, transactionId: 42));

      final byContract = await repository.getByContractDraftId(8);
      final byTransaction = await repository.getByTransactionId(42);

      expect(byContract, hasLength(1));
      expect(byContract.single.contractDraftId, 8);
      expect(byTransaction, hasLength(1));
      expect(byTransaction.single.transactionId, 42);
    });

    test('getByReceiptDocumentId находит акты, привязанные к чеку', () async {
      await repository.save(receipt(type: DocumentType.act, receiptDocumentId: 5));
      await repository.save(receipt(type: DocumentType.act, receiptDocumentId: 6));

      final acts = await repository.getByReceiptDocumentId(5);

      expect(acts, hasLength(1));
      expect(acts.single.type, DocumentType.act);
      expect(acts.single.receiptDocumentId, 5);
    });

    test('delete и clear удаляют документы', () async {
      final id1 = await repository.save(receipt());
      await repository.save(receipt());

      await repository.delete(id1);
      expect(await repository.getById(id1), isNull);
      expect(await repository.count(), 1);

      await repository.clear();
      expect(await repository.getAll(), isEmpty);
    });
  });

  group('шифрование документов', () {
    test('персональные поля шифруются в базе и расшифровываются при чтении',
        () async {
      final encryptedRepo = IsarDocumentRepository(
        isar,
        encryption: const _PrefixEncryption(),
      );
      final id = await encryptedRepo.save(receipt());

      final raw = await isar.documents.where().idEqualTo(id).findFirst();
      expect(raw!.counterpartyName, startsWith('enc:'));
      expect(raw.counterpartyInn, startsWith('enc:'));
      expect(raw.serviceName, startsWith('enc:'));
      expect(raw.issuerName, startsWith('enc:'));
      expect(raw.issuerInn, startsWith('enc:'));
      // Не персональные поля остаются как есть.
      expect(raw.contractNumber, '14/09');

      final loaded = await encryptedRepo.getById(id);
      expect(loaded!.counterpartyName, 'ООО «Ромашка»');
      expect(loaded.counterpartyInn, '7701234567');
      expect(loaded.serviceName, 'Разработка ПО');
      expect(loaded.issuerName, 'Иванов Иван Иванович');
      expect(loaded.issuerInn, '771234567890');
    });

    test('поля акта (результат и подписи) шифруются в базе', () async {
      final encryptedRepo = IsarDocumentRepository(
        isar,
        encryption: const _PrefixEncryption(),
      );
      final id = await encryptedRepo.save(
        receipt(
          type: DocumentType.act,
          result: 'Работы выполнены',
          executorSignatory: 'Иванов И.И.',
          customerSignatory: 'Петров П.П.',
        ),
      );

      final raw = await isar.documents.where().idEqualTo(id).findFirst();
      expect(raw!.result, startsWith('enc:'));
      expect(raw.executorSignatory, startsWith('enc:'));
      expect(raw.customerSignatory, startsWith('enc:'));

      final loaded = await encryptedRepo.getById(id);
      expect(loaded!.result, 'Работы выполнены');
      expect(loaded.executorSignatory, 'Иванов И.И.');
      expect(loaded.customerSignatory, 'Петров П.П.');
    });
  });
}

/// Шифрование-заглушка: хранит значение как есть.
class _PassthroughEncryption implements FieldEncryptionService {
  const _PassthroughEncryption();

  @override
  Future<String> encrypt(String plainText) async => plainText;

  @override
  Future<String> decrypt(String encryptedText) async => encryptedText;
}

/// Детерминированное шифрование: добавляет префикс `enc:`.
class _PrefixEncryption implements FieldEncryptionService {
  const _PrefixEncryption();

  static const _marker = 'enc:';

  @override
  Future<String> encrypt(String plainText) async => '$_marker$plainText';

  @override
  Future<String> decrypt(String encryptedText) async =>
      encryptedText.startsWith(_marker)
      ? encryptedText.substring(_marker.length)
      : encryptedText;
}
