import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:npd_shield/data/pdf/contract_pdf_service.dart';
import 'package:npd_shield/data/pdf/contract_pdf_share_service.dart';
import 'package:npd_shield/presentation/contracts/contract_pdf_preview_sheet.dart';

void main() {
  _FakeShareService? shareService;
  ContractPdfPreviewResult? result;

  GeneratedContractPdf fakePdf() {
    return GeneratedContractPdf(
      bytes: Uint8List.fromList(List.filled(2048, 1)),
      pageCount: 3,
      fileName: 'contract_1.pdf',
      generationTime: const Duration(milliseconds: 5),
    );
  }

  Future<void> pumpSheet(WidgetTester tester, {bool failShare = false}) async {
    shareService = _FakeShareService(failShare: failShare);
    result = null;

    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: _SheetHost(
          onOpen: (context) async {
            result = await showContractPdfPreviewSheet(
              context,
              pdf: fakePdf(),
              shareService: shareService!,
              previewBuilder: () => Container(
                key: const Key('fake_pdf_preview'),
                color: Colors.white,
                child: const Center(child: Text('PDF рендер')),
              ),
            );
          },
        ),
      ),
    );
    await tester.tap(find.byKey(const Key('open_sheet')));
    await tester.pumpAndSettle();
  }

  testWidgets('показывает предпросмотр, метаданные и кнопки действий', (
    tester,
  ) async {
    await pumpSheet(tester);

    expect(find.byKey(const Key('pdf_preview_sheet')), findsOneWidget);
    expect(find.text('Предпросмотр PDF'), findsOneWidget);
    expect(find.byKey(const Key('fake_pdf_preview')), findsOneWidget);
    expect(find.textContaining('contract_1.pdf · 3 стр. · 2.0 КБ'), findsOneWidget);
    expect(find.byKey(const Key('pdf_share_button')), findsOneWidget);
    expect(find.byKey(const Key('pdf_save_button')), findsOneWidget);
  });

  testWidgets('шаринг через стандартные приложения возвращает результат', (
    tester,
  ) async {
    await pumpSheet(tester);

    await tester.tap(find.byKey(const Key('pdf_share_button')));
    await tester.pumpAndSettle();

    expect(shareService!.shared, 1);
    expect(result, ContractPdfPreviewResult.shared);
  });

  testWidgets('сохранение PDF возвращает результат saved', (tester) async {
    await pumpSheet(tester);

    await tester.tap(find.byKey(const Key('pdf_save_button')));
    await tester.pumpAndSettle();

    expect(shareService!.saved, 1);
    expect(result, ContractPdfPreviewResult.saved);
  });

  testWidgets('показывает ошибку, если шаринг недоступен', (tester) async {
    await pumpSheet(tester, failShare: true);

    await tester.tap(find.byKey(const Key('pdf_share_button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('pdf_action_error')), findsOneWidget);
    expect(result, isNull);
    expect(shareService!.shared, 0);
  });

  testWidgets('закрытие листа без действий возвращает dismissed', (
    tester,
  ) async {
    await pumpSheet(tester);

    await tester.tapAt(const Offset(20, 20));
    await tester.pumpAndSettle();

    expect(result, ContractPdfPreviewResult.dismissed);
  });
}

class _SheetHost extends StatelessWidget {
  final Future<void> Function(BuildContext context) onOpen;

  const _SheetHost({required this.onOpen});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          key: const Key('open_sheet'),
          onPressed: () => onOpen(context),
          child: const Text('Открыть лист'),
        ),
      ),
    );
  }
}

class _FakeShareService implements ContractPdfShareService {
  final bool failShare;
  int shared = 0;
  int saved = 0;

  _FakeShareService({this.failShare = false});

  @override
  Future<void> share(GeneratedContractPdf pdf) async {
    if (failShare) {
      throw const ContractPdfActionException('Не удалось открыть меню «Поделиться».');
    }
    shared++;
  }

  @override
  Future<String> saveToDocuments(GeneratedContractPdf pdf) async {
    saved++;
    return 'path/${pdf.fileName}';
  }
}
