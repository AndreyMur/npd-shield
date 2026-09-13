import 'package:flutter_test/flutter_test.dart';
import 'package:npd_shield/data/models/risk_marker.dart';
import 'package:npd_shield/data/risk_markers.dart';

void main() {
  group('Встроенная база маркеров риска', () {
    test('содержит не менее 50 маркеров', () {
      expect(builtInRiskMarkers.length, greaterThanOrEqualTo(50));
    });

    test('коды маркеров уникальны', () {
      final codes = builtInRiskMarkers.map((d) => d.code).toList();
      expect(codes.toSet().length, codes.length);
    });

    test('каждый маркер содержит все обязательные поля', () {
      for (final marker in builtInRiskMarkers) {
        expect(marker.code, isNotEmpty, reason: marker.code);
        expect(marker.pattern, isNotEmpty, reason: marker.code);
        expect(marker.description, isNotEmpty, reason: marker.code);
        expect(marker.example, isNotEmpty, reason: marker.code);
        expect(marker.suggestion, isNotEmpty, reason: marker.code);
      }
    });

    test('все RegExp-шаблоны компилируются', () {
      for (final marker in builtInRiskMarkers) {
        expect(
          () => RegExp(
            marker.pattern,
            caseSensitive: false,
            multiLine: true,
            dotAll: true,
            unicode: true,
          ),
          returnsNormally,
          reason: 'Некорректный шаблон у ${marker.code}: ${marker.pattern}',
        );
      }
    });

    test('представлены все три уровня риска', () {
      final severities = builtInRiskMarkers.map((d) => d.severity).toSet();
      expect(severities, {
        RiskSeverity.critical,
        RiskSeverity.medium,
        RiskSeverity.low,
      });
    });

    test('каждый уровень содержит не менее пяти маркеров', () {
      for (final severity in RiskSeverity.values) {
        final count = builtInRiskMarkers
            .where((d) => d.severity == severity)
            .length;
        expect(count, greaterThanOrEqualTo(5), reason: severity.name);
      }
    });

    test('toMarker переносит поля без потерь', () {
      final descriptor = builtInRiskMarkers.first;
      final marker = descriptor.toMarker();

      expect(marker.code, descriptor.code);
      expect(marker.pattern, descriptor.pattern);
      expect(marker.severity, descriptor.severity);
      expect(marker.description, descriptor.description);
      expect(marker.example, descriptor.example);
      expect(marker.suggestion, descriptor.suggestion);
    });
  });
}
