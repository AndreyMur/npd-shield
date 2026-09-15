import 'models/app_notification.dart';
import 'models/transaction.dart';
import 'repositories/notification_repository.dart';
import 'repositories/transaction_repository.dart';

/// Наполняет репозиторий тестовыми данными для демонстрации дашборда.
/// Данные охватывают последние 12 месяцев для хорошей визуализации графиков.
Future<void> seedDashboardData(TransactionRepository repository) async {
  final now = DateTime.now();
  final currentYear = now.year;

  await repository.clear();

  final transactions = <Transaction>[
    // IT сфера - растущий тренд с сезонностью
    // Январь
    Transaction(
      amount: 45000,
      date: DateTime(currentYear, 1, 15),
      sphere: TransactionSphere.it,
      clientName: 'ООО "ТехноПарк"',
      clientInn: '7701234567',
    ),
    Transaction(
      amount: 32000,
      date: DateTime(currentYear, 1, 28),
      sphere: TransactionSphere.it,
      clientName: 'ИП Петров',
      clientInn: '7702345678',
    ),
    // Февраль
    Transaction(
      amount: 58000,
      date: DateTime(currentYear, 2, 10),
      sphere: TransactionSphere.it,
      clientName: 'АО "СофтЛаб"',
      clientInn: '7703456789',
    ),
    Transaction(
      amount: 41000,
      date: DateTime(currentYear, 2, 25),
      sphere: TransactionSphere.it,
      clientName: 'ООО "ВебСтудия"',
      clientInn: '7704567890',
    ),
    // Март
    Transaction(
      amount: 72000,
      date: DateTime(currentYear, 3, 5),
      sphere: TransactionSphere.it,
      clientName: 'ООО "Цифровые решения"',
      clientInn: '7705678901',
    ),
    Transaction(
      amount: 35000,
      date: DateTime(currentYear, 3, 20),
      sphere: TransactionSphere.it,
      clientName: 'ИП Сидоров',
      clientInn: '7706789012',
    ),
    // Апрель
    Transaction(
      amount: 89000,
      date: DateTime(currentYear, 4, 8),
      sphere: TransactionSphere.it,
      clientName: 'АО "ИнфоСистемы"',
      clientInn: '7707890123',
    ),
    Transaction(
      amount: 46000,
      date: DateTime(currentYear, 4, 22),
      sphere: TransactionSphere.it,
      clientName: 'ООО "МобайлДев"',
      clientInn: '7708901234',
    ),
    // Май
    Transaction(
      amount: 63000,
      date: DateTime(currentYear, 5, 12),
      sphere: TransactionSphere.it,
      clientName: 'ИП Иванов',
      clientInn: '7709012345',
    ),
    Transaction(
      amount: 51000,
      date: DateTime(currentYear, 5, 27),
      sphere: TransactionSphere.it,
      clientName: 'ООО "Креатив"',
      clientInn: '7710123456',
    ),
    // Июнь
    Transaction(
      amount: 78000,
      date: DateTime(currentYear, 6, 3),
      sphere: TransactionSphere.it,
      clientName: 'АО "ДатаЦентр"',
      clientInn: '7711234567',
    ),
    Transaction(
      amount: 95000,
      date: DateTime(currentYear, 6, 18),
      sphere: TransactionSphere.it,
      clientName: 'ООО "АйТиПартнер"',
      clientInn: '7712345678',
    ),
    Transaction(
      amount: 42000,
      date: DateTime(currentYear, 6, 25),
      sphere: TransactionSphere.it,
      clientName: 'ИП Козлов',
      clientInn: '7713456789',
    ),
    // Июль
    Transaction(
      amount: 67000,
      date: DateTime(currentYear, 7, 9),
      sphere: TransactionSphere.it,
      clientName: 'ООО "СофтТех"',
      clientInn: '7714567890',
    ),
    Transaction(
      amount: 83000,
      date: DateTime(currentYear, 7, 21),
      sphere: TransactionSphere.it,
      clientName: 'АО "ГеймДев"',
      clientInn: '7715678901',
    ),
    // Август (текущий месяц)
    Transaction(
      amount: 91000,
      date: DateTime(currentYear, 8, 5),
      sphere: TransactionSphere.it,
      clientName: 'ООО "НекстТех"',
      clientInn: '7716789012',
    ),
    Transaction(
      amount: 54000,
      date: DateTime(currentYear, 8, 15),
      sphere: TransactionSphere.it,
      clientName: 'ИП Морозов',
      clientInn: '7717890123',
    ),
    Transaction(
      amount: 76000,
      date: DateTime(currentYear, 8, 25),
      sphere: TransactionSphere.it,
      clientName: 'ООО "СмартСофт"',
      clientInn: '7718901234',
    ),

    // Логистика - стабильный доход с небольшим ростом
    // Январь
    Transaction(
      amount: 28000,
      date: DateTime(currentYear, 1, 10),
      sphere: TransactionSphere.logistics,
      clientName: 'ООО "ТрансЛогистика"',
      clientInn: '7801234567',
    ),
    Transaction(
      amount: 35000,
      date: DateTime(currentYear, 1, 22),
      sphere: TransactionSphere.logistics,
      clientName: 'ИП Волков',
      clientInn: '7802345678',
    ),
    // Февраль
    Transaction(
      amount: 42000,
      date: DateTime(currentYear, 2, 8),
      sphere: TransactionSphere.logistics,
      clientName: 'ООО "ГрузПеревозки"',
      clientInn: '7803456789',
    ),
    Transaction(
      amount: 31000,
      date: DateTime(currentYear, 2, 19),
      sphere: TransactionSphere.logistics,
      clientName: 'АО "ЛогистикПро"',
      clientInn: '7804567890',
    ),
    // Март
    Transaction(
      amount: 38000,
      date: DateTime(currentYear, 3, 12),
      sphere: TransactionSphere.logistics,
      clientName: 'ИП Зайцев',
      clientInn: '7805678901',
    ),
    Transaction(
      amount: 47000,
      date: DateTime(currentYear, 3, 26),
      sphere: TransactionSphere.logistics,
      clientName: 'ООО "ЭкспрессДоставка"',
      clientInn: '7806789012',
    ),
    // Апрель
    Transaction(
      amount: 52000,
      date: DateTime(currentYear, 4, 5),
      sphere: TransactionSphere.logistics,
      clientName: 'ООО "КаргоСервис"',
      clientInn: '7807890123',
    ),
    Transaction(
      amount: 44000,
      date: DateTime(currentYear, 4, 17),
      sphere: TransactionSphere.logistics,
      clientName: 'ИП Новиков',
      clientInn: '7808901234',
    ),
    // Май
    Transaction(
      amount: 49000,
      date: DateTime(currentYear, 5, 7),
      sphere: TransactionSphere.logistics,
      clientName: 'АО "ТрансСервис"',
      clientInn: '7809012345',
    ),
    Transaction(
      amount: 36000,
      date: DateTime(currentYear, 5, 21),
      sphere: TransactionSphere.logistics,
      clientName: 'ООО "ЛогистикаПлюс"',
      clientInn: '7810123456',
    ),
    // Июнь
    Transaction(
      amount: 58000,
      date: DateTime(currentYear, 6, 4),
      sphere: TransactionSphere.logistics,
      clientName: 'ИП Павлов',
      clientInn: '7811234567',
    ),
    Transaction(
      amount: 41000,
      date: DateTime(currentYear, 6, 16),
      sphere: TransactionSphere.logistics,
      clientName: 'ООО "Доставка24"',
      clientInn: '7812345678',
    ),
    // Июль
    Transaction(
      amount: 63000,
      date: DateTime(currentYear, 7, 2),
      sphere: TransactionSphere.logistics,
      clientName: 'АО "ФастКарго"',
      clientInn: '7813456789',
    ),
    Transaction(
      amount: 45000,
      date: DateTime(currentYear, 7, 14),
      sphere: TransactionSphere.logistics,
      clientName: 'ООО "ТрансЛогистик"',
      clientInn: '7814567890',
    ),
    Transaction(
      amount: 51000,
      date: DateTime(currentYear, 7, 28),
      sphere: TransactionSphere.logistics,
      clientName: 'ИП Соколов',
      clientInn: '7815678901',
    ),
    // Август (текущий месяц)
    Transaction(
      amount: 67000,
      date: DateTime(currentYear, 8, 6),
      sphere: TransactionSphere.logistics,
      clientName: 'ООО "ЛогистикГрупп"',
      clientInn: '7816789012',
    ),
    Transaction(
      amount: 39000,
      date: DateTime(currentYear, 8, 17),
      sphere: TransactionSphere.logistics,
      clientName: 'ИП Лебедев',
      clientInn: '7817890123',
    ),
    Transaction(
      amount: 54000,
      date: DateTime(currentYear, 8, 28),
      sphere: TransactionSphere.logistics,
      clientName: 'АО "КаргоТранс"',
      clientInn: '7818901234',
    ),
  ];

  for (final transaction in transactions) {
    await repository.add(transaction);
  }
}

