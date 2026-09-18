import 'package:flutter/material.dart';

import '../../core/theme/app_icons.dart';
import '../../core/theme/app_tokens.dart';
import '../../data/backup/backup_service.dart';
import '../../data/files/backup_file_picker.dart';
import '../../data/files/export_file_saver.dart';
import '../../data/files/text_file_picker.dart';
import '../../data/models/app_notification.dart';
import '../../data/notifications/notification_service.dart';
import '../../data/repositories/client_repository.dart';
import '../../data/repositories/contract_draft_repository.dart';
import '../../data/repositories/contract_template_repository.dart';
import '../../data/repositories/contractor_profile_repository.dart';
import '../../data/repositories/document_repository.dart';
import '../../data/repositories/invoice_repository.dart';
import '../../data/repositories/notification_repository.dart';
import '../../data/repositories/notification_settings_repository.dart';
import '../../data/repositories/risk_report_repository.dart';
import '../../data/repositories/transaction_repository.dart';
import '../../data/services/activity_spheres_service.dart';
import '../../domain/risk/risk_analyzer.dart';
import '../clients/clients_screen.dart';
import '../contracts/contract_archive_screen.dart';
import '../contracts/contract_library_screen.dart';
import '../dashboard/dashboard_screen.dart';
import '../documents/document_archive_screen.dart';
import '../help/help_screen.dart';
import '../invoices/invoices_screen.dart';
import '../notifications/invoice_notification_action.dart';
import '../notifications/notification_center_screen.dart';
import '../operations/operations_screen.dart';
import '../operations/transaction_form_screen.dart';
import '../reports/reports_screen.dart';
import '../risk/risk_shield_screen.dart';
import '../settings/settings_screen.dart';
import 'home_menu_drawer.dart';

/// Навигационная оболочка приложения: дашборд, операции, шаблоны, договоры,
/// документы, Risk Shield, уведомления, настройки и помощь.
///
/// На узких экранах (мобильные) используется нижняя панель, на широких
/// (десктоп) — боковая навигация.
class HomeShell extends StatefulWidget {
  final TransactionRepository transactionRepository;
  final ClientRepository clientRepository;
  final InvoiceRepository invoiceRepository;
  final ContractTemplateRepository templateRepository;
  final ContractDraftRepository draftRepository;
  final ContractorProfileRepository profileRepository;
  final RiskAnalyzerUseCase riskAnalyzer;
  final RiskReportRepository riskReportRepository;
  final DocumentRepository documentRepository;
  final NotificationRepository notificationRepository;
  final NotificationService notificationService;
  final NotificationSettingsRepository notificationSettingsRepository;
  final TextFilePicker textFilePicker;
  final ActivitySpheresService activitySpheresService;
  final BackupGateway backupGateway;
  final ExportFileSaver fileSaver;
  final BackupFilePicker backupFilePicker;
  final ThemeMode themeMode;
  final void Function(ThemeMode mode) onThemeModeChanged;
  final Future<void> Function() onLoadDemoData;
  final Future<void> Function() onClearAllData;

  const HomeShell({
    super.key,
    required this.transactionRepository,
    required this.clientRepository,
    required this.invoiceRepository,
    required this.templateRepository,
    required this.draftRepository,
    required this.profileRepository,
    required this.riskAnalyzer,
    required this.riskReportRepository,
    required this.documentRepository,
    required this.notificationRepository,
    required this.notificationService,
    required this.notificationSettingsRepository,
    required this.textFilePicker,
    required this.activitySpheresService,
    required this.backupGateway,
    required this.fileSaver,
    required this.backupFilePicker,
    required this.themeMode,
    required this.onThemeModeChanged,
    required this.onLoadDemoData,
    required this.onClearAllData,
  });

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  /// Индекс раздела «Уведомления» в списке разделов.
  static const _notificationsIndex = 8;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  int _selectedIndex = 0;
  int _unreadCount = 0;

  late final InvoiceNotificationAction _invoiceNotificationAction;

  @override
  void initState() {
    super.initState();
    _invoiceNotificationAction = InvoiceNotificationAction(
      invoiceRepository: widget.invoiceRepository,
    );
    _refreshUnreadCount();
  }

