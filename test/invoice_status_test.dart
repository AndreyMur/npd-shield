import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:npd_shield/data/models/invoice.dart';
import 'package:npd_shield/data/repositories/isar_invoice_repository.dart';
import 'package:npd_shield/data/security/field_encryption_service.dart';

import 'helpers/fake_transaction_repository.dart';

void main() {
  final now = DateTime(2026, 9, 15);

  Invoice invoice({
    required InvoiceStatus status,
    DateTime? dueDate,
    double amount = 50000,
    double paidAmount = 0,
  }) {
    return Invoice(
      number: '14/09',
      amount: amount,
      issuedAt: DateTime(2026, 9, 1),
      dueDate: dueDate ?? DateTime(2026, 9, 30),
      status: status,
      paidAmount: paidAmount,
    );
  }

  group('статус «просрочен» определяется по сроку и дате', () {
    test('отправленный счёт с прошедшим сроком просрочен', () {
      final subject = invoice(
        status: InvoiceStatus.sent,
        dueDate: DateTime(2026, 9, 1),
      );

      expect(subject.effectiveStatus(now: now), InvoiceStatus.overdue);
      expect(subject.isOverdue(now: now), isTrue);
    });

    test('счёт со сроком сегодня ещё не просрочен', () {
      final subject = invoice(
        status: InvoiceStatus.sent,
        dueDate: DateTime(2026, 9, 15),
      );

      expect(subject.effectiveStatus(now: now), InvoiceStatus.sent);
      expect(subject.isOverdue(now: now), isFalse);
    });

    test('счёт с будущим сроком не просрочен', () {
      final subject = invoice(
        status: InvoiceStatus.sent,
        dueDate: DateTime(2026, 9, 30),
      );

      expect(subject.effectiveStatus(now: now), InvoiceStatus.sent);
    });

    test('срок сравнивается по дню, а не по времени', () {
      final subject = invoice(
        status: InvoiceStatus.sent,
        dueDate: DateTime(2026, 9, 14, 23, 59),
      );

      expect(subject.effectiveStatus(now: DateTime(2026, 9, 15, 0, 1)),
          InvoiceStatus.overdue);
    });

    test('оплаченный счёт не становится просроченным', () {
      final subject = invoice(
        status: InvoiceStatus.paid,
        dueDate: DateTime(2026, 9, 1),
        paidAmount: 50000,
      );

      expect(subject.effectiveStatus(now: now), InvoiceStatus.paid);
    });

    test('отменённый счёт не становится просроченным', () {
      final subject = invoice(
        status: InvoiceStatus.cancelled,
        dueDate: DateTime(2026, 9, 1),
      );

      expect(subject.effectiveStatus(now: now), InvoiceStatus.cancelled);
    });

    test('черновик не становится просроченным', () {
      final subject = invoice(
        status: InvoiceStatus.draft,
        dueDate: DateTime(2026, 9, 1),
      );

      expect(subject.effectiveStatus(now: now), InvoiceStatus.draft);
    });

    test('частично оплаченный отправленный счёт просрочивается по сроку', () {
      final subject = invoice(
        status: InvoiceStatus.sent,
        dueDate: DateTime(2026, 9, 1),
        paidAmount: 20000,
      );

      expect(subject.effectiveStatus(now: now), InvoiceStatus.overdue);
      expect(subject.outstanding, 30000);
    });
  });

  group('ручная установка «просрочен» недоступна', () {
    test('«просрочен» отсутствует в списке ручных статусов', () {
      expect(InvoiceStatus.manualValues, isNot(contains(InvoiceStatus.overdue)));
      expect(
        InvoiceStatus.manualValues,
        containsAll([
          InvoiceStatus.draft,
          InvoiceStatus.sent,
          InvoiceStatus.paid,
          InvoiceStatus.cancelled,
        ]),
      );
    });

    late Isar isar;
    late IsarInvoiceRepository repository;

    setUp(() async {
      final dir = await Directory.systemTemp.createTemp('npd_invoice_status');
      isar = await Isar.open(
        [InvoiceSchema],
        directory: dir.path,
        name: 'invoice_status_${dir.path.hashCode}',
      );
      repository = IsarInvoiceRepository(
        isar,
        FakeTransactionRepository(),
        encryption: const _PassthroughEncryption(),
      );
    });

    tearDown(() async {
      await isar.close(deleteFromDisk: true);
    });

    test('add со статусом «просрочен» бросает ArgumentError', () async {
      expect(
        () => repository.add(invoice(status: InvoiceStatus.overdue)),
        throwsA(isA<ArgumentError>()),
      );
      expect(await repository.count(), 0);
    });

    test('update со статусом «просрочен» бросает ArgumentError', () async {
      final id = await repository.add(invoice(status: InvoiceStatus.sent));
      final loaded = await repository.getById(id);
      loaded!.status = InvoiceStatus.overdue;

      expect(
        () => repository.update(loaded),
        throwsA(isA<ArgumentError>()),
      );

      final stored = await repository.getById(id);
      expect(stored!.status, InvoiceStatus.sent);
    });

    test('просроченный счёт хранится как отправленный', () async {
      final id = await repository.add(
        invoice(
          status: InvoiceStatus.sent,
          dueDate: DateTime(2026, 9, 1),
        ),
      );

      final stored = await isar.invoices.get(id);
      expect(stored!.status, InvoiceStatus.sent);

      final loaded = await repository.getById(id);
      expect(loaded!.effectiveStatus(now: now), InvoiceStatus.overdue);
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
