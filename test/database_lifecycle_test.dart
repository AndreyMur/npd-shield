import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:npd_shield/data/database.dart';
import 'package:npd_shield/data/models/app_notification.dart';
import 'package:npd_shield/data/models/contract_draft.dart';
import 'package:npd_shield/data/models/transaction.dart';
import 'package:npd_shield/data/repositories/isar_transaction_repository.dart';

void main() {
  test('открытие базы не наполняет её демонстрационными данными', () async {
    final dir = await Directory.systemTemp.createTemp('npd_autoseed_test');

    final isar = await AppDatabase.open(path: dir.path);

    expect(await isar.transactions.where().count(), 0);
    expect(await isar.appNotifications.where().count(), 0);
    expect(await isar.contractDrafts.where().count(), 0);

    await isar.close(deleteFromDisk: true);
  });

  test('пользовательские данные сохраняются при повторном открытии базы', () async {
    final dir = await Directory.systemTemp.createTemp('npd_persist_test');

    final first = await AppDatabase.open(path: dir.path);
    await IsarTransactionRepository(first).add(
      Transaction(
        amount: 5000,
        date: DateTime(2026, 9, 1),
        sphere: TransactionSphere.it,
        clientName: 'Клиент',
        clientInn: '1234567890',
      ),
    );
    await first.close();

    final reopened = await AppDatabase.open(path: dir.path);
    final transactions = await IsarTransactionRepository(reopened).getAll();

    expect(transactions, hasLength(1));
    expect(transactions.single.amount, 5000);

    await reopened.close(deleteFromDisk: true);
  });

  test('база предыдущей версии мигрирует без потери данных', () async {
    final dir = await Directory.systemTemp.createTemp('npd_migration_test');

    final legacy = await Isar.open(
      [TransactionSchema],
      directory: dir.path,
      name: 'npd_shield',
    );
    await IsarTransactionRepository(legacy).add(
      Transaction(
        amount: 7777,
        date: DateTime(2025, 12, 31),
        sphere: TransactionSphere.logistics,
        clientName: 'Старый клиент',
        clientInn: '0987654321',
      ),
    );
    await legacy.close();

    final migrated = await AppDatabase.open(path: dir.path);
    final transactions = await IsarTransactionRepository(migrated).getAll();

    expect(transactions, hasLength(1));
    expect(transactions.single.amount, 7777);
    expect(transactions.single.sphere, TransactionSphere.logistics);
    expect(await migrated.appNotifications.where().count(), 0);

    await migrated.close(deleteFromDisk: true);
  });
}
