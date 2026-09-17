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
  late int completions;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    spheres = FakeActivitySpheresService();
    profile = FakeContractorProfileRepository();
    firstRun = SharedPrefsFirstRunService();
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
    await tester.tap(find.byKey(const Key('onboarding_finish')));
    await tester.pumpAndSettle();

    expect(await firstRun.isOnboardingCompleted(), isTrue);
    expect(await firstRun.getStartMode(), StartMode.fromScratch);
    expect(spheres.spheres, [TransactionSphere.it]);
    expect(profile.profile?.fullName, 'Иванов Иван Иванович');
    expect(profile.profile?.inn, '771234567890');
    expect(completions, 1);
  });

  testWidgets('без профиля завершает онбординг без данных', (tester) async {
    await pumpOnboarding(tester);
    await selectSphereAndContinue(tester);
    await tester.tap(find.byKey(const Key('onboarding_finish')));
    await tester.pumpAndSettle();

    expect(profile.profile, isNull);
    expect(await firstRun.getStartMode(), StartMode.fromScratch);
    expect(completions, 1);
  });

  testWidgets('в онбординге нет выбора режима старта', (tester) async {
    await pumpOnboarding(tester);
    await selectSphereAndContinue(tester);

    expect(find.byKey(const Key('onboarding_step_start')), findsNothing);
    expect(find.byKey(const Key('onboarding_mode_demo')), findsNothing);
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

  testWidgets('некорректный ИНН не завершает онбординг', (tester) async {
    await pumpOnboarding(tester);
    await selectSphereAndContinue(tester);

    await tester.enterText(find.byKey(const Key('onboarding_inn')), '123');
    await tester.tap(find.byKey(const Key('onboarding_finish')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('onboarding_step_profile')), findsOneWidget);
    expect(find.text('Введите 10 или 12 цифр'), findsOneWidget);
    expect(await firstRun.isOnboardingCompleted(), isFalse);
  });
}
