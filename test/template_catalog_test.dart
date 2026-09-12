import 'package:flutter_test/flutter_test.dart';
import 'package:npd_shield/data/built_in_templates.dart';
import 'package:npd_shield/data/models/contract_template.dart';
import 'package:npd_shield/domain/contracts/template_catalog.dart';

import 'helpers/fake_contract_repositories.dart';

void main() {
  group('filterTemplates', () {
    test('без фильтра возвращает все шаблоны', () {
      final templates = [
        template(code: 'a', title: 'A'),
        template(code: 'b', title: 'B'),
      ];

      final result = filterTemplates(templates);

      expect(result.map((t) => t.code), containsAll(['a', 'b']));
    });

    test('фильтрует по категории (сфере)', () {
      final templates = [
        template(code: 'it', sphere: TemplateSphere.it),
        template(code: 'log', sphere: TemplateSphere.logistics),
        template(code: 'uni', sphere: TemplateSphere.universal),
      ];

      final result = filterTemplates(
        templates,
        filter: const TemplateFilter(sphere: TemplateSphere.logistics),
      );

      expect(result.map((t) => t.code), ['log']);
    });

    test('ищет по названию без учёта регистра', () {
      final templates = [
        template(code: 'a', title: 'Разработка мобильного приложения'),
        template(code: 'b', title: 'Перевозка груза'),
      ];

      final result = filterTemplates(
        templates,
        filter: const TemplateFilter(query: 'МОБИЛЬНОГО'),
      );

      expect(result.map((t) => t.code), ['a']);
    });

    test('ищет по описанию, ОКВЭД и примеру', () {
      final templates = [
        template(code: 'a', description: 'Услуги экспедирования груза'),
        template(code: 'b', okved: '62.01', title: 'Разработка'),
        template(
          code: 'c',
          title: 'Дизайн',
          example: 'Дизайн личного кабинета, 150 000 ₽',
        ),
      ];

      expect(
        filterTemplates(
          templates,
          filter: const TemplateFilter(query: 'экспедирования'),
        ).map((t) => t.code),
        ['a'],
      );
      expect(
        filterTemplates(
          templates,
          filter: const TemplateFilter(query: '62.01'),
        ).map((t) => t.code),
        ['b'],
      );
      expect(
        filterTemplates(
          templates,
          filter: const TemplateFilter(query: 'кабинета'),
        ).map((t) => t.code),
        ['c'],
      );
    });

    test('комбинирует поиск и фильтр категории', () {
      final templates = [
        template(
          code: 'it_dev',
          sphere: TemplateSphere.it,
          title: 'Разработка',
        ),
        template(
          code: 'log_dev',
          sphere: TemplateSphere.logistics,
          title: 'Доставка',
        ),
      ];

      final result = filterTemplates(
        templates,
        filter: const TemplateFilter(
          query: 'доставка',
          sphere: TemplateSphere.it,
        ),
      );

      expect(result, isEmpty);
    });

    test('поднимает рекомендованные шаблоны в начало', () {
      final templates = [
        template(code: 'regular', title: 'А'),
        template(code: 'recommended', title: 'Я', recommended: true),
      ];

      final result = filterTemplates(templates);

      expect(result.first.code, 'recommended');
    });

    test('встроенный каталог фильтруется по запросу и категории', () {
      final all = builtInTemplates.map((d) => d.toTemplate()).toList();

      final it = filterTemplates(
        all,
        filter: const TemplateFilter(sphere: TemplateSphere.it),
      );
      expect(it.length, 10);

      final logistics = filterTemplates(
        all,
        filter: const TemplateFilter(sphere: TemplateSphere.logistics),
      );
      expect(logistics.length, 10);

      final courier = filterTemplates(
        all,
        filter: const TemplateFilter(query: 'курьер'),
      );
      expect(courier, isNotEmpty);
      expect(
        courier.every((t) => t.sphere == TemplateSphere.logistics),
        isTrue,
      );
    });
  });
}
