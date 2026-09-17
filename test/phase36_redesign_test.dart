import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:npd_shield/core/layout/app_breakpoints.dart';
import 'package:npd_shield/core/theme/app_theme.dart';
import 'package:npd_shield/core/theme/app_tokens.dart';
import 'package:npd_shield/data/models/transaction.dart';
import 'package:npd_shield/data/services/first_run_service.dart';
import 'package:npd_shield/presentation/loading/loading_screen.dart';
import 'package:npd_shield/presentation/onboarding/onboarding_screen.dart';
import 'package:npd_shield/presentation/settings/settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/fake_activity_spheres_service.dart';
import 'helpers/fake_contract_repositories.dart';
import 'helpers/fake_notification_settings_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Адаптивные breakpoint-ы', () {
    test('fromWidth определяет размер окна', () {
      expect(AppBreakpoints.fromWidth(320), AppWindowSize.compact);
      expect(AppBreakpoints.fromWidth(599), AppWindowSize.compact);
      expect(AppBreakpoints.fromWidth(600), AppWindowSize.medium);
      expect(AppBreakpoints.fromWidth(899), AppWindowSize.medium);
      expect(AppBreakpoints.fromWidth(900), AppWindowSize.expanded);
      expect(AppBreakpoints.fromWidth(1440), AppWindowSize.expanded);
    });

    test('горизонтальные gutters растут по ширине', () {
      expect(AppBreakpoints.horizontalGutter(375), AppSpacing.md);
      expect(AppBreakpoints.horizontalGutter(700), AppSpacing.lg);
      expect(AppBreakpoints.horizontalGutter(1200), AppSpacing.xl);
    });

    test('боковая навигация: планшет и ландшафт телефона', () {
      expect(
        AppBreakpoints.useRail(width: 1024, height: 768),
        isTrue,
        reason: 'планшет',
      );
      expect(
        AppBreakpoints.useRail(width: 800, height: 400),
        isTrue,
        reason: 'ландшафт телефона',
      );
      expect(
        AppBreakpoints.useRail(width: 375, height: 800),
        isFalse,
        reason: 'портрет телефона',
      );
      expect(
        AppBreakpoints.useRail(width: 599, height: 900),
        isFalse,
        reason: 'узкий портрет',
      );
    });
  });

  group('Онбординг: адаптив и доступность', () {
    late FakeActivitySpheresService spheres;
    late FakeContractorProfileRepository profile;
    late SharedPrefsFirstRunService firstRun;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      spheres = FakeActivitySpheresService();
      profile = FakeContractorProfileRepository();
      firstRun = SharedPrefsFirstRunService();
    });

    Future<void> pump(
      WidgetTester tester, {
      required Size size,
      double textScale = 1.0,
    }) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      tester.platformDispatcher.textScaleFactorTestValue = textScale;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(null),
          home: OnboardingScreen(
            activitySpheresService: spheres,
            profileRepository: profile,
            firstRunService: firstRun,
            onCompleted: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('рендерится на 375 px без переполнений', (tester) async {
      await pump(tester, size: const Size(375, 800));

      expect(find.byKey(const Key('onboarding_step_spheres')), findsOneWidget);
      expect(find.byKey(const Key('onboarding_progress')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('рендерится в ландшафте телефона', (tester) async {
      await pump(tester, size: const Size(800, 400));

      expect(find.byKey(const Key('onboarding_step_spheres')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('максимальный системный шрифт не ломает верстку', (
      tester,
    ) async {
      await pump(tester, size: const Size(375, 800), textScale: 2.0);

      expect(find.byKey(const Key('onboarding_step_spheres')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('шапка несёт семантику прогресса шагов', (tester) async {
      await pump(tester, size: const Size(375, 800));

      final semantics = tester.getSemantics(
        find.byKey(const Key('onboarding_progress')),
      );
      expect(semantics.label, contains('Шаг 1 из 2'));
    });
  });

  group('Настройки: адаптив и доступность', () {
    late FakeContractorProfileRepository profile;
    late FakeActivitySpheresService spheres;
    late FakeNotificationSettingsRepository notificationSettings;

    setUp(() {
      profile = FakeContractorProfileRepository();
      spheres = FakeActivitySpheresService([TransactionSphere.it]);
      notificationSettings = FakeNotificationSettingsRepository();
    });

    Future<void> pump(
      WidgetTester tester, {
      required Size size,
      double textScale = 1.0,
    }) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      tester.platformDispatcher.textScaleFactorTestValue = textScale;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(null),
          home: SettingsScreen(
            onLoadDemoData: () async {},
            onClearAllData: () async {},
            profileRepository: profile,
            activitySpheresService: spheres,
            notificationSettingsRepository: notificationSettings,
            themeMode: ThemeMode.system,
            onThemeModeChanged: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('рендерится на 375 px без переполнений', (tester) async {
      await pump(tester, size: const Size(375, 800));

      expect(find.byKey(const Key('settings_profile')), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.scrollUntilVisible(
        find.byKey(const Key('settings_clear_data')),
        200,
      );
      expect(find.byKey(const Key('settings_clear_data')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('крупный системный шрифт не ломает верстку', (tester) async {
      await pump(tester, size: const Size(375, 800), textScale: 2.0);

      expect(find.byKey(const Key('settings_profile')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('Экран загрузки', () {
    testWidgets('показывает фирменный стиль и семантику загрузки', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(theme: AppTheme.light(null), home: const LoadingScreen()),
      );

      expect(find.byKey(const Key('app_loading_screen')), findsOneWidget);
      expect(find.text('NPD Shield'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });
  });

  group('Тема навигации', () {
    test('NavigationBar и NavigationRail используют токены', () {
      final theme = AppTheme.light(null);
      final tokens = AppTokens.light;

      expect(theme.navigationBarTheme.backgroundColor, tokens.surface);
      expect(
        theme.navigationBarTheme.indicatorColor,
        tokens.primary.withValues(alpha: 0.14),
      );
      expect(theme.navigationRailTheme.backgroundColor, tokens.surface);
      expect(
        theme.navigationRailTheme.selectedIconTheme?.color,
        tokens.primary,
      );
    });
  });

  group('Консистентность фазы 36', () {
    test('в экранах фазы 36 нет хардкод-цветов', () {
      const files = [
        'lib/presentation/onboarding/onboarding_screen.dart',
        'lib/presentation/settings/settings_screen.dart',
        'lib/presentation/home/home_shell.dart',
        'lib/presentation/loading/loading_screen.dart',
      ];

      final colorPattern = RegExp(r'Color\(0x');
      final materialColorPattern = RegExp(r'\bColors\.');
      for (final path in files) {
        final source = File(path).readAsStringSync();
        expect(
          colorPattern.hasMatch(source),
          isFalse,
          reason: '$path содержит хардкод-цвет Color(0x...)',
        );
        expect(
          materialColorPattern.hasMatch(source),
          isFalse,
          reason: '$path содержит Material-цвет Colors.*',
        );
      }
    });
  });

  group('Производительность p95 построения кадра', () {
    testWidgets('p95 сборки разделов укладывается в бюджет кадра', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      SharedPreferences.setMockInitialValues({});
      final profile = FakeContractorProfileRepository();
      final spheres = FakeActivitySpheresService([TransactionSphere.it]);
      final notificationSettings = FakeNotificationSettingsRepository();

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(null),
          home: SettingsScreen(
            onLoadDemoData: () async {},
            onClearAllData: () async {},
            profileRepository: profile,
            activitySpheresService: spheres,
            notificationSettingsRepository: notificationSettings,
            themeMode: ThemeMode.system,
            onThemeModeChanged: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      final samples = <double>[];
      for (var i = 0; i < 24; i++) {
        final stopwatch = Stopwatch()..start();
        await tester.pump(const Duration(milliseconds: 16));
        stopwatch.stop();
        samples.add(stopwatch.elapsedMicroseconds / 1000);
      }

      samples.sort();
      final p95 = samples[(samples.length * 0.95).floor().clamp(0, samples.length - 1)];
      expect(
        p95,
        lessThan(16),
        reason: 'p95 построения кадра $p95 мс должен быть < 16 мс',
      );
    });
  });
}
