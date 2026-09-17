import 'dart:convert';
import 'dart:typed_data';

import 'package:isar/isar.dart';

import '../../domain/documents/my_tax_deep_link.dart';
import '../../domain/profile/contractor_profile.dart';
import '../models/app_notification.dart';
import '../models/client.dart';
import '../models/contract_draft.dart';
import '../models/document.dart';
import '../models/invoice.dart';
import '../models/risk_marker.dart';
import '../models/transaction.dart';
import '../repositories/contractor_profile_repository.dart';
import '../security/database_encryption_service.dart';
import '../security/field_encryption_service.dart';
import '../services/activity_spheres_service.dart';

/// Идентификатор формата резервной копии.
const String backupFormatId = 'npd_shield_backup';

/// Текущая версия формата резервной копии.
const int backupFormatVersion = 1;

/// Число записей по каждой сущности в резервной копии.
class BackupCounts {
  final int transactions;
  final int clients;
  final int invoices;
  final int documents;
  final int contractDrafts;
  final int riskReports;
  final int notifications;

  /// Был ли сохранён профиль исполнителя.
  final bool hasProfile;

  /// Количество выбранных сфер деятельности.
  final int activitySpheres;

  const BackupCounts({
    this.transactions = 0,
    this.clients = 0,
    this.invoices = 0,
    this.documents = 0,
    this.contractDrafts = 0,
    this.riskReports = 0,
    this.notifications = 0,
    this.hasProfile = false,
    this.activitySpheres = 0,
  });

  /// Суммарное число записей данных (без профиля и сфер).
  int get total =>
      transactions +
      clients +
      invoices +
      documents +
      contractDrafts +
      riskReports +
      notifications;

  /// Пустая ли резервная копия (нет ни одной записи и профиля).
  bool get isEmpty => total == 0 && !hasProfile && activitySpheres == 0;
}

/// Готовая резервная копия: содержимое файла, имя и сводка.
class BackupFile {
  final String fileName;
  final Uint8List bytes;
  final DateTime createdAt;
  final BackupCounts counts;

  const BackupFile({
    required this.fileName,
    required this.bytes,
    required this.createdAt,
    required this.counts,
  });
}

/// Результат импорта резервной копии.
class BackupImportResult {
  final BackupCounts counts;

  const BackupImportResult({required this.counts});
}

/// Операции резервного копирования, используемые интерфейсом.
///
/// Узкий контракт поверх [BackupService] позволяет экрану отчётов зависеть
/// только от экспорта и импорта и подменять их в тестах.
abstract class BackupGateway {
  /// Формирует резервную копию всех данных.
  Future<BackupFile> exportBackup();

  /// Восстанавливает данные из резервной копии, заменяя текущие.
  Future<BackupImportResult> importBackup(Uint8List bytes);
}

/// Ошибка чтения резервной копии: файл повреждён или несовместим.
class BackupFormatException implements Exception {
  final String message;

  const BackupFormatException(this.message);

  @override
  String toString() => message;
}

/// Экспорт и импорт всех пользовательских данных в файл.
///
/// Резервная копия — JSON-файл в UTF-8, содержащий операции, клиентов, счета,
/// документы, черновики договоров, отчёты о рисках, уведомления, профиль
/// исполнителя и выбранные сферы деятельности. Идентификаторы записей
/// сохраняются, поэтому связи между сущностями (клиент, счёт, документ,
/// операция) после восстановления не нарушаются.
///
/// Чувствительные строки при экспорте расшифровываются, а при импорте
/// шифруются заново текущим ключом устройства. Поэтому копия переносима между
/// установками и не содержит зашифрованных «чужим» ключом данных.
class BackupService implements BackupGateway {
  final Isar isar;
  final ContractorProfileRepository profileRepository;
  final ActivitySpheresService activitySpheresService;
  final FieldEncryptionService encryption;
  final DateTime Function() _now;

  BackupService({
    required this.isar,
    required this.profileRepository,
    required this.activitySpheresService,
    FieldEncryptionService? encryption,
    DateTime Function()? now,
  }) : encryption = encryption ?? DatabaseEncryptionService(),
       _now = now ?? DateTime.now;

