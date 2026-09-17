import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:npd_shield/data/backup/backup_service.dart';
import 'package:npd_shield/data/files/backup_file_picker.dart';
import 'package:npd_shield/data/models/invoice.dart';
import 'package:npd_shield/data/models/transaction.dart';
import 'package:npd_shield/data/pdf/generated_pdf.dart';
import 'package:npd_shield/presentation/reports/reports_screen.dart';

import 'helpers/fake_backup_file_picker.dart';
import 'helpers/fake_backup_gateway.dart';
import 'helpers/fake_export_file_saver.dart';
import 'helpers/fake_invoice_repository.dart';
import 'helpers/fake_transaction_repository.dart';

void main() {
  final now = DateTime(2026, 9, 16);

  Transaction income({
    required double amount,
    required DateTime date,
    TransactionSphere sphere = TransactionSphere.it,
    String clientName = '',
    String clientInn = '',
  }) {
    return Transaction(
      amount: amount,
      date: date,
      sphere: sphere,
      clientName: clientName,
      clientInn: clientInn,
      type: TransactionType.income,
    );
  }

  Transaction expense({
    required double amount,
    required DateTime date,
    TransactionSphere sphere = TransactionSphere.it,
    String clientName = '',
    String clientInn = '',
  }) {
    return Transaction(
      amount: amount,
      date: date,
      sphere: sphere,
      clientName: clientName,
      clientInn: clientInn,
      type: TransactionType.expense,
    );
  }

  FakeTransactionRepository seededTransactions() {
    return FakeTransactionRepository([
      income(
        amount: 1000000,
        date: DateTime(2026, 9, 10),
        clientName: 'ООО «Альфа»',
        clientInn: '7701234567',
      ),
      expense(
        amount: 200000,
        date: DateTime(2026, 9, 12),
        clientName: 'ООО «Альфа»',
        clientInn: '7701234567',
      ),
      income(
        amount: 500000,
        date: DateTime(2026, 9, 15),
        sphere: TransactionSphere.logistics,
        clientName: 'ООО «Бета»',
        clientInn: '7709876543',
      ),
      income(
        amount: 100000,
        date: DateTime(2026, 1, 5),
        clientName: 'ООО «Гамма»',
      ),
    ]);
  }

  Future<void> pumpReports(
    WidgetTester tester, {
    FakeTransactionRepository? transactions,
    FakeInvoiceRepository? invoices,
    FakeBackupGateway? gateway,
    FakeExportFileSaver? fileSaver,
    FakeBackupFilePicker? picker,
    ReportPdfBuilder? pdfBuilder,
  }) async {
    tester.view.physicalSize = const Size(1200, 3600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: ReportsScreen(
          transactionRepository: transactions ?? FakeTransactionRepository(),
          invoiceRepository: invoices ?? FakeInvoiceRepository(),
          backupGateway: gateway ?? FakeBackupGateway(),
          fileSaver: fileSaver ?? FakeExportFileSaver(),
          backupFilePicker: picker ?? FakeBackupFilePicker(),
          now: now,
          pdfBuilder: pdfBuilder,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  String valueOf(WidgetTester tester, String key) {
    return tester.widget<Text>(find.byKey(Key(key))).data!;
  }

  testWidgets('строит отчёт за период: итоги, сферы и клиенты', (tester) async {
    await pumpReports(tester, transactions: seededTransactions());

    expect(find.byKey(const Key('report_summary')), findsOneWidget);
    expect(valueOf(tester, 'report_income'), '1 500 000,00 ₽');
    expect(valueOf(tester, 'report_expense'), '200 000,00 ₽');
    expect(valueOf(tester, 'report_profit'), '1 300 000,00 ₽');
    // Налог 6% с вычетом взносов: 90 000 − 49 500 = 40 500.
    expect(valueOf(tester, 'report_tax'), '40 500,00 ₽');

    expect(find.byKey(const Key('report_sphere_chart')), findsOneWidget);
    expect(find.byKey(const Key('report_sphere_row_0')), findsOneWidget);
    expect(find.text('IT'), findsWidgets);
    expect(find.text('Логистика'), findsWidgets);
    expect(find.text('ООО «Альфа»'), findsWidgets);
    expect(find.text('ООО «Бета»'), findsOneWidget);
  });

  testWidgets('переключение периода меняет отчёт', (tester) async {
    await pumpReports(tester, transactions: seededTransactions());

    // За сентябрь январьская операция не входит.
    expect(valueOf(tester, 'report_income'), '1 500 000,00 ₽');

    await tester.tap(find.byKey(const Key('report_period_year')));
    await tester.pumpAndSettle();

    expect(valueOf(tester, 'report_income'), '1 600 000,00 ₽');
    expect(
      valueOf(tester, 'report_period_label'),
      '01.01.2026 — 31.12.2026',
    );
  });

  testWidgets('пустой отчёт показывает пустые состояния', (tester) async {
    await pumpReports(tester);

    expect(valueOf(tester, 'report_income'), '0,00 ₽');
    expect(
      find.byKey(const Key('report_sphere_chart_empty')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('report_breakdown_sphere_empty')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('report_breakdown_client_empty')),
      findsOneWidget,
    );
  });

  testWidgets('выгружает операции в CSV и сохраняет файл', (tester) async {
    final saver = FakeExportFileSaver();
    await pumpReports(
      tester,
      transactions: seededTransactions(),
      fileSaver: saver,
    );

    await tester.tap(find.byKey(const Key('reports_export_operations_csv')));
    await tester.pumpAndSettle();

    expect(saver.saved, hasLength(1));
    expect(saver.saved.single.fileName, startsWith('operations_'));
    final content = utf8.decode(saver.saved.single.bytes);
    expect(content, contains('ООО «Альфа»'));
    expect(content, isNot(contains('ООО «Гамма»')));
    expect(find.textContaining('Выгружено операций'), findsOneWidget);
  });

  testWidgets('выгружает счета в CSV', (tester) async {
    final saver = FakeExportFileSaver();
    final invoices = FakeInvoiceRepository([
      Invoice(
        number: '14/09',
        amount: 50000,
        issuedAt: DateTime(2026, 9, 1),
        dueDate: DateTime(2026, 9, 30),
        clientName: 'ООО «Альфа»',
        status: InvoiceStatus.sent,
      ),
    ]);
    await pumpReports(tester, invoices: invoices, fileSaver: saver);

    await tester.tap(find.byKey(const Key('reports_export_invoices_csv')));
    await tester.pumpAndSettle();

    expect(saver.saved, hasLength(1));
    expect(saver.saved.single.fileName, startsWith('invoices_'));
    expect(
      utf8.decode(saver.saved.single.bytes),
      contains('14/09'),
    );
  });

  testWidgets('сохраняет PDF-отчёт на устройство', (tester) async {
    final saver = FakeExportFileSaver();
    final bytes = Uint8List.fromList([0x25, 0x50, 0x44, 0x46]);
    await pumpReports(
      tester,
      transactions: seededTransactions(),
      fileSaver: saver,
      pdfBuilder: (report) async => GeneratedPdf(
        bytes: bytes,
        pageCount: 1,
        fileName: 'report_2026-09-01_2026-09-30.pdf',
        generationTime: Duration.zero,
      ),
    );

    await tester.tap(find.byKey(const Key('reports_export_pdf')));
    await tester.pumpAndSettle();

    expect(saver.saved, hasLength(1));
    expect(saver.saved.single.fileName, 'report_2026-09-01_2026-09-30.pdf');
    expect(saver.saved.single.bytes, bytes);
    expect(find.textContaining('PDF-отчёт сохранён'), findsOneWidget);
  });

  testWidgets('создаёт резервную копию и сохраняет её', (tester) async {
    final gateway = FakeBackupGateway();
    final saver = FakeExportFileSaver();
    await pumpReports(tester, gateway: gateway, fileSaver: saver);

    await tester.tap(find.byKey(const Key('reports_export_backup')));
    await tester.pumpAndSettle();

    expect(gateway.exportCalls, 1);
    expect(saver.saved, hasLength(1));
    expect(saver.saved.single.fileName, endsWith('.json'));
    expect(find.textContaining('Резервная копия создана'), findsOneWidget);
  });

  testWidgets('импорт копии требует подтверждения и восстанавливает данные', (
    tester,
  ) async {
    final gateway = FakeBackupGateway();
    final picker = FakeBackupFilePicker(
      PickedBinaryFile(
        name: 'backup.json',
        bytes: Uint8List.fromList([0x7B, 0x7D]),
      ),
    );
    await pumpReports(tester, gateway: gateway, picker: picker);

    await tester.tap(find.byKey(const Key('reports_import_backup')));
    await tester.pumpAndSettle();

    expect(find.text('Восстановить данные из копии?'), findsOneWidget);
    expect(find.textContaining('заменит все текущие данные'), findsOneWidget);
    expect(gateway.imported, isEmpty);

    await tester.tap(find.byKey(const Key('backup_import_confirm')));
    await tester.pumpAndSettle();

    expect(gateway.imported, hasLength(1));
    expect(find.textContaining('Данные восстановлены'), findsOneWidget);
  });

  testWidgets('отмена подтверждения не восстанавливает данные', (tester) async {
    final gateway = FakeBackupGateway();
    final picker = FakeBackupFilePicker(
      PickedBinaryFile(
        name: 'backup.json',
        bytes: Uint8List.fromList([0x7B, 0x7D]),
      ),
    );
    await pumpReports(tester, gateway: gateway, picker: picker);

    await tester.tap(find.byKey(const Key('reports_import_backup')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('backup_import_cancel')));
    await tester.pumpAndSettle();

    expect(gateway.imported, isEmpty);
    expect(find.text('Восстановить данные из копии?'), findsNothing);
  });

  testWidgets('повреждённая копия показывает ошибку', (tester) async {
    final gateway = FakeBackupGateway(
      importError: const BackupFormatException('Файл повреждён.'),
    );
    final picker = FakeBackupFilePicker(
      PickedBinaryFile(name: 'broken.json', bytes: Uint8List.fromList([1])),
    );
    await pumpReports(tester, gateway: gateway, picker: picker);

    await tester.tap(find.byKey(const Key('reports_import_backup')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('backup_import_confirm')));
    await tester.pumpAndSettle();

    expect(find.text('Файл повреждён.'), findsOneWidget);
  });
}
