import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:npd_shield/core/theme/app_theme.dart';
import 'package:npd_shield/core/theme/app_tokens.dart';
import 'package:npd_shield/core/widgets/widgets.dart';
import 'package:npd_shield/data/files/text_file_picker.dart';
import 'package:npd_shield/data/models/risk_marker.dart';
import 'package:npd_shield/data/models/transaction.dart';
import 'package:npd_shield/domain/reports/business_report.dart';
import 'package:npd_shield/domain/risk/risk_analyzer.dart';
import 'package:npd_shield/domain/risk/safety_index.dart';
import 'package:npd_shield/presentation/contracts/contract_archive_screen.dart';
import 'package:npd_shield/presentation/contracts/contract_library_screen.dart';
import 'package:npd_shield/presentation/reports/report_sphere_chart.dart';
import 'package:npd_shield/presentation/reports/reports_screen.dart';
import 'package:npd_shield/presentation/risk/risk_match_card.dart';
import 'package:npd_shield/presentation/risk/risk_report_view.dart';
import 'package:npd_shield/presentation/risk/risk_shield_screen.dart';
import 'package:npd_shield/presentation/risk/risk_visuals.dart';

import 'helpers/fake_backup_file_picker.dart';
import 'helpers/fake_backup_gateway.dart';
import 'helpers/fake_contract_repositories.dart';
import 'helpers/fake_export_file_saver.dart';
import 'helpers/fake_invoice_repository.dart';
import 'helpers/fake_transaction_repository.dart';

/// Fake-пикер TXT-файла: пустое состояние Risk Shield не требует выбора файла.
class _FakeTextFilePicker implements TextFilePicker {
  @override
  Future<PickedTextFile?> pick() async => null;
}

RiskMatch match(RiskSeverity severity, {int start = 0}) => RiskMatch(
  markerCode: 'code_${severity.name}',
  severity: severity,
  matchedText: 'фрагмент',
  start: start,
  end: start + 7,
  description: 'Описание риска уровня ${severity.name}',
  suggestion: 'Безопасная формулировка',
);

RiskReport reportWith(List<RiskMatch> risks) {
  final report = RiskReport(
    sourceName: 'dogovor.txt',
    textLength: 120,
    risks: risks,
    safetyIndex: 40,
  );
  report.id = 1;
  return report;
}

