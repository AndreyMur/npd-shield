import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:npd_shield/data/models/risk_marker.dart';
import 'package:npd_shield/data/pdf/contract_pdf_service.dart';
import 'package:npd_shield/data/pdf/contract_pdf_share_service.dart';
import 'package:npd_shield/data/repositories/contract_template_text_loader.dart';
import 'package:npd_shield/data/repositories/risk_report_repository.dart';
import 'package:npd_shield/data/risk_markers.dart';
import 'package:npd_shield/domain/profile/contractor_profile.dart';
import 'package:npd_shield/domain/risk/risk_analyzer.dart';
import 'package:npd_shield/presentation/contracts/contract_library_screen.dart';

import 'helpers/fake_contract_repositories.dart';

const _riskyTemplate = '''
ДОГОВОР № {{contractNumber}}
на оказание услуг

г. {{contractCity}}                                                    «{{contractDate}}»

1. ПРЕДМЕТ ДОГОВОРА

1.1. Исполнитель оказывает услуги: {{subject}}.

2. ПОРЯДОК РАСЧЁТОВ

2.1. Заказчик выплачивает заработную плату.

3. РЕКВИЗИТЫ И ПОДПИСИ СТОРОН

Исполнитель:
ИП {{executorFullName}}
ИНН {{executorInn}}

Заказчик:
{{clientName}}
ИНН {{clientInn}}

_______________________ / {{executorFullName}} /
''';

/// Сквозной smoke-тест интеграции Risk Shield с генератором договоров:
/// генерация договора → автопроверка → просмотр результатов → копирование
/// альтернатив → сохранение отчёта в историю.
void main() {
  testWidgets(
    'smoke: генерация договора → автопроверка → результаты → копирование',
    (tester) async {
      tester.view.physicalSize = const Size(1000, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

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

      final drafts = FakeContractDraftRepository();
      final reports = _FakeRiskReportRepository();
      final analyzer = RiskAnalyzerUseCase(
        builtInRiskMarkers.map((d) => d.toMarker()).toList(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ContractLibraryScreen(
            templateRepository: FakeContractTemplateRepository([
              template(
                code: 'it_software_development',
                title: 'Разработка ПО',
              ),
            ]),
            draftRepository: drafts,
            profileRepository: FakeContractorProfileRepository(
              ContractorProfile.demo,
            ),
            templateTextLoader: const _FakeTemplateTextLoader(_riskyTemplate),
            pdfGenerator: (document, fileName) async => GeneratedContractPdf(
              bytes: Uint8List.fromList(const [1, 2, 3]),
              pageCount: 1,
              fileName: fileName,
              generationTime: Duration.zero,
            ),
            shareService: _FakeShareService(),
            previewBuilder: () =>
                const SizedBox(key: Key('fake_pdf_preview')),
            riskAnalyzer: analyzer,
            riskReportRepository: reports,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Выбор шаблона и заполнение мастера.
      await tester.tap(
        find.byKey(const Key('template_card_it_software_development')),
      );
      await tester.pumpAndSettle();

      Future<void> next() async {
        final button = find.byKey(const Key('wizard_next_button'));
        await tester.ensureVisible(button);
        await tester.pumpAndSettle();
        await tester.tap(button);
        await tester.pumpAndSettle();
      }

      await next(); // Параметры → Исполнитель.
      await next(); // Исполнитель → Заказчик.
      await tester.enterText(
        find.byKey(const Key('field_clientName')),
        'ООО «Ромашка»',
      );
      await tester.enterText(
        find.byKey(const Key('field_clientInn')),
        '7701234567',
      );
      await next(); // Заказчик → Предмет и стоимость.
      await tester.enterText(
        find.byKey(const Key('field_subject')),
        'разработка сайта',
      );
      await tester.enterText(find.byKey(const Key('field_amount')), '150000');
      await next(); // Предмет → Предпросмотр: запускается автопроверка.

      // 2. Автопроверка показала результаты в карточке договора.
      expect(find.byKey(const Key('risk_contract_card')), findsOneWidget);
      expect(find.byKey(const Key('risk_contract_index')), findsOneWidget);
      expect(find.byKey(const Key('risk_contract_disclaimer')), findsOneWidget);
      expect(
        find.textContaining('Найдено рисков:'),
        findsOneWidget,
      );

      // 3. Раскрытие риска и копирование безопасной формулировки.
      await tester.tap(find.byIcon(Icons.expand_more).first);
      await tester.pumpAndSettle();

      expect(find.text('Безопасная формулировка'), findsOneWidget);
      final copyButton = find.text('Скопировать формулировку').first;
      await tester.ensureVisible(copyButton);
      await tester.pumpAndSettle();
      await tester.tap(copyButton);
      await tester.pumpAndSettle();

      final copy = clipboardCalls.singleWhere(
        (call) => call.method == 'Clipboard.setData',
      );
      expect((copy.arguments as Map)['text'], isNotEmpty);

      // 4. Создание PDF и сохранение отчёта в историю.
      final createButton = find.byKey(const Key('wizard_create_pdf_button'));
      await tester.ensureVisible(createButton);
      await tester.pumpAndSettle();
      await tester.tap(createButton);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('pdf_preview_sheet')), findsOneWidget);
      expect(reports.saved, hasLength(1));
      expect(reports.saved.single.risks, isNotEmpty);
      expect(drafts.drafts, hasLength(1));
    },
  );
}

class _FakeTemplateTextLoader implements ContractTemplateTextLoader {
  final String text;
  const _FakeTemplateTextLoader(this.text);

  @override
  Future<String> load(String code) async => text;
}

class _FakeShareService implements ContractPdfShareService {
  @override
  Future<void> share(GeneratedContractPdf pdf) async {}

  @override
  Future<String> saveToDocuments(GeneratedContractPdf pdf) async =>
      'path/${pdf.fileName}';
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
