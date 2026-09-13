import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:npd_shield/data/models/risk_marker.dart';
import 'package:npd_shield/data/repositories/isar_risk_report_repository.dart';
import 'package:npd_shield/data/security/field_encryption_service.dart';

void main() {
  late Isar isar;
  late IsarRiskReportRepository repository;

  setUp(() async {
    final dir = await Directory.systemTemp.createTemp('npd_risk_report_test');
    isar = await Isar.open(
      [RiskReportSchema],
      directory: dir.path,
      name: 'risk_report_test_${dir.path.hashCode}',
    );
    repository = IsarRiskReportRepository(
      isar,
      encryption: const _PassthroughEncryption(),
    );
  });

  tearDown(() async {
    await isar.close(deleteFromDisk: true);
  });

  RiskReport report({
    String sourceName = 'dogovor.txt',
    DateTime? createdAt,
    List<RiskMatch>? risks,
  }) {
    final result = RiskReport(
      sourceName: sourceName,
      textLength: 120,
      risks: risks ?? const [],
      safetyIndex: 40,
    );
    result.createdAt = createdAt ?? result.createdAt;
    return result;
  }

  RiskMatch match({String matchedText = 'трудовой договор'}) {
    return RiskMatch(
      markerCode: 'labor_contract_term',
      severity: RiskSeverity.critical,
      matchedText: matchedText,
      start: 0,
      end: matchedText.length,
      description: 'Описание',
      example: 'Пример',
      suggestion: 'Альтернатива',
    );
  }

  group('IsarRiskReportRepository', () {
    test('save присваивает id и позволяет прочитать отчёт', () async {
      final id = await repository.save(report(risks: [match()]));

      final found = await repository.getById(id);

      expect(id, isNot(0));
      expect(found, isNotNull);
      expect(found!.sourceName, 'dogovor.txt');
      expect(found.textLength, 120);
      expect(found.safetyIndex, 40);
      expect(found.risks, hasLength(1));
      expect(found.risks.single.markerCode, 'labor_contract_term');
      expect(found.risks.single.severity, RiskSeverity.critical);
    });

    test('getAll возвращает отчёты от новых к старым', () async {
      final now = DateTime(2026, 9, 10);
      await repository.save(
        report(sourceName: 'a', createdAt: now.subtract(const Duration(days: 1))),
      );
      await repository.save(report(sourceName: 'b', createdAt: now));
      await repository.save(
        report(sourceName: 'c', createdAt: now.subtract(const Duration(days: 2))),
      );

      final all = await repository.getAll();

      expect(all.map((r) => r.sourceName).toList(), ['b', 'a', 'c']);
    });

    test('delete и clear удаляют отчёты', () async {
      final id1 = await repository.save(report(sourceName: 'a'));
      await repository.save(report(sourceName: 'b'));

      await repository.delete(id1);
      expect(await repository.getById(id1), isNull);
      expect(await repository.getAll(), hasLength(1));

      await repository.clear();
      expect(await repository.getAll(), isEmpty);
    });

    test('riskCount отражает число сохранённых рисков', () async {
      await repository.save(
        report(risks: [match(), match(matchedText: 'оплачиваемый отпуск')]),
      );

      final all = await repository.getAll();

      expect(all.single.riskCount, 2);
    });
  });

  group('шифрование отчётов', () {
    test('sourceName и matchedText шифруются и расшифровываются', () async {
      final encryptedRepo = IsarRiskReportRepository(
        isar,
        encryption: const _PrefixEncryption(),
      );
      final id = await encryptedRepo.save(
        report(sourceName: 'dogovor.txt', risks: [match()]),
      );

      final raw = await isar.riskReports.where().idEqualTo(id).findFirst();
      expect(raw!.sourceName, startsWith('enc:'));
      expect(raw.risks.single.matchedText, startsWith('enc:'));

      final loaded = await encryptedRepo.getById(id);
      expect(loaded!.sourceName, 'dogovor.txt');
      expect(loaded.risks.single.matchedText, 'трудовой договор');
    });
  });
}

/// Шифрование-заглушка: хранит значение как есть (для тестов механики репозитория).
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
