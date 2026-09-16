import 'package:npd_shield/data/models/invoice.dart';
import 'package:npd_shield/data/models/transaction.dart';
import 'package:npd_shield/data/repositories/invoice_repository.dart';
import 'package:npd_shield/data/repositories/transaction_repository.dart';

/// Фейковый репозиторий счетов для widget- и unit-тестов.
///
/// Если передан [transactionRepository], полная оплата создаёт доход-операцию
/// так же, как настоящий репозиторий, — это позволяет проверять интеграцию
/// отметки оплаты со списком доходов в виджет-тестах.
class FakeInvoiceRepository implements InvoiceRepository {
  final List<Invoice> invoices;
  final TransactionRepository? transactionRepository;
  int _nextId = 1;

  FakeInvoiceRepository([List<Invoice>? invoices, this.transactionRepository])
      : invoices = invoices ?? [] {
    for (final invoice in this.invoices) {
      if (invoice.id >= _nextId) _nextId = invoice.id + 1;
    }
  }

  @override
  Future<int> add(Invoice invoice) async {
    if (invoice.id <= 0) {
      invoice.id = _nextId++;
    } else if (invoice.id >= _nextId) {
      _nextId = invoice.id + 1;
    }
    invoices.add(invoice);
    return invoice.id;
  }

  @override
  Future<int> update(Invoice invoice) async {
    final index = invoices.indexWhere((i) => i.id == invoice.id);
    if (index >= 0) {
      invoices[index] = invoice;
    } else {
      invoices.add(invoice);
    }
    return invoice.id;
  }

  @override
  Future<Invoice?> getById(int id) async {
    for (final invoice in invoices) {
      if (invoice.id == id) return invoice;
    }
    return null;
  }

  @override
  Future<bool> delete(int id) async {
    final index = invoices.indexWhere((i) => i.id == id);
    if (index < 0) return false;
    invoices.removeAt(index);
    return true;
  }

  @override
  Future<int> count() async => invoices.length;

  @override
  Future<List<Invoice>> getAll() async {
    final result = List.of(invoices);
    result.sort((a, b) => b.issuedAt.compareTo(a.issuedAt));
    return result;
  }

  @override
  Future<List<Invoice>> getByClientId(int clientId) async {
    return invoices.where((i) => i.clientId == clientId).toList();
  }

  @override
  Future<List<Invoice>> getOverdue({DateTime? now}) async {
    final result = invoices.where((i) => i.isOverdue(now: now)).toList();
    result.sort((a, b) => a.dueDate.compareTo(b.dueDate));
    return result;
  }

  @override
  Future<double> getOutstandingTotal({DateTime? now}) async {
    double total = 0;
    for (final invoice in invoices) {
      if (invoice.status == InvoiceStatus.draft ||
          invoice.status == InvoiceStatus.cancelled) {
        continue;
      }
      total += invoice.outstanding;
    }
    return total;
  }

  @override
  Future<Invoice> markPaid(
    int id, {
    double? amount,
    DateTime? paidAt,
    TransactionSphere sphere = TransactionSphere.it,
    String category = '',
    String comment = '',
  }) async {
    final invoice = await getById(id);
    if (invoice == null) {
      throw StateError('Счёт $id не найден');
    }
    if (invoice.status == InvoiceStatus.cancelled) {
      throw StateError('Нельзя оплатить отменённый счёт');
    }
    if (invoice.isFullyPaid) return invoice;

    final requested = amount ?? invoice.outstanding;
    if (requested <= 0) {
      throw ArgumentError.value(
        amount,
        'amount',
        'Сумма оплаты должна быть больше нуля',
      );
    }

    invoice.paidAmount += requested > invoice.outstanding
        ? invoice.outstanding
        : requested;
    invoice.paidAt = paidAt ?? DateTime.now();
    if (invoice.isFullyPaid) {
      invoice.status = InvoiceStatus.paid;
      final transactions = transactionRepository;
      if (invoice.transactionId == 0 && transactions != null) {
        invoice.transactionId = await transactions.add(
          Transaction(
            amount: invoice.amount,
            date: invoice.paidAt ?? DateTime.now(),
            sphere: sphere,
            clientName: invoice.clientName,
            clientInn: invoice.clientInn,
            clientId: invoice.clientId == 0 ? null : invoice.clientId,
            category: category,
            comment: comment,
          ),
        );
      }
    }
    await update(invoice);
    return invoice;
  }

  @override
  Future<void> clear() async => invoices.clear();
}
