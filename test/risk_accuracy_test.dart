import 'package:flutter_test/flutter_test.dart';
import 'package:npd_shield/data/risk_markers.dart';
import 'package:npd_shield/domain/risk/risk_analyzer.dart';

import 'fixtures/risk_contract_corpus.dart';

void main() {
  final analyzer = RiskAnalyzerUseCase(
    builtInRiskMarkers.map((d) => d.toMarker()).toList(),
  );

  group('Точность Risk Shield на тестовой базе', () {
    test('находит не менее 90% размеченных рисков (recall)', () async {
      var expected = 0;
      var found = 0;
      final missed = <String>[];

      for (final doc in unsafeRiskCorpus) {
        final report = await analyzer.analyze(doc.text, sourceName: doc.name);
        final foundCodes = report.risks.map((r) => r.markerCode).toSet();
        for (final code in doc.expectedMarkerCodes) {
          expected++;
          if (foundCodes.contains(code)) {
            found++;
          } else {
            missed.add('${doc.name} → $code');
          }
        }
      }

      final recall = expected == 0 ? 1.0 : found / expected;
      expect(
        recall,
        greaterThan(0.9),
        reason:
            'Recall ${(recall * 100).toStringAsFixed(1)}% ($found/$expected). '
            'Пропущенные риски: $missed',
      );
    });

    test('ложноположительные на безопасных договорах < 5%', () async {
      var flagged = 0;
      final findings = <String>[];

      for (final doc in safeRiskCorpus) {
        final report = await analyzer.analyze(doc.text, sourceName: doc.name);
        final foundCodes = report.risks.map((r) => r.markerCode).toSet();
        if (foundCodes.isNotEmpty) {
          flagged++;
          findings.add('${doc.name} → $foundCodes');
        }
      }

      final fpRate = safeRiskCorpus.isEmpty
          ? 0.0
          : flagged / safeRiskCorpus.length;
      expect(
        fpRate,
        lessThan(0.05),
        reason:
            'False positive rate ${(fpRate * 100).toStringAsFixed(1)}% '
            '($flagged/${safeRiskCorpus.length}). Срабатывания: $findings',
      );
    });

    test('тестовая база сбалансирована по образцам', () {
      expect(unsafeRiskCorpus.length, greaterThanOrEqualTo(10));
      expect(safeRiskCorpus.length, greaterThanOrEqualTo(10));
      for (final doc in unsafeRiskCorpus) {
        expect(doc.expectedMarkerCodes, isNotEmpty, reason: doc.name);
      }
    });

    test('на безопасных образцах нет ни одного совпадения', () async {
      final unexpected = <String>[];
      for (final doc in safeRiskCorpus) {
        final report = await analyzer.analyze(doc.text, sourceName: doc.name);
        for (final risk in report.risks) {
          unexpected.add('${doc.name}: ${risk.markerCode} "${risk.matchedText}"');
        }
      }
      expect(unexpected, isEmpty, reason: 'Ложные срабатывания: $unexpected');
    });
  });
}
