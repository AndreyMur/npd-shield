import 'package:flutter/material.dart';

import '../../data/models/contract_draft.dart';

/// Визуальные параметры статусов договора.
extension ContractStatusVisuals on ContractStatus {
  /// Человекочитаемое название статуса.
  String get label => switch (this) {
    ContractStatus.draft => 'Черновик',
    ContractStatus.signed => 'Подписан',
    ContractStatus.archived => 'Архив',
  };

  /// Цвет маркировки статуса.
  Color get color => switch (this) {
    ContractStatus.draft => const Color(0xFF607D8B),
    ContractStatus.signed => const Color(0xFF2E7D32),
    ContractStatus.archived => const Color(0xFF6D4C41),
  };

  /// Значок статуса.
  IconData get icon => switch (this) {
    ContractStatus.draft => Icons.edit_note,
    ContractStatus.signed => Icons.verified_outlined,
    ContractStatus.archived => Icons.inventory_2_outlined,
  };
}
