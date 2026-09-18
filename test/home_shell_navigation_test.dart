import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:npd_shield/core/theme/app_theme.dart';
import 'package:npd_shield/core/theme/app_typography.dart';
import 'package:npd_shield/domain/risk/risk_analyzer.dart';
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
  const menuLabels = [
    'Дашборд',
    'Операции',
    'Клиенты',
    'Счета',
    'Шаблоны',
    'Договоры',
    'Документы',
    'Проверка',
    'Уведомления',
    'Отчёты',
    'Настройки',
    'Помощь',
  ];

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

  Future<void> openMenu(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('dashboard_menu_button')));
    await tester.pumpAndSettle();
  }

  int selectedIndex(WidgetTester tester) =>
      tester
          .widget<IndexedStack>(find.byKey(const Key('home_indexed_stack')))
          .index!;

  group('Фаза 39: сквозной путь навигации на телефоне', () {
    testWidgets('на ширине < 900 px нижняя панель не отображается', (
      tester,
    ) async {
      await pumpShell(tester, width: 400);

      expect(find.byType(NavigationBar), findsNothing);
      expect(find.byType(NavigationRail), findsNothing);
    });

    testWidgets('в шапке Дашборда есть гамбургер, открывающий меню', (
      tester,
    ) async {
      await pumpShell(tester, width: 400);

      expect(find.byKey(const Key('dashboard_menu_button')), findsOneWidget);
      expect(find.byType(HomeMenuDrawer), findsNothing);

      await openMenu(tester);

      expect(find.byType(HomeMenuDrawer), findsOneWidget);
    });

    testWidgets('меню содержит все 12 разделов с иконкой и текстом', (
      tester,
    ) async {
      await pumpShell(tester, width: 400);
      await openMenu(tester);

      final drawer = find.byType(HomeMenuDrawer);
      for (final label in menuLabels) {
        expect(
          find.descendant(of: drawer, matching: find.text(label)),
          findsOneWidget,
          reason: 'в меню нет пункта «$label»',
        );
      }
      for (var i = 0; i < menuLabels.length; i++) {
        final tile = find.byKey(Key('home_menu_item_$i'));
        expect(tile, findsOneWidget);
        expect(
          find.descendant(of: tile, matching: find.byType(Icon)),
          findsOneWidget,
          reason: 'у пункта «${menuLabels[i]}» нет иконки',
        );
      }
    });

    testWidgets('шрифт подписей меню меньше подписей прежней нижней панели', (
      tester,
    ) async {
      await pumpShell(tester, width: 400);
      await openMenu(tester);

      final label = tester.widget<Text>(
        find.descendant(
          of: find.byType(HomeMenuDrawer),
          matching: find.text('Операции'),
        ),
      );
      expect(label.style?.fontSize, AppTypography.menuLabel.fontSize);
      expect(label.style!.fontSize!, lessThan(AppTypography.label.fontSize!));
    });

    testWidgets('активный раздел выделен в меню', (tester) async {
      await pumpShell(tester, width: 400);
      await openMenu(tester);

      final active = tester.widget<ListTile>(
        find.byKey(const Key('home_menu_item_0')),
      );
      final inactive = tester.widget<ListTile>(
        find.byKey(const Key('home_menu_item_1')),
      );
      expect(active.selected, isTrue);
      expect(inactive.selected, isFalse);
    });

    testWidgets('выбор раздела закрывает меню и открывает нужный экран', (
      tester,
    ) async {
      await pumpShell(tester, width: 400);
      await openMenu(tester);

      await tester.tap(find.byKey(const Key('home_menu_item_10')));
      await tester.pumpAndSettle();

      expect(find.byType(HomeMenuDrawer), findsNothing);
      expect(selectedIndex(tester), 10);
    });

    testWidgets('«Назад» при открытом меню закрывает только меню', (
      tester,
    ) async {
      await pumpShell(tester, width: 400);
      await openMenu(tester);
      expect(find.byType(HomeMenuDrawer), findsOneWidget);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(find.byType(HomeMenuDrawer), findsNothing);
      expect(find.byType(HomeShell), findsOneWidget);
      expect(selectedIndex(tester), 0);
    });

    testWidgets('на ширине >= 900 px NavigationRail отображается без изменений', (
      tester,
    ) async {
      await pumpShell(tester, width: 1200);

      expect(find.byType(NavigationRail), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);
      expect(find.byKey(const Key('dashboard_menu_button')), findsNothing);
      expect(find.byType(HomeMenuDrawer), findsNothing);
    });
  });
}
