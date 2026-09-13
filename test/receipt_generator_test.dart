import 'package:flutter_test/flutter_test.dart';
import 'package:npd_shield/core/constants/contract_field_keys.dart';
import 'package:npd_shield/data/models/document.dart';
import 'package:npd_shield/data/models/transaction.dart';
import 'package:npd_shield/domain/documents/receipt.dart';
import 'package:npd_shield/domain/profile/contractor_profile.dart';

void main() {
  const generator = ReceiptGenerator();

  Map<String, String> contractFields() => const {
    ContractFieldKeys.contractNumber: '14/09',
    ContractFieldKeys.contractDate: '05.09.2026',
    ContractFieldKeys.clientName: 'ООО «Ромашка»',
    ContractFieldKeys.clientInn: '7701234567',
    ContractFieldKeys.subject: 'Разработка сайта',
    ContractFieldKeys.amount: '150 000,50',
  };

  group('автозаполнение чека', () {
    test('реквизиты исполнителя берутся из профиля ИП', () {
      final receipt = generator.generate(
        profile: ContractorProfile.demo,
        contractFields: contractFields(),
      );

      expect(receipt.sellerName, ContractorProfile.demo.fullName);
      expect(receipt.sellerInn, ContractorProfile.demo.inn);
    });

    test('поля чека заполняются из договора', () {
      final receipt = generator.generate(
        profile: ContractorProfile.demo,
        contractFields: contractFields(),
        contractDraftId: 5,
      );

      expect(receipt.serviceName, 'Разработка сайта');
      expect(receipt.amount, 150000.50);
      expect(receipt.buyerName, 'ООО «Ромашка»');
      expect(receipt.buyerInn, '7701234567');
      expect(receipt.contractNumber, '14/09');
      expect(receipt.contractDraftId, 5);
      expect(receipt.date, DateTime(2026, 9, 5));
    });

    test('дата по умолчанию берётся из параметра date', () {
      final receipt = generator.generate(
        profile: ContractorProfile.demo,
        contractFields: contractFields(),
        date: DateTime(2026, 10, 1),
      );

      expect(receipt.date, DateTime(2026, 10, 1));
    });
  });

  group('приоритет транзакции', () {
    test('сумма и покупатель берутся из транзакции, если она передана', () {
      final transaction = Transaction(
        amount: 99000,
        date: DateTime(2026, 9, 20),
        sphere: TransactionSphere.logistics,
        clientName: 'ИП Петров',
        clientInn: '7702345678',
      );

      final receipt = generator.generate(
        profile: ContractorProfile.demo,
        contractFields: contractFields(),
        transaction: transaction,
        transactionId: 11,
      );

      expect(receipt.amount, 99000);
      expect(receipt.buyerName, 'ИП Петров');
      expect(receipt.buyerInn, '7702345678');
      expect(receipt.date, DateTime(2026, 9, 20));
      expect(receipt.transactionId, 11);
      // Наименование услуги всё ещё из договора.
      expect(receipt.serviceName, 'Разработка сайта');
    });

    test('без предмета договора подставляется название сферы транзакции', () {
      final transaction = Transaction(
        amount: 1000,
        date: DateTime(2026, 9, 20),
        sphere: TransactionSphere.logistics,
        clientName: 'ИП Петров',
        clientInn: '',
      );

      final receipt = generator.generate(
        profile: ContractorProfile.demo,
        transaction: transaction,
      );

      expect(receipt.serviceName, 'Логистические услуги');
      expect(receipt.amount, 1000);
    });
  });

  group('формат полей', () {
    test('сумма форматируется с разрядами и копейками', () {
      final receipt = generator.generate(
        profile: ContractorProfile.demo,
        contractFields: contractFields(),
      );

      expect(receipt.formattedAmount, '150 000,50 ₽');
    });

    test('дата форматируется как ДД.ММ.ГГГГ', () {
      final receipt = generator.generate(
        profile: ContractorProfile.demo,
        contractFields: contractFields(),
      );

      expect(receipt.formattedDate, '05.09.2026');
    });

    test('hasBuyerInn отражает наличие ИНН покупателя', () {
      final withInn = generator.generate(
        profile: ContractorProfile.demo,
        contractFields: contractFields(),
      );
      final withoutInn = generator.generate(
        profile: ContractorProfile.demo,
      );

      expect(withInn.hasBuyerInn, isTrue);
      expect(withoutInn.hasBuyerInn, isFalse);
    });
  });

  group('parseReceiptAmount', () {
    test('разбирает пробелы, запятую и валюту', () {
      expect(parseReceiptAmount('150 000,50'), 150000.50);
      expect(parseReceiptAmount('150000.50'), 150000.50);
      expect(parseReceiptAmount('150 000 ₽'), 150000);
      expect(parseReceiptAmount(''), 0);
    });
  });

  group('parseContractDate', () {
    test('разбирает корректную дату и отвергает некорректную', () {
      expect(parseContractDate('05.09.2026'), DateTime(2026, 9, 5));
      expect(parseContractDate('5.9.2026'), isNull);
      expect(parseContractDate('32.09.2026'), isNull);
      expect(parseContractDate(''), isNull);
    });
  });

  group('toDocument', () {
    test('преобразует чек в запись архива документов', () {
      final receipt = generator.generate(
        profile: ContractorProfile.demo,
        contractFields: contractFields(),
        contractDraftId: 3,
        transactionId: 9,
      );

      final document = receipt.toDocument();

      expect(document.type, DocumentType.receipt);
      expect(document.status, DocumentStatus.generated);
      expect(document.amount, 150000.50);
      expect(document.date, DateTime(2026, 9, 5));
      expect(document.contractDraftId, 3);
      expect(document.contractNumber, '14/09');
      expect(document.counterpartyName, 'ООО «Ромашка»');
      expect(document.counterpartyInn, '7701234567');
      expect(document.transactionId, 9);
      expect(document.serviceName, 'Разработка сайта');
      expect(document.issuerName, ContractorProfile.demo.fullName);
      expect(document.issuerInn, ContractorProfile.demo.inn);
    });
  });
}
