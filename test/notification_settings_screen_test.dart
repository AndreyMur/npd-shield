import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:npd_shield/data/models/app_notification.dart';
import 'package:npd_shield/domain/notifications/notification_settings.dart';
import 'package:npd_shield/presentation/settings/notification_settings_screen.dart';

import 'helpers/fake_notification_settings_repository.dart';

void main() {
  Future<void> pumpScreen(
    WidgetTester tester,
    FakeNotificationSettingsRepository repository, {
    NotificationTimePicker? timePicker,
  }) async {
    tester.view.physicalSize = const Size(1000, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: NotificationSettingsScreen(
          repository: repository,
          timePicker: timePicker ?? (context, initial) async => initial,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('показывает тумблеры для каждого типа уведомлений', (
    tester,
  ) async {
    await pumpScreen(tester, FakeNotificationSettingsRepository());

    for (final type in NotificationType.values) {
      expect(
        find.byKey(Key('notification_settings_${type.name}')),
        findsOneWidget,
      );
    }
  });

  testWidgets('переключение типа сохраняется', (tester) async {
    final repository = FakeNotificationSettingsRepository();
    await pumpScreen(tester, repository);

    await tester.tap(find.byKey(const Key('notification_settings_anomaly')));
    await tester.pumpAndSettle();

    expect(repository.settings.anomalyEnabled, isFalse);
    expect(repository.settings.limitEnabled, isTrue);
    expect(repository.saveCount, 1);
  });

  testWidgets('загружает сохранённые настройки типов', (tester) async {
    final repository = FakeNotificationSettingsRepository(
      NotificationSettings.defaults.copyWith(
        invoiceEnabled: false,
        digestEnabled: false,
      ),
    );
    await pumpScreen(tester, repository);

    final invoiceSwitch = tester.widget<SwitchListTile>(
      find.byKey(const Key('notification_settings_invoice')),
    );
    final digestSwitch = tester.widget<SwitchListTile>(
      find.byKey(const Key('notification_settings_digest')),
    );

    expect(invoiceSwitch.value, isFalse);
    expect(digestSwitch.value, isFalse);
  });

  testWidgets('выключение тихих часов сохраняется и блокирует время', (
    tester,
  ) async {
    final repository = FakeNotificationSettingsRepository();
    await pumpScreen(tester, repository);

    await tester.tap(
      find.byKey(const Key('notification_settings_quiet_hours')),
    );
    await tester.pumpAndSettle();

    expect(repository.settings.quietHoursEnabled, isFalse);

    final startTile = tester.widget<ListTile>(
      find.byKey(const Key('notification_settings_quiet_start')),
    );
    expect(startTile.onTap, isNull);
  });

  testWidgets('изменение начала тихих часов сохраняется', (tester) async {
    final repository = FakeNotificationSettingsRepository();
    await pumpScreen(
      tester,
      repository,
      timePicker: (context, initial) async =>
          const TimeOfDay(hour: 23, minute: 30),
    );

    await tester.tap(
      find.byKey(const Key('notification_settings_quiet_start')),
    );
    await tester.pumpAndSettle();

    expect(repository.settings.quietHoursStartMinutes, 23 * 60 + 30);
    expect(find.text('23:30'), findsOneWidget);
  });

  testWidgets('изменение конца тихих часов сохраняется', (tester) async {
    final repository = FakeNotificationSettingsRepository();
    await pumpScreen(
      tester,
      repository,
      timePicker: (context, initial) async =>
          const TimeOfDay(hour: 6, minute: 15),
    );

    await tester.tap(find.byKey(const Key('notification_settings_quiet_end')));
    await tester.pumpAndSettle();

    expect(repository.settings.quietHoursEndMinutes, 6 * 60 + 15);
    expect(find.text('06:15'), findsOneWidget);
  });

  testWidgets('отмена выбора времени не меняет настройки', (tester) async {
    final repository = FakeNotificationSettingsRepository();
    await pumpScreen(
      tester,
      repository,
      timePicker: (context, initial) async => null,
    );

    await tester.tap(
      find.byKey(const Key('notification_settings_quiet_start')),
    );
    await tester.pumpAndSettle();

    expect(
      repository.settings.quietHoursStartMinutes,
      NotificationSettings.defaults.quietHoursStartMinutes,
    );
    expect(repository.saveCount, 0);
  });

  testWidgets('показывает сохранённые тихие часы', (tester) async {
    final repository = FakeNotificationSettingsRepository(
      NotificationSettings.defaults.copyWith(
        quietHoursStartMinutes: 21 * 60,
        quietHoursEndMinutes: 7 * 60,
      ),
    );
    await pumpScreen(tester, repository);

    expect(find.text('21:00'), findsOneWidget);
    expect(find.text('07:00'), findsOneWidget);
  });
}
