import 'package:isar/isar.dart';

import '../models/risk_marker.dart';
import '../security/database_encryption_service.dart';
import '../security/field_encryption_service.dart';
import 'risk_report_repository.dart';

class IsarRiskReportRepository implements RiskReportRepository {
  final Isar isar;
  final FieldEncryptionService _encryptionService;

  IsarRiskReportRepository(this.isar, {FieldEncryptionService? encryption})
    : _encryptionService = encryption ?? DatabaseEncryptionService();

  @override
  Future<int> save(RiskReport report) {
    return isar.writeTxn(() async {
      await _encryptFields(report);
      return isar.riskReports.put(report);
    });
  }

  @override
  Future<RiskReport?> getById(int id) async {
    final report = await isar.riskReports.where().idEqualTo(id).findFirst();
    if (report != null) {
      await _decryptFields(report);
    }
    return report;
  }

  @override
  Future<List<RiskReport>> getAll() async {
    final reports = await isar.riskReports
        .where()
        .sortByCreatedAtDesc()
        .findAll();
    for (final report in reports) {
      await _decryptFields(report);
    }
    return reports;
  }

  @override
  Future<void> delete(int id) {
    return isar.writeTxn(() => isar.riskReports.delete(id));
  }

  @override
  Future<void> clear() {
    return isar.writeTxn(() => isar.riskReports.clear());
  }

  /// Шифрует имя файла и найденные фрагменты договора перед записью.
  ///
  /// Текст договора содержит персональные данные сторон, поэтому
  /// чувствительные строки шифруются на уровне поля — как данные клиентов
  /// в транзакциях и заполненные поля черновиков.
  Future<void> _encryptFields(RiskReport report) async {
    if (report.sourceName.isNotEmpty) {
      report.sourceName = await _encryptionService.encrypt(report.sourceName);
    }
    for (final match in report.risks) {
      if (match.matchedText.isEmpty) continue;
      match.matchedText = await _encryptionService.encrypt(match.matchedText);
    }
  }

  /// Расшифровывает имя файла и фрагменты при чтении.
  Future<void> _decryptFields(RiskReport report) async {
    if (report.sourceName.isNotEmpty) {
      report.sourceName = await _decrypt(report.sourceName);
    }
    for (final match in report.risks) {
      if (match.matchedText.isEmpty) continue;
      match.matchedText = await _decrypt(match.matchedText);
    }
  }

  Future<String> _decrypt(String value) async {
    try {
      return await _encryptionService.decrypt(value);
    } catch (_) {
      // Если расшифровка не удалась, оставляем значение как есть.
      // Это возможно при чтении данных, сохранённых до включения шифрования.
      return value;
    }
  }
}
