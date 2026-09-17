import 'package:flutter/material.dart';

import '../../core/theme/app_tokens.dart';
import '../../core/widgets/app_chip.dart';
import '../../data/models/invoice.dart';

/// Цвет и иконка, которыми статус счёта отображается в интерфейсе.
///
/// Единая точка правды: и список, и карточка счёта используют одни и те же
/// визуальные признаки, поэтому просроченный счёт всегда выделен одинаково.
class InvoiceStatusVisuals {
  /// Основной цвет статуса (для текста, иконки и рамки).
  final Color color;

  /// Иконка статуса.
  final IconData icon;

  const InvoiceStatusVisuals({required this.color, required this.icon});
}

/// Возвращает визуальные атрибуты статуса [status] в текущей теме.
InvoiceStatusVisuals invoiceStatusVisuals(
  BuildContext context,
  InvoiceStatus status,
) {
  final tokens = AppTokens.of(context);
  return switch (status) {
    InvoiceStatus.draft => InvoiceStatusVisuals(
      color: tokens.muted,
      icon: Icons.edit_note_outlined,
    ),
    InvoiceStatus.sent => InvoiceStatusVisuals(
      color: tokens.primary,
      icon: Icons.send_outlined,
    ),
    InvoiceStatus.paid => InvoiceStatusVisuals(
      color: tokens.success,
      icon: Icons.check_circle_outline,
    ),
    InvoiceStatus.overdue => InvoiceStatusVisuals(
      color: tokens.destructive,
      icon: Icons.warning_amber_rounded,
    ),
    InvoiceStatus.cancelled => InvoiceStatusVisuals(
      color: tokens.muted,
      icon: Icons.block_outlined,
    ),
  };
}

/// Компактная цветная метка статуса счёта.
class InvoiceStatusChip extends StatelessWidget {
  final InvoiceStatus status;

  const InvoiceStatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final visuals = invoiceStatusVisuals(context, status);
    return AppStatusChip(
      label: status.label,
      color: visuals.color,
      icon: visuals.icon,
    );
  }
}