  /// Формирует резервную копию всех данных.
  @override
  Future<BackupFile> exportBackup() async {
    final createdAt = _now();

    final transactions = await isar.transactions.where().findAll();
    for (final transaction in transactions) {
      await _decryptTransaction(transaction);
    }
    final clients = await isar.clients.where().findAll();
    for (final client in clients) {
      await _decryptClient(client);
    }
    final invoices = await isar.invoices.where().findAll();
    for (final invoice in invoices) {
      await _decryptInvoice(invoice);
    }
    final documents = await isar.documents.where().findAll();
    for (final document in documents) {
      await _decryptDocument(document);
    }
    final drafts = await isar.contractDrafts.where().findAll();
    for (final draft in drafts) {
      await _decryptDraft(draft);
    }
    final reports = await isar.riskReports.where().findAll();
    for (final report in reports) {
      await _decryptRiskReport(report);
    }
    final notifications = await isar.appNotifications.where().findAll();

    final profile = await profileRepository.load();
    final spheres = await activitySpheresService.load();

    final payload = <String, dynamic>{
      'format': backupFormatId,
      'version': backupFormatVersion,
      'createdAt': createdAt.toIso8601String(),
      'transactions': [for (final t in transactions) _transactionToJson(t)],
      'clients': [for (final c in clients) _clientToJson(c)],
      'invoices': [for (final i in invoices) _invoiceToJson(i)],
      'documents': [for (final d in documents) _documentToJson(d)],
      'contractDrafts': [for (final d in drafts) _draftToJson(d)],
      'riskReports': [for (final r in reports) _riskReportToJson(r)],
      'notifications': [
        for (final n in notifications) _notificationToJson(n),
      ],
      'profile': profile?.toJson(),
      'activitySpheres': [for (final sphere in spheres) sphere.name],
    };

    final content = const JsonEncoder.withIndent('  ').convert(payload);
    return BackupFile(
      fileName: _backupFileName(createdAt),
      bytes: Uint8List.fromList(utf8.encode(content)),
      createdAt: createdAt,
      counts: BackupCounts(
        transactions: transactions.length,
        clients: clients.length,
        invoices: invoices.length,
        documents: documents.length,
        contractDrafts: drafts.length,
        riskReports: reports.length,
        notifications: notifications.length,
        hasProfile: profile != null,
        activitySpheres: spheres.length,
      ),
    );
  }

  /// Восстанавливает данные из резервной копии, заменяя текущие.
  ///
  /// Перед записью все коллекции очищаются, поэтому после импорта в базе
  /// остаются ровно те данные, что были в копии. Бросает
  /// [BackupFormatException], если файл повреждён или имеет другую версию.
  @override
  Future<BackupImportResult> importBackup(Uint8List bytes) async {
    final payload = _decode(bytes);

    final transactions = _parseList(payload, 'transactions', _transactionFromJson);
    final clients = _parseList(payload, 'clients', _clientFromJson);
    final invoices = _parseList(payload, 'invoices', _invoiceFromJson);
    final documents = _parseList(payload, 'documents', _documentFromJson);
    final drafts = _parseList(payload, 'contractDrafts', _draftFromJson);
    final reports = _parseList(payload, 'riskReports', _riskReportFromJson);
    final notifications = _parseList(
      payload,
      'notifications',
      _notificationFromJson,
    );

    await isar.writeTxn(() async {
      await isar.transactions.clear();
      await isar.clients.clear();
      await isar.invoices.clear();
      await isar.documents.clear();
      await isar.contractDrafts.clear();
      await isar.riskReports.clear();
      await isar.appNotifications.clear();

      for (final transaction in transactions) {
        await _encryptTransaction(transaction);
      }
      for (final client in clients) {
        await _encryptClient(client);
      }
      for (final invoice in invoices) {
        await _encryptInvoice(invoice);
      }
      for (final document in documents) {
        await _encryptDocument(document);
      }
      for (final draft in drafts) {
        await _encryptDraft(draft);
      }
      for (final report in reports) {
        await _encryptRiskReport(report);
      }

      await isar.transactions.putAll(transactions);
      await isar.clients.putAll(clients);
      await isar.invoices.putAll(invoices);
      await isar.documents.putAll(documents);
      await isar.contractDrafts.putAll(drafts);
      await isar.riskReports.putAll(reports);
      await isar.appNotifications.putAll(notifications);
    });

    final profileJson = payload['profile'];
    if (profileJson is Map<String, dynamic>) {
      await profileRepository.save(ContractorProfile.fromJson(profileJson));
    } else {
      await profileRepository.clear();
    }

    final spheres = _parseSpheres(payload['activitySpheres']);
    await activitySpheresService.save(spheres);

    return BackupImportResult(
      counts: BackupCounts(
        transactions: transactions.length,
        clients: clients.length,
        invoices: invoices.length,
        documents: documents.length,
        contractDrafts: drafts.length,
        riskReports: reports.length,
        notifications: notifications.length,
        hasProfile: profileJson is Map<String, dynamic>,
        activitySpheres: spheres.length,
      ),
    );
  }

