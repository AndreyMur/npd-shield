import 'package:flutter/material.dart';

import '../../core/constants/contract_field_keys.dart';
import '../../data/models/invoice.dart';
import '../../data/repositories/client_repository.dart';
import '../../data/repositories/invoice_repository.dart';
import '../../domain/documents/receipt.dart';
import 'invoice_form_screen.dart';
import 'invoice_payment_dialog.dart';
import 'invoice_status_visuals.dart';

/// Действия над счётом из списка.
enum _InvoiceAction { markPaid, delete }

/// Экран счетов: список, суммарная дебиторская задолженность, выделение
/// просроченных счетов, создание, редактирование, удаление с подтверждением
/// и отметка оплаты (в том числе частичной).
///
/// Просроченные счета выделяются цветом и статусом автоматически по сроку
/// оплаты. Отметка оплаты создаёт доход-операцию через репозиторий.
class InvoicesScreen extends StatefulWidget {
  final InvoiceRepository repository;

  /// Справочник клиентов. Если задан — клиента можно выбрать из него.
  final ClientRepository? clientRepository;

  /// «Сейчас» для стабильности тестов.
  final DateTime? now;

  const InvoicesScreen({
    super.key,
    required this.repository,
    this.clientRepository,
    this.now,
  });

  @override
  State<InvoicesScreen> createState() => _InvoicesScreenState();
}

class _InvoicesScreenState extends State<InvoicesScreen> {
  List<Invoice> _invoices = [];
  double _outstandingTotal = 0;
  bool _loading = true;
  Object? _error;

