import 'package:flutter/material.dart';

import '../../data/models/invoice.dart';
import '../../data/models/transaction.dart';
import '../../domain/documents/receipt.dart';

/// Параметры платежа по счёту, выбранные пользователем в диалоге оплаты.
class InvoicePaymentRequest {
  /// Сумма платежа (может быть частичной).
  final double amount;

  /// Сфера деятельности создаваемого дохода.
  final TransactionSphere sphere;

  const InvoicePaymentRequest({required this.amount, required this.sphere});
}

/// Открывает диалог отметки оплаты счёта.
///
/// Сумма по умолчанию — весь остаток к оплате; её можно уменьшить для частичной
/// оплаты. Возвращает параметры платежа или `null`, если пользователь отменил.
Future<InvoicePaymentRequest?> showInvoicePaymentDialog(
  BuildContext context, {
  required Invoice invoice,
}) {
  return showDialog<InvoicePaymentRequest>(
    context: context,
    builder: (_) => _InvoicePaymentDialog(invoice: invoice),
  );
}

class _InvoicePaymentDialog extends StatefulWidget {
  final Invoice invoice;

  const _InvoicePaymentDialog({required this.invoice});

  @override
  State<_InvoicePaymentDialog> createState() => _InvoicePaymentDialogState();
}

class _InvoicePaymentDialogState extends State<_InvoicePaymentDialog> {
  late final TextEditingController _amountController;
  TransactionSphere _sphere = TransactionSphere.it;
  String? _error;

  double get _outstanding => widget.invoice.outstanding;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: _outstanding.toStringAsFixed(2).replaceAll('.', ','),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _confirm() {
    final amount = parseReceiptAmount(_amountController.text);
    if (amount <= 0) {
      setState(() => _error = 'Укажите сумму больше нуля');
      return;
    }
    if (amount > _outstanding) {
      setState(() => _error = 'Сумма больше остатка к оплате');
      return;
    }
    Navigator.of(context).pop(
      InvoicePaymentRequest(amount: amount, sphere: _sphere),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final partial = parseReceiptAmount(_amountController.text) < _outstanding;
    return AlertDialog(
      title: const Text('Оплата счёта'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Остаток к оплате: ${formatReceiptAmount(_outstanding)}',
            key: const Key('invoice_payment_outstanding'),
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          TextField(
            key: const Key('invoice_payment_amount_field'),
            controller: _amountController,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (_) => setState(() => _error = null),
            decoration: InputDecoration(
              labelText: 'Сумма платежа, ₽',
              border: const OutlineInputBorder(),
              errorText: _error,
            ),
          ),
          if (partial) ...[
            const SizedBox(height: 8),
            Text(
              'Частичная оплата: остаток уменьшится',
              key: const Key('invoice_payment_partial_hint'),
              style: theme.textTheme.bodySmall!.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: 16),
          Text('Сфера дохода', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          SegmentedButton<TransactionSphere>(
            key: const Key('invoice_payment_sphere_selector'),
            segments: [
              for (final sphere in TransactionSphere.values)
                ButtonSegment(value: sphere, label: Text(sphere.label)),
            ],
            selected: {_sphere},
            onSelectionChanged: (selection) =>
                setState(() => _sphere = selection.first),
          ),
        ],
      ),
      actions: [
        TextButton(
          key: const Key('invoice_payment_cancel'),
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Отмена'),
        ),
        FilledButton(
          key: const Key('invoice_payment_confirm'),
          onPressed: _confirm,
          child: const Text('Отметить оплату'),
        ),
      ],
    );
  }
}
