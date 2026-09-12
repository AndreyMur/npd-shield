import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:npd_shield/data/built_in_templates.dart';
import 'package:npd_shield/data/models/contract_template.dart';
import 'package:npd_shield/data/repositories/isar_contract_template_repository.dart';

void main() {
  late Isar isar;
  late IsarContractTemplateRepository repository;

  setUp(() async {
    final dir = await Directory.systemTemp.createTemp('npd_template_test');
    isar = await Isar.open(
      [TemplateSchema],
      directory: dir.path,
      name: 'template_test_${dir.path.hashCode}',
    );
    repository = IsarContractTemplateRepository(isar);
  });

  tearDown(() async {
    await isar.close(deleteFromDisk: true);
  });

  Template tpl({
    String code = 'it_test',
    TemplateSphere sphere = TemplateSphere.it,
    String title = 'Шаблон',
    String description = 'Описание',
  }) {
    return Template(
      code: code,
      sphere: sphere,
      title: title,
      description: description,
    );
  }

  group('IsarContractTemplateRepository', () {
    test(
      'put and getAll return templates ordered by sphere then title',
      () async {
        await repository.put(
          tpl(
            code: 'logistics_a',
            sphere: TemplateSphere.logistics,
            title: 'А',
          ),
        );
        await repository.put(
          tpl(code: 'it_b', sphere: TemplateSphere.it, title: 'Б'),
        );
        await repository.put(
          tpl(code: 'it_a', sphere: TemplateSphere.it, title: 'А'),
        );
        await repository.put(
          tpl(
            code: 'universal_c',
            sphere: TemplateSphere.universal,
            title: 'В',
          ),
        );

        final all = await repository.getAll();

        expect(all.length, 4);
        expect(all.map((t) => t.code).toList(), [
          'it_a',
          'it_b',
          'logistics_a',
          'universal_c',
        ]);
      },
    );

    test('getBySphere filters by sphere', () async {
      await repository.put(tpl(code: 'it_a', sphere: TemplateSphere.it));
      await repository.put(
        tpl(code: 'logistics_a', sphere: TemplateSphere.logistics),
      );

      final it = await repository.getBySphere(TemplateSphere.it);
      final logistics = await repository.getBySphere(TemplateSphere.logistics);

      expect(it.map((t) => t.code), ['it_a']);
      expect(logistics.map((t) => t.code), ['logistics_a']);
    });

    test('getByCode finds template by stable code', () async {
      await repository.put(tpl(code: 'it_known', title: 'Известный'));

      final found = await repository.getByCode('it_known');
      final missing = await repository.getByCode('unknown');

      expect(found?.title, 'Известный');
      expect(missing, isNull);
    });

    test('put обновляет шаблон по его Isar id без дублирования', () async {
      await repository.put(tpl(code: 'it_same', title: 'Старое название'));
      final stored = (await repository.getByCode('it_same'))!;
      stored.title = 'Новое название';
      await repository.put(stored);

      final all = await repository.getAll();

      expect(all.length, 1);
      expect(all.single.title, 'Новое название');
    });

    test('clear removes all templates', () async {
      await repository.put(tpl(code: 'it_a'));
      await repository.clear();

      expect(await repository.getAll(), isEmpty);
    });
  });

  group('built_in_templates', () {
    test(
      'каталог содержит 20+ шаблонов: 10 IT, 10 логистики, 2 универсальных',
      () {
        expect(builtInTemplates.length, greaterThanOrEqualTo(20));
        expect(
          builtInTemplates.where((t) => t.sphere == TemplateSphere.it).length,
          10,
        );
        expect(
          builtInTemplates
              .where((t) => t.sphere == TemplateSphere.logistics)
              .length,
          10,
        );
        expect(
          builtInTemplates
              .where((t) => t.sphere == TemplateSphere.universal)
              .length,
          2,
        );
      },
    );

    test('коды шаблонов уникальны', () {
      final codes = builtInTemplates.map((t) => t.code).toSet();
      expect(codes.length, builtInTemplates.length);
    });

    test('каждый шаблон адаптирован под ОКВЭД сферы', () {
      for (final descriptor in builtInTemplates) {
        expect(descriptor.okved, isNotEmpty, reason: descriptor.code);
        switch (descriptor.sphere) {
          case TemplateSphere.it:
            expect(descriptor.okved, anyOf('62.01', '62.02'));
          case TemplateSphere.logistics:
            expect(descriptor.okved, '49.41');
          case TemplateSphere.universal:
            break;
        }
      }
    });

    test('каждый шаблон содержит пример заполнения', () {
      for (final descriptor in builtInTemplates) {
        expect(descriptor.example, isNotEmpty, reason: descriptor.code);
      }
    });

    test('есть рекомендованные шаблоны в IT и логистике', () {
      expect(
        builtInTemplates.where((t) => t.recommended).length,
        greaterThanOrEqualTo(2),
      );
      expect(
        builtInTemplates.any(
          (t) => t.recommended && t.sphere == TemplateSphere.it,
        ),
        isTrue,
      );
      expect(
        builtInTemplates.any(
          (t) => t.recommended && t.sphere == TemplateSphere.logistics,
        ),
        isTrue,
      );
    });

    test(
      'seed добавляет шаблоны и идемпотентен при повторном вызове',
      () async {
        final first = await seedBuiltInTemplates(repository);
        final second = await seedBuiltInTemplates(repository);

        expect(first, builtInTemplates.length);
        expect(second, 0);
        expect(await repository.getAll(), hasLength(builtInTemplates.length));
      },
    );

    test('пути к текстам шаблонов указывают на assets', () {
      for (final descriptor in builtInTemplates) {
        final path = templateAssetPath(descriptor.code);
        expect(path, startsWith('assets/templates/'));
        expect(path, endsWith('.txt'));
      }
    });
  });
}