  DateTime get _now => widget.now ?? DateTime.now();

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final invoices = await widget.repository.getAll();
      final total = await widget.repository.getOutstandingTotal(now: _now);
      if (!mounted) return;
      setState(() {
        _invoices = invoices;
        _outstandingTotal = total;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error;
        _loading = false;
      });
    }
  }

  /// Сумма и количество просроченных счетов на текущую дату.
  ({double amount, int count}) get _overdue {
    double amount = 0;
    int count = 0;
    for (final invoice in _invoices) {
      if (invoice.effectiveStatus(now: _now) != InvoiceStatus.overdue) continue;
      amount += invoice.outstanding;
      count++;
    }
    return (amount: amount, count: count);
  }

  Future<void> _openForm({Invoice? invoice}) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => InvoiceFormScreen(
          repository: widget.repository,
          clientRepository: widget.clientRepository,
          invoice: invoice,
          now: widget.now,
        ),
      ),
    );
    if (changed == true) await _reload();
  }

  Future<void> _markPaid(Invoice invoice) async {
    final request = await showInvoicePaymentDialog(context, invoice: invoice);
    if (request == null || !mounted) return;

    final Invoice updated;
    try {
      updated = await widget.repository.markPaid(
        invoice.id,
        amount: request.amount,
        paidAt: _now,
        sphere: request.sphere,
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Не удалось отметить оплату')),
        );
      return;
    }
    await _reload();
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            updated.isFullyPaid ? 'Счёт оплачен' : 'Платёж учтён',
          ),
        ),
      );
  }

  Future<void> _delete(Invoice invoice) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Удалить счёт?'),
        content: Text(
          'Счёт № ${invoice.number} будет удалён. '
          'Созданный при оплате доход сохранится. '
          'Действие можно отменить сразу после удаления.',
        ),
        actions: [
          TextButton(
            key: const Key('invoice_delete_cancel'),
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            key: const Key('invoice_delete_confirm'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final deleted = await widget.repository.delete(invoice.id);
    if (!deleted || !mounted) return;
    await _reload();
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: const Text('Счёт удалён'),
          action: SnackBarAction(
            label: 'Отменить',
            onPressed: () => _undoDelete(invoice),
          ),
        ),
      );
  }

  Future<void> _undoDelete(Invoice invoice) async {
    await widget.repository.add(invoice);
    await _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Счета')),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('invoices_add_button'),
        onPressed: () => _openForm(),
        icon: const Icon(Icons.receipt_long_outlined),
        label: const Text('Счёт'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: _buildSummary(),
          ),
          Expanded(child: _buildList()),
        ],
      ),
    );
  }

  Widget _buildSummary() {
    final theme = Theme.of(context);
    final overdue = _overdue;
    return Card(
      key: const Key('invoices_summary'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Дебиторская задолженность',
              style: theme.textTheme.bodyMedium!.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              formatReceiptAmount(_outstandingTotal),
              key: const Key('invoices_outstanding_total'),
              style: theme.textTheme.headlineSmall!.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            if (overdue.count > 0) ...[
              const SizedBox(height: 8),
              Row(
                key: const Key('invoices_overdue_summary'),
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    size: 18,
                    color: theme.colorScheme.error,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Просрочено ${overdue.count} · '
                      '${formatReceiptAmount(overdue.amount)}',
                      style: theme.textTheme.bodyMedium!.copyWith(
                        color: theme.colorScheme.error,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildList() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Не удалось загрузить счета'),
            const SizedBox(height: 12),
            OutlinedButton(
              key: const Key('invoices_retry'),
              onPressed: _reload,
              child: const Text('Повторить'),
            ),
          ],
        ),
      );
    }
    if (_invoices.isEmpty) {
      return const Center(
        child: Text(
          'Счетов пока нет',
          key: Key('invoices_empty'),
        ),
      );
    }
    return ListView.builder(
      key: const Key('invoices_list'),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 88),
      itemCount: _invoices.length,
      itemBuilder: (context, index) => _buildTile(_invoices[index]),
    );
  }

  Widget _buildTile(Invoice invoice) {
    final theme = Theme.of(context);
    final status = invoice.effectiveStatus(now: _now);
    final visuals = invoiceStatusVisuals(context, status);
    final overdue = status == InvoiceStatus.overdue;
    final client = invoice.clientName.trim();
    final canPay = !invoice.isFullyPaid &&
        status != InvoiceStatus.cancelled;

    final subtitleParts = <String>[
      'Выставлен ${formatContractDate(invoice.issuedAt)}',
      'до ${formatContractDate(invoice.dueDate)}',
    ];
    if (invoice.paidAmount > 0 && !invoice.isFullyPaid) {
      subtitleParts.add('Оплачено ${formatReceiptAmount(invoice.paidAmount)}');
    }

    return Card(
      key: Key('invoice_entry_${invoice.id}'),
      margin: const EdgeInsets.only(bottom: 8),
      color: overdue
          ? theme.colorScheme.errorContainer.withValues(alpha: 0.3)
          : null,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _openForm(invoice: invoice),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 4, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: visuals.color.withValues(alpha: 0.12),
                child: Icon(visuals.icon, color: visuals.color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Счёт № ${invoice.number}',
                            style: theme.textTheme.titleMedium,
                          ),
                        ),
                        InvoiceStatusChip(
                          key: Key('invoice_status_${invoice.id}'),
                          status: status,
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      client.isEmpty ? 'Без клиента' : client,
                      style: theme.textTheme.bodyMedium,
                    ),
                    Text(
                      subtitleParts.join(' · '),
                      style: theme.textTheme.bodySmall!.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    formatReceiptAmount(invoice.amount),
                    key: Key('invoice_amount_${invoice.id}'),
                    style: theme.textTheme.titleMedium!.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  PopupMenuButton<_InvoiceAction>(
                    key: Key('invoice_menu_${invoice.id}'),
                    tooltip: 'Действия',
                    onSelected: (action) {
                      switch (action) {
                        case _InvoiceAction.markPaid:
                          _markPaid(invoice);
                        case _InvoiceAction.delete:
                          _delete(invoice);
                      }
                    },
                    itemBuilder: (context) => [
                      if (canPay)
                        PopupMenuItem(
                          key: Key('invoice_mark_paid_${invoice.id}'),
                          value: _InvoiceAction.markPaid,
                          child: const Text('Отметить оплаченным'),
                        ),
                      PopupMenuItem(
                        key: Key('invoice_delete_${invoice.id}'),
                        value: _InvoiceAction.delete,
                        child: const Text('Удалить'),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
