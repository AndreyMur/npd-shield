import 'package:npd_shield/data/models/invoice.dart';
import 'package:npd_shield/data/models/transaction.dart';
import 'package:npd_shield/data/repositories/invoice_repository.dart';

/// Фейковый репозиторий счетов для widget- и unit-тестов.
class FakeInvoiceRepository implements InvoiceRepository {
  final List<Invoice> invoices;
  int _nextId = 1;

  FakeInvoiceRepository([List<Invoice>? invoices]) : invoices = invoices ?? [] {
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
    final requested = amount ?? invoice.outstanding;
    invoice.paidAmount += requested > invoice.outstanding
        ? invoice.outstanding
        : requested;
    invoice.paidAt = paidAt ?? DateTime.now();
    if (invoice.isFullyPaid) invoice.status = InvoiceStatus.paid;
    await update(invoice);
    return invoice;
  }

  @override
  Future<void> clear() async => invoices.clear();
}