  Map<String, dynamic> _decode(Uint8List bytes) {
    final Object? decoded;
    try {
      decoded = jsonDecode(utf8.decode(bytes));
    } catch (_) {
      throw const BackupFormatException(
        'Файл повреждён или не является резервной копией NPD Shield.',
      );
    }
    if (decoded is! Map<String, dynamic>) {
      throw const BackupFormatException(
        'Файл повреждён или не является резервной копией NPD Shield.',
      );
    }
    if (decoded['format'] != backupFormatId) {
      throw const BackupFormatException(
        'Неизвестный формат файла. Выберите резервную копию NPD Shield.',
      );
    }
    final version = decoded['version'];
    if (version is! int || version > backupFormatVersion) {
      throw BackupFormatException(
        'Версия резервной копии не поддерживается (версия файла: $version).',
      );
    }
    return decoded;
  }

  List<T> _parseList<T>(
    Map<String, dynamic> payload,
    String key,
    T Function(Map<String, dynamic>) parse,
  ) {
    final raw = payload[key];
    if (raw == null) return [];
    if (raw is! List) {
      throw BackupFormatException('Раздел «$key» резервной копии повреждён.');
    }
    final result = <T>[];
    for (final item in raw) {
      if (item is! Map<String, dynamic>) {
        throw BackupFormatException('Раздел «$key» резервной копии повреждён.');
      }
      try {
        result.add(parse(item));
      } catch (error) {
        if (error is BackupFormatException) rethrow;
        throw BackupFormatException('Раздел «$key» резервной копии повреждён.');
      }
    }
    return result;
  }

  List<TransactionSphere> _parseSpheres(Object? raw) {
    if (raw is! List) return const [];
    return [
      for (final value in raw)
        ...TransactionSphere.values.where((sphere) => sphere.name == value),
    ];
  }

  // --- Сериализация сущностей ---

  Map<String, dynamic> _transactionToJson(Transaction t) => {
    'id': t.id,
    'amount': t.amount,
    'date': t.date.toIso8601String(),
    'sphere': t.sphere.name,
    'type': t.type.name,
    'category': t.category,
    'clientName': t.clientName,
    'clientInn': t.clientInn,
    'clientId': t.clientId,
    'comment': t.comment,
  };

  Transaction _transactionFromJson(Map<String, dynamic> json) {
    final transaction = Transaction(
      amount: _asDouble(json['amount']),
      date: _asDate(json['date']),
      sphere: _asEnum(TransactionSphere.values, json['sphere'], TransactionSphere.it),
      clientName: _asString(json['clientName']),
      clientInn: _asString(json['clientInn']),
      type: _asEnum(TransactionType.values, json['type'], TransactionType.income),
      category: _asString(json['category']),
      clientId: _asIntOrNull(json['clientId']),
      comment: _asString(json['comment']),
    );
    transaction.id = _asId(json['id']);
    return transaction;
  }

  Map<String, dynamic> _clientToJson(Client c) => {
    'id': c.id,
    'name': c.name,
    'inn': c.inn,
    'type': c.type.name,
    'contacts': c.contacts,
    'notes': c.notes,
    'createdAt': c.createdAt.toIso8601String(),
  };

