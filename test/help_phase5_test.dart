import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:npd_shield/core/theme/app_theme.dart';
import 'package:npd_shield/core/theme/app_tokens.dart';
import 'package:npd_shield/data/help_articles.dart';
import 'package:npd_shield/data/repositories/help_repository.dart';
import 'package:npd_shield/domain/help/help_article.dart';
import 'package:npd_shield/domain/help/help_search.dart';
import 'package:npd_shield/presentation/help/help_article_screen.dart';
import 'package:npd_shield/presentation/help/help_screen.dart';

void main() {
  const repository = EmbeddedHelpRepository();

  Future<void> pumpHelp(
    WidgetTester tester, {
    required double width,
    double height = 2400,
  }) async {
    tester.view.physicalSize = Size(width, height);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light(null), home: const HelpScreen()),
    );
    await tester.pumpAndSettle();
  }

  Future<void> pumpArticle(
    WidgetTester tester, {
    required String id,
    required double width,
    double height = 2400,
  }) async {
    tester.view.physicalSize = Size(width, height);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final article = repository.getArticleById(id)!;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(null),
        home: HelpArticleScreen(article: article, repository: repository),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('Фаза 5: адаптивность экрана «Помощь»', () {
    testWidgets('на мобильной ширине контент занимает доступную ширину', (
      tester,
    ) async {
      await pumpHelp(tester, width: 360);

      expect(find.byKey(const Key('help_screen')), findsOneWidget);
      expect(find.byKey(const Key('help_search_field')), findsOneWidget);
      expect(find.byKey(const Key('help_toc_title')), findsOneWidget);
      expect(
        tester.getSize(find.byKey(const Key('help_content_constraints'))).width,
        360,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('на широком экране контент ограничен читаемой шириной', (
      tester,
    ) async {
      await pumpHelp(tester, width: 1400);

      final contentWidth = tester
          .getSize(find.byKey(const Key('help_content_constraints')))
          .width;
      expect(contentWidth, AppBreakpoints.contentMaxWidth);
      expect(contentWidth, lessThan(1400));
      expect(tester.takeException(), isNull);
    });

    testWidgets('на ширине 320 px нет переполнения', (tester) async {
      await pumpHelp(tester, width: 320);

      expect(find.byKey(const Key('help_search_field')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('статья адаптивна на мобильном и широком экранах', (
      tester,
    ) async {
      await pumpArticle(tester, id: 'getting_started', width: 360);
      expect(
        tester
            .getSize(find.byKey(const Key('help_article_content_constraints')))
            .width,
        360,
      );
      expect(tester.takeException(), isNull);

      await pumpArticle(tester, id: 'getting_started', width: 1400);
      expect(
        tester
            .getSize(find.byKey(const Key('help_article_content_constraints')))
            .width,
        AppBreakpoints.contentMaxWidth,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('статья не переполняет экран при 320 px', (tester) async {
      await pumpArticle(tester, id: 'scenario_backup', width: 320);
      expect(find.byKey(const Key('help_article_screen')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('Фаза 5: состояния экрана «Помощь»', () {
    testWidgets('поле поиска закреплено вне прокручиваемого списка', (
      tester,
    ) async {
      await pumpHelp(tester, width: 400, height: 800);

      expect(
        find.ancestor(
          of: find.byKey(const Key('help_search_field')),
          matching: find.byType(Scrollable),
        ),
        findsNothing,
      );
    });

    testWidgets('прокрутка оглавления не смещает поле поиска', (tester) async {
      await pumpHelp(tester, width: 400, height: 800);

      final searchFinder = find.byKey(const Key('help_search_field'));
      final before = tester.getTopLeft(searchFinder);

      await tester.drag(
        find.byKey(const Key('help_toc_scroll')),
        const Offset(0, -400),
      );
      await tester.pumpAndSettle();

      expect(tester.getTopLeft(searchFinder), before);
      expect(find.byKey(const Key('help_toc_scroll')), findsOneWidget);
    });

    testWidgets('пустой поиск показывает оглавление', (tester) async {
      await pumpHelp(tester, width: 400);

      expect(find.byKey(const Key('help_toc_title')), findsOneWidget);
      expect(find.byKey(const Key('help_search_results_title')), findsNothing);
    });

    testWidgets('нет результатов — понятное сообщение и вход в оглавление', (
      tester,
    ) async {
      await pumpHelp(tester, width: 400);

      await tester.enterText(
        find.byKey(const Key('help_search_field')),
        'нет-такой-статьи-в-справочнике',
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('help_search_empty')), findsOneWidget);
      expect(find.text('Ничего не найдено'), findsOneWidget);
      expect(find.byKey(const Key('help_search_open_toc')), findsOneWidget);

      await tester.tap(find.byKey(const Key('help_search_open_toc')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('help_toc_title')), findsOneWidget);
      expect(find.byKey(const Key('help_search_empty')), findsNothing);
    });

    testWidgets('длинная статья прокручивается до дисклеймера', (tester) async {
      await pumpArticle(tester, id: 'getting_started', width: 400, height: 600);

      final disclaimer = find.byKey(const Key('help_disclaimer'));

      await tester.scrollUntilVisible(disclaimer, 300);
      await tester.pumpAndSettle();

      expect(disclaimer, findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('Фаза 5: офлайн и производительность', () {
    test('поиск синхронный и работает по встроенному контенту', () {
      final result = repository.search('договор');

      expect(result, isA<List<HelpArticle>>());
      expect(result, isNotEmpty);
      expect(result.every(builtInHelpArticles.contains), isTrue);
    });

    test('отклик поиска укладывается в 200 мс', () {
      const queries = ['договор', 'оплата счёта', 'налог', 'лимит НПД'];
      const iterations = 50;

      final stopwatch = Stopwatch()..start();
      for (var i = 0; i < iterations; i++) {
        for (final query in queries) {
          searchHelpArticles(builtInHelpArticles, query);
        }
      }
      stopwatch.stop();

      final perSearch =
          stopwatch.elapsedMilliseconds / (iterations * queries.length);
      expect(
        perSearch,
        lessThan(200),
        reason: 'Средний отклик поиска: ${perSearch.toStringAsFixed(3)} мс',
      );
    });
  });
}
