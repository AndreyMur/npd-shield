import 'package:flutter_test/flutter_test.dart';
import 'package:npd_shield/core/constants/contract_field_keys.dart';
import 'package:npd_shield/data/models/document.dart';
import 'package:npd_shield/domain/documents/act.dart';
import 'package:npd_shield/domain/documents/receipt.dart';
import 'package:npd_shield/domain/profile/contractor_profile.dart';

void main() {
  const generator = ActGenerator();

  Map<String, String> contractFields() => const {
    ContractFieldKeys.contractNumber: '14/09',
    ContractFieldKeys.contractDate: '05.09.2026',
    ContractFieldKeys.clientName: 'ООО «Ромашка»',
    ContractFieldKeys.clientInn: '7701234567',
    ContractFieldKeys.subject: 'Разработка сайта',
    ContractFieldKeys.amount: '150 000,50',
  };

  Receipt receipt() => Receipt(
    sellerName: ContractorProfile.demo.fullName,
    sellerInn: ContractorProfile.demo.inn,
    serviceName: 'Разработка сайта',
    amount: 150000.50,
    date: DateTime(2026, 9, 5),
    buyerName: 'ООО «Ромашка»',
    buyerInn: '7701234567',
    contractDraftId: 5,
    contractNumber: '14/09',
  );

  group('автозаполнение акта из договора', () {
    test('реквизиты исполнителя берутся из профиля ИП', () {
      final act = generator.generate(
        profile: ContractorProfile.demo,
        contractFields: contractFields(),
      );

      expect(act.sellerName, ContractorProfile.demo.fullName);
      expect(act.sellerInn, ContractorProfile.demo.inn);
    });

    test('поля акта заполняются из договора', () {
      final act = generator.generate(
        profile: ContractorProfile.demo,
        contractFields: contractFields(),
        contractDraftId: 7,
      );

      expect(act.worksDescription, 'Разработка сайта');
      expect(act.amount, 150000.50);
      expect(act.buyerName, 'ООО «Ромашка»');
      expect(act.buyerInn, '7701234567');
      expect(act.contractNumber, '14/09');
      expect(act.contractDraftId, 7);
      expect(act.completionDate, DateTime(2026, 9, 5));
      expect(act.result, defaultActResult);
    });

    test('подписи сторон подставляются из профиля и заказчика', () {
      final act = generator.generate(
        profile: ContractorProfile.demo,
        contractFields: contractFields(),
      );

      expect(act.executorSignatory, ContractorProfile.demo.fullName);
      expect(act.customerSignatory, 'ООО «Ромашка»');
      expect(act.hasSignatures, isTrue);
    });

    test('дата выполнения по умолчанию берётся из параметра', () {
      final act = generator.generate(
        profile: ContractorProfile.demo,
        contractFields: contractFields(),
        completionDate: DateTime(2026, 10, 1),
      );

      expect(act.completionDate, DateTime(2026, 10, 1));
    });
  });

  group('приоритет чека', () {
    test('сумма, заказчик и дата берутся из чека', () {
      final act = generator.generate(
        profile: ContractorProfile.demo,
        contractFields: contractFields(),
        receipt: receipt(),
        receiptDocumentId: 42,
      );

      expect(act.amount, 150000.50);
      expect(act.buyerName, 'ООО «Ромашка»');
      expect(act.buyerInn, '7701234567');
      expect(act.completionDate, DateTime(2026, 9, 5));
      expect(act.receiptDocumentId, 42);
      expect(act.worksDescription, 'Разработка сайта');
    });

    test('без предмета договора описание берётся из чека', () {
      final act = generator.generate(
        profile: ContractorProfile.demo,
        receipt: receipt(),
        receiptDocumentId: 1,
      );

      expect(act.worksDescription, 'Разработка сайта');
      expect(act.amount, 150000.50);
    });
  });

  group('формат и преобразование', () {
    test('сумма и дата форматируются', () {
      final act = generator.generate(
        profile: ContractorProfile.demo,
        contractFields: contractFields(),
      );

      expect(act.formattedAmount, '150 000,50 ₽');
      expect(act.formattedDate, '05.09.2026');
    });

    test('hasBuyerInn отражает наличие ИНН заказчика', () {
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

    test('toDocument преобразует акт в запись архива со связями', () {
      final act = generator.generate(
        profile: ContractorProfile.demo,
        contractFields: contractFields(),
        contractDraftId: 3,
        receiptDocumentId: 9,
      );

      final document = act.toDocument();

      expect(document.type, DocumentType.act);
      expect(document.status, DocumentStatus.generated);
      expect(document.amount, 150000.50);
      expect(document.date, DateTime(2026, 9, 5));
      expect(document.contractDraftId, 3);
      expect(document.contractNumber, '14/09');
      expect(document.receiptDocumentId, 9);
      expect(document.counterpartyName, 'ООО «Ромашка»');
      expect(document.counterpartyInn, '7701234567');
      expect(document.serviceName, 'Разработка сайта');
      expect(document.result, defaultActResult);
      expect(document.executorSignatory, ContractorProfile.demo.fullName);
      expect(document.customerSignatory, 'ООО «Ромашка»');
      expect(document.issuerName, ContractorProfile.demo.fullName);
      expect(document.issuerInn, ContractorProfile.demo.inn);
    });

    test('toDocument помечает черновик статусом draft', () {
      final act = generator.generate(
        profile: ContractorProfile.demo,
        contractFields: contractFields(),
      );

      final document = act.toDocument(status: DocumentStatus.draft);

      expect(document.status, DocumentStatus.draft);
    });
  });
}
