import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:npd_shield/data/models/risk_marker.dart';
import 'package:npd_shield/data/repositories/isar_risk_marker_repository.dart';
import 'package:npd_shield/data/risk_markers.dart';

void main() {
  late Isar isar;
  late IsarRiskMarkerRepository repository;

  setUp(() async {
    final dir = await Directory.systemTemp.createTemp('npd_risk_marker_test');
    isar = await Isar.open(
      [RiskMarkerSchema],
      directory: dir.path,
      name: 'risk_marker_test_${dir.path.hashCode}',
    );
    repository = IsarRiskMarkerRepository(isar);
  });

  tearDown(() async {
    await isar.close(deleteFromDisk: true);
  });

  RiskMarker marker({
    String code = 'marker',
    RiskSeverity severity = RiskSeverity.medium,
  }) {
    return RiskMarker(
      code: code,
      pattern: 'риск',
      severity: severity,
      description: 'Описание',
      example: 'Пример',
      suggestion: 'Альтернатива',
    );
  }

  group('IsarRiskMarkerRepository', () {
    test('put и getByCode сохраняют маркер', () async {
      await repository.put(marker(code: 'labor'));

      final found = await repository.getByCode('labor');

      expect(found, isNotNull);
      expect(found!.code, 'labor');
      expect(found.pattern, 'риск');
      expect(found.suggestion, 'Альтернатива');
    });

    test('getByCode возвращает null для неизвестного кода', () async {
      expect(await repository.getByCode('unknown'), isNull);
    });

    test('getAll сортирует маркеры по уровню риска', () async {
      await repository.put(marker(code: 'low', severity: RiskSeverity.low));
      await repository.put(
        marker(code: 'critical', severity: RiskSeverity.critical),
      );
      await repository.put(
        marker(code: 'medium', severity: RiskSeverity.medium),
      );

      final all = await repository.getAll();

      expect(
        all.map((m) => m.severity).toList(),
        [RiskSeverity.critical, RiskSeverity.medium, RiskSeverity.low],
      );
    });

    test('clear удаляет все маркеры', () async {
      await repository.put(marker(code: 'a'));
      await repository.put(marker(code: 'b'));

      await repository.clear();

      expect(await repository.getAll(), isEmpty);
    });
  });

  group('seedRiskMarkers', () {
    test('добавляет встроенную базу маркеров', () async {
      final added = await seedRiskMarkers(repository);

      expect(added, builtInRiskMarkers.length);
      expect(await repository.getAll(), hasLength(builtInRiskMarkers.length));
    });

    test('идемпотентен при повторном запуске', () async {
      await seedRiskMarkers(repository);

      final addedAgain = await seedRiskMarkers(repository);

      expect(addedAgain, 0);
      expect(await repository.getAll(), hasLength(builtInRiskMarkers.length));
    });

    test('обновляет изменившиеся встроенные маркеры', () async {
      await seedRiskMarkers(repository);
      final descriptor = builtInRiskMarkers.first;
      final stored = await repository.getByCode(descriptor.code);
      await repository.put(
        stored!
          ..pattern = 'устаревший шаблон'
          ..suggestion = 'устаревшая альтернатива',
      );

      final added = await seedRiskMarkers(repository);

      expect(added, 0);
      final refreshed = await repository.getByCode(descriptor.code);
      expect(refreshed!.pattern, descriptor.pattern);
      expect(refreshed.suggestion, descriptor.suggestion);
    });

    test('встроенная база содержит все три уровня риска', () async {
      await seedRiskMarkers(repository);

      final severities = (await repository.getAll())
          .map((m) => m.severity)
          .toSet();

      expect(severities, {
        RiskSeverity.critical,
        RiskSeverity.medium,
        RiskSeverity.low,
      });
    });
  });
}
