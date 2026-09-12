import 'package:flutter_test/flutter_test.dart';
import 'package:npd_shield/domain/risk/risk_file_limits.dart';

void main() {
  group('лимит размера TXT-файла', () {
    test('ровно 100 КБ ASCII проходит проверку', () {
      final text = 'a' * maxRiskContractFileBytes;

      expect(riskContractByteLength(text), maxRiskContractFileBytes);
      expect(isRiskContractWithinLimit(text), isTrue);
    });

    test('100 КБ + 1 байт не проходит проверку', () {
      final text = 'a' * (maxRiskContractFileBytes + 1);

      expect(riskContractByteLength(text), maxRiskContractFileBytes + 1);
      expect(isRiskContractWithinLimit(text), isFalse);
    });

    test('кириллица считается в байтах UTF-8 (2 байта на символ)', () {
      final text = 'я' * (maxRiskContractFileBytes ~/ 2);

      expect(riskContractByteLength(text), maxRiskContractFileBytes);
      expect(isRiskContractWithinLimit(text), isTrue);
      expect(isRiskContractWithinLimit('$text я'), isFalse);
    });

    test('пустой текст проходит проверку', () {
      expect(isRiskContractWithinLimit(''), isTrue);
    });

    test('исключение хранит фактический и максимальный размер', () {
      const error = ContractFileTooLargeException(
        actualBytes: 200 * 1024,
        maxBytes: maxRiskContractFileBytes,
      );

      expect(error.actualBytes, 200 * 1024);
      expect(error.maxBytes, maxRiskContractFileBytes);
      expect(error.toString(), contains('${200 * 1024}'));
    });
  });
}
