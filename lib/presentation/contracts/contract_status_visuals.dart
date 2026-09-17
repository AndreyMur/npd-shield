import 'package:flutter/material.dart';

import '../../core/theme/app_tokens.dart';
import '../../data/models/contract_draft.dart';

/// Визуальные параметры статусов договора.
extension ContractStatusVisuals on ContractStatus {
  /// Человекочитаемое название статуса.
  String get label => switch (this) {
    ContractStatus.draft => 'Черновик',
    ContractStatus.signed => 'Подписан',
    ContractStatus.archived => 'Архив',
  };

  /// Цвет маркировки статуса из семантических токенов темы.
  Color color(AppTokens tokens) => switch (this) {
    ContractStatus.draft => tokens.muted,
    ContractStatus.signed => tokens.success,
    ContractStatus.archived => tokens.primary,
  };

  /// Значок статуса.
  IconData get icon => switch (this) {
    ContractStatus.draft => Icons.edit_note,
    ContractStatus.signed => Icons.verified_outlined,
    ContractStatus.archived => Icons.inventory_2_outlined,
  };
}
