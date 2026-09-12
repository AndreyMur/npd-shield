import 'package:flutter_test/flutter_test.dart';
import 'package:npd_shield/core/validation/contract_input.dart';

void main() {
  group('ContractInput.validate', () {
    test('отклоняет плейсхолдеры шаблона', () {
      expect(ContractInput.validate('{{clientName}}'), isNotNull);
      expect(ContractInput.isSafe('{{x}}'), isFalse);
    });

    test('отклоняет управляющие и невидимые символы', () {
      expect(ContractInput.validate('ООО\u0000Ромашка'), isNotNull);
      expect(ContractInput.validate('ООО\u200BРомашка'), isNotNull);
    });

    test('отклоняет исполняемую разметку', () {
      expect(ContractInput.validate('<script>alert(1)</script>'), isNotNull);
      expect(ContractInput.validate('<iframe src="x"></iframe>'), isNotNull);
    });

    test('пропускает обычный текст', () {
      expect(ContractInput.validate('ООО «Ромашка», г. Москва'), isNull);
      expect(ContractInput.validate(''), isNull);
    });

    test('отклоняет слишком длинное значение', () {
      final long = 'а' * (ContractInput.maxValueLength + 1);
      expect(ContractInput.validate(long), isNotNull);
    });
  });

  group('ContractInput.sanitize', () {
    test('обезвреживает плейсхолдеры и управляющие символы', () {
      final sanitized = ContractInput.sanitize('a{{b}}\u0000c');

      expect(sanitized, isNot(contains('{{')));
      expect(sanitized, isNot(contains('}}')));
      expect(sanitized, isNot(contains('\u0000')));
    });

    test('ограничивает длину значения', () {
      final long = 'a' * (ContractInput.maxValueLength + 100);

      expect(
        ContractInput.sanitize(long).length,
        ContractInput.maxValueLength,
      );
    });

    test('не меняет безопасный текст', () {
      expect(
        ContractInput.sanitize('Иванов Иван Иванович'),
        'Иванов Иван Иванович',
      );
    });
  });

  group('ContractInput.validateTemplate', () {
    test('пропускает корректный шаблон', () {
      expect(
        ContractInput.validateTemplate('Договор № {{contractNumber}}'),
        isNull,
      );
    });

    test('отклоняет исполняемую разметку', () {
      expect(
        ContractInput.validateTemplate('<script>x</script>'),
        isNotNull,
      );
    });

    test('отклоняет некорректные плейсхолдеры', () {
      expect(ContractInput.validateTemplate('{{ bad key }}'), isNotNull);
      expect(ContractInput.validateTemplate('{{unclosed'), isNotNull);
    });
  });

  group('ContractInputFormatter', () {
    test('удаляет фигурные скобки и управляющие символы', () {
      const formatter = ContractInputFormatter();

      final result = formatter.formatEditUpdate(
        TextEditingValue.empty,
        const TextEditingValue(text: 'a{{b}}c\u0000'),
      );

      expect(result.text, 'a((b))c');
    });

    test('не меняет безопасный текст', () {
      const formatter = ContractInputFormatter();

      final result = formatter.formatEditUpdate(
        TextEditingValue.empty,
        const TextEditingValue(text: 'ООО «Ромашка»'),
      );

      expect(result.text, 'ООО «Ромашка»');
    });
  });
}
