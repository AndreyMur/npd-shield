import 'package:flutter_test/flutter_test.dart';
import 'package:npd_shield/data/models/contract_draft.dart';
import 'package:npd_shield/domain/contracts/contract_status.dart';

void main() {
  group('ContractStatus transitions', () {
    test('черновик можно подписать или отправить в архив', () {
      expect(
        ContractStatus.draft.allowedTransitions,
        {ContractStatus.signed, ContractStatus.archived},
      );
      expect(
        ContractStatus.draft.canTransitionTo(ContractStatus.signed),
        isTrue,
      );
      expect(
        ContractStatus.draft.canTransitionTo(ContractStatus.archived),
        isTrue,
      );
    });

    test('подписанный договор можно вернуть в черновик или архивировать', () {
      expect(
        ContractStatus.signed.allowedTransitions,
        {ContractStatus.draft, ContractStatus.archived},
      );
    });

    test('из архива договор возвращается только в подписанные', () {
      expect(
        ContractStatus.archived.allowedTransitions,
        {ContractStatus.signed},
      );
      expect(
        ContractStatus.archived.canTransitionTo(ContractStatus.draft),
        isFalse,
      );
    });

    test('переход в тот же статус недопустим', () {
      for (final status in ContractStatus.values) {
        expect(status.canTransitionTo(status), isFalse);
      }
    });

    test('transitionTo возвращает новый статус или null', () {
      expect(
        ContractStatus.draft.transitionTo(ContractStatus.signed),
        ContractStatus.signed,
      );
      expect(
        ContractStatus.archived.transitionTo(ContractStatus.draft),
        isNull,
      );
    });
  });
}
