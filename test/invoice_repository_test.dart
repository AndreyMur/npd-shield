import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:npd_shield/data/models/invoice.dart';
import 'package:npd_shield/data/models/transaction.dart';
import 'package:npd_shield/data/repositories/isar_invoice_repository.dart';
import 'package:npd_shield/data/security/field_encryption_service.dart';

import 'helpers/fake_transaction_repository.dart';

void main() {
  late Isar isar;
  late FakeTransactionRepository transactions;
  late IsarInvoiceRepository repository;

  setUp(() async {
    final dir = await Directory.systemTemp.createTemp('npd_invoice_test');
    isar = await Isar.open(
      [InvoiceSchema],
      directory: dir.path,
      name: 'invoice_test_${dir.path.hashCode}',
    );
    transactions = FakeTransactionRepository();
    repository = IsarInvoiceRepository(
      isar,
      transactions,
      encryption: const _PassthroughEncryption(),
    );
  });

  tearDown(() async {
    await isar.close(deleteFromDisk: true);
  });

  Invoice invoice({
    String number = '14/09',
    double amount = 50000,
    DateTime? issuedAt,
    DateTime? dueDate,
    int clientId = 0,
    String clientName = 'ООО «Ромашка»',
    String clientInn = '7701234567',
    InvoiceStatus status = InvoiceStatus.sent,
    double paidAmount = 0,
    String comment = '',
  }) {
    return Invoice(
      number: number,
      amount: amount,
      issuedAt: issuedAt ?? DateTime(2026, 9, 1),
      dueDate: dueDate ?? DateTime(2026, 9, 30),
      clientId: clientId,
      clientName: clientName,
      clientInn: clientInn,
      status: status,
      paidAmount: paidAmount,
      comment: comment,
    );
  }

  group('CRUD', () {
    test('add присваивает id и позволяет прочитать счёт', () async {
      final id = await repository.add(invoice(number: '7/09'));

      final loaded = await repository.getById(id);

      expect(id, isNot(0));
      expect(loaded, isNotNull);
      expect(loaded!.number, '7/09');
      expect(loaded.amount, 50000);
      expect(loaded.clientName, 'ООО «Ромашка»');
      expect(loaded.clientInn, '7701234567');
      expect(loaded.status, InvoiceStatus.sent);
      expect(loaded.transactionId, 0);
    });

    test('getById возвращает null для неизвестного id', () async {
      expect(await repository.getById(999), isNull);
    });

    test('update сохраняет изменённые поля', () async {
      final id = await repository.add(invoice(number: '1/09'));

      final loaded = await repository.getById(id);
      loaded!.number = '2/09';
      loaded.amount = 80000;
      loaded.status = InvoiceStatus.cancelled;
      loaded.comment = 'Отменён по просьбе клиента';
      await repository.update(loaded);

      final updated = await repository.getById(id);
      expect(updated!.number, '2/09');
      expect(updated.amount, 80000);
      expect(updated.status, InvoiceStatus.cancelled);
      expect(updated.comment, 'Отменён по просьбе клиента');
    });

    test('delete удаляет счёт и сообщает об успехе', () async {
      final id = await repository.add(invoice());

      final deleted = await repository.delete(id);

      expect(deleted, isTrue);
      expect(await repository.getById(id), isNull);
      expect(await repository.getAll(), isEmpty);
    });

    test('delete сообщает false для неизвестного id', () async {
      expect(await repository.delete(123), isFalse);
    });

    test('count считает счета', () async {
      await repository.add(invoice(number: '1'));
      await repository.add(invoice(number: '2'));

      expect(await repository.count(), 2);
    });

    test('getAll возвращает счета от новых к старым', () async {
      final base = DateTime(2026, 9, 1);
      await repository.add(invoice(number: '1', issuedAt: base));
      await repository.add(invoice(number: '3', issuedAt: base.add(const Duration(days: 2))));
      await repository.add(invoice(number: '2', issuedAt: base.add(const Duration(days: 1))));

      final all = await repository.getAll();

      expect(all.map((i) => i.number).toList(), ['3', '2', '1']);
    });

    test('getByClientId возвращает счета только выбранного клиента', () async {
      await repository.add(invoice(number: '1', clientId: 7));
      await repository.add(invoice(number: '2', clientId: 8));
      await repository.add(invoice(number: '3', clientId: 7));

      final result = await repository.getByClientId(7);

      expect(result, hasLength(2));
      expect(result.every((i) => i.clientId == 7), isTrue);
    });

    test('clear удаляет все счета', () async {
      await repository.add(invoice(number: '1'));
      await repository.add(invoice(number: '2'));

      await repository.clear();

      expect(await repository.count(), 0);
      expect(await repository.getAll(), isEmpty);
    });
  });

  group('шифрование счетов', () {
    test('персональные поля шифруются в базе и расшифровываются при чтении', () async {
      final encryptedRepository = IsarInvoiceRepository(
        isar,
        transactions,
        encryption: const _PrefixEncryption(),
      );
      final id = await encryptedRepository.add(
        invoice(clientName: 'ООО «Ромашка»', clientInn: '7701234567', comment: 'VIP'),
      );

      final raw = await isar.invoices.get(id);
      expect(raw!.clientName, 'enc:ООО «Ромашка»');
      expect(raw.clientInn, 'enc:7701234567');
      expect(raw.comment, 'enc:VIP');

      final loaded = await encryptedRepository.getById(id);
      expect(loaded!.clientName, 'ООО «Ромашка»');
      expect(loaded.clientInn, '7701234567');
      expect(loaded.comment, 'VIP');
    });
  });

  group('частичная оплата', () {
    test('частичная оплата уменьшает остаток и не меняет статус', () async {
      final id = await repository.add(invoice(amount: 50000));

      final paid = await repository.markPaid(id, amount: 20000);

      expect(paid.paidAmount, 20000);
      expect(paid.outstanding, 30000);
      expect(paid.status, InvoiceStatus.sent);
      expect(paid.transactionId, 0);
      expect(transactions.transactions, isEmpty);
    });

    test('несколько частичных оплат накапливаются', () async {
      final id = await repository.add(invoice(amount: 50000));

      await repository.markPaid(id, amount: 20000);
      final paid = await repository.markPaid(id, amount: 20000);

      expect(paid.paidAmount, 40000);
      expect(paid.outstanding, 10000);
      expect(paid.status, InvoiceStatus.sent);
    });

    test('без суммы гасится весь остаток', () async {
      final id = await repository.add(invoice(amount: 50000));
      await repository.markPaid(id, amount: 20000);

      final paid = await repository.markPaid(id);

      expect(paid.paidAmount, 50000);
      expect(paid.outstanding, 0);
      expect(paid.status, InvoiceStatus.paid);
    });

    test('оплата больше остатка не создаёт переплату', () async {
      final id = await repository.add(invoice(amount: 50000));

      final paid = await repository.markPaid(id, amount: 70000);

      expect(paid.paidAmount, 50000);
      expect(paid.outstanding, 0);
    });

    test('нельзя оплатить отменённый счёт', () async {
      final id = await repository.add(invoice(status: InvoiceStatus.cancelled));

      expect(
        () => repository.markPaid(id),
        throwsA(isA<StateError>()),
      );
    });

    test('оплата неизвестного счёта бросает StateError', () async {
      expect(
        () => repository.markPaid(999),
        throwsA(isA<StateError>()),
      );
    });

    test('нулевая или отрицательная сумма бросает ArgumentError', () async {
      final id = await repository.add(invoice());

      expect(
        () => repository.markPaid(id, amount: 0),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => repository.markPaid(id, amount: -100),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  group('создание дохода при полной оплате', () {
    test('полная оплата переводит счёт в «оплачен» и создаёт доход', () async {
      final id = await repository.add(
        invoice(
          amount: 50000,
          clientId: 7,
          clientName: 'ООО «Ромашка»',
          clientInn: '7701234567',
        ),
      );

      final paid = await repository.markPaid(
        id,
        paidAt: DateTime(2026, 9, 20),
        sphere: TransactionSphere.logistics,
        category: 'Разработка',
        comment: 'Оплата по счёту 14/09',
      );

      expect(paid.status, InvoiceStatus.paid);
      expect(paid.transactionId, isNot(0));
      expect(transactions.transactions, hasLength(1));

      final income = transactions.transactions.single;
      expect(income.id, paid.transactionId);
      expect(income.type, TransactionType.income);
      expect(income.amount, 50000);
      expect(income.date, DateTime(2026, 9, 20));
      expect(income.sphere, TransactionSphere.logistics);
      expect(income.clientId, 7);
      expect(income.clientName, 'ООО «Ромашка»');
      expect(income.clientInn, '7701234567');
      expect(income.category, 'Разработка');
      expect(income.comment, 'Оплата по счёту 14/09');
    });

    test('доход создаётся только при полной оплате и один раз', () async {
      final id = await repository.add(invoice(amount: 50000));

      await repository.markPaid(id, amount: 20000);
      expect(transactions.transactions, isEmpty);

      await repository.markPaid(id, amount: 30000);
      expect(transactions.transactions, hasLength(1));

      await repository.markPaid(id);
      expect(transactions.transactions, hasLength(1));
    });

    test('счёт без клиента создаёт доход без привязки к карточке', () async {
      final id = await repository.add(invoice(clientId: 0));

      await repository.markPaid(id);

      expect(transactions.transactions.single.clientId, isNull);
    });
  });

  group('просроченные счета', () {
    final now = DateTime(2026, 9, 15);

    test('getOverdue возвращает отправленные счета с прошедшим сроком', () async {
      await repository.add(
        invoice(number: 'old', dueDate: DateTime(2026, 9, 1)),
      );
      await repository.add(
        invoice(number: 'future', dueDate: DateTime(2026, 9, 30)),
      );
      await repository.add(
        invoice(
          number: 'paid',
          dueDate: DateTime(2026, 9, 1),
          status: InvoiceStatus.paid,
        ),
      );
      await repository.add(
        invoice(
          number: 'draft',
          dueDate: DateTime(2026, 9, 1),
          status: InvoiceStatus.draft,
        ),
      );

      final overdue = await repository.getOverdue(now: now);

      expect(overdue, hasLength(1));
      expect(overdue.single.number, 'old');
    });

    test('getOverdue сортирует счета от старых к новым по сроку', () async {
      await repository.add(invoice(number: 'new', dueDate: DateTime(2026, 9, 10)));
      await repository.add(invoice(number: 'old', dueDate: DateTime(2026, 9, 2)));

      final overdue = await repository.getOverdue(now: now);

      expect(overdue.map((i) => i.number).toList(), ['old', 'new']);
    });

    test('getOutstandingTotal суммирует остаток выставленных счетов', () async {
      await repository.add(invoice(number: '1', amount: 50000));
      await repository.add(invoice(number: '2', amount: 30000, paidAmount: 10000));
      await repository.add(
        invoice(number: 'draft', amount: 90000, status: InvoiceStatus.draft),
      );
      await repository.add(
        invoice(
          number: 'cancelled',
          amount: 40000,
          status: InvoiceStatus.cancelled,
        ),
      );

      final total = await repository.getOutstandingTotal(now: now);

      expect(total, 70000);
    });
  });
}

/// Шифрование-заглушка: хранит значение как есть.
class _PassthroughEncryption implements FieldEncryptionService {
  const _PassthroughEncryption();

  @override
  Future<String> encrypt(String plainText) async => plainText;

  @override
  Future<String> decrypt(String encryptedText) async => encryptedText;
}

/// Детерминированное шифрование: добавляет префикс `enc:`.
class _PrefixEncryption implements FieldEncryptionService {
  const _PrefixEncryption();

  static const _marker = 'enc:';

  @override
  Future<String> encrypt(String plainText) async => '$_marker$plainText';

  @override
  Future<String> decrypt(String encryptedText) async =>
      encryptedText.startsWith(_marker)
      ? encryptedText.substring(_marker.length)
      : encryptedText;
}
