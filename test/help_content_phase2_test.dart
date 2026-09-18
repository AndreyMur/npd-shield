import 'package:flutter_test/flutter_test.dart';
import 'package:npd_shield/data/help_articles.dart';
import 'package:npd_shield/data/repositories/help_repository.dart';
import 'package:npd_shield/domain/help/help_article.dart';

void main() {
  group('Контент справочника: полнота', () {
    test('покрыты все 11 рабочих разделов приложения', () {
      final covered = builtInHelpArticles
          .map((article) => article.section)
          .toSet();

      for (final section in HelpSection.values.where(
        (section) => section.isAppSection,
      )) {
        expect(
          covered,
          contains(section),
          reason: 'Нет ни одной статьи для раздела «${section.label}»',
        );
      }
    });

    test('вспомогательные разделы не считаются рабочими', () {
      expect(HelpSection.gettingStarted.isAppSection, isFalse);
      expect(HelpSection.scenarios.isAppSection, isFalse);
      expect(
        HelpSection.values.where((section) => section.isAppSection),
        hasLength(11),
      );
    });

    test('у каждой статьи заполнены заголовок, описание и шаги', () {
      for (final article in builtInHelpArticles) {
        expect(
          article.title.trim(),
          isNotEmpty,
          reason: 'Пустой заголовок у статьи ${article.id}',
        );
        expect(
          article.summary.trim(),
          isNotEmpty,
          reason: 'Пустое описание у статьи ${article.id}',
        );
        expect(
          article.steps,
          isNotEmpty,
          reason: 'Нет шагов у статьи ${article.id}',
        );
        for (final step in article.steps) {
          expect(
            step.trim(),
            isNotEmpty,
            reason: 'Пустой шаг у статьи ${article.id}',
          );
        }
      }
    });

    test('вопросы и подсказки заполнены целиком', () {
      for (final article in builtInHelpArticles) {
        for (final item in article.faq) {
          expect(
            item.question.trim(),
            isNotEmpty,
            reason: 'Пустой вопрос у статьи ${article.id}',
          );
          expect(
            item.answer.trim(),
            isNotEmpty,
            reason: 'Пустой ответ у статьи ${article.id}',
          );
        }
      }
    });

    test('идентификаторы статей уникальны', () {
      final ids = builtInHelpArticles.map((article) => article.id).toList();

      expect(ids.toSet(), hasLength(ids.length));
    });

    test('есть статьи для блока «С чего начать»', () {
      expect(builtInHelpArticles.where((article) => article.quickStart), isNotEmpty);
    });

    test('покрыты ключевые сквозные сценарии', () {
      final ids = builtInHelpArticles.map((article) => article.id).toSet();

      expect(
        ids,
        containsAll([
          'getting_started',
          'scenario_my_tax',
          'scenario_pdf',
          'scenario_backup',
          'scenario_contract',
          'scenario_risk_check',
        ]),
      );
    });
  });

  group('Контент справочника: связи', () {
    test('связанные статьи ссылаются на существующие материалы', () {
      final ids = builtInHelpArticles.map((article) => article.id).toSet();

      for (final article in builtInHelpArticles) {
        for (final relatedId in article.relatedIds) {
          expect(
            ids,
            contains(relatedId),
            reason:
                'Статья ${article.id} ссылается на несуществующую статью '
                '$relatedId',
          );
        }
      }
    });

    test('статья не ссылается сама на себя', () {
      for (final article in builtInHelpArticles) {
        expect(
          article.relatedIds,
          isNot(contains(article.id)),
          reason: 'Статья ${article.id} ссылается на себя',
        );
      }
    });
  });

  group('EmbeddedHelpRepository', () {
    const repository = EmbeddedHelpRepository();

    test('getArticles возвращает весь встроенный контент', () {
      expect(repository.getArticles(), hasLength(builtInHelpArticles.length));
    });

    test('getArticleById находит статью и возвращает null для неизвестной', () {
      expect(repository.getArticleById('dashboard_overview'), isNotNull);
      expect(repository.getArticleById('unknown'), isNull);
    });

    test('getArticlesBySection возвращает только статьи раздела', () {
      final articles = repository.getArticlesBySection(HelpSection.invoices);

      expect(articles, isNotEmpty);
      expect(
        articles.every((article) => article.section == HelpSection.invoices),
        isTrue,
      );
    });

    test('getSections возвращает разделы с контентом в порядке объявления', () {
      final sections = repository.getSections();

      expect(sections.first, HelpSection.gettingStarted);
      expect(sections, contains(HelpSection.scenarios));
      expect(sections, contains(HelpSection.dashboard));
      expect(
        sections,
        orderedEquals(
          HelpSection.values.where(sections.contains).toList(),
        ),
      );
    });

    test('getQuickStartArticles возвращает только вводные статьи', () {
      final articles = repository.getQuickStartArticles();

      expect(articles, isNotEmpty);
      expect(articles.every((article) => article.quickStart), isTrue);
    });

    test('список статей защищён от изменения', () {
      expect(
        () => repository.getArticles().add(builtInHelpArticles.first),
        throwsUnsupportedError,
      );
    });
  });
}