  Client _clientFromJson(Map<String, dynamic> json) {
    final client = Client(
      name: _asString(json['name']),
      inn: _asString(json['inn']),
      type: _asEnum(ClientType.values, json['type'], ClientType.individual),
      contacts: _asString(json['contacts']),
      notes: _asString(json['notes']),
    );
    client.id = _asId(json['id']);
    client.createdAt = _asDate(json['createdAt']);
    return client;
  }

  Map<String, dynamic> _invoiceToJson(Invoice i) => {
    'id': i.id,
    'number': i.number,
    'clientId': i.clientId,
    'clientName': i.clientName,
    'clientInn': i.clientInn,
    'amount': i.amount,
    'issuedAt': i.issuedAt.toIso8601String(),
    'dueDate': i.dueDate.toIso8601String(),
    'status': i.status.name,
    'paidAmount': i.paidAmount,
    'paidAt': i.paidAt?.toIso8601String(),
    'transactionId': i.transactionId,
    'comment': i.comment,
    'createdAt': i.createdAt.toIso8601String(),
  };

  Invoice _invoiceFromJson(Map<String, dynamic> json) {
    final invoice = Invoice(
      number: _asString(json['number']),
      amount: _asDouble(json['amount']),
      issuedAt: _asDate(json['issuedAt']),
      dueDate: _asDate(json['dueDate']),
      clientId: _asInt(json['clientId']),
      clientName: _asString(json['clientName']),
      clientInn: _asString(json['clientInn']),
      status: _asEnum(
        InvoiceStatus.manualValues,
        json['status'],
        InvoiceStatus.draft,
      ),
      paidAmount: _asDouble(json['paidAmount']),
      paidAt: _asDateOrNull(json['paidAt']),
      transactionId: _asInt(json['transactionId']),
      comment: _asString(json['comment']),
    );
    invoice.id = _asId(json['id']);
    invoice.createdAt = _asDate(json['createdAt']);
    return invoice;
  }

  Map<String, dynamic> _documentToJson(Document d) => {
    'id': d.id,
    'type': d.type.name,
    'status': d.status.name,
    'contractDraftId': d.contractDraftId,
    'contractNumber': d.contractNumber,
    'counterpartyName': d.counterpartyName,
    'counterpartyInn': d.counterpartyInn,
    'amount': d.amount,
    'date': d.date.toIso8601String(),
    'transactionId': d.transactionId,
    'clientId': d.clientId,
    'receiptDocumentId': d.receiptDocumentId,
    'content': d.content,
    'serviceName': d.serviceName,
    'result': d.result,
    'executorSignatory': d.executorSignatory,
    'customerSignatory': d.customerSignatory,
    'issuerName': d.issuerName,
    'issuerInn': d.issuerInn,
    'createdAt': d.createdAt.toIso8601String(),
  };

  Document _documentFromJson(Map<String, dynamic> json) {
    final document = Document(
      type: _asEnum(DocumentType.values, json['type'], DocumentType.receipt),
      amount: _asDouble(json['amount']),
      date: _asDate(json['date']),
      status: _asEnum(DocumentStatus.values, json['status'], DocumentStatus.draft),
      contractDraftId: _asInt(json['contractDraftId']),
      contractNumber: _asString(json['contractNumber']),
      counterpartyName: _asString(json['counterpartyName']),
      counterpartyInn: _asString(json['counterpartyInn']),
      transactionId: _asInt(json['transactionId']),
      clientId: _asInt(json['clientId']),
      receiptDocumentId: _asInt(json['receiptDocumentId']),
      content: _asString(json['content']),
      serviceName: _asString(json['serviceName']),
      result: _asString(json['result']),
      executorSignatory: _asString(json['executorSignatory']),
      customerSignatory: _asString(json['customerSignatory']),
      issuerName: _asString(json['issuerName']),
      issuerInn: _asString(json['issuerInn']),
    );
    document.id = _asId(json['id']);
    document.createdAt = _asDate(json['createdAt']);
    return document;
  }

  Map<String, dynamic> _draftToJson(ContractDraft d) => {
    'id': d.id,
    'templateId': d.templateId,
    'filledFields': [
      for (final field in d.filledFields)
        {'key': field.key, 'value': field.value},
    ],
    'status': d.status.name,
    'clientId': d.clientId,
    'createdAt': d.createdAt.toIso8601String(),
  };

