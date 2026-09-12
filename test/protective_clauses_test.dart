import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:npd_shield/data/built_in_templates.dart';
import 'package:npd_shield/domain/contracts/contract_document.dart';
import 'package:npd_shield/domain/contracts/protective_clauses.dart';

void main() {
  group('withProtectiveClauses', () {
    test('вставляет раздел защитных формулировок перед реквизитами', () {
      const template = 'ДОГОВОР\n\n1. ПРЕДМЕТ\n\nТекст.\n\n'
          '2. РЕКВИЗИТЫ И ПОДПИСИ СТОРОН\n\nИП Иванов\n';

      final result = withProtectiveClauses(template);

      expect(result, contains(protectiveSectionHeading));
      for (final clause in protectiveClauses) {
        expect(result, contains(clause.text));
      }
      expect(
        result.indexOf(protectiveSectionHeading),
        lessThan(result.indexOf('2. РЕКВИЗИТЫ')),
      );
    });

    test('идемпотентна: повторная вставка не дублирует раздел', () {
      const template = '1. ПРЕДМЕТ\n\n2. РЕКВИЗИТЫ\n';
      final once = withProtectiveClauses(template);
      final twice = withProtectiveClauses(once);

      expect(twice, once);
      expect(
        protectiveSectionHeading.allMatches(twice).length,
        1,
      );
    });

    test('добавляет раздел в конец, если блок реквизитов отсутствует', () {
      const template = 'ДОГОВОР\n\n1. ПРЕДМЕТ\n';
      final result = withProtectiveClauses(template);

      expect(result.indexOf(protectiveSectionHeading), greaterThan(0));
    });
  });

  group('composeContractDocument', () {
    test('маркирует защитные формулировки отдельным типом блока', () {
      final document = composeContractDocument('1. ПРЕДМЕТ\n\nТекст.\n', const {});

      final protective = document.blocks
          .where((b) => b.type == ContractBlockType.protective)
          .toList();

      expect(protective, isNotEmpty);
      expect(protective.any((b) => isProtectiveHeading(b.text)), isTrue);
      expect(
        protective.where((b) => isProtectiveClause(b.text)).length,
        greaterThanOrEqualTo(protectiveClauses.length),
      );
      expect(document.plainText, contains('не состоит с ним в трудовых отношениях'));
    });

    test('вставку можно отключить флагом injectProtectiveClauses', () {
      final document = composeContractDocument(
        '1. ПРЕДМЕТ\n\nТекст.\n',
        const {},
        injectProtectiveClauses: false,
      );

      expect(
        document.blocks.where((b) => b.isProtective),
        isEmpty,
      );
      expect(document.plainText, isNot(contains(protectiveSectionHeading)));
    });
  });

  group('встроенные шаблоны', () {
    for (final descriptor in builtInTemplates) {
      test('«${descriptor.code}» содержит 100% защитных формулировок', () async {
        final text = await File(
          templateAssetPath(descriptor.code),
        ).readAsString();

        final document = composeContractDocument(text, const {});

        for (final clause in protectiveClauses) {
          expect(
            document.plainText,
            contains(clause.text),
            reason: 'Шаблон ${descriptor.code} не содержит: ${clause.key}',
          );
        }

        final protective = document.blocks
            .where((b) => b.isProtective)
            .toList();
        expect(
          protective.length,
          greaterThanOrEqualTo(protectiveClauses.length),
          reason: descriptor.code,
        );
      });
    }
  });
}
