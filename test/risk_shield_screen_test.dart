import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:npd_shield/data/files/text_file_picker.dart';
import 'package:npd_shield/data/models/risk_marker.dart';
import 'package:npd_shield/data/repositories/risk_report_repository.dart';
import 'package:npd_shield/domain/risk/risk_analyzer.dart';
import 'package:npd_shield/domain/risk/risk_file_limits.dart';
import 'package:npd_shield/presentation/risk/risk_shield_screen.dart';

RiskMarker marker({
  String code = 'labor',
  String pattern = r'трудовой\s+договор',
  RiskSeverity severity = RiskSeverity.critical,
}) {
  return RiskMarker(
    code: code,
    pattern: pattern,
    severity: severity,
    description: 'Договор назван трудовым.',
    example: 'Стороны заключают трудовой договор.',
    suggestion: 'Замените на договор ГПХ.',
  );
}

Future<void> pumpScreen(
  WidgetTester tester, {
  required TextFilePicker picker,
  RiskAnalyzerUseCase? analyzer,
  RiskReportRepository? reportRepository,
}) async {
  tester.view.physicalSize = const Size(900, 1600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      home: RiskShieldScreen(
        analyzer: analyzer ?? RiskAnalyzerUseCase([marker()]),
        filePicker: picker,
        reportRepository: reportRepository,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('пустое состояние предлагает загрузить договор', (tester) async {
    await pumpScreen(tester, picker: _FakeTextFilePicker());

    expect(find.byKey(const Key('risk_shield_screen')), findsOneWidget);
    expect(find.byKey(const Key('risk_pick_button')), findsOneWidget);
    expect(find.text('Загрузить договор'), findsOneWidget);
  });

  testWidgets('после загрузки показывает риски с уровнями', (tester) async {
    final picker = _FakeTextFilePicker(
      file: const PickedTextFile(
        name: 'dogovor.txt',
        content: 'Стороны заключают трудовой договор.',
      ),
    );

    await pumpScreen(tester, picker: picker);
    await tester.tap(find.byKey(const Key('risk_pick_button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('risk_file_name')), findsOneWidget);
    expect(find.text('dogovor.txt'), findsOneWidget);
    expect(find.text('Найдено рисков: 1'), findsOneWidget);
    expect(find.byKey(const Key('risk_result_list')), findsOneWidget);
    expect(find.text('Критический'), findsOneWidget);
    expect(find.textContaining('трудовой договор'), findsWidgets);
    expect(find.text('Замените на договор ГПХ.'), findsOneWidget);
  });

  testWidgets('при отсутствии рисков показывает безопасный результат', (
    tester,
  ) async {
    final picker = _FakeTextFilePicker(
      file: const PickedTextFile(
        name: 'safe.txt',
        content: 'Исполнитель оказывает услуги и передаёт результат по акту.',
      ),
    );

    await pumpScreen(tester, picker: picker);
    await tester.tap(find.byKey(const Key('risk_pick_button')));
    await tester.pumpAndSettle();

    expect(find.text('Риски не найдены'), findsOneWidget);
    expect(find.text('Опасных формулировок не найдено'), findsOneWidget);
  });

  testWidgets('файл больше 100 КБ показывает ошибку', (tester) async {
    final picker = _FakeTextFilePicker(
      error: const ContractFileTooLargeException(
        actualBytes: 200 * 1024,
        maxBytes: maxRiskContractFileBytes,
      ),
    );

    await pumpScreen(tester, picker: picker);
    await tester.tap(find.byKey(const Key('risk_pick_button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('risk_error')), findsOneWidget);
    expect(find.textContaining('больше 100 КБ'), findsOneWidget);
  });

  testWidgets('отмена выбора файла оставляет пустое состояние', (tester) async {
    final picker = _FakeTextFilePicker();

    await pumpScreen(tester, picker: picker);
    await tester.tap(find.byKey(const Key('risk_pick_button')));
    await tester.pumpAndSettle();

    expect(picker.calls, 1);
    expect(find.byKey(const Key('risk_pick_button')), findsOneWidget);
    expect(find.byKey(const Key('risk_result_list')), findsNothing);
  });

  testWidgets('сохраняет отчёт проверки в репозиторий', (tester) async {
    final picker = _FakeTextFilePicker(
      file: const PickedTextFile(
        name: 'dogovor.txt',
        content: 'Стороны заключают трудовой договор.',
      ),
    );
    final reports = _FakeRiskReportRepository();

    await pumpScreen(tester, picker: picker, reportRepository: reports);
    await tester.tap(find.byKey(const Key('risk_pick_button')));
    await tester.pumpAndSettle();

    expect(reports.saved, hasLength(1));
    expect(reports.saved.single.sourceName, 'dogovor.txt');
    expect(reports.saved.single.risks, hasLength(1));
  });

  testWidgets('позволяет проверить другой договор после результата', (
    tester,
  ) async {
    final picker = _FakeTextFilePicker(
      file: const PickedTextFile(
        name: 'dogovor.txt',
        content: 'Стороны заключают трудовой договор.',
      ),
    );

    await pumpScreen(tester, picker: picker);
    await tester.tap(find.byKey(const Key('risk_pick_button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('risk_pick_another_button')), findsOneWidget);
  });
}

class _FakeTextFilePicker implements TextFilePicker {
  PickedTextFile? file;
  Object? error;
  int calls = 0;

  _FakeTextFilePicker({this.file, this.error});

  @override
  Future<PickedTextFile?> pick() async {
    calls++;
    if (error != null) throw error!;
    return file;
  }
}

class _FakeRiskReportRepository implements RiskReportRepository {
  final List<RiskReport> saved = [];
  int _nextId = 1;

  @override
  Future<int> save(RiskReport report) async {
    report.id = _nextId++;
    saved.add(report);
    return report.id;
  }

  @override
  Future<RiskReport?> getById(int id) async {
    for (final report in saved) {
      if (report.id == id) return report;
    }
    return null;
  }

  @override
  Future<List<RiskReport>> getAll() async => List.of(saved);

  @override
  Future<void> delete(int id) async => saved.removeWhere((r) => r.id == id);

  @override
  Future<void> clear() async => saved.clear();
}
