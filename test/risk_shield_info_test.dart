import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:npd_shield/data/files/text_file_picker.dart';
import 'package:npd_shield/data/models/risk_marker.dart';
import 'package:npd_shield/domain/risk/risk_analyzer.dart';
import 'package:npd_shield/presentation/risk/risk_shield_info_sheet.dart';
import 'package:npd_shield/presentation/risk/risk_shield_screen.dart';

RiskMarker _marker() => RiskMarker(
  code: 'labor',
  pattern: r'трудовой\s+договор',
  severity: RiskSeverity.critical,
  description: 'Договор назван трудовым.',
  example: 'Стороны заключают трудовой договор.',
  suggestion: 'Замените на договор ГПХ.',
);

void main() {
  testWidgets('лист информации содержит дисклеймер и инструкцию конвертации', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: RiskShieldInfoSheet())),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('risk_info_sheet')), findsOneWidget);
    expect(find.byKey(const Key('risk_info_disclaimer')), findsOneWidget);
    expect(find.text(riskShieldDisclaimer), findsOneWidget);
    expect(find.textContaining('TXT'), findsWidgets);
    expect(find.textContaining('DOCX'), findsWidgets);
    expect(find.textContaining('PDF'), findsWidgets);
    expect(find.byKey(const Key('risk_info_step_0')), findsOneWidget);
    expect(
      find.byKey(Key('risk_info_step_${riskShieldConversionSteps.length - 1}')),
      findsOneWidget,
    );
  });

  testWidgets('пустое состояние показывает дисклеймер и открывает инструкцию', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 1800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: RiskShieldScreen(
          analyzer: RiskAnalyzerUseCase([_marker()]),
          filePicker: _FakeTextFilePicker(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('risk_empty_disclaimer')), findsOneWidget);
    expect(find.text(riskShieldDisclaimer), findsOneWidget);

    await tester.tap(find.byKey(const Key('risk_empty_info_button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('risk_info_sheet')), findsOneWidget);
  });

  testWidgets('кнопка информации доступна из AppBar', (tester) async {
    tester.view.physicalSize = const Size(900, 1800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: RiskShieldScreen(
          analyzer: RiskAnalyzerUseCase([_marker()]),
          filePicker: _FakeTextFilePicker(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('risk_info_button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('risk_info_sheet')), findsOneWidget);
    expect(
      find.textContaining('не заменяет юридическую консультацию'),
      findsWidgets,
    );
  });
}

class _FakeTextFilePicker implements TextFilePicker {
  @override
  Future<PickedTextFile?> pick() async => null;
}
