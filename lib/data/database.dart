import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

import 'models/app_notification.dart';
import 'models/contract_draft.dart';
import 'models/contract_template.dart';
import 'models/document.dart';
import 'models/risk_marker.dart';
import 'models/transaction.dart';

class AppDatabase {
  AppDatabase._();

  static late Isar instance;

  /// Все коллекции приложения.
  ///
  /// Вынесены отдельно, чтобы тесты могли открывать ту же схему, что и
  /// приложение, и проверять миграцию без дублирования списка.
  static List<CollectionSchema<dynamic>> get schemas => [
    TransactionSchema,
    TemplateSchema,
    ContractDraftSchema,
    RiskMarkerSchema,
    RiskReportSchema,
    DocumentSchema,
    AppNotificationSchema,
  ];

  /// Открывает базу данных приложения.
  ///
  /// Миграции схемы выполняются Isar автоматически: при добавлении новых
  /// коллекций или полей существующая база обновляется без потери данных.
  /// Удалённые поля помечаются как устаревшие и игнорируются при чтении.
  static Future<Isar> open({String? path}) async {
    final isarDir = path ?? (await getApplicationDocumentsDirectory()).path;

    instance = await Isar.open(
      schemas,
      directory: isarDir,
      name: 'npd_shield',
    );
    return instance;
  }
}
