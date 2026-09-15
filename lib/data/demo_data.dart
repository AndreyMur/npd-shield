import '../domain/profile/contractor_profile.dart';
import 'repositories/contractor_profile_repository.dart';
import 'repositories/notification_repository.dart';
import 'repositories/transaction_repository.dart';
import 'seed_data.dart';

/// Загружает демонстрационные данные по явному действию пользователя.
///
/// В отличие от прежнего автоматического сида при запуске, функция ничего не
/// очищает: демо добавляется к текущим данным, а решение о загрузке (с
/// предупреждением о перезаписи) принимает пользователь в интерфейсе.
Future<void> loadDemoData({
  required TransactionRepository transactionRepository,
  required NotificationRepository notificationRepository,
  required ContractorProfileRepository profileRepository,
  DateTime? now,
}) async {
  await seedDemoTransactions(transactionRepository, now: now);
  await seedDemoNotifications(notificationRepository, now: now);
  await profileRepository.save(ContractorProfile.demo);
}
