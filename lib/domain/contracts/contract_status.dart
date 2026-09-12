import '../../data/models/contract_draft.dart';

/// Логика жизненного цикла договора: Черновик → Подписан → Архив.
///
/// Переходы между статусами валидируются, чтобы UI не мог перевести
/// договор в некорректное состояние.
extension ContractStatusTransitions on ContractStatus {
  /// Допустимые статусы, в которые можно перевести договор.
  Set<ContractStatus> get allowedTransitions => switch (this) {
    ContractStatus.draft => const {
      ContractStatus.signed,
      ContractStatus.archived,
    },
    ContractStatus.signed => const {
      ContractStatus.draft,
      ContractStatus.archived,
    },
    ContractStatus.archived => const {ContractStatus.signed},
  };

  /// Можно ли перевести договор из текущего статуса в [target].
  bool canTransitionTo(ContractStatus target) =>
      target != this && allowedTransitions.contains(target);

  /// Переводит статус в [target] или возвращает `null`, если переход
  /// недопустим.
  ContractStatus? transitionTo(ContractStatus target) =>
      canTransitionTo(target) ? target : null;
}
