import 'package:flutter_test/flutter_test.dart';
import 'package:npd_shield/data/models/transaction.dart';
import 'package:npd_shield/domain/reports/report_builder.dart';

import 'helpers/fake_transaction_repository.dart';

void main() {
  Transaction tx({
    double amount = 0,
    DateTime? date,
    TransactionSphere sphere = TransactionSphere.it,
    TransactionType type = TransactionType.income,
    String clientName = '',
    String clientInn = '',
    int? clientId,
  }) {
    return Transaction(
      amount: amount,
      date: date ?? DateTime(2026, 9, 15),
      sphere: sphere,
      clientName: clientName,
      clientInn: clientInn,
      type: type,
      clientId: clientId,
    );
  }

  group('ReportBuilder', () {
    test('считает доход, расход и прибыль за период', () async {
      final repository = FakeTransactionRepository([
        tx(amount: 100000, date: DateTime(2026, 9, 1)),
        tx(
          amount: 40000,
          date: DateTime(2026, 9, 20),
          type: TransactionType.expense,
        ),
        tx(amount: 999999, date: DateTime(2026, 8, 31)),
        tx(amount: 999999, date: DateTime(2026, 10, 1)),
      ]);
      final builder = ReportBuilder(transactionRepository: repository);

      final report = await builder.build(
        from: DateTime(2026, 9, 1),
        to: DateTime(2026, 9, 30),
      );

      expect(report.income, 100000);
      expect(report.expense, 40000);
      expect(report.profit, 60000);
    });

    test('период включает обе граничные даты целиком', () async {
      final repository = FakeTransactionRepository([
        tx(amount: 100, date: DateTime(2026, 9, 1, 0, 0)),
        tx(amount: 200, date: DateTime(2026, 9, 30, 23, 59)),
        tx(amount: 400, date: DateTime(2026, 10, 1, 0, 0)),
      ]);
      final builder = ReportBuilder(transactionRepository: repository);

      final report = await builder.build(
        from: DateTime(2026, 9, 1),
        to: DateTime(2026, 9, 30),
      );

      expect(report.income, 300);
      expect(report.from, DateTime(2026, 9, 1));
      expect(report.to, DateTime(2026, 9, 30));
    });

    test('налог считается только с дохода и с вычетом взносов', () async {
      final repository = FakeTransactionRepository([
        tx(amount: 1000000, date: DateTime(2026, 9, 5)),
        tx(
          amount: 500000,
          date: DateTime(2026, 9, 6),
          type: TransactionType.expense,
        ),
      ]);
      final builder = ReportBuilder(transactionRepository: repository);

      final report = await builder.build(
        from: DateTime(2026, 9, 1),
        to: DateTime(2026, 9, 30),
      );

      expect(report.tax.accruedTax, 60000);
      expect(report.tax.insuranceDeduction, 49500);
      expect(report.taxAmount, 10500);
    });

    test('разбивает показатели по сферам деятельности', () async {
      final repository = FakeTransactionRepository([
        tx(amount: 100000, sphere: TransactionSphere.it),
        tx(amount: 30000, sphere: TransactionSphere.it, type: TransactionType.expense),
        tx(amount: 50000, sphere: TransactionSphere.logistics),
      ]);
      final builder = ReportBuilder(transactionRepository: repository);

      final report = await builder.build(
        from: DateTime(2026, 9, 1),
        to: DateTime(2026, 9, 30),
      );

      expect(report.spheres, hasLength(2));
      final it = report.spheres.firstWhere(
        (row) => row.sphere == TransactionSphere.it,
      );
      final logistics = report.spheres.firstWhere(
        (row) => row.sphere == TransactionSphere.logistics,
      );
      expect(it.income, 100000);
      expect(it.expense, 30000);
      expect(it.profit, 70000);
      expect(logistics.income, 50000);
      expect(logistics.expense, 0);
      expect(report.spheres.first.sphere, TransactionSphere.it);
    });

    test('группирует операции по клиенту и по ИНН без карточки', () async {
      final repository = FakeTransactionRepository([
        tx(amount: 100000, clientId: 7, clientName: 'ООО «Ромашка»', clientInn: '7701234567'),
        tx(amount: 50000, clientId: 7, clientName: 'ООО «Ромашка»', clientInn: '7701234567'),
        tx(amount: 20000, clientName: 'ИП Петров', clientInn: '771234567890'),
        tx(amount: 10000, clientName: 'ИП Петров', clientInn: '771234567890'),
      ]);
      final builder = ReportBuilder(transactionRepository: repository);

      final report = await builder.build(
        from: DateTime(2026, 9, 1),
        to: DateTime(2026, 9, 30),
      );

      expect(report.clients, hasLength(2));
      final company = report.clients.firstWhere((c) => c.clientId == 7);
      expect(company.clientName, 'ООО «Ромашка»');
      expect(company.income, 150000);
      final individual = report.clients.firstWhere((c) => c.clientId == null);
      expect(individual.clientInn, '771234567890');
      expect(individual.income, 30000);
      expect(report.clients.first.clientId, 7);
    });

    test('фильтрует отчёт по сфере и клиенту', () async {
      final repository = FakeTransactionRepository([
        tx(amount: 100000, sphere: TransactionSphere.it, clientId: 7),
        tx(amount: 50000, sphere: TransactionSphere.logistics, clientId: 7),
        tx(amount: 70000, sphere: TransactionSphere.it, clientId: 8),
      ]);
      final builder = ReportBuilder(transactionRepository: repository);

      final bySphere = await builder.build(
        from: DateTime(2026, 9, 1),
        to: DateTime(2026, 9, 30),
        sphere: TransactionSphere.it,
      );
      final byClient = await builder.build(
        from: DateTime(2026, 9, 1),
        to: DateTime(2026, 9, 30),
        clientId: 7,
      );

      expect(bySphere.income, 170000);
      expect(byClient.income, 150000);
    });

    test('пустой отчёт при отсутствии операций', () async {
      final builder = ReportBuilder(
        transactionRepository: FakeTransactionRepository(),
      );

      final report = await builder.build(
        from: DateTime(2026, 9, 1),
        to: DateTime(2026, 9, 30),
      );

      expect(report.isEmpty, isTrue);
      expect(report.income, 0);
      expect(report.expense, 0);
      expect(report.profit, 0);
      expect(report.taxAmount, 0);
      expect(report.spheres, isEmpty);
      expect(report.clients, isEmpty);
    });
  });
}
