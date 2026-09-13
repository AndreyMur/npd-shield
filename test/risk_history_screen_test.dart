import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:npd_shield/data/models/risk_marker.dart';
import 'package:npd_shield/data/repositories/risk_report_repository.dart';
import 'package:npd_shield/presentation/risk/risk_history_screen.dart';

RiskMatch match({
  String markerCode = 'labor_contract_term',
  RiskSeverity severity = RiskSeverity.critical,
  String matchedText = 'трудовой договор',
}) {
  return RiskMatch(
    markerCode: markerCode,
    severity: severity,
    matchedText: matchedText,
    start: 0,
    end: matchedText.length,
    description: 'Договор назван трудовым.',
    example: 'Стороны заключают трудовой договор.',
    suggestion: 'Замените на договор ГПХ.',
  );
}

RiskReport report({
  int id = 1,
  String sourceName = 'dogovor.txt',
  DateTime? createdAt,
  double safetyIndex = 40,
  List<RiskMatch>? risks,
}) {
  final result = RiskReport(
    sourceName: sourceName,
    textLength: 120,
    risks: risks ?? [match()],
    safetyIndex: safetyIndex,
  );
  result.id = id;
  result.createdAt = createdAt ?? DateTime(2026, 9, 12, 14, 5);
  return result;
}

Future<void> pumpHistory(
  WidgetTester tester, {
  required RiskReportRepository repository,
}) async {
  tester.view.physicalSize = const Size(900, 1600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(home: RiskHistoryScreen(repository: repository)),
  );
  await tester.pumpAndSettle();
}

void main() {
  test('formatHistoryDate форматирует дату как дд.мм.гггг чч:мм', () {
    expect(
      formatHistoryDate(DateTime(2026, 9, 12, 14, 5)),
      '12.09.2026 14:05',
    );
  });

  testWidgets('пустая история показывает заглушку', (tester) async {
    await pumpHistory(tester, repository: _FakeRiskReportRepository());

    expect(find.byKey(const Key('risk_history_screen')), findsOneWidget);
    expect(find.byKey(const Key('risk_history_empty')), findsOneWidget);
    expect(find.text('История проверок пуста'), findsOneWidget);
  });

  testWidgets('список показывает договор, дату, индекс и число рисков', (
    tester,
  ) async {
    final repository = _FakeRiskReportRepository()
      ..reports.add(
        report(
          id: 1,
          sourceName: 'dogovor.txt',
          safetyIndex: 40,
          risks: [match(), match(severity: RiskSeverity.medium)],
        ),
      );

    await pumpHistory(tester, repository: repository);

    expect(find.byKey(const Key('risk_history_list')), findsOneWidget);
    expect(find.byKey(const Key('risk_history_name_1')), findsOneWidget);
    expect(find.text('dogovor.txt'), findsOneWidget);
    expect(find.text('12.09.2026 14:05'), findsOneWidget);
    expect(find.text('Индекс: 40% · Высокий риск'), findsOneWidget);
    expect(find.text('Рисков: 2'), findsOneWidget);
  });

  testWidgets('открывает результат проверки при нажатии на карточку', (
    tester,
  ) async {
    final repository = _FakeRiskReportRepository()
      ..reports.add(report(id: 7, sourceName: 'dogovor.txt'));

    await pumpHistory(tester, repository: repository);

    await tester.tap(find.byKey(const Key('risk_history_card_7')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('risk_report_detail_screen')), findsOneWidget);
    expect(find.byKey(const Key('safety_index_gauge')), findsOneWidget);
    expect(find.byKey(const Key('risk_result_list')), findsOneWidget);
    expect(find.text('Критический'), findsOneWidget);
  });

  testWidgets('удаляет проверку после подтверждения', (tester) async {
    final repository = _FakeRiskReportRepository()
      ..reports.add(report(id: 1, sourceName: 'a.txt'))
      ..reports.add(report(id: 2, sourceName: 'b.txt'));

    await pumpHistory(tester, repository: repository);

    await tester.tap(find.byKey(const Key('risk_history_delete_1')));
    await tester.pumpAndSettle();

    expect(find.text('Удалить проверку?'), findsOneWidget);

    await tester.tap(find.byKey(const Key('confirm_history_delete_button')));
    await tester.pumpAndSettle();

    expect(repository.deleted, [1]);
    expect(find.byKey(const Key('risk_history_card_1')), findsNothing);
    expect(find.byKey(const Key('risk_history_card_2')), findsOneWidget);
    expect(find.text('Проверка удалена'), findsOneWidget);
  });

  testWidgets('отмена удаления оставляет проверку в истории', (tester) async {
    final repository = _FakeRiskReportRepository()
      ..reports.add(report(id: 1, sourceName: 'a.txt'));

    await pumpHistory(tester, repository: repository);

    await tester.tap(find.byKey(const Key('risk_history_delete_1')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Отмена'));
    await tester.pumpAndSettle();

    expect(repository.deleted, isEmpty);
    expect(find.byKey(const Key('risk_history_card_1')), findsOneWidget);
  });

  testWidgets('ошибка загрузки показывает кнопку повтора', (tester) async {
    final repository = _FakeRiskReportRepository(loadError: true);

    await pumpHistory(tester, repository: repository);

    expect(find.text('Не удалось загрузить историю проверок'), findsOneWidget);
    expect(find.byKey(const Key('risk_history_retry')), findsOneWidget);
  });
}

class _FakeRiskReportRepository implements RiskReportRepository {
  _FakeRiskReportRepository({this.loadError = false});

  final bool loadError;
  final List<RiskReport> reports = [];
  final List<int> deleted = [];
  int _nextId = 100;

  @override
  Future<int> save(RiskReport report) async {
    report.id = _nextId++;
    reports.add(report);
    return report.id;
  }

  @override
  Future<RiskReport?> getById(int id) async {
    for (final report in reports) {
      if (report.id == id) return report;
    }
    return null;
  }

  @override
  Future<List<RiskReport>> getAll() async {
    if (loadError) throw StateError('load failed');
    return List.of(reports);
  }

  @override
  Future<void> delete(int id) async {
    deleted.add(id);
    reports.removeWhere((r) => r.id == id);
  }

  @override
  Future<void> clear() async => reports.clear();
}
