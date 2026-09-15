import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:npd_shield/data/models/transaction.dart';
import 'package:npd_shield/data/services/first_run_service.dart';
import 'package:npd_shield/presentation/onboarding/onboarding_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/fake_activity_spheres_service.dart';
import 'helpers/fake_contract_repositories.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeActivitySpheresService spheres;
  late FakeContractorProfileRepository profile;
  late SharedPrefsFirstRunService firstRun;
  late int demoLoads;
  late int completions;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    spheres = FakeActivitySpheresService();
    profile = FakeContractorProfileRepository();
    firstRun = SharedPrefsFirstRunService();
    demoLoads = 0;
    completions = 0;
  });

  Future<void> pumpOnboarding(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1000, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: OnboardingScreen(
          activitySpheresService: spheres,
          profileRepository: profile,
          firstRunService: firstRun,
          onLoadDemoData: () async => demoLoads++,
          onCompleted: () => completions++,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> selectSphereAndContinue(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('onboarding_sphere_it')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('onboarding_next')));
    await tester.pumpAndSettle();
  }

  testWidgets('проходит все шаги и сохраняет выбор сфер и профиль', (
    tester,
  ) async {
    await pumpOnboarding(tester);

    expect(find.byKey(const Key('onboarding_step_spheres')), findsOneWidget);

    await selectSphereAndContinue(tester);

    expect(find.byKey(const Key('onboarding_step_profile')), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('onboarding_full_name')),
      'Иванов Иван Иванович',
    );
    await tester.enterText(find.byKey(const Key('onboarding_inn')), '771234567890');
    await tester.tap(find.byKey(const Key('onboarding_next')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('onboarding_step_start')), findsOneWidget);
    await tester.tap(find.byKey(const Key('onboarding_finish')));
    await tester.pumpAndSettle();

    expect(await firstRun.isOnboardingCompleted(), isTrue);
    expect(await firstRun.getStartMode(), StartMode.fromScratch);
    expect(spheres.spheres, [TransactionSphere.it]);
    expect(profile.profile?.fullName, 'Иванов Иван Иванович');
    expect(profile.profile?.inn, '771234567890');
    expect(demoLoads, 0);
    expect(completions, 1);
  });

  testWidgets('режим «с нуля» не загружает демо и не создаёт профиль', (
    tester,
  ) async {
    await pumpOnboarding(tester);
    await selectSphereAndContinue(tester);
    await tester.tap(find.byKey(const Key('onboarding_next')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('onboarding_finish')));
    await tester.pumpAndSettle();

    expect(demoLoads, 0);
    expect(profile.profile, isNull);
    expect(await firstRun.getStartMode(), StartMode.fromScratch);
    expect(completions, 1);
  });

  testWidgets('режим «демо» требует подтверждения и загружает данные', (
    tester,
  ) async {
    await pumpOnboarding(tester);
    await selectSphereAndContinue(tester);
    await tester.tap(find.byKey(const Key('onboarding_next')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('onboarding_mode_demo')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('onboarding_finish')));
    await tester.pumpAndSettle();

    expect(find.text('Загрузить демо-данные?'), findsOneWidget);
    await tester.tap(find.byKey(const Key('demo_load_confirm')));
    await tester.pumpAndSettle();

    expect(demoLoads, 1);
    expect(await firstRun.getStartMode(), StartMode.demo);
    expect(completions, 1);
  });

  testWidgets('отмена подтверждения демо не завершает онбординг', (
    tester,
  ) async {
    await pumpOnboarding(tester);
    await selectSphereAndContinue(tester);
    await tester.tap(find.byKey(const Key('onboarding_next')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('onboarding_mode_demo')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('onboarding_finish')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('demo_load_cancel')));
    await tester.pumpAndSettle();

    expect(demoLoads, 0);
    expect(completions, 0);
    expect(await firstRun.isOnboardingCompleted(), isFalse);
    expect(find.byKey(const Key('onboarding_step_start')), findsOneWidget);
  });

  testWidgets('без выбранной сферы дальше не переходит', (tester) async {
    await pumpOnboarding(tester);

    await tester.tap(find.byKey(const Key('onboarding_next')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('onboarding_step_spheres')), findsOneWidget);
    expect(
      find.text('Выберите хотя бы одну сферу деятельности'),
      findsOneWidget,
    );
  });

  testWidgets('некорректный ИНН не пропускает дальше', (tester) async {
    await pumpOnboarding(tester);
    await selectSphereAndContinue(tester);

    await tester.enterText(find.byKey(const Key('onboarding_inn')), '123');
    await tester.tap(find.byKey(const Key('onboarding_next')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('onboarding_step_profile')), findsOneWidget);
    expect(find.text('Введите 10 или 12 цифр'), findsOneWidget);
  });
}