void main() {
  final themes = {
    'светлая': AppTheme.light(null),
    'тёмная': AppTheme.dark(null),
  };

  void setViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(1000, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
  }

  Future<void> pump(WidgetTester tester, Widget child, ThemeData theme) async {
    setViewport(tester);
    await tester.pumpWidget(
      MaterialApp(theme: theme, home: child),
    );
    await tester.pumpAndSettle();
  }

  group('Договоры и шаблоны', () {
    for (final entry in themes.entries) {
      final name = entry.key;
      final theme = entry.value;

      testWidgets('$name тема: библиотека шаблонов использует компоненты',
          (tester) async {
        await pump(
          tester,
          ContractLibraryScreen(
            templateRepository: FakeContractTemplateRepository([
              template(
                code: 'it_dev',
                title: 'Разработка ПО',
                recommended: true,
                okved: '62.01',
              ),
            ]),
            draftRepository: FakeContractDraftRepository(),
            profileRepository: FakeContractorProfileRepository(null),
          ),
          theme,
        );

        expect(tester.takeException(), isNull);
        expect(find.byType(AppCard), findsWidgets);
        expect(find.byType(AppFilterChip), findsWidgets);
        expect(find.text('Разработка ПО'), findsOneWidget);
      });

      testWidgets('$name тема: пустой архив договоров — AppEmptyState',
          (tester) async {
        await pump(
          tester,
          ContractArchiveScreen(
            draftRepository: FakeContractDraftRepository(),
            templateRepository: FakeContractTemplateRepository(),
            profileRepository: FakeContractorProfileRepository(null),
          ),
          theme,
        );

        expect(tester.takeException(), isNull);
        expect(find.byType(AppEmptyState), findsOneWidget);
        expect(find.text('Договоров пока нет'), findsOneWidget);
      });
    }
  });

  group('Risk Shield: уровни риска различимы', () {
    test('уровни различаются цветом, иконкой и текстом одновременно', () {
      final icons = <IconData>{};
      final colors = <Color>{};
      final labels = <String>{};
      for (final severity in RiskSeverity.values) {
        icons.add(severity.icon);
        colors.add(severity.color(AppTokens.light));
        labels.add(severity.label);
      }
      expect(icons, hasLength(RiskSeverity.values.length));
      expect(colors, hasLength(RiskSeverity.values.length));
      expect(labels, hasLength(RiskSeverity.values.length));
    });

    for (final entry in themes.entries) {
      final name = entry.key;
      final theme = entry.value;

      testWidgets('$name тема: карточка риска показывает иконку и метку',
          (tester) async {
        final severity = RiskSeverity.medium;
        await pump(
          tester,
          Scaffold(
            body: RiskMatchCard(match: match(severity)),
          ),
          theme,
        );

        expect(tester.takeException(), isNull);
        expect(find.text(severity.label), findsOneWidget);
        expect(find.byIcon(severity.icon), findsOneWidget);
      });

      testWidgets('$name тема: отчёт Risk Shield и шкала индекса',
          (tester) async {
        await pump(
          tester,
          Scaffold(
            body: RiskReportView(
              report: reportWith([
                match(RiskSeverity.critical),
                match(RiskSeverity.medium, start: 20),
                match(RiskSeverity.low, start: 40),
              ]),
              fileName: 'dogovor.txt',
            ),
          ),
          theme,
        );

        expect(tester.takeException(), isNull);
        expect(find.byKey(const Key('safety_index_scale')), findsOneWidget);
        expect(find.byKey(const Key('safety_index_gauge')), findsOneWidget);
        expect(find.text('Критический'), findsOneWidget);
        expect(find.text('Средний'), findsOneWidget);
        expect(find.text('Низкий'), findsOneWidget);
      });

      testWidgets('$name тема: пустое состояние Risk Shield', (tester) async {
        await pump(
          tester,
          RiskShieldScreen(
            analyzer: RiskAnalyzerUseCase(const []),
            filePicker: _FakeTextFilePicker(),
          ),
          theme,
        );

        expect(tester.takeException(), isNull);
        expect(find.byKey(const Key('risk_pick_button')), findsOneWidget);
      });
    }

    test('зоны индекса безопасности различаются иконкой и цветом', () {
      final icons = <IconData>{};
      final colors = <Color>{};
      for (final level in SafetyLevel.values) {
        icons.add(level.icon);
        colors.add(level.color(AppTokens.light));
      }
      expect(icons, hasLength(SafetyLevel.values.length));
      expect(colors, hasLength(SafetyLevel.values.length));
    });
  });

  group('Отчёты и графики', () {
    final spheres = [
      const ReportSphereBreakdown(
        sphere: TransactionSphere.it,
        income: 100000,
        expense: 40000,
      ),
      const ReportSphereBreakdown(
        sphere: TransactionSphere.logistics,
        income: 60000,
        expense: 20000,
      ),
    ];

    for (final entry in themes.entries) {
      final name = entry.key;
      final theme = entry.value;

      testWidgets('$name тема: график по сферам с читаемой легендой',
          (tester) async {
        await pump(
          tester,
          Scaffold(
            body: ListView(
              children: [ReportSphereChart(spheres: spheres)],
            ),
          ),
          theme,
        );

        expect(tester.takeException(), isNull);
        expect(find.byKey(const Key('report_sphere_chart')), findsOneWidget);
        expect(find.text('Доход'), findsOneWidget);
        expect(find.text('Расход'), findsOneWidget);
      });

      testWidgets('$name тема: экран отчётов строится без ошибок',
          (tester) async {
        await pump(
          tester,
          ReportsScreen(
            transactionRepository: FakeTransactionRepository([
              Transaction(
                amount: 100000,
                date: DateTime(2026, 9, 10),
                sphere: TransactionSphere.it,
                type: TransactionType.income,
                clientName: 'ООО «Альфа»',
                clientInn: '7701234567',
              ),
            ]),
            invoiceRepository: FakeInvoiceRepository(),
            backupGateway: FakeBackupGateway(),
            fileSaver: FakeExportFileSaver(),
            backupFilePicker: FakeBackupFilePicker(),
            now: DateTime(2026, 9, 16),
          ),
          theme,
        );

        expect(tester.takeException(), isNull);
        expect(find.byKey(const Key('report_summary')), findsOneWidget);
        expect(find.byKey(const Key('report_sphere_chart')), findsOneWidget);
      });
    }
  });

  group('Контраст семантических токенов', () {
    for (final entry in {
      'light': AppTokens.light,
      'dark': AppTokens.dark,
    }.entries) {
      final name = entry.key;
      final tokens = entry.value;

      test('$name: текст риска на фоне ≥ 4.5:1', () {
        expect(_ratio(tokens.destructive, tokens.surface), greaterThanOrEqualTo(4.5));
        expect(_ratio(tokens.success, tokens.surface), greaterThanOrEqualTo(3.0));
        expect(
          _ratio(tokens.warningStrong, tokens.surface),
          greaterThanOrEqualTo(4.5),
        );
      });

      test('$name: разделители различимы (граница ≠ фон)', () {
        expect(tokens.border, isNot(tokens.surface));
        expect(_ratio(tokens.border, tokens.surface), greaterThan(1.1));
      });
    }
  });

  group('Консистентность токенов', () {
    test('в экранах фазы 35 нет хардкод-цветов', () {
      // contract_document_preview.dart намеренно рисует «лист бумаги»
      // (белый фон, чёрный текст) и не зависит от темы приложения.
      const files = [
        'lib/presentation/contracts/contract_library_screen.dart',
        'lib/presentation/contracts/contract_archive_screen.dart',
        'lib/presentation/contracts/contract_form_screen.dart',
        'lib/presentation/contracts/contract_wizard_screen.dart',
        'lib/presentation/contracts/contract_pdf_preview_sheet.dart',
        'lib/presentation/contracts/contract_status_visuals.dart',
        'lib/presentation/contracts/template_sphere_visuals.dart',
        'lib/presentation/risk/risk_match_card.dart',
        'lib/presentation/risk/risk_report_view.dart',
        'lib/presentation/risk/risk_history_screen.dart',
        'lib/presentation/risk/risk_shield_screen.dart',
        'lib/presentation/risk/risk_shield_summary_card.dart',
        'lib/presentation/risk/risk_shield_info_sheet.dart',
        'lib/presentation/risk/safety_index_gauge.dart',
        'lib/presentation/risk/risk_visuals.dart',
        'lib/presentation/reports/reports_screen.dart',
        'lib/presentation/reports/report_sphere_chart.dart',
        'lib/presentation/reports/report_period_selector.dart',
      ];

      final colorPattern = RegExp(r'Color\(0x');
      final materialColorPattern = RegExp(r'\bColors\.');
      for (final path in files) {
        final source = File(path).readAsStringSync();
        expect(
          colorPattern.hasMatch(source),
          isFalse,
          reason: '$path содержит хардкод-цвет Color(0x...)',
        );
        expect(
          materialColorPattern.hasMatch(source),
          isFalse,
          reason: '$path содержит Material-цвет Colors.*',
        );
      }
    });

    test('Risk Shield использует семантические токены для уровней', () {
      final source = File(
        'lib/presentation/risk/risk_visuals.dart',
      ).readAsStringSync();
      expect(source.contains('tokens.destructive'), isTrue);
      expect(source.contains('tokens.warningStrong'), isTrue);
      expect(source.contains('tokens.success'), isTrue);
    });

    test('графики отчётов используют токены дохода и расхода', () {
      final source = File(
        'lib/presentation/reports/report_sphere_chart.dart',
      ).readAsStringSync();
      expect(source.contains('tokens.success'), isTrue);
      expect(source.contains('tokens.destructive'), isTrue);
    });
  });
}

double _ratio(Color a, Color b) {
  final l1 = _luminance(a);
  final l2 = _luminance(b);
  final lighter = max(l1, l2);
  final darker = min(l1, l2);
  return (lighter + 0.05) / (darker + 0.05);
}

double _luminance(Color color) {
  double channel(double value) {
    return value <= 0.03928
        ? value / 12.92
        : pow((value + 0.055) / 1.055, 2.4).toDouble();
  }

  return 0.2126 * channel(color.r) +
      0.7152 * channel(color.g) +
      0.0722 * channel(color.b);
}
