import 'package:flutter_test/flutter_test.dart';
import 'package:npd_shield/domain/contracts/contract_document.dart';

const _template = '''
ДОГОВОР № {{contractNumber}}
на разработку программного обеспечения

г. {{contractCity}}                                                    «{{contractDate}}»

1. ПРЕДМЕТ ДОГОВОРА

1.1. Исполнитель выполняет работы, описание: {{subject}}.

2. РЕКВИЗИТЫ И ПОДПИСИ СТОРОН

Исполнитель:
ИП {{executorFullName}}
ИНН {{executorInn}}

_______________________ / {{executorFullName}} /

_______________________ / ______________ /
''';

void main() {
  group('composeContractDocument', () {
    final values = <String, String>{
      'contractNumber': '14/09',
      'contractDate': '05.09.2026',
      'contractCity': 'Казань',
      'subject': 'разработка сайта',
      'executorFullName': 'Иванов Иван Иванович',
      'executorInn': '771234567890',
    };

    test('заменяет плейсхолдеры значениями и не оставляет нерешённых ключей', () {
      final document = composeContractDocument(_template, values);

      expect(document.unresolvedKeys, isEmpty);
      expect(document.plainText, isNot(contains('{{')));
      expect(document.plainText, contains('ДОГОВОР № 14/09'));
      expect(document.plainText, contains('г. Казань «05.09.2026»'));
      expect(document.plainText, contains('описание: разработка сайта'));
      expect(document.plainText, contains('ИП Иванов Иван Иванович'));
    });

    test('сохраняет кириллический текст без искажений', () {
      final document = composeContractDocument(_template, values);
      expect(document.plainText, contains('на разработку программного обеспечения'));
      expect(document.plainText, contains('Исполнитель выполняет работы'));
      expect(document.plainText, contains('ПРЕДМЕТ ДОГОВОРА'));
    });

    test('отмечает отсутствующие значения как нерешённые ключи', () {
      final document = composeContractDocument(_template, const {
        'contractNumber': '1',
      });
      expect(document.unresolvedKeys, containsAll([
        'contractDate',
        'contractCity',
        'subject',
        'executorFullName',
        'executorInn',
      ]));
    });

    test('классифицирует блоки: шапка, заголовок, тело, подпись', () {
      final document = composeContractDocument(_template, values);

      final titles = document.blocks
          .where((b) => b.type == ContractBlockType.title)
          .toList();
      expect(titles, hasLength(1));
      expect(titles.single.text, 'ДОГОВОР № 14/09');

      final subtitles = document.blocks
          .where((b) => b.type == ContractBlockType.subtitle)
          .toList();
      expect(subtitles.single.text, 'на разработку программного обеспечения');

      final headings = document.blocks
          .where((b) => b.type == ContractBlockType.heading)
          .map((b) => b.text)
          .toList();
      expect(headings, ['1. ПРЕДМЕТ ДОГОВОРА', '2. РЕКВИЗИТЫ И ПОДПИСИ СТОРОН']);

      final signature = document.blocks
          .where((b) => b.type == ContractBlockType.signature)
          .toList();
      expect(signature, hasLength(2));
      expect(signature.first.text, contains('Иванов Иван Иванович'));
    });

    test('разделяет строку «г. Город … дата» на meta-блок с выравниванием', () {
      final document = composeContractDocument(_template, values);
      final meta = document.blocks
          .where((b) => b.type == ContractBlockType.meta)
          .toList();
      expect(meta, hasLength(1));
      expect(meta.single.text, 'г. Казань');
      expect(meta.single.secondaryText, '«05.09.2026»');
    });

    test('превращает пустые строки шаблона в spacing-блоки', () {
      final document = composeContractDocument(_template, values);
      final spacings = document.blocks
          .where((b) => b.type == ContractBlockType.spacing)
          .toList();
      expect(spacings, isNotEmpty);
      expect(spacings.every((b) => b.spacingSteps >= 1), isTrue);
    });

    test('не ломается при отсутствии значений: пустые строки остаются пустыми', () {
      final document = composeContractDocument(_template, const {});
      expect(document.unresolvedKeys, isNotEmpty);
      expect(document.plainText, isNot(contains('{{')));
    });
  });
}
