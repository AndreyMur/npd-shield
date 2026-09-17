# Отчёт по модулю Business Management Core (Фаза 37)

## Дата: 2026-09-17
## Ветка: feature-phase-37

## Назначение

Движок уведомлений (Модуль 6): фоновая и стартовая проверка условий реально
формирует уведомления по правилам вместо заглушки. Правила покрывают лимит НПД,
сроки оплаты счетов, аномальные операции и недельный дайджест, а движок
применяет настройки, тихие часы и защиту от дублей.

## Что реализовано

| Задача | Реализация |
|--------|------------|
| Фоновый обработчик | `lib/data/notifications/notification_background_scheduler.dart`: `notificationBackgroundDispatcher` открывает БД в фоновом изоляте и вызывает `runBackgroundNotificationCheck()`; `lib/data/notifications/notification_check_runner.dart` собирает репозитории, правила и доставку |
| Проверка при запуске | `lib/main.dart`: `_runStartupNotificationCheck` прогоняет тот же `NotificationCheckRunner` после старта (на Windows workmanager недоступен), ошибки подавляются |
| Движок | `lib/domain/notifications/notification_engine.dart`: запускает правила, фильтрует по типу и тихим часам, отбрасывает дубли по `dedupeKey`, сохраняет через репозиторий |
| Правила | `notification_rule.dart` (интерфейс), `notification_draft.dart` (заготовка), `notification_check_context.dart` (данные проверки: время, операции, счета, настройки, агрегаты дохода) |
| Лимит | `lib/domain/notifications/limit_monitor.dart`: пороги 80/90/95/100% (берётся самый высокий пересечённый), контрольные сроки 60/30 дней, доход только по НПД |
| Счета | `lib/domain/notifications/invoice_reminder_rule.dart`: напоминания за 14/7/3 дня и отдельное уведомление о просрочке; черновики, отменённые и оплаченные счета игнорируются; кнопка «Отметить оплаченным» |
| Аномалии | `lib/domain/notifications/anomaly_detector.dart`: сумма выше средней в 3 раза, новый контрагент с крупной суммой, операция в необычное время (23:00–06:00, 00:00 без времени не считается) |
| Дайджест | `lib/domain/notifications/weekly_digest_rule.dart`: по воскресеньям после 10:00 — доход, налог, число сделок и остаток до лимита |
| Настройки | `lib/domain/notifications/notification_settings.dart`: типы, пороги, сроки напоминаний, тихие часы (в т.ч. пересекающие полночь), `toJson/fromJson`; `lib/data/repositories/notification_settings_repository.dart` — хранение в `SharedPreferences` |
| Дедупликация | `AppNotification.dedupeKey` (индекс) и `NotificationRepository.findByDedupeKey`; поле добавлено в бэкап |

## Рабочий путь

1. Точка входа (`main` или workmanager) собирает `NotificationCheckRunner` с
   репозиториями операций, счетов, уведомлений, настроек и сервисом доставки.
2. `run()` загружает настройки, операции и счета, строит
   `NotificationCheckContext` и передаёт его движку.
3. Движок вызывает все правила; каждое правило возвращает `NotificationDraft` с
   уникальным ключом события.
4. Черновик пропускается, если его тип выключен, сейчас тихие часы или
   уведомление с таким ключом уже сохранено; иначе оно сохраняется в центр.
5. Движок удаляет уведомления старше срока хранения и показывает новые через
   `NotificationService`.

## Критерий готовности фазы

| Критерий | Проверка |
|----------|----------|
| Фоновая проверка формирует уведомления, а не заглушку | `test/notification_check_runner_test.dart` |
| Пороги лимита 80/90/95/100% и сроки 60/30 дней срабатывают | `test/limit_monitor_test.dart` |
| Напоминания о счетах 3/7/14 и просрочка без дублей | `test/invoice_reminder_rule_test.dart`, `test/notification_engine_test.dart` |
| Детектор аномалий и недельный дайджест работают | `test/anomaly_detector_test.dart`, `test/weekly_digest_rule_test.dart` |
| Повторная проверка не создаёт дублей | `test/notification_engine_test.dart`, `test/notification_check_runner_test.dart` |
| Тихие часы блокируют уведомления | `test/notification_settings_test.dart`, `test/notification_engine_test.dart` |
| Настройки сохраняются и восстанавливаются | `test/notification_settings_test.dart` |

## Тесты

| Файл | Что проверяет |
|------|----------------|
| `test/notification_engine_test.dart` | сохранение уведомлений, пропуск выключенного типа, тихие часы, отсутствие дублей |
| `test/limit_monitor_test.dart` | пороги 80/90/95/100%, скачок через пороги, сроки 60/30 дней, расходы не входят в лимит |
| `test/invoice_reminder_rule_test.dart` | напоминания 14/7/3 дня, просрочка, игнорирование черновиков/отменённых/оплаченных, настраиваемые сроки |
| `test/anomaly_detector_test.dart` | крупная сумма, новый контрагент, ночное время, окно анализа |
| `test/weekly_digest_rule_test.dart` | воскресенье после 10:00, состав недели, исчерпанный лимит |
| `test/notification_settings_test.dart` | значения по умолчанию, тихие часы (в т.ч. через полночь), типы, `toJson/fromJson` |
| `test/notification_check_runner_test.dart` | прогон создаёт и показывает уведомление, отсутствие дублей, очистка старых, тихие часы |
| `test/helpers/fake_notification_settings_repository.dart` | тестовое хранилище настроек |

## Подтверждение

* `flutter analyze` — без замечаний.
* Новые тесты (48) проходят полностью.
* Полный прогон `flutter test` — 693 теста, все проходят.

## Дальше (вне фазы)

* Фаза 38 плана: уведомления — настройки и действия (Модуль 6).
