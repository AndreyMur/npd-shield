import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:npd_shield/data/export/csv_export_service.dart';
import 'package:npd_shield/data/models/invoice.dart';
import 'package:npd_shield/data/models/transaction.dart';

void main() {
  const service = CsvExportService();

  Transaction tx({
    double amount = 0,
    DateTime? date,
    TransactionSphere sphere = TransactionSphere.it,
    TransactionType type = TransactionType.income,
    String clientName = 'ООО «Ромашка»',
    String clientInn = '7701234567',
    String category = '',
    String comment = '',
  }) {
    return Transaction(
      amount: amount,
      date: date ?? DateTime(2026, 9, 15),
      sphere: sphere,
      clientName: clientName,
      clientInn: clientInn,
      type: type,
      category: category,
      comment: comment,
    );
  }

  group('CSV операций', () {
    test('содержит заголовок и строку операции', () {
      final export = service.exportTransactions(
        [tx(amount: 150000, category: 'Разработка', comment: 'Оплата')],
        from: DateTime(2026, 9, 1),
        to: DateTime(2026, 9, 30),
      );

      final lines = export.content.trim().split('\r\n');
      expect(lines.first, 'Дата;Тип;Сфера;Сумма;Клиент;ИНН;Категория;Комментарий');
      expect(
        lines[1],
        '15.09.2026;Доход;IT;150 000,00;ООО «Ромашка»;7701234567;Разработка;Оплата',
      );
      expect(export.rowCount, 1);
    });

    test('байты начинаются с UTF-8 BOM', () {
      final export = service.exportTransactions(
        [tx(amount: 1000)],
        from: DateTime(2026, 9, 1),
        to: DateTime(2026, 9, 30),
      );

      expect(export.bytes.take(3).toList(), [0xEF, 0xBB, 0xBF]);
      final decoded = utf8.decode(export.bytes.sublist(3));
      expect(decoded, startsWith('Дата;'));
    });

    test('экранирует поля с разделителем и кавычками', () {
      final export = service.exportTransactions(
        [tx(amount: 1000, comment: 'Счёт №5; оплата "частями"')],
        from: DateTime(2026, 9, 1),
        to: DateTime(2026, 9, 30),
      );

      expect(
        export.content,
        contains('"Счёт №5; оплата ""частями"""'),
      );
    });

    test('сортирует операции по дате и формирует имя файла', () {
      final export = service.exportTransactions(
        [
          tx(amount: 200, date: DateTime(2026, 9, 20)),
          tx(amount: 100, date: DateTime(2026, 9, 5)),
        ],
        from: DateTime(2026, 9, 1),
        to: DateTime(2026, 9, 30),
      );

      final lines = export.content.trim().split('\r\n');
      expect(lines[1], contains('100,00'));
      expect(lines[2], contains('200,00'));
      expect(export.fileName, 'operations_2026-09-01_2026-09-30.csv');
    });

    test('расход и логистика попадают в выгрузку', () {
      final export = service.exportTransactions(
        [
          tx(
            amount: 25000.5,
            type: TransactionType.expense,
            sphere: TransactionSphere.logistics,
          ),
        ],
        from: DateTime(2026, 9, 1),
        to: DateTime(2026, 9, 30),
      );

      expect(export.content, contains('Расход;Логистика;25 000,50'));
    });
  });

  group('CSV счетов', () {
    Invoice invoice({
      String number = '14/09',
      double amount = 50000,
      double paidAmount = 0,
      DateTime? issuedAt,
      DateTime? dueDate,
      InvoiceStatus status = InvoiceStatus.sent,
      String clientName = 'ООО «Ромашка»',
      String clientInn = '7701234567',
      String comment = '',
    }) {
      return Invoice(
        number: number,
        amount: amount,
        issuedAt: issuedAt ?? DateTime(2026, 9, 1),
        dueDate: dueDate ?? DateTime(2026, 9, 30),
        status: status,
        paidAmount: paidAmount,
        clientName: clientName,
        clientInn: clientInn,
        comment: comment,
      );
    }

    test('содержит заголовок и показатели счёта', () {
      final export = service.exportInvoices(
        [invoice(amount: 50000, paidAmount: 20000)],
        from: DateTime(2026, 9, 1),
        to: DateTime(2026, 9, 30),
        now: DateTime(2026, 9, 15),
      );

      final lines = export.content.trim().split('\r\n');
      expect(
        lines.first,
        'Номер;Дата выставления;Срок оплаты;Статус;Сумма;Оплачено;Остаток;'
        'Клиент;ИНН;Комментарий',
      );
      expect(
        lines[1],
        '14/09;01.09.2026;30.09.2026;Отправлен;50 000,00;20 000,00;30 000,00;'
        'ООО «Ромашка»;7701234567;',
      );
      expect(export.rowCount, 1);
    });

    test('просроченный счёт получает статус «Просрочен»', () {
      final export = service.exportInvoices(
        [invoice(dueDate: DateTime(2026, 9, 1))],
        from: DateTime(2026, 9, 1),
        to: DateTime(2026, 9, 30),
        now: DateTime(2026, 9, 15),
      );

      expect(export.content, contains(';Просрочен;'));
    });

    test('отбирает счета только за выбранный период выставления', () {
      final export = service.exportInvoices(
        [
          invoice(number: 'inside', issuedAt: DateTime(2026, 9, 10)),
          invoice(number: 'outside', issuedAt: DateTime(2026, 8, 10)),
        ],
        from: DateTime(2026, 9, 1),
        to: DateTime(2026, 9, 30),
        now: DateTime(2026, 9, 15),
      );

      expect(export.rowCount, 1);
      expect(export.content, contains('inside'));
      expect(export.content, isNot(contains('outside')));
      expect(export.fileName, 'invoices_2026-09-01_2026-09-30.csv');
    });
  });
}
