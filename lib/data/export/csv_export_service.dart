import 'dart:convert';
import 'dart:typed_data';

import '../../domain/reports/report_format.dart';
import '../models/invoice.dart';
import '../models/transaction.dart';

/// Готовый CSV-файл: содержимое, предлагаемое имя и число строк данных.
class CsvExport {
  /// Предлагаемое имя файла с расширением `.csv`.
  final String fileName;

  /// Текст CSV без BOM.
  final String content;

  /// Число строк данных (без строки заголовка).
  final int rowCount;

  const CsvExport({
    required this.fileName,
    required this.content,
    required this.rowCount,
  });

  /// Байты файла в UTF-8 с BOM — Excel корректно распознаёт кириллицу.
  Uint8List get bytes {
    final encoded = utf8.encode(content);
    return Uint8List.fromList([0xEF, 0xBB, 0xBF, ...encoded]);
  }
}

/// Формирует CSV-выгрузки операций и счетов.
///
/// Файлы ориентированы на русскую версию Excel: разделитель полей — точка с
/// запятой, десятичный разделитель — запятая, кодировка UTF-8 с BOM. Поля,
/// содержащие разделитель, кавычки или перевод строки, экранируются.
class CsvExportService {
  const CsvExportService();

  static const String _delimiter = ';';
  static const String _lineEnding = '\r\n';

  /// Заголовок выгрузки операций.
  static const List<String> transactionColumns = [
    'Дата',
    'Тип',
    'Сфера',
    'Сумма',
    'Клиент',
    'ИНН',
    'Категория',
    'Комментарий',
  ];

  /// Заголовок выгрузки счетов.
  static const List<String> invoiceColumns = [
    'Номер',
    'Дата выставления',
    'Срок оплаты',
    'Статус',
    'Сумма',
    'Оплачено',
    'Остаток',
    'Клиент',
    'ИНН',
    'Комментарий',
  ];

  /// Выгружает операции за период `[from, to]` включительно.
  CsvExport exportTransactions(
    List<Transaction> transactions, {
    required DateTime from,
    required DateTime to,
  }) {
    final sorted = List<Transaction>.of(transactions)
      ..sort((a, b) {
        final byDate = a.date.compareTo(b.date);
        if (byDate != 0) return byDate;
        return a.id.compareTo(b.id);
      });
    return CsvExport(
      fileName: _fileName('operations', from, to),
      content: buildTransactionsCsv(sorted),
      rowCount: sorted.length,
    );
  }

  /// Выгружает счета за период выставления `[from, to]` включительно.
  ///
  /// Статус счёта вычисляется на дату [now] (по умолчанию — текущую), поэтому
  /// просроченные счета попадают в файл именно как «Просрочен».
  CsvExport exportInvoices(
    List<Invoice> invoices, {
    required DateTime from,
    required DateTime to,
    DateTime? now,
  }) {
    final reference = now ?? DateTime.now();
    final start = DateTime(from.year, from.month, from.day);
    final endInclusive = DateTime(to.year, to.month, to.day);
    final sorted = invoices
        .where((invoice) {
          final issued = DateTime(
            invoice.issuedAt.year,
            invoice.issuedAt.month,
            invoice.issuedAt.day,
          );
          return !issued.isBefore(start) && !issued.isAfter(endInclusive);
        })
        .toList()
      ..sort((a, b) {
        final byDate = a.issuedAt.compareTo(b.issuedAt);
        if (byDate != 0) return byDate;
        return a.id.compareTo(b.id);
      });
    return CsvExport(
      fileName: _fileName('invoices', from, to),
      content: buildInvoicesCsv(sorted, now: reference),
      rowCount: sorted.length,
    );
  }

  /// Строит текст CSV с операциями (без BOM).
  String buildTransactionsCsv(List<Transaction> transactions) {
    final buffer = StringBuffer()
      ..write(transactionColumns.map(_escape).join(_delimiter))
      ..write(_lineEnding);
    for (final transaction in transactions) {
      buffer
        ..write(
          [
            formatReportDate(transaction.date),
            transaction.type.label,
            transaction.sphere.label,
            formatReportAmount(transaction.amount),
            transaction.clientName,
            transaction.clientInn,
            transaction.category,
            transaction.comment,
          ].map(_escape).join(_delimiter),
        )
        ..write(_lineEnding);
    }
    return buffer.toString();
  }

  /// Строит текст CSV со счетами (без BOM).
  String buildInvoicesCsv(List<Invoice> invoices, {DateTime? now}) {
    final reference = now ?? DateTime.now();
    final buffer = StringBuffer()
      ..write(invoiceColumns.map(_escape).join(_delimiter))
      ..write(_lineEnding);
    for (final invoice in invoices) {
      buffer
        ..write(
          [
            invoice.number,
            formatReportDate(invoice.issuedAt),
            formatReportDate(invoice.dueDate),
            invoice.effectiveStatus(now: reference).label,
            formatReportAmount(invoice.amount),
            formatReportAmount(invoice.paidAmount),
            formatReportAmount(invoice.outstanding),
            invoice.clientName,
            invoice.clientInn,
            invoice.comment,
          ].map(_escape).join(_delimiter),
        )
        ..write(_lineEnding);
    }
    return buffer.toString();
  }

  /// Экранирует поле по правилам RFC 4180.
  static String _escape(String value) {
    final needsQuotes =
        value.contains(_delimiter) ||
        value.contains('"') ||
        value.contains('\n') ||
        value.contains('\r');
    if (!needsQuotes) return value;
    return '"${value.replaceAll('"', '""')}"';
  }

  static String _fileName(String prefix, DateTime from, DateTime to) {
    return '${prefix}_${_fileDate(from)}_${_fileDate(to)}.csv';
  }

  static String _fileDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }
}
