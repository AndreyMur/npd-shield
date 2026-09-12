import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  String description = 'Договор назван трудовым.',
  String suggestion = 'Замените на договор ГПХ.',
}) {
  return RiskMarker(
    code: code,
    pattern: pattern,
    severity: severity,
    description: description,
    example: 'Стороны заключают трудовой договор.',
    suggestion: suggestion,
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

Future<void> pumpAndAnalyze(
  WidgetTester tester, {
  required String name,
  required String content,
  RiskAnalyzerUseCase? analyzer,
  RiskReportRepository? reportRepository,
}) async {
  await pumpScreen(
    tester,
    picker: _FakeTextFilePicker(
      file: PickedTextFile(name: name, content: content),
    ),
    analyzer: analyzer,
    reportRepository: reportRepository,
  );
  await tester.tap(find.byKey(const Key('risk_pick_button')));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('пустое состояние предлагает загрузить договор', (tester) async {
    await pumpScreen(tester, picker: _FakeTextFilePicker());

    expect(find.byKey(const Key('risk_shield_screen')), findsOneWidget);
    expect(find.byKey(const Key('risk_pick_button')), findsOneWidget);
    expect(find.text('Загрузить договор'), findsOneWidget);
  });

  testWidgets('после загрузки показывает индекс и риски с уровнями', (
    tester,
  ) async {
    await pumpScreen(
      tester,
      picker: _FakeTextFilePicker(
        file: const PickedTextFile(
          name: 'dogovor.txt',
          content: 'Стороны заключают трудовой договор.',
        ),
      ),
    );
    await tester.tap(find.byKey(const Key('risk_pick_button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('risk_file_name')), findsOneWidget);
    expect(find.text('dogovor.txt'), findsOneWidget);
    expect(find.byKey(const Key('safety_index_gauge')), findsOneWidget);
    expect(find.text('0%'), findsOneWidget);
    expect(find.text('Высокий риск'), findsOneWidget);
    expect(find.text('Найдено рисков: 1'), findsOneWidget);
    expect(find.byKey(const Key('risk_result_list')), findsOneWidget);
    expect(find.text('Критический'), findsOneWidget);
  });

  testWidgets('при отсутствии рисков показывает безопасный результат', (
    tester,
  ) async {
    await pumpScreen(
      tester,
      picker: _FakeTextFilePicker(
        file: const PickedTextFile(
          name: 'safe.txt',
          content: 'Исполнитель оказывает услуги и передаёт результат по акту.',
        ),
      ),
    );
    await tester.tap(find.byKey(const Key('risk_pick_button')));
    await tester.pumpAndSettle();

    expect(find.text('100%'), findsOneWidget);
    expect(find.text('Высокая безопасность'), findsOneWidget);
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

  testWidgets('сохраняет отчёт проверки с индексом в репозиторий', (
    tester,
  ) async {
    final reports = _FakeRiskReportRepository();

    await pumpScreen(
      tester,
      picker: _FakeTextFilePicker(
        file: const PickedTextFile(
          name: 'dogovor.txt',
          content: 'Стороны заключают трудовой договор.',
        ),
      ),
      reportRepository: reports,
    );
    await tester.tap(find.byKey(const Key('risk_pick_button')));
    await tester.pumpAndSettle();

    expect(reports.saved, hasLength(1));
    expect(reports.saved.single.sourceName, 'dogovor.txt');
    expect(reports.saved.single.risks, hasLength(1));
    expect(reports.saved.single.safetyIndex, 0);
  });

  testWidgets('позволяет проверить другой договор после результата', (
    tester,
  ) async {
    await pumpScreen(
      tester,
      picker: _FakeTextFilePicker(
        file: const PickedTextFile(
          name: 'dogovor.txt',
          content: 'Стороны заключают трудовой договор.',
        ),
      ),
    );
    await tester.tap(find.byKey(const Key('risk_pick_button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('risk_pick_another_button')), findsOneWidget);
  });

  testWidgets('карточка риска раскрывает описание, место и альтернативу', (
    tester,
  ) async {
    await pumpAndAnalyze(
      tester,
      name: 'dogovor.txt',
      content: 'Стороны заключают трудовой договор.',
    );

    expect(find.text('Где найдено'), findsNothing);

    await tester.tap(find.byIcon(Icons.expand_more));
    await tester.pumpAndSettle();

    expect(find.text('Где найдено'), findsOneWidget);
    expect(find.text('Безопасная формулировка'), findsOneWidget);
    expect(find.text('Замените на договор ГПХ.'), findsOneWidget);
    expect(find.textContaining('трудовой договор'), findsOneWidget);
    expect(find.textContaining('позиция'), findsOneWidget);
  });

  testWidgets('фильтрует риски по уровню', (tester) async {
    final analyzer = RiskAnalyzerUseCase([
      marker(
        code: 'critical',
        pattern: r'трудовой\s+договор',
        severity: RiskSeverity.critical,
        description: 'Трудовой договор.',
      ),
      marker(
        code: 'medium',
        pattern: 'отпуск',
        severity: RiskSeverity.medium,
        description: 'Оплачиваемый отпуск.',
      ),
      marker(
        code: 'low',
        pattern: 'наличными',
        severity: RiskSeverity.low,
        description: 'Оплата наличными.',
      ),
    ]);

    await pumpAndAnalyze(
      tester,
      name: 'mixed.txt',
      content: 'Трудовой договор. Ежегодный отпуск. Оплата наличными.',
      analyzer: analyzer,
    );

    expect(find.text('Все (3)'), findsOneWidget);
    expect(find.text('Критические (1)'), findsOneWidget);
    expect(find.text('Средние (1)'), findsOneWidget);
    expect(find.text('Низкие (1)'), findsOneWidget);

    await tester.tap(find.text('Средние (1)'));
    await tester.pumpAndSettle();

    expect(find.text('Средний'), findsOneWidget);
    expect(find.text('Критический'), findsNothing);
    expect(find.text('Низкий'), findsNothing);

    await tester.tap(find.text('Все (3)'));
    await tester.pumpAndSettle();

    expect(find.text('Критический'), findsOneWidget);
    expect(find.text('Средний'), findsOneWidget);
    expect(find.text('Низкий'), findsOneWidget);
  });

  testWidgets('копирует безопасную формулировку в буфер обмена', (tester) async {
    final clipboardCalls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          clipboardCalls.add(call);
          return null;
        });
    addTearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null);
    });

    await pumpAndAnalyze(
      tester,
      name: 'dogovor.txt',
      content: 'Стороны заключают трудовой договор.',
    );

    await tester.tap(find.byIcon(Icons.expand_more));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Скопировать формулировку'));
    await tester.pumpAndSettle();

    final copy = clipboardCalls.singleWhere(
      (call) => call.method == 'Clipboard.setData',
    );
    expect((copy.arguments as Map)['text'], 'Замените на договор ГПХ.');
    expect(find.text('Безопасная формулировка скопирована'), findsOneWidget);
  });

  testWidgets('индекс и уровни доступны для скринридеров', (tester) async {
    final handle = tester.ensureSemantics();

    await pumpAndAnalyze(
      tester,
      name: 'dogovor.txt',
      content: 'Стороны заключают трудовой договор.',
    );

    final gauge = tester.getSemantics(
      find.byKey(const Key('safety_index_gauge')),
    );
    expect(gauge.label, contains('Индекс безопасности'));
    expect(gauge.label, contains('0 процентов'));
    expect(gauge.label, contains('Высокий риск'));

    expect(find.bySemanticsLabel(RegExp('Критический')), findsWidgets);

    handle.dispose();
  });

  testWidgets('кнопка истории открывает экран истории проверок', (tester) async {
    final reports = _FakeRiskReportRepository();

    await pumpScreen(
      tester,
      picker: _FakeTextFilePicker(
        file: const PickedTextFile(
          name: 'dogovor.txt',
          content: 'Стороны заключают трудовой договор.',
        ),
      ),
      reportRepository: reports,
    );
    await tester.tap(find.byKey(const Key('risk_pick_button')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('risk_history_button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('risk_history_screen')), findsOneWidget);
    expect(find.byKey(const Key('risk_history_list')), findsOneWidget);
    expect(find.text('dogovor.txt'), findsWidgets);
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
