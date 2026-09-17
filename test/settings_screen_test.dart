import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:npd_shield/data/models/transaction.dart';
import 'package:npd_shield/domain/profile/contractor_profile.dart';
import 'package:npd_shield/presentation/settings/settings_screen.dart';

import 'helpers/fake_activity_spheres_service.dart';
import 'helpers/fake_contract_repositories.dart';
import 'helpers/fake_notification_settings_repository.dart';

void main() {
  late FakeContractorProfileRepository profile;
  late FakeActivitySpheresService spheres;
  late FakeNotificationSettingsRepository notificationSettings;

  setUp(() {
    profile = FakeContractorProfileRepository();
    spheres = FakeActivitySpheresService([TransactionSphere.it]);
    notificationSettings = FakeNotificationSettingsRepository();
  });

  Future<void> pumpSettings(
    WidgetTester tester, {
    Future<void> Function()? onLoadDemoData,
    Future<void> Function()? onClearAllData,
    ThemeMode themeMode = ThemeMode.system,
    ValueChanged<ThemeMode>? onThemeModeChanged,
  }) async {
    tester.view.physicalSize = const Size(1000, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: SettingsScreen(
          onLoadDemoData: onLoadDemoData ?? () async {},
          onClearAllData: onClearAllData ?? () async {},
          profileRepository: profile,
          activitySpheresService: spheres,
          notificationSettingsRepository: notificationSettings,
          themeMode: themeMode,
          onThemeModeChanged: onThemeModeChanged ?? (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('очистка данных требует подтверждения и вызывает callback', (
    tester,
  ) async {
    var cleared = 0;
    await pumpSettings(tester, onClearAllData: () async => cleared++);

    await tester.tap(find.byKey(const Key('settings_clear_data')));
    await tester.pumpAndSettle();

    expect(find.text('Очистить все данные?'), findsOneWidget);

    await tester.tap(find.byKey(const Key('data_reset_confirm')));
    await tester.pumpAndSettle();

    expect(cleared, 1);
  });

  testWidgets('отмена подтверждения не очищает данные', (tester) async {
    var cleared = 0;
    await pumpSettings(tester, onClearAllData: () async => cleared++);

    await tester.tap(find.byKey(const Key('settings_clear_data')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('data_reset_cancel')));
    await tester.pumpAndSettle();

    expect(cleared, 0);
    expect(find.text('Очистить все данные?'), findsNothing);
  });

  testWidgets('загрузка демо требует подтверждения и показывает снекбар', (
    tester,
  ) async {
    var loads = 0;
    await pumpSettings(tester, onLoadDemoData: () async => loads++);

    await tester.tap(find.byKey(const Key('settings_load_demo')));
    await tester.pumpAndSettle();

    expect(find.text('Загрузить демо-данные?'), findsOneWidget);
    await tester.tap(find.byKey(const Key('demo_load_confirm')));
    await tester.pumpAndSettle();

    expect(loads, 1);
    expect(find.text('Демо-данные загружены'), findsOneWidget);
  });

  testWidgets('отмена подтверждения не загружает демо', (tester) async {
    var loads = 0;
    await pumpSettings(tester, onLoadDemoData: () async => loads++);

    await tester.tap(find.byKey(const Key('settings_load_demo')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('demo_load_cancel')));
    await tester.pumpAndSettle();

    expect(loads, 0);
  });

  testWidgets('показывает сохранённое ФИО и открывает редактор профиля', (
    tester,
  ) async {
    profile.profile = const ContractorProfile(
      fullName: 'Иванов Иван Иванович',
      inn: '771234567890',
      ogrnip: '321770012345678',
      registrationAddress: 'г. Москва',
      bankName: 'Банк',
      bankAccount: '40817810000000001234',
      bankBik: '044525974',
    );
    await pumpSettings(tester);

    expect(find.text('Иванов Иван Иванович'), findsOneWidget);

    await tester.tap(find.byKey(const Key('settings_profile')));
    await tester.pumpAndSettle();

    expect(find.text('Профиль ИП'), findsWidgets);
    expect(find.byKey(const Key('profile_full_name')), findsOneWidget);
  });

  testWidgets('выбор темы вызывает onThemeModeChanged', (tester) async {
    final changes = <ThemeMode>[];
    await pumpSettings(tester, onThemeModeChanged: changes.add);

    await tester.tap(find.byKey(const Key('settings_theme_dark')));
    await tester.pumpAndSettle();

    expect(changes, [ThemeMode.dark]);
  });

  testWidgets('переключение сфер сохраняет выбор', (tester) async {
    await pumpSettings(tester);

    expect(spheres.spheres, [TransactionSphere.it]);

    await tester.tap(find.byKey(const Key('settings_sphere_logistics')));
    await tester.pumpAndSettle();

    expect(spheres.spheres, containsAll([TransactionSphere.it, TransactionSphere.logistics]));

    await tester.tap(find.byKey(const Key('settings_sphere_it')));
    await tester.pumpAndSettle();

    expect(spheres.spheres, [TransactionSphere.logistics]);
  });

  testWidgets('нельзя убрать последнюю сферу деятельности', (tester) async {
    await pumpSettings(tester);

    await tester.tap(find.byKey(const Key('settings_sphere_it')));
    await tester.pumpAndSettle();

    expect(spheres.spheres, [TransactionSphere.it]);
    expect(find.text('Нужна хотя бы одна сфера деятельности'), findsOneWidget);
  });

  testWidgets('открывает диалог «О приложении»', (tester) async {
    await pumpSettings(tester);

    await tester.tap(find.byKey(const Key('settings_about')));
    await tester.pumpAndSettle();

    expect(find.text('NPD Shield'), findsWidgets);
    expect(find.text('Версия 1.0.0'), findsOneWidget);
  });

  testWidgets('открывает экран настроек уведомлений', (tester) async {
    await pumpSettings(tester);

    await tester.tap(find.byKey(const Key('settings_notifications')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('notification_settings_quiet_hours')),
      findsOneWidget,
    );
  });
}
