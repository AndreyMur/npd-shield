import 'package:flutter/material.dart';

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
  final scheme = Theme.of(context).colorScheme;
  return switch (status) {
    InvoiceStatus.draft => InvoiceStatusVisuals(
      color: scheme.outline,
      icon: Icons.edit_note_outlined,
    ),
    InvoiceStatus.sent => InvoiceStatusVisuals(
      color: scheme.primary,
      icon: Icons.send_outlined,
    ),
    InvoiceStatus.paid => const InvoiceStatusVisuals(
      color: Color(0xFF2E7D32),
      icon: Icons.check_circle_outline,
    ),
    InvoiceStatus.overdue => InvoiceStatusVisuals(
      color: scheme.error,
      icon: Icons.warning_amber_rounded,
    ),
    InvoiceStatus.cancelled => InvoiceStatusVisuals(
      color: scheme.outline,
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: visuals.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.label,
        style: Theme.of(context).textTheme.labelSmall!.copyWith(
          color: visuals.color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