  Future<void> _refreshUnreadCount() async {
    try {
      final count = await widget.notificationRepository.unreadCount();
      if (mounted) setState(() => _unreadCount = count);
    } catch (_) {
      // Счётчик непрочитанных не критичен для навигации.
    }
  }

  void _select(int index) {
    setState(() => _selectedIndex = index);
    if (index == _notificationsIndex) _refreshUnreadCount();
  }

  /// Открывает боковое меню на телефоне.
  void _openMenu() {
    _scaffoldKey.currentState?.openDrawer();
  }

  /// Обрабатывает выбор раздела в боковом меню: закрывает меню и
  /// переключает экран, сохраняя состояние экранов через `IndexedStack`.
  void _selectFromMenu(int index) {
    Navigator.of(context).pop();
    _select(index);
  }

  Future<void> _openAddOperation() async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => TransactionFormScreen(
          repository: widget.transactionRepository,
          clientRepository: widget.clientRepository,
        ),
      ),
    );
    if (mounted) setState(() {});
  }

  /// Выполняет действие из карточки уведомления.
  ///
  /// Сейчас поддерживается «Отметить оплаченным» для напоминаний о счетах:
  /// счёт гасится полностью, а уведомление убирается из центра. Возвращает
  /// `true`, если уведомление стало неактуальным.
  Future<bool> _handleNotificationAction(AppNotification notification) async {
    final result = await _invoiceNotificationAction.markPaid(notification);
    if (mounted && result.message != null) {
      _showNotificationMessage(result.message!);
    }
    return result.resolved;
  }

  void _showNotificationMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _badge(IconData icon) {
    return Badge(
      key: const Key('home_unread_badge'),
      isLabelVisible: _unreadCount > 0,
      label: Text('$_unreadCount'),
      child: AppIcon(icon),
    );
  }

  /// Пункт навигации: контурная иконка для невыбранного состояния,
  /// заполненная — для выбранного (единое семейство Material Symbols).
  NavigationDestination _destination({
    required IconData outline,
    required IconData filled,
    required String label,
    bool badge = false,
  }) {
    Widget wrap(IconData icon) => badge ? _badge(icon) : AppIcon(icon);
    return NavigationDestination(
      icon: wrap(AppIcons.toggle(outline, filled, selected: false)),
      selectedIcon: wrap(AppIcons.toggle(outline, filled, selected: true)),
      label: label,
    );
  }

  List<Widget> _screens({required bool showMenuButton}) {
    final onOpenMenu = showMenuButton ? _openMenu : null;
    return [
      DashboardScreen(
        repository: widget.transactionRepository,
        documentRepository: widget.documentRepository,
        onAddOperation: _openAddOperation,
        onOpenMenu: onOpenMenu,
      ),
      OperationsScreen(
        repository: widget.transactionRepository,
        clientRepository: widget.clientRepository,
        onOpenMenu: onOpenMenu,
      ),
      ClientsScreen(
        repository: widget.clientRepository,
        transactionRepository: widget.transactionRepository,
        documentRepository: widget.documentRepository,
        onOpenMenu: onOpenMenu,
      ),
      InvoicesScreen(
        repository: widget.invoiceRepository,
        clientRepository: widget.clientRepository,
        onOpenMenu: onOpenMenu,
      ),
      ContractLibraryScreen(
        templateRepository: widget.templateRepository,
        draftRepository: widget.draftRepository,
        profileRepository: widget.profileRepository,
        riskAnalyzer: widget.riskAnalyzer,
        riskReportRepository: widget.riskReportRepository,
        documentRepository: widget.documentRepository,
        clientRepository: widget.clientRepository,
        onOpenMenu: onOpenMenu,
      ),
      ContractArchiveScreen(
        draftRepository: widget.draftRepository,
        templateRepository: widget.templateRepository,
        profileRepository: widget.profileRepository,
        riskAnalyzer: widget.riskAnalyzer,
        riskReportRepository: widget.riskReportRepository,
        documentRepository: widget.documentRepository,
        transactionRepository: widget.transactionRepository,
        clientRepository: widget.clientRepository,
        onOpenMenu: onOpenMenu,
      ),
      DocumentArchiveScreen(
        documentRepository: widget.documentRepository,
        onOpenMenu: onOpenMenu,
      ),
      RiskShieldScreen(
        analyzer: widget.riskAnalyzer,
        filePicker: widget.textFilePicker,
        reportRepository: widget.riskReportRepository,
        onOpenMenu: onOpenMenu,
      ),
      NotificationCenterScreen(
        repository: widget.notificationRepository,
        notificationService: widget.notificationService,
        onNotificationAction: _handleNotificationAction,
        onOpenMenu: onOpenMenu,
        onUnreadCountChanged: (count) {
          if (count != _unreadCount) setState(() => _unreadCount = count);
        },
      ),
      ReportsScreen(
        transactionRepository: widget.transactionRepository,
        invoiceRepository: widget.invoiceRepository,
        backupGateway: widget.backupGateway,
        fileSaver: widget.fileSaver,
        backupFilePicker: widget.backupFilePicker,
        onOpenMenu: onOpenMenu,
      ),
      SettingsScreen(
        onLoadDemoData: widget.onLoadDemoData,
        onClearAllData: widget.onClearAllData,
        profileRepository: widget.profileRepository,
        activitySpheresService: widget.activitySpheresService,
        notificationSettingsRepository: widget.notificationSettingsRepository,
        themeMode: widget.themeMode,
        onThemeModeChanged: widget.onThemeModeChanged,
        onOpenMenu: onOpenMenu,
      ),
      HelpScreen(onOpenMenu: onOpenMenu),
    ];
  }

  List<NavigationDestination> _destinations() {
    return [
      _destination(
        outline: Icons.dashboard_outlined,
        filled: Icons.dashboard,
        label: 'Дашборд',
      ),
      _destination(
        outline: Icons.swap_vert_outlined,
        filled: Icons.swap_vert,
        label: 'Операции',
      ),
      _destination(
        outline: Icons.people_outline,
        filled: Icons.people,
        label: 'Клиенты',
      ),
      _destination(
        outline: Icons.receipt_long_outlined,
        filled: Icons.receipt_long,
        label: 'Счета',
      ),
      _destination(
        outline: Icons.description_outlined,
        filled: Icons.description,
        label: 'Шаблоны',
      ),
      _destination(
        outline: Icons.folder_copy_outlined,
        filled: Icons.folder_copy,
        label: 'Договоры',
      ),
      _destination(
        outline: Icons.folder_open_outlined,
        filled: Icons.folder_open,
        label: 'Документы',
      ),
      _destination(
        outline: Icons.shield_outlined,
        filled: Icons.shield,
        label: 'Проверка',
      ),
      _destination(
        outline: Icons.notifications_outlined,
        filled: Icons.notifications,
        label: 'Уведомления',
        badge: true,
      ),
      _destination(
        outline: Icons.assessment_outlined,
        filled: Icons.assessment,
        label: 'Отчёты',
      ),
      _destination(
        outline: Icons.settings_outlined,
        filled: Icons.settings,
        label: 'Настройки',
      ),
      _destination(
        outline: Icons.help_outline,
        filled: Icons.help,
        label: 'Помощь',
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final destinations = _destinations();
    final wide = MediaQuery.sizeOf(context).width >= AppBreakpoints.wide;
    final screens = _screens(showMenuButton: !wide);

    if (wide) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: _selectedIndex,
              onDestinationSelected: _select,
              labelType: NavigationRailLabelType.all,
              scrollable: true,
              destinations: [
                for (final destination in destinations)
                  NavigationRailDestination(
                    icon: destination.icon,
                    selectedIcon: destination.selectedIcon,
                    label: Text(destination.label),
                  ),
              ],
            ),
            const VerticalDivider(width: 1),
            Expanded(
              child: IndexedStack(
                key: const Key('home_indexed_stack'),
                index: _selectedIndex,
                children: screens,
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      key: _scaffoldKey,
      drawer: HomeMenuDrawer(
        selectedIndex: _selectedIndex,
        destinations: destinations,
        onSelected: _selectFromMenu,
      ),
      body: IndexedStack(
        key: const Key('home_indexed_stack'),
        index: _selectedIndex,
        children: screens,
      ),
    );
  }
}
