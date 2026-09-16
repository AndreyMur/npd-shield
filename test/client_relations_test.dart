import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:npd_shield/data/models/client.dart';
import 'package:npd_shield/data/models/document.dart';
import 'package:npd_shield/data/models/transaction.dart';
import 'package:npd_shield/data/repositories/isar_client_repository.dart';
import 'package:npd_shield/data/repositories/isar_document_repository.dart';
import 'package:npd_shield/data/repositories/isar_transaction_repository.dart';
import 'package:npd_shield/data/security/field_encryption_service.dart';

class _PassthroughEncryption implements FieldEncryptionService {
  const _PassthroughEncryption();

  @override
  Future<String> encrypt(String plainText) async => plainText;

  @override
  Future<String> decrypt(String encryptedText) async => encryptedText;
}

void main() {
  late Isar isar;
  late IsarClientRepository clients;
  late IsarTransactionRepository transactions;
  late IsarDocumentRepository documents;

  setUp(() async {
    final dir = await Directory.systemTemp.createTemp('npd_client_links_test');
    isar = await Isar.open(
      [ClientSchema, TransactionSchema, DocumentSchema],
      directory: dir.path,
      name: 'test_${dir.path.hashCode}',
    );
    const encryption = _PassthroughEncryption();
    clients = IsarClientRepository(isar, encryption: encryption);
    transactions = IsarTransactionRepository(isar, encryption: encryption);
    documents = IsarDocumentRepository(isar, encryption: encryption);
  });

  tearDown(() async {
    await isar.close(deleteFromDisk: true);
  });

  test('deleting a client keeps related operations and documents', () async {
    final clientId = await clients.add(
      Client(name: 'ООО Ромашка', inn: '7701234567'),
    );

    final transactionId = await transactions.add(
      Transaction(
        amount: 50000,
        date: DateTime(2026, 9, 10),
        sphere: TransactionSphere.it,
        clientName: 'ООО Ромашка',
        clientInn: '7701234567',
        clientId: clientId,
      ),
    );

    final documentId = await documents.save(
      Document(
        type: DocumentType.act,
        amount: 50000,
        date: DateTime(2026, 9, 10),
        counterpartyName: 'ООО Ромашка',
        counterpartyInn: '7701234567',
        clientId: clientId,
        transactionId: transactionId,
      ),
    );

    final deleted = await clients.delete(clientId);

    expect(deleted, isTrue);
    expect(await clients.getById(clientId), isNull);

    final transaction = await transactions.getById(transactionId);
    expect(transaction, isNotNull);
    expect(transaction!.clientId, clientId);

    final document = await documents.getById(documentId);
    expect(document, isNotNull);
    expect(document!.clientId, clientId);
    expect(document.transactionId, transactionId);
  });

  test('clearing clients keeps related operations and documents', () async {
    final clientId = await clients.add(Client(name: 'ИП Петров'));
    final transactionId = await transactions.add(
      Transaction(
        amount: 1000,
        date: DateTime(2026, 9, 1),
        sphere: TransactionSphere.logistics,
        clientName: 'ИП Петров',
        clientInn: '500100200300',
        clientId: clientId,
      ),
    );
    final documentId = await documents.save(
      Document(
        type: DocumentType.receipt,
        amount: 1000,
        date: DateTime(2026, 9, 1),
        clientId: clientId,
      ),
    );

    await clients.clear();

    expect(await clients.count(), 0);
    expect(await transactions.count(), 1);
    expect(await documents.count(), 1);
    expect((await transactions.getById(transactionId))!.clientId, clientId);
    expect((await documents.getById(documentId))!.clientId, clientId);
  });
}
