import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:npd_shield/data/backup/backup_service.dart';
import 'package:npd_shield/data/database.dart';
import 'package:npd_shield/data/models/app_notification.dart';
import 'package:npd_shield/data/models/client.dart';
import 'package:npd_shield/data/models/contract_draft.dart';
import 'package:npd_shield/data/models/document.dart';
import 'package:npd_shield/data/models/invoice.dart';
import 'package:npd_shield/data/models/risk_marker.dart';
import 'package:npd_shield/data/models/transaction.dart';
import 'package:npd_shield/data/repositories/isar_client_repository.dart';
import 'package:npd_shield/data/repositories/isar_contract_draft_repository.dart';
import 'package:npd_shield/data/repositories/isar_document_repository.dart';
import 'package:npd_shield/data/repositories/isar_invoice_repository.dart';
import 'package:npd_shield/data/repositories/isar_notification_repository.dart';
import 'package:npd_shield/data/repositories/isar_risk_report_repository.dart';
import 'package:npd_shield/data/repositories/isar_transaction_repository.dart';
import 'package:npd_shield/data/security/field_encryption_service.dart';
import 'package:npd_shield/domain/documents/my_tax_deep_link.dart';
import 'package:npd_shield/domain/profile/contractor_profile.dart';

import 'helpers/fake_activity_spheres_service.dart';
import 'helpers/fake_contract_repositories.dart';

const _srcEnc = _PrefixEncryption('src:');
const _tgtEnc = _PrefixEncryption('tgt:');

