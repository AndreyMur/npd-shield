import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:npd_shield/core/theme/app_theme.dart';
import 'package:npd_shield/presentation/help/help_screen.dart';

void main() {
  Future<void> pumpHelp(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 10000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light(null), home: const HelpScreen()),
    );
    await tester.pumpAndSettle();
  }

  group('Фаза 3: экран справочника', () {
    testWidgets('рендерит блок «С чего начать» и оглавление', (tester) async {
      await pumpHelp(tester);

      expect(find.byKey(const Key('help_quick_start_title')), findsOneWidget);
      expect(find.text('С чего начать'), findsOneWidget);
      expect(find.byKey(const Key('help_toc_title')), findsOneWidget);
      expect(
        find.byKey(const Key('help_quick_start_getting_started')),
        findsOneWidget,
      );
      expect(find.text('Дашборд'), findsOneWidget);
      expect(find.text('Операции'), findsOneWidget);
    });

    testWidgets('открывает статью из блока «С чего начать»', (tester) async {
      await pumpHelp(tester);

      await tester.tap(
        find.byKey(const Key('help_quick_start_getting_started')),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('help_article_screen')), findsOneWidget);
      expect(find.byKey(const Key('help_article_summary')), findsOneWidget);
      expect(find.text('Как пользоваться'), findsOneWidget);
    });

    testWidgets('открывает статью из оглавления', (tester) async {
      await pumpHelp(tester);

      await tester.tap(find.byKey(const Key('help_section_dashboard')));
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const Key('help_article_dashboard_overview')),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('help_article_screen')), findsOneWidget);
      expect(find.text('Дашборд: обзор финансов'), findsWidgets);
    });
  });

  group('Фаза 3: экран статьи', () {
    testWidgets('переход по связанной статье', (tester) async {
      await pumpHelp(tester);

      await tester.tap(
        find.byKey(const Key('help_quick_start_getting_started')),
      );
      await tester.pumpAndSettle();

      final related = find.byKey(const Key('help_related_scenario_contract'));
      expect(related, findsOneWidget);

      await tester.tap(related);
      await tester.pumpAndSettle();

      expect(find.text('Как создать договор из шаблона'), findsWidgets);
      expect(find.byKey(const Key('help_article_screen')), findsOneWidget);
    });

    testWidgets('возврат к оглавлению', (tester) async {
      await pumpHelp(tester);

      await tester.tap(
        find.byKey(const Key('help_quick_start_getting_started')),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('help_article_screen')), findsOneWidget);

      await tester.tap(find.byKey(const Key('help_back_to_toc')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('help_article_screen')), findsNothing);
      expect(find.byKey(const Key('help_screen')), findsOneWidget);
      expect(find.byKey(const Key('help_toc_title')), findsOneWidget);
    });

    testWidgets('отображает дисклеймер', (tester) async {
      await pumpHelp(tester);

      await tester.tap(
        find.byKey(const Key('help_quick_start_getting_started')),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('help_disclaimer')), findsOneWidget);
      expect(find.textContaining('справочный характер'), findsWidgets);
    });
  });

  group('Фаза 3: точка входа «О приложении»', () {
    testWidgets('открывает диалог «О приложении» с версией', (tester) async {
      await pumpHelp(tester);

      final entry = find.byKey(const Key('help_about_entry'));
      expect(entry, findsOneWidget);

      await tester.tap(entry);
      await tester.pumpAndSettle();

      expect(find.text('NPD Shield'), findsWidgets);
      expect(find.text('1.0.0'), findsWidgets);
    });
  });
}
