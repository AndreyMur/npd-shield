import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:npd_shield/core/theme/app_theme.dart';
import 'package:npd_shield/core/theme/app_tokens.dart';
import 'package:npd_shield/data/models/app_notification.dart';
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
  ];

  const menuButtonKeys = [
    'dashboard_menu_button',
    'operations_menu_button',
    'clients_menu_button',
    'invoices_menu_button',
    'contract_library_menu_button',
    'contract_archive_menu_button',
    'document_archive_menu_button',
    'risk_shield_menu_button',
    'notifications_menu_button',
    'reports_menu_button',
    'settings_menu_button',
  ];

  AppNotification unreadNote(int index) => AppNotification(
    type: NotificationType.limit,
    title: 'Уведомление $index',
    body: 'Текст уведомления $index',
    createdAt: DateTime.now().subtract(Duration(hours: index)),
  );

  Future<void> pumpShell(
    WidgetTester tester, {
    double width = 400,
    ThemeData? theme,
    FakeNotificationRepository? notificationRepository,
  }) async {
    tester.view.physicalSize = Size(width, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: theme ?? AppTheme.light(null),
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
          notificationRepository:
              notificationRepository ?? FakeNotificationRepository(),
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

  Future<void> openMenu(WidgetTester tester, String buttonKey) async {
    await tester.tap(find.byKey(Key(buttonKey)));
    await tester.pumpAndSettle();
  }

  int selectedIndex(WidgetTester tester) =>
      tester
          .widget<IndexedStack>(find.byKey(const Key('home_indexed_stack')))
          .index!;

  group('Фаза 40: гамбургер на всех экранах', () {
    testWidgets('гамбургер открывает меню на всех 11 экранах разделов', (
      tester,
    ) async {
      await pumpShell(tester);

      var current = 0;
      for (var i = 0; i < menuButtonKeys.length; i++) {
        // Перейти в раздел i через меню, открытое с текущего экрана.
        await openMenu(tester, menuButtonKeys[current]);
        await tester.tap(find.byKey(Key('home_menu_item_$i')));
        await tester.pumpAndSettle();
        expect(selectedIndex(tester), i);

        // На выбранном экране гамбургер должен открывать меню.
        await openMenu(tester, menuButtonKeys[i]);
        expect(
          find.byType(HomeMenuDrawer),
          findsOneWidget,
          reason: 'на экране «${menuLabels[i]}» гамбургер не открыл меню',
        );

        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        current = i;
      }
    });

    testWidgets('на широких экранах гамбургер не отображается', (tester) async {
      await pumpShell(tester, width: 1200);

      for (final key in menuButtonKeys) {
        expect(find.byKey(Key(key)), findsNothing);
      }
      expect(find.byType(NavigationRail), findsOneWidget);
    });
  });

  group('Фаза 40: счётчик непрочитанных уведомлений', () {
    testWidgets('счётчик виден у пункта «Уведомления» при значении > 0', (
      tester,
    ) async {
      await pumpShell(
        tester,
        notificationRepository: FakeNotificationRepository([
          unreadNote(1),
          unreadNote(2),
          unreadNote(3),
        ]),
      );
      await openMenu(tester, 'dashboard_menu_button');

      final badge = tester.widget<Badge>(
        find.byKey(const Key('home_unread_badge')),
      );
      expect(badge.isLabelVisible, isTrue);
      expect(
        find.descendant(
          of: find.byKey(const Key('home_menu_item_8')),
          matching: find.text('3'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('счётчик скрыт при значении 0', (tester) async {
      await pumpShell(tester);
      await openMenu(tester, 'dashboard_menu_button');

      final badge = tester.widget<Badge>(
        find.byKey(const Key('home_unread_badge')),
      );
      expect(badge.isLabelVisible, isFalse);
    });
  });

  group('Фаза 40: светлая и тёмная темы', () {
    for (final (name, theme) in [
      ('светлой', AppTheme.light(null)),
      ('тёмной', AppTheme.dark(null)),
    ]) {
      testWidgets('меню корректно в $name теме', (tester) async {
        await pumpShell(tester, theme: theme);
        await openMenu(tester, 'dashboard_menu_button');

        final drawer = tester.widget<Drawer>(
          find.byKey(const Key('home_menu_drawer')),
        );
        expect(drawer.backgroundColor, theme.extension<AppTokens>()!.surface);
        for (final label in menuLabels) {
          expect(
            find.descendant(
              of: find.byType(HomeMenuDrawer),
              matching: find.text(label),
            ),
            findsOneWidget,
            reason: 'в $name теме нет пункта «$label»',
          );
        }
      });
    }
  });

  group('Фаза 40: доступность меню', () {
    testWidgets('интерактивная область пунктов меню не меньше 48×48 dp', (
      tester,
    ) async {
      await pumpShell(tester);
      await openMenu(tester, 'dashboard_menu_button');

      for (var i = 0; i < menuLabels.length; i++) {
        final size = tester.getSize(find.byKey(Key('home_menu_item_$i')));
        expect(
          size.width,
          greaterThanOrEqualTo(48),
          reason: 'пункт «${menuLabels[i]}» уже 48 dp по ширине',
        );
        expect(
          size.height,
          greaterThanOrEqualTo(48),
          reason: 'пункт «${menuLabels[i]}» ниже 48 dp',
        );
      }
    });

    testWidgets('гамбургер не меньше 48×48 dp', (tester) async {
      await pumpShell(tester);

      final size = tester.getSize(
        find.byKey(const Key('dashboard_menu_button')),
      );
      expect(size.width, greaterThanOrEqualTo(48));
      expect(size.height, greaterThanOrEqualTo(48));
    });

    testWidgets('гамбургер и подписи меню читаемы скринридерами', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pumpShell(tester);

      expect(find.byTooltip('Меню'), findsWidgets);

      await openMenu(tester, 'dashboard_menu_button');

      expect(
        tester
            .getSemantics(find.byKey(const Key('home_menu_item_8')))
            .label,
        contains('Уведомления'),
      );
      expect(
        tester.getSemantics(find.byKey(const Key('home_menu_item_0'))).label,
        contains('Дашборд'),
      );

      handle.dispose();
    });
  });
}
