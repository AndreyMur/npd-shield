import 'package:flutter_test/flutter_test.dart';
import 'package:npd_shield/data/models/app_notification.dart';
import 'package:npd_shield/domain/notifications/notification_check_context.dart';
import 'package:npd_shield/domain/notifications/notification_draft.dart';
import 'package:npd_shield/domain/notifications/notification_engine.dart';
import 'package:npd_shield/domain/notifications/notification_rule.dart';
import 'package:npd_shield/domain/notifications/notification_settings.dart';

import 'helpers/fake_notification_repository.dart';

/// Правило-заглушка: всегда возвращает заданные заготовки.
class StubRule implements NotificationRule {
  final List<NotificationDraft> drafts;
  const StubRule(this.drafts);

  @override
  List<NotificationDraft> evaluate(NotificationCheckContext context) => drafts;
}

NotificationCheckContext contextWith({
  DateTime? now,
  NotificationSettings settings = NotificationSettings.defaults,
}) {
  return NotificationCheckContext(
    now: now ?? DateTime(2026, 9, 15, 12),
    transactions: const [],
    invoices: const [],
    settings: settings,
  );
}

NotificationDraft draft({
  NotificationType type = NotificationType.limit,
  String key = 'rule:1',
}) {
  return NotificationDraft(
    type: type,
    title: 'Заголовок',
    body: 'Текст',
    dedupeKey: key,
  );
}

void main() {
  test('движок сохраняет сформированные уведомления', () async {
    final repository = FakeNotificationRepository();
    final engine = NotificationEngine(
      repository: repository,
      rules: [StubRule([draft(key: 'rule:1'), draft(key: 'rule:2')])],
    );

    final created = await engine.run(contextWith());

    expect(created, hasLength(2));
    expect(repository.notifications, hasLength(2));
    expect(repository.notifications.first.dedupeKey, isNotNull);
  });

  test('повторный прогон не создаёт дублей', () async {
    final repository = FakeNotificationRepository();
    final engine = NotificationEngine(
      repository: repository,
      rules: [StubRule([draft(key: 'rule:1')])],
    );

    await engine.run(contextWith());
    final second = await engine.run(contextWith());

    expect(second, isEmpty);
    expect(repository.notifications, hasLength(1));
  });

  test('дубли внутри одного прогона схлопываются', () async {
    final repository = FakeNotificationRepository();
    final engine = NotificationEngine(
      repository: repository,
      rules: [
        StubRule([draft(key: 'same')]),
        StubRule([draft(key: 'same')]),
      ],
    );

    final created = await engine.run(contextWith());

    expect(created, hasLength(1));
  });

  test('выключенный тип пропускается', () async {
    final repository = FakeNotificationRepository();
    final engine = NotificationEngine(
      repository: repository,
      rules: [
        StubRule([draft(type: NotificationType.anomaly, key: 'anomaly:1')]),
      ],
    );

    final created = await engine.run(
      contextWith(settings: const NotificationSettings(anomalyEnabled: false)),
    );

    expect(created, isEmpty);
    expect(repository.notifications, isEmpty);
  });

  test('в тихие часы уведомления не создаются', () async {
    final repository = FakeNotificationRepository();
    final engine = NotificationEngine(
      repository: repository,
      rules: [StubRule([draft(key: 'rule:1')])],
    );

    final created = await engine.run(
      contextWith(now: DateTime(2026, 9, 15, 23)),
    );

    expect(created, isEmpty);
    expect(repository.notifications, isEmpty);
  });

  test('заготовка без ключа дедупликации не сохраняется', () async {
    final repository = FakeNotificationRepository();
    final engine = NotificationEngine(
      repository: repository,
      rules: [StubRule([draft(key: '')])],
    );

    final created = await engine.run(contextWith());

    expect(created, isEmpty);
  });

  test('уже сохранённое уведомление не создаётся повторно', () async {
    final existing = AppNotification(
      type: NotificationType.limit,
      title: 'Старое',
      body: 'Текст',
      createdAt: DateTime(2026, 9, 14),
      dedupeKey: 'rule:1',
    );
    final repository = FakeNotificationRepository([existing]);
    final engine = NotificationEngine(
      repository: repository,
      rules: [StubRule([draft(key: 'rule:1')])],
    );

    final created = await engine.run(contextWith());

    expect(created, isEmpty);
    expect(repository.notifications, hasLength(1));
  });
}
