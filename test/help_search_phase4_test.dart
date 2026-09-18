import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:npd_shield/core/theme/app_theme.dart';
import 'package:npd_shield/data/help_articles.dart';
import 'package:npd_shield/data/repositories/help_repository.dart';
import 'package:npd_shield/domain/help/help_search.dart';
import 'package:npd_shield/presentation/help/help_screen.dart';

void main() {
  Future<void> pumpHelp(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light(null), home: const HelpScreen()),
    );
    await tester.pumpAndSettle();
  }

  Finder searchField() => find.descendant(
    of: find.byKey(const Key('help_search_field')),
    matching: find.byType(TextField),
  );

  group('Фаза 4: поиск по заголовку', () {
    test('находит статьи по заголовку', () {
      final results = searchHelpArticles(builtInHelpArticles, 'договор');

      expect(results, isNotEmpty);
      expect(
        results.map((article) => article.id),
        containsAll(['scenario_contract', 'contracts_guide']),
      );
    });

    test('совпадение в заголовке выше совпадения в содержимом', () {
      final results = searchHelpArticles(builtInHelpArticles, 'договор');

      expect(results.first.title.toLowerCase(), contains('договор'));
    });

    test('поиск не зависит от регистра', () {
      final lower = searchHelpArticles(builtInHelpArticles, 'дашборд');
      final upper = searchHelpArticles(builtInHelpArticles, 'ДАШБОРД');

      expect(
        upper.map((article) => article.id),
        orderedEquals(lower.map((article) => article.id)),
      );
      expect(upper, isNotEmpty);
    });
  });

  group('Фаза 4: поиск по содержимому', () {
    test('находит статью по тексту в частых вопросах', () {
      final results = searchHelpArticles(builtInHelpArticles, 'сезонность');

      expect(
        results.map((article) => article.id),
        contains('dashboard_overview'),
      );
    });

    test('находит статьи по тексту в шагах инструкции', () {
      final results = searchHelpArticles(builtInHelpArticles, 'ОГРНИП');

      expect(
        results.map((article) => article.id),
        containsAll(['getting_started', 'settings_guide']),
      );
    });

    test('пустой запрос не возвращает результатов', () {
      expect(searchHelpArticles(builtInHelpArticles, ''), isEmpty);
      expect(searchHelpArticles(builtInHelpArticles, '   '), isEmpty);
    });
  });

  group('Фаза 4: поиск офлайн', () {
    test('репозиторий ищет по встроенному контенту синхронно', () {
      const repository = EmbeddedHelpRepository();

      final results = repository.search('лимит');

      expect(results, isNotEmpty);
      expect(
        results.every((article) => builtInHelpArticles.contains(article)),
        isTrue,
      );
    });

    test('результаты поиска защищены от изменения', () {
      const repository = EmbeddedHelpRepository();

      expect(
        () => repository.search('договор').add(builtInHelpArticles.first),
        throwsUnsupportedError,
      );
    });
  });

  group('Фаза 4: экран поиска', () {
    testWidgets('результаты обновляются по мере ввода', (tester) async {
      await pumpHelp(tester);

      expect(find.byKey(const Key('help_toc_title')), findsOneWidget);

      await tester.enterText(find.byKey(const Key('help_search_field')), 'дог');
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('help_toc_title')), findsNothing);
      expect(
        find.byKey(const Key('help_search_results_title')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('help_search_result_scenario_contract')),
        findsOneWidget,
      );
    });

    testWidgets('результат показывает название статьи и раздел', (tester) async {
      await pumpHelp(tester);

      await tester.enterText(
        find.byKey(const Key('help_search_field')),
        'как создать договор',
      );
      await tester.pumpAndSettle();

      final tile = find.byKey(
        const Key('help_search_result_scenario_contract'),
      );
      expect(tile, findsOneWidget);
      expect(
        find.descendant(
          of: tile,
          matching: find.text('Как создать договор из шаблона'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(of: tile, matching: find.text('Сквозные сценарии')),
        findsOneWidget,
      );
    });

    testWidgets('тап по результату открывает статью', (tester) async {
      await pumpHelp(tester);

      await tester.enterText(
        find.byKey(const Key('help_search_field')),
        'как создать договор',
      );
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const Key('help_search_result_scenario_contract')),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('help_article_screen')), findsOneWidget);
      expect(find.text('Как создать договор из шаблона'), findsWidgets);
    });

    testWidgets('показывает пустое состояние при отсутствии результатов', (
      tester,
    ) async {
      await pumpHelp(tester);

      await tester.enterText(
        find.byKey(const Key('help_search_field')),
        'абракадабра-которой-нет',
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('help_search_empty')), findsOneWidget);
      expect(find.text('Ничего не найдено'), findsOneWidget);
      expect(find.byKey(const Key('help_search_open_toc')), findsOneWidget);
    });

    testWidgets('из пустого состояния открывает оглавление', (tester) async {
      await pumpHelp(tester);

      await tester.enterText(
        find.byKey(const Key('help_search_field')),
        'абракадабра-которой-нет',
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('help_search_open_toc')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('help_search_empty')), findsNothing);
      expect(find.byKey(const Key('help_toc_title')), findsOneWidget);
      expect(tester.widget<TextField>(searchField()).controller?.text, isEmpty);
    });

    testWidgets('очистка поиска возвращает оглавление', (tester) async {
      await pumpHelp(tester);

      await tester.enterText(
        find.byKey(const Key('help_search_field')),
        'договор',
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('help_search_results_title')),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const Key('help_search_clear')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('help_toc_title')), findsOneWidget);
      expect(tester.widget<TextField>(searchField()).controller?.text, isEmpty);
    });
  });
}