  ContractDraft _draftFromJson(Map<String, dynamic> json) {
    final rawFields = json['filledFields'];
    final fields = <DraftFieldValue>[];
    if (rawFields is List) {
      for (final raw in rawFields) {
        if (raw is! Map<String, dynamic>) continue;
        fields.add(
          DraftFieldValue(
            key: _asString(raw['key']),
            value: _asString(raw['value']),
          ),
        );
      }
    }
    final draft = ContractDraft(
      templateId: _asString(json['templateId']),
      filledFields: fields,
      status: _asEnum(ContractStatus.values, json['status'], ContractStatus.draft),
      clientId: _asInt(json['clientId']),
    );
    draft.id = _asId(json['id']);
    draft.createdAt = _asDate(json['createdAt']);
    return draft;
  }

  Map<String, dynamic> _riskReportToJson(RiskReport r) => {
    'id': r.id,
    'createdAt': r.createdAt.toIso8601String(),
    'sourceName': r.sourceName,
    'textLength': r.textLength,
    'safetyIndex': r.safetyIndex,
    'risks': [
      for (final match in r.risks)
        {
          'markerCode': match.markerCode,
          'severity': match.severity.name,
          'matchedText': match.matchedText,
          'start': match.start,
          'end': match.end,
          'description': match.description,
          'example': match.example,
          'suggestion': match.suggestion,
        },
    ],
  };

  RiskReport _riskReportFromJson(Map<String, dynamic> json) {
    final rawRisks = json['risks'];
    final risks = <RiskMatch>[];
    if (rawRisks is List) {
      for (final raw in rawRisks) {
        if (raw is! Map<String, dynamic>) continue;
        risks.add(
          RiskMatch(
            markerCode: _asString(raw['markerCode']),
            severity: _asEnum(RiskSeverity.values, raw['severity'], RiskSeverity.low),
            matchedText: _asString(raw['matchedText']),
            start: _asInt(raw['start']),
            end: _asInt(raw['end']),
            description: _asString(raw['description']),
            example: _asString(raw['example']),
            suggestion: _asString(raw['suggestion']),
          ),
        );
      }
    }
    final report = RiskReport(
      sourceName: _asString(json['sourceName']),
      textLength: _asInt(json['textLength']),
      risks: risks,
      safetyIndex: _asDouble(json['safetyIndex']),
    );
    report.id = _asId(json['id']);
    report.createdAt = _asDate(json['createdAt']);
    return report;
  }

  Map<String, dynamic> _notificationToJson(AppNotification n) => {
    'id': n.id,
    'type': n.type.name,
    'status': n.status.name,
    'title': n.title,
    'body': n.body,
    'createdAt': n.createdAt.toIso8601String(),
    'payload': n.payload,
    'actionLabel': n.actionLabel,
    'readAt': n.readAt?.toIso8601String(),
  };

  AppNotification _notificationFromJson(Map<String, dynamic> json) {
    final notification = AppNotification(
      type: _asEnum(NotificationType.values, json['type'], NotificationType.limit),
      title: _asString(json['title']),
      body: _asString(json['body']),
      createdAt: _asDate(json['createdAt']),
      status: _asEnum(
        NotificationStatus.values,
        json['status'],
        NotificationStatus.unread,
      ),
      payload: _asString(json['payload']),
      actionLabel: _asString(json['actionLabel']),
      readAt: _asDateOrNull(json['readAt']),
    );
    notification.id = _asId(json['id']);
    return notification;
  }

  // --- Шифрование чувствительных полей ---

  Future<void> _encryptTransaction(Transaction t) async {
    t.clientName = await _encrypt(t.clientName);
    t.clientInn = await _encrypt(t.clientInn);
  }

  Future<void> _decryptTransaction(Transaction t) async {
    t.clientName = await _decrypt(t.clientName);
    t.clientInn = await _decrypt(t.clientInn);
  }

  Future<void> _encryptClient(Client c) async {
    c.name = await _encrypt(c.name);
    c.inn = await _encrypt(c.inn);
    c.contacts = await _encrypt(c.contacts);
    c.notes = await _encrypt(c.notes);
  }

