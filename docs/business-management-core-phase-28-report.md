# Отчёт по модулю Business Management Core (Фаза 28)

## Дата: 2026-09-16
## Ветка: feature-phase-28

## Назначение

Слой данных операций (Модуль 1): модель операции поддерживает доходы и расходы,
репозиторий — полный CRUD, фильтры и агрегаты. Доход учитывается в лимите НПД и
налоге, расход — нет; доступны доход, расход и прибыль за период.

## Что реализовано

| Задача | Реализация |
|--------|------------|
| Расширить `Transaction` | `lib/data/models/transaction.dart`: добавлены `TransactionType { income, expense }` (`label`, `isIncome`, `isExpense`), поля `type` (индекс, `@enumerated`), `category`, `comment`, `clientId` (индекс, ссылка на будущего клиента). Старые записи читаются как доход (`type` по умолчанию — `income`) |
| CRUD и выборки | `TransactionRepository` / `IsarTransactionRepository`: `getById`, `update`, `delete`, `count`, `getAll({filter})`. Все чтения расшифровывают `clientName`/`clientInn`; записи инвалидируют кэш агрегатов |
| Фильтр операций | `TransactionFilter` (`type`, `sphere`, `from` включительно, `to` исключительно, `clientId`, `search`) с методом `matches`; поиск без учёта регистра по клиенту, ИНН, категории и комментарию |
| Агрегаты за период | `PeriodSummary { income, expense, profit }` и `getPeriodSummary(...)` с фильтрами по периоду/сфере/типу/клиенту |
| Доход для лимита и налога | `IncomeSummary` расширен `monthExpense`/`yearExpense` и `monthProfit`/`yearProfit`; `getIncomeSummary`, `getAverageMonthlyIncome`, `getIncomeSeries` считают только операции типа «доход», поэтому расходы не попадают в лимит 2,4 млн и налог |
| Инвалидация кэша | В `_OptimizedCache` добавлен кэш периодных агрегатов; `invalidate()` вызывается на `add`, `update`, `delete`, `clear` |
| Инъекция шифрования | `IsarTransactionRepository` принимает `FieldEncryptionService` (как остальные репозитории) — для детерминированных тестов |

## Рабочий путь

1. Пользователь создаёт операцию через `add` (или позже — через UI): тип
   «доход»/«расход», сумма, дата, сфера, категория, комментарий, клиент.
2. `getAll(TransactionFilter)` возвращает отфильтрованный список; `count`
   считает записи по тому же фильтру.
3. `getPeriodSummary` даёт доход, расход и прибыль за произвольный период.
4. `getIncomeSummary` отдаёт доход за месяц/год (для лимита и налога) и расход
   за те же периоды (для прибыли на дашборде).
5. Любое изменение (`add`/`update`/`delete`/`clear`) сбрасывает кэш агрегатов,
   и следующие сводки пересчитываются.

## Критерий готовности фазы

| Критерий | Проверка |
|----------|----------|
| CRUD операций покрыт тестами | `test/transaction_crud_test.dart` |
| Агрегаты покрыты тестами | `test/transaction_aggregates_test.dart` |
| Доход учитывается в лимите, расход — нет | `transaction_aggregates_test`: `income used for limit and tax excludes expenses` |
| Прибыль = доход − расход | `transaction_aggregates_test`, `IncomeSummary.monthProfit/yearProfit`, `PeriodSummary.profit` |
| Корректность при нуле операций | тесты «is zero when there are no operations», «zero-filled buckets» |

## Тесты

| Файл | Что проверяет |
|------|----------------|
| `test/transaction_crud_test.dart` | `getById`, `update`, `delete` (в т.ч. отсутствующий id), `count`, фильтры по типу/сфере/периоду/клиенту, поиск по имени/категории/комментарию, комбинация условий, инвалидация кэша на add/update/delete/clear |
| `test/transaction_aggregates_test.dart` | Разделение дохода и расхода, прибыль, доход для лимита/налога без расходов, периодные агрегаты, нулевые операции, игнор расходов в среднем доходе и графике |
| `test/transaction_repository_test.dart` | Существующие тесты агрегатов (совместимость сигнатур сохранена) |
| `test/helpers/fake_transaction_repository.dart` | Обновлён под новый интерфейс (id, CRUD, фильтры, периодные агрегаты) |

## Подтверждение

* `flutter analyze` — без замечаний.
* Новые тесты (27) проходят полностью.
* Полный прогон `flutter test` — 503 теста, все проходят.
* `flutter build windows --release` — сборка проходит.

## Дальше (вне фазы)

* Фаза 29 плана: экран «Операции» (список, фильтры, поиск, итоги), форма
  создания/редактирования и карточка прибыли на дашборде.
* Фаза 30: клиенты (`Client`) и связь `Transaction.clientId` с реальным
  справочником.