/// Наполняет центр уведомлений примерами для демонстрации, если он пуст.
///
/// Тексты намеренно не содержат сумм и реквизитов — только безопасные
/// формулировки, как того требует PRD.
Future<void> seedNotifications(
  NotificationRepository repository, {
  DateTime? now,
}) async {
  if (await repository.count() > 0) return;

  final reference = now ?? DateTime.now();
  final notifications = <AppNotification>[
    AppNotification(
      type: NotificationType.limit,
      title: 'Приближение к лимиту',
      body: 'Вы близко к лимиту 2,4 млн. Проверьте остаток в разделе дашборда.',
      createdAt: reference.subtract(const Duration(hours: 2)),
    ),
    AppNotification(
      type: NotificationType.invoice,
      title: 'Счёт не оплачен',
      body: 'Счёт ожидает оплаты. Отметьте оплату после перевода.',
      createdAt: reference.subtract(const Duration(days: 1, hours: 3)),
      payload: 'invoice:14/09',
      actionLabel: 'Отметить как оплаченный',
    ),
    AppNotification(
      type: NotificationType.anomaly,
      title: 'Нестандартная транзакция',
      body: 'Сумма расчёта заметно превышает обычную. Проверьте операцию.',
      createdAt: reference.subtract(const Duration(days: 2, hours: 5)),
    ),
    AppNotification(
      type: NotificationType.digest,
      title: 'Недельная сводка',
      body: 'Доход за неделю, налог и остаток до лимита — внутри.',
      createdAt: reference.subtract(const Duration(days: 4)),
      actionLabel: 'Подробнее',
    ),
  ];

  for (final notification in notifications) {
    await repository.save(notification);
  }
}
