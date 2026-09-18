import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:npd_shield/core/theme/app_theme.dart';
import 'package:npd_shield/domain/risk/risk_analyzer.dart';
import 'package:npd_shield/presentation/help/help_screen.dart';
import 'package:npd_shield/presentation/home/home_menu_drawer.dart';
import 'package:npd_shield/presentation/home/home_shell.dart';

import 'helpers/fake_activity_spheres_service.dart';
import 'helpers/fake_backup_file_picker.dart';
import 'helpers/fake_backup_gateway.dart';
import 'helpers/fake_client_repository.dart';
import 'helpers/fake_contract_repositories.dart';
import 'helpers/fake_document_repository.dart';
import 'helpers/fake_export_file_saver.dart';
import 'helpers/fake_invoice_repository.dart';
import 'helpers/fake_notification_repository.dart';
import 'helpers/fake_notification_service.dart';
import 'helpers/fake_notification_settings_repository.dart';
import 'helpers/fake_risk_report_repository.dart';
import 'helpers/fake_text_file_picker.dart';
import 'helpers/fake_transaction_repository.dart';

void main() {
  const helpIndex = 11;

  Future<void> pumpShell(WidgetTester tester, {required double width}) async {
    tester.view.physicalSize = Size(width, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(null),
        home: HomeShell(
          transactionRepository: FakeTransactionRepository(),
          clientRepository: FakeClientRepository(),
          invoiceRepository: FakeInvoiceRepository(),
          templateRepository: FakeContractTemplateRepository(),
          draftRepository: FakeContractDraftRepository(),
          profileRepository: FakeContractorProfileRepository(),
          riskAnalyzer: const RiskAnalyzerUseCase([]),
          riskReportRepository: FakeRiskReportRepository(),
          documentRepository: FakeDocumentRepository(),
          notificationRepository: FakeNotificationRepository(),
          notificationService: FakeNotificationService(),
          notificationSettingsRepository: FakeNotificationSettingsRepository(),
          textFilePicker: FakeTextFilePicker(),
          activitySpheresService: FakeActivitySpheresService(),
          backupGateway: FakeBackupGateway(),
          fileSaver: FakeExportFileSaver(),
          backupFilePicker: FakeBackupFilePicker(),
          themeMode: ThemeMode.light,
          onThemeModeChanged: (_) {},
          onLoadDemoData: () async {},
          onClearAllData: () async {},
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  int selectedIndex(WidgetTester tester) =>
      tester
          .widget<IndexedStack>(find.byKey(const Key('home_indexed_stack')))
          .index!;

  group('Фаза 1: точка входа в «Помощь»', () {
    testWidgets('на телефоне пункт «Помощь» есть в меню и открывает HelpScreen', (
      tester,
    ) async {
      await pumpShell(tester, width: 400);

      await tester.tap(find.byKey(const Key('dashboard_menu_button')));
      await tester.pumpAndSettle();

      final drawer = find.byType(HomeMenuDrawer);
      expect(
        find.descendant(of: drawer, matching: find.text('Помощь')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('home_menu_item_$helpIndex')), findsOneWidget);

      await tester.tap(find.byKey(const Key('home_menu_item_$helpIndex')));
      await tester.pumpAndSettle();

      expect(find.byType(HomeMenuDrawer), findsNothing);
      expect(selectedIndex(tester), helpIndex);
      expect(find.byKey(const Key('help_screen')), findsOneWidget);
    });

    testWidgets('на широком экране пункт «Помощь» есть в NavigationRail', (
      tester,
    ) async {
      await pumpShell(tester, width: 1200);

      final rail = find.byType(NavigationRail);
      expect(rail, findsOneWidget);
      expect(
        find.descendant(of: rail, matching: find.text('Помощь')),
        findsOneWidget,
      );

      await tester.tap(
        find.descendant(of: rail, matching: find.text('Помощь')),
      );
      await tester.pumpAndSettle();

      expect(selectedIndex(tester), helpIndex);
      expect(find.byKey(const Key('help_screen')), findsOneWidget);
    });

    testWidgets('HelpScreen показывает заголовок, поиск и контент', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(theme: AppTheme.light(null), home: const HelpScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.text('Помощь'), findsOneWidget);
      final search = tester.widget<TextField>(
        find.descendant(
          of: find.byKey(const Key('help_search_field')),
          matching: find.byType(TextField),
        ),
      );
      expect(search.enabled, isTrue);
      expect(find.byKey(const Key('help_quick_start_title')), findsOneWidget);
    });
  });
}