void main() {
  late Directory dir;
  late Isar source;
  late Isar target;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('npd_backup_test');
    final suffix = dir.path.hashCode;
    source = await Isar.open(
      AppDatabase.schemas,
      directory: dir.path,
      name: 'backup_source_$suffix',
    );
    target = await Isar.open(
      AppDatabase.schemas,
      directory: dir.path,
      name: 'backup_target_$suffix',
    );
  });

  tearDown(() async {
    await source.close(deleteFromDisk: true);
    await target.close(deleteFromDisk: true);
  });

  BackupService serviceFor(
    Isar isar, {
    FakeContractorProfileRepository? profile,
    FakeActivitySpheresService? spheres,
    FieldEncryptionService encryption = _tgtEnc,
  }) {
    return BackupService(
      isar: isar,
      profileRepository: profile ?? FakeContractorProfileRepository(),
      activitySpheresService: spheres ?? FakeActivitySpheresService(),
      encryption: encryption,
      now: () => DateTime(2026, 9, 17, 12, 30, 45),
    );
  }

  Future<void> seedSource(Isar isar) async {
    final transactions = IsarTransactionRepository(
      isar,
      encryption: _srcEnc,
    );
    final clients = IsarClientRepository(isar, encryption: _srcEnc);
    final invoices = IsarInvoiceRepository(
      isar,
      transactions,
      encryption: _srcEnc,
    );
    final documents = IsarDocumentRepository(isar, encryption: _srcEnc);
    final drafts = IsarContractDraftRepository(
      isar,
      encryption: _srcEnc,
    );
    final reports = IsarRiskReportRepository(
      isar,
      encryption: _srcEnc,
    );
    final notifications = IsarNotificationRepository(isar);

    await clients.add(
      Client(
        name: 'ООО «Ромашка»',
        inn: '7701234567',
        type: ClientType.legal,
        contacts: '+7 900 000-00-00',
        notes: 'VIP',
      ),
    );
    final clientId = (await clients.getAll()).single.id;

    await transactions.add(
      Transaction(
        amount: 50000,
        date: DateTime(2026, 9, 10),
        sphere: TransactionSphere.it,
        clientName: 'ООО «Ромашка»',
        clientInn: '7701234567',
        clientId: clientId,
        category: 'Разработка',
        comment: 'Оплата',
      ),
    );
    final incomeId = (await transactions.getAll()).single.id;
    await transactions.add(
      Transaction(
        amount: 10000,
        date: DateTime(2026, 9, 12),
        sphere: TransactionSphere.logistics,
        clientName: '',
        clientInn: '',
        type: TransactionType.expense,
      ),
    );

    await invoices.add(
      Invoice(
        number: '14/09',
        amount: 50000,
        issuedAt: DateTime(2026, 9, 1),
        dueDate: DateTime(2026, 9, 30),
        clientId: clientId,
        clientName: 'ООО «Ромашка»',
        clientInn: '7701234567',
        status: InvoiceStatus.sent,
        paidAmount: 20000,
      ),
    );

    await documents.save(
      Document(
        type: DocumentType.act,
        amount: 50000,
        date: DateTime(2026, 9, 10),
        status: DocumentStatus.generated,
        contractNumber: '14/09',
        counterpartyName: 'ООО «Ромашка»',
        counterpartyInn: '7701234567',
        clientId: clientId,
        transactionId: incomeId,
        serviceName: 'Разработка',
        issuerName: 'Иванов Иван Иванович',
        issuerInn: '771234567890',
      ),
    );

    await drafts.save(
      ContractDraft(
        templateId: 'it_software_development',
        filledFields: contractFieldsFromMap({
          'customer': 'ООО «Ромашка»',
          'customerInn': '7701234567',
        }),
        status: ContractStatus.signed,
        clientId: clientId,
      ),
    );

    await reports.save(
      RiskReport(
        sourceName: 'dogovor.txt',
        textLength: 120,
        safetyIndex: 70,
        risks: [
          RiskMatch(
            markerCode: 'subordination',
            severity: RiskSeverity.critical,
            matchedText: 'подчиняется правилам',
            start: 3,
            end: 20,
          ),
        ],
      ),
    );

    await notifications.save(
      AppNotification(
        type: NotificationType.limit,
        title: 'Приближение к лимиту',
        body: 'Израсходовано 80%',
        createdAt: DateTime(2026, 9, 1),
        status: NotificationStatus.read,
        payload: 'limit',
        actionLabel: 'Открыть',
        readAt: DateTime(2026, 9, 2),
      ),
    );
  }

  group('BackupService', () {
    test('экспорт собирает все данные и формирует имя файла', () async {
      await seedSource(source);
      final backup = await serviceFor(
        source,
        profile: FakeContractorProfileRepository(ContractorProfile.demo),
        spheres: FakeActivitySpheresService([
          TransactionSphere.it,
          TransactionSphere.logistics,
        ]),
        encryption: _srcEnc,
      ).exportBackup();

      expect(backup.fileName, 'npd_shield_backup_2026-09-17_123045.json');
      expect(backup.counts.transactions, 2);
      expect(backup.counts.clients, 1);
      expect(backup.counts.invoices, 1);
      expect(backup.counts.documents, 1);
      expect(backup.counts.contractDrafts, 1);
      expect(backup.counts.riskReports, 1);
      expect(backup.counts.notifications, 1);
      expect(backup.counts.hasProfile, isTrue);
      expect(backup.counts.activitySpheres, 2);
      expect(backup.bytes, isNotEmpty);

      final json = jsonDecode(utf8.decode(backup.bytes)) as Map<String, dynamic>;
      expect(json['format'], backupFormatId);
      expect(json['version'], backupFormatVersion);
      final transactions = json['transactions'] as List;
      expect(transactions, hasLength(2));
      expect(
        transactions.cast<Map<String, dynamic>>().first['clientName'],
        'ООО «Ромашка»',
      );
    });

    test('импорт на чистую базу восстанавливает данные и связи', () async {
      await seedSource(source);
      final backup = await serviceFor(
        source,
        profile: FakeContractorProfileRepository(ContractorProfile.demo),
        spheres: FakeActivitySpheresService([
          TransactionSphere.it,
          TransactionSphere.logistics,
        ]),
        encryption: _srcEnc,
      ).exportBackup();

      final targetProfile = FakeContractorProfileRepository();
      final targetSpheres = FakeActivitySpheresService();
      final result = await serviceFor(
        target,
        profile: targetProfile,
        spheres: targetSpheres,
      ).importBackup(backup.bytes);

      expect(result.counts.transactions, 2);
      expect(result.counts.clients, 1);
      expect(result.counts.hasProfile, isTrue);

      final clients = IsarClientRepository(
        target,
        encryption: _tgtEnc,
      );
      final transactions = IsarTransactionRepository(
        target,
        encryption: _tgtEnc,
      );
      final invoices = IsarInvoiceRepository(
        target,
        transactions,
        encryption: _tgtEnc,
      );
      final documents = IsarDocumentRepository(
        target,
        encryption: _tgtEnc,
      );
      final drafts = IsarContractDraftRepository(
        target,
        encryption: _tgtEnc,
      );
      final reports = IsarRiskReportRepository(
        target,
        encryption: _tgtEnc,
      );

      final restoredClient = (await clients.getAll()).single;
      expect(restoredClient.name, 'ООО «Ромашка»');
      expect(restoredClient.inn, '7701234567');
      expect(restoredClient.type, ClientType.legal);
      expect(restoredClient.contacts, '+7 900 000-00-00');
      expect(restoredClient.notes, 'VIP');

      final restoredTransactions = await transactions.getAll();
      expect(restoredTransactions, hasLength(2));
      final income = restoredTransactions.firstWhere((t) => t.type.isIncome);
      expect(income.clientName, 'ООО «Ромашка»');
      expect(income.clientId, restoredClient.id);
      expect(income.category, 'Разработка');
      expect(income.amount, 50000);

      final restoredInvoice = (await invoices.getAll()).single;
      expect(restoredInvoice.clientName, 'ООО «Ромашка»');
      expect(restoredInvoice.paidAmount, 20000);
      expect(restoredInvoice.outstanding, 30000);

      final restoredDocument = (await documents.getAll()).single;
      expect(restoredDocument.counterpartyName, 'ООО «Ромашка»');
      expect(restoredDocument.clientId, restoredClient.id);
      expect(restoredDocument.transactionId, income.id);
      expect(restoredDocument.serviceName, 'Разработка');
      expect(restoredDocument.issuerName, 'Иванов Иван Иванович');

      final restoredDraft = (await drafts.getAll()).single;
      expect(restoredDraft.status, ContractStatus.signed);
      expect(
        contractFieldsToMap(restoredDraft.filledFields)['customer'],
        'ООО «Ромашка»',
      );
      expect(restoredDraft.clientId, restoredClient.id);

      final restoredReport = (await reports.getAll()).single;
      expect(restoredReport.sourceName, 'dogovor.txt');
      expect(restoredReport.risks.single.matchedText, 'подчиняется правилам');

      final notifications = await IsarNotificationRepository(
        target,
      ).getAll();
      expect(notifications.single.title, 'Приближение к лимиту');
      expect(notifications.single.status, NotificationStatus.read);

      expect(targetProfile.profile?.inn, ContractorProfile.demo.inn);
      expect(targetSpheres.spheres, [
        TransactionSphere.it,
        TransactionSphere.logistics,
      ]);
    });

    test('импорт шифрует данные ключом целевой базы', () async {
      await seedSource(source);
      final backup = await serviceFor(
        source,
        encryption: _srcEnc,
      ).exportBackup();

      await serviceFor(target).importBackup(backup.bytes);

      final rawTransactions = await target.transactions.where().findAll();
      final rawIncome = rawTransactions.firstWhere(
        (t) => t.clientName.isNotEmpty,
      );
      expect(rawIncome.clientName, 'tgt:ООО «Ромашка»');
      expect(rawIncome.clientInn, 'tgt:7701234567');

      final rawClients = await target.clients.where().findAll();
      expect(rawClients.single.name, 'tgt:ООО «Ромашка»');
    });

    test('импорт заменяет текущие данные, а не добавляет их', () async {
      await seedSource(source);
      final backup = await serviceFor(
        source,
        encryption: _srcEnc,
      ).exportBackup();

      await IsarClientRepository(
        target,
        encryption: _tgtEnc,
      ).add(Client(name: 'Старый клиент'));

      await serviceFor(target).importBackup(backup.bytes);

      final clients = await IsarClientRepository(
        target,
        encryption: _tgtEnc,
      ).getAll();
      expect(clients, hasLength(1));
      expect(clients.single.name, 'ООО «Ромашка»');
    });

    test('пустая копия очищает данные', () async {
      final backup = await serviceFor(
        source,
        encryption: _srcEnc,
      ).exportBackup();

      await IsarClientRepository(
        target,
        encryption: _tgtEnc,
      ).add(Client(name: 'Старый клиент'));

      final result = await serviceFor(target).importBackup(backup.bytes);

      expect(result.counts.total, 0);
      expect(
        await IsarClientRepository(target).count(),
        0,
      );
    });

    test('отклоняет повреждённый файл', () async {
      final service = serviceFor(target);

      expect(
        () => service.importBackup(
          Uint8List.fromList(utf8.encode('не json')),
        ),
        throwsA(isA<BackupFormatException>()),
      );
    });

    test('отклоняет файл чужого формата', () async {
      final service = serviceFor(target);
      final bytes = Uint8List.fromList(
        utf8.encode(jsonEncode({'format': 'other', 'version': 1})),
      );

      expect(
        () => service.importBackup(bytes),
        throwsA(isA<BackupFormatException>()),
      );
    });

    test('отклоняет копию будущей версии', () async {
      final service = serviceFor(target);
      final bytes = Uint8List.fromList(
        utf8.encode(
          jsonEncode({'format': backupFormatId, 'version': 999}),
        ),
      );

      expect(
        () => service.importBackup(bytes),
        throwsA(isA<BackupFormatException>()),
      );
    });
  });
}

/// Детерминированное шифрование с настраиваемым префиксом.
class _PrefixEncryption implements FieldEncryptionService {
  final String prefix;

  const _PrefixEncryption([this.prefix = 'enc:']);

  @override
  Future<String> encrypt(String plainText) async => '$prefix$plainText';

  @override
  Future<String> decrypt(String encryptedText) async =>
      encryptedText.startsWith(prefix)
      ? encryptedText.substring(prefix.length)
      : encryptedText;
}
