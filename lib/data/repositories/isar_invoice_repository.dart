import 'package:isar/isar.dart';

import '../models/invoice.dart';
import '../models/transaction.dart';
import '../security/database_encryption_service.dart';
import '../security/field_encryption_service.dart';
import 'invoice_repository.dart';
import 'transaction_repository.dart';

/// Реализация хранилища счетов поверх Isar с шифрованием персональных данных.
///
/// Чувствительные строки (наименование и ИНН контрагента, комментарий)
/// шифруются на уровне поля алгоритмом AES-256 — как данные клиентов в
/// операциях и документах. Поэтому выборка и сортировка по этим полям
/// выполняются в памяти после расшифровки.
///
/// Отметка полной оплаты создаёт доход-операцию через переданный
/// [TransactionRepository], поэтому оплата счёта сразу учитывается в лимите
/// НПД и налоге.
class IsarInvoiceRepository implements InvoiceRepository {
  final Isar isar;
  final TransactionRepository transactionRepository;
  final FieldEncryptionService _encryptionService;

  IsarInvoiceRepository(
    this.isar,
    this.transactionRepository, {
    FieldEncryptionService? encryption,
  }) : _encryptionService = encryption ?? DatabaseEncryptionService();

  @override
  Future<int> add(Invoice invoice) {
    _assertManualStatus(invoice);
    return isar.writeTxn(() async {
      await _encryptFields(invoice);
      return isar.invoices.put(invoice);
    });
  }

  @override
  Future<int> update(Invoice invoice) {
    _assertManualStatus(invoice);
    return isar.writeTxn(() async {
      await _encryptFields(invoice);
      return isar.invoices.put(invoice);
    });
  }

  @override
  Future<Invoice?> getById(int id) async {
    final invoice = await isar.invoices.get(id);
    if (invoice != null) {
      await _decryptFields(invoice);
    }
    return invoice;
  }

  @override
  Future<bool> delete(int id) {
    return isar.writeTxn(() => isar.invoices.delete(id));
  }

  @override
  Future<int> count() {
    return isar.invoices.count();
  }

  @override
  Future<List<Invoice>> getAll() async {
    final invoices = await isar.invoices.where().sortByIssuedAtDesc().findAll();
    for (final invoice in invoices) {
      await _decryptFields(invoice);
    }
    return invoices;
  }

  @override
  Future<List<Invoice>> getByClientId(int clientId) async {
    final invoices = await isar.invoices
        .filter()
        .clientIdEqualTo(clientId)
        .sortByIssuedAtDesc()
        .findAll();
    for (final invoice in invoices) {
      await _decryptFields(invoice);
    }
    return invoices;
  }

  @override
  Future<List<Invoice>> getOverdue({DateTime? now}) async {
    final reference = now ?? DateTime.now();
    final invoices = await isar.invoices.where().findAll();
    final overdue = <Invoice>[];
    for (final invoice in invoices) {
      await _decryptFields(invoice);
      if (invoice.isOverdue(now: reference)) overdue.add(invoice);
    }
    overdue.sort((a, b) => a.dueDate.compareTo(b.dueDate));
    return overdue;
  }

  @override
  Future<double> getOutstandingTotal({DateTime? now}) async {
    final invoices = await getAll();
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
    if (invoice.isFullyPaid) {
      return invoice;
    }

    final requested = amount ?? invoice.outstanding;
    if (requested <= 0) {
      throw ArgumentError.value(
        amount,
        'amount',
        'Сумма оплаты должна быть больше нуля',
      );
    }

    final applied = requested > invoice.outstanding
        ? invoice.outstanding
        : requested;
    invoice.paidAmount += applied;
    invoice.paidAt = paidAt ?? DateTime.now();

    if (invoice.isFullyPaid) {
      invoice.status = InvoiceStatus.paid;
      if (invoice.transactionId == 0) {
        invoice.transactionId = await _createIncome(
          invoice,
          sphere: sphere,
          category: category,
          comment: comment,
        );
      }
    }

    await update(invoice);
    return (await getById(id))!;
  }

  @override
  Future<void> clear() {
    return isar.writeTxn(() => isar.invoices.clear());
  }

  /// Создаёт доход-операцию по полностью оплаченному счёту.
  Future<int> _createIncome(
    Invoice invoice, {
    required TransactionSphere sphere,
    required String category,
    required String comment,
  }) {
    final transaction = Transaction(
      amount: invoice.amount,
      date: invoice.paidAt ?? DateTime.now(),
      sphere: sphere,
      clientName: invoice.clientName,
      clientInn: invoice.clientInn,
      clientId: invoice.clientId == 0 ? null : invoice.clientId,
      category: category,
      comment: comment,
    );
    return transactionRepository.add(transaction);
  }

  /// Отклоняет ручную установку статуса «просрочен».
  void _assertManualStatus(Invoice invoice) {
    if (invoice.status == InvoiceStatus.overdue) {
      throw ArgumentError(
        'Статус «просрочен» определяется автоматически и не может быть '
        'установлен вручную',
      );
    }
  }

  Future<void> _encryptFields(Invoice invoice) async {
    invoice.clientName = await _encrypt(invoice.clientName);
    invoice.clientInn = await _encrypt(invoice.clientInn);
    invoice.comment = await _encrypt(invoice.comment);
  }

  Future<void> _decryptFields(Invoice invoice) async {
    invoice.clientName = await _decrypt(invoice.clientName);
    invoice.clientInn = await _decrypt(invoice.clientInn);
    invoice.comment = await _decrypt(invoice.comment);
  }

  Future<String> _encrypt(String value) async {
    if (value.isEmpty) return value;
    return _encryptionService.encrypt(value);
  }

  Future<String> _decrypt(String value) async {
    if (value.isEmpty) return value;
    try {
      return await _encryptionService.decrypt(value);
    } catch (_) {
      // Если расшифровка не удалась, оставляем значение как есть:
      // так читаются данные, сохранённые до включения шифрования.
      return value;
    }
  }
}
