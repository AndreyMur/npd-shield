import 'package:flutter_test/flutter_test.dart';
import 'package:npd_shield/data/demo_data.dart';
import 'package:npd_shield/data/models/transaction.dart';
import 'package:npd_shield/domain/profile/contractor_profile.dart';

import 'helpers/fake_contract_repositories.dart';
import 'helpers/fake_notification_repository.dart';
import 'helpers/fake_transaction_repository.dart';

void main() {
  test('loadDemoData наполняет операции, уведомления и профиль', () async {
    final transactions = FakeTransactionRepository();
    final notifications = FakeNotificationRepository();
    final profile = FakeContractorProfileRepository();

    await loadDemoData(
      transactionRepository: transactions,
      notificationRepository: notifications,
      profileRepository: profile,
      now: DateTime(2026, 9, 15),
    );

    expect(transactions.transactions, isNotEmpty);
    expect(notifications.notifications, isNotEmpty);
    expect(profile.profile, isNotNull);
  });

  test('loadDemoData не удаляет существующие данные пользователя', () async {
    final existing = Transaction(
      amount: 12345,
      date: DateTime(2026, 9, 10),
      sphere: TransactionSphere.it,
      clientName: 'Существующий клиент',
      clientInn: '1234567890',
    );
    final transactions = FakeTransactionRepository([existing]);
    final notifications = FakeNotificationRepository();
    final profile = FakeContractorProfileRepository();

    await loadDemoData(
      transactionRepository: transactions,
      notificationRepository: notifications,
      profileRepository: profile,
      now: DateTime(2026, 9, 15),
    );

    expect(transactions.transactions, contains(existing));
    expect(transactions.transactions.length, greaterThan(1));
  });

  test('loadDemoData перезаписывает профиль демонстрационным', () async {
    final transactions = FakeTransactionRepository();
    final notifications = FakeNotificationRepository();
    final profile = FakeContractorProfileRepository(
      const ContractorProfile(
        fullName: 'Реальный ИП',
        inn: '000000000000',
        ogrnip: '',
        registrationAddress: '',
        bankName: '',
        bankAccount: '',
        bankBik: '',
      ),
    );

    await loadDemoData(
      transactionRepository: transactions,
      notificationRepository: notifications,
      profileRepository: profile,
    );

    expect(profile.profile, ContractorProfile.demo);
  });
}