  Future<void> _decryptClient(Client c) async {
    c.name = await _decrypt(c.name);
    c.inn = await _decrypt(c.inn);
    c.contacts = await _decrypt(c.contacts);
    c.notes = await _decrypt(c.notes);
  }

  Future<void> _encryptInvoice(Invoice i) async {
    i.clientName = await _encrypt(i.clientName);
    i.clientInn = await _encrypt(i.clientInn);
    i.comment = await _encrypt(i.comment);
  }

  Future<void> _decryptInvoice(Invoice i) async {
    i.clientName = await _decrypt(i.clientName);
    i.clientInn = await _decrypt(i.clientInn);
    i.comment = await _decrypt(i.comment);
  }

  Future<void> _encryptDocument(Document d) async {
    d.counterpartyName = await _encrypt(d.counterpartyName);
    d.counterpartyInn = await _encrypt(d.counterpartyInn);
    d.content = await _encrypt(d.content);
    d.serviceName = await _encrypt(d.serviceName);
    d.result = await _encrypt(d.result);
    d.executorSignatory = await _encrypt(d.executorSignatory);
    d.customerSignatory = await _encrypt(d.customerSignatory);
    d.issuerName = await _encrypt(d.issuerName);
    d.issuerInn = await _encrypt(d.issuerInn);
  }

  Future<void> _decryptDocument(Document d) async {
    d.counterpartyName = await _decrypt(d.counterpartyName);
    d.counterpartyInn = await _decrypt(d.counterpartyInn);
    d.content = await _decrypt(d.content);
    d.serviceName = await _decrypt(d.serviceName);
    d.result = await _decrypt(d.result);
    d.executorSignatory = await _decrypt(d.executorSignatory);
    d.customerSignatory = await _decrypt(d.customerSignatory);
    d.issuerName = await _decrypt(d.issuerName);
    d.issuerInn = await _decrypt(d.issuerInn);
  }

  Future<void> _encryptDraft(ContractDraft draft) async {
    for (final field in draft.filledFields) {
      field.value = await _encrypt(field.value);
    }
  }

  Future<void> _decryptDraft(ContractDraft draft) async {
    for (final field in draft.filledFields) {
      field.value = await _decrypt(field.value);
    }
  }

  Future<void> _encryptRiskReport(RiskReport report) async {
    report.sourceName = await _encrypt(report.sourceName);
    for (final match in report.risks) {
      match.matchedText = await _encrypt(match.matchedText);
    }
  }

  Future<void> _decryptRiskReport(RiskReport report) async {
    report.sourceName = await _decrypt(report.sourceName);
    for (final match in report.risks) {
      match.matchedText = await _decrypt(match.matchedText);
    }
  }

  Future<String> _encrypt(String value) {
    if (value.isEmpty) return Future.value(value);
    return encryption.encrypt(value);
  }

  Future<String> _decrypt(String value) async {
    if (value.isEmpty) return value;
    try {
      return await encryption.decrypt(value);
    } catch (_) {
      // Данные, сохранённые до включения шифрования, читаются как есть.
      return value;
    }
  }

  // --- Разбор значений JSON ---

  static Id _asId(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return 0;
  }

  static int _asInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return 0;
  }

  static int? _asIntOrNull(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return null;
  }

  static double _asDouble(Object? value) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return 0;
  }

  static String _asString(Object? value) => value is String ? value : '';

  static DateTime _asDate(Object? value) {
    if (value is String) {
      final parsed = DateTime.tryParse(value);
      if (parsed != null) return parsed;
    }
    throw const BackupFormatException('Некорректная дата в резервной копии.');
  }

  static DateTime? _asDateOrNull(Object? value) {
    if (value == null) return null;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  static T _asEnum<T extends Enum>(List<T> values, Object? name, T fallback) {
    if (name is String) {
      for (final value in values) {
        if (value.name == name) return value;
      }
    }
    return fallback;
  }

  static String _backupFileName(DateTime date) {
    String two(int value) => value.toString().padLeft(2, '0');
    return 'npd_shield_backup_${date.year}-${two(date.month)}-${two(date.day)}'
        '_${two(date.hour)}${two(date.minute)}${two(date.second)}.json';
  }
}
