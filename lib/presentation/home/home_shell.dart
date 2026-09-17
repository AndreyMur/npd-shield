import 'package:flutter/material.dart';

import '../../data/backup/backup_service.dart';
import '../../data/files/backup_file_picker.dart';
import '../../data/files/export_file_saver.dart';
import '../../data/files/text_file_picker.dart';
import '../../data/notifications/notification_service.dart';
import '../../data/repositories/client_repository.dart';
import '../../data/repositories/contract_draft_repository.dart';
import '../../data/repositories/contract_template_repository.dart';
import '../../data/repositories/contractor_profile_repository.dart';
import '../../data/repositories/document_repository.dart';
import '../../data/repositories/invoice_repository.dart';
import '../../data/repositories/notification_repository.dart';
import '../../data/repositories/risk_report_repository.dart';
import '../../data/repositories/transaction_repository.dart';
import '../../data/services/activity_spheres_service.dart';
import '../../domain/risk/risk_analyzer.dart';
import '../clients/clients_screen.dart';
import '../contracts/contract_archive_screen.dart';
import '../contracts/contract_library_screen.dart';
import '../dashboard/dashboard_screen.dart';
import '../documents/document_archive_screen.dart';
import '../invoices/invoices_screen.dart';
import '../notifications/notification_center_screen.dart';
import '../operations/operations_screen.dart';
import '../operations/transaction_form_screen.dart';
import '../reports/reports_screen.dart';
import '../risk/risk_shield_screen.dart';
import '../settings/settings_screen.dart';

/// Навигационная оболочка приложения: дашборд, операции, шаблоны, договоры,
/// документы, Risk Shield, уведомления и настройки.
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

  /// Ширина, с которой включается боковая навигация.
  static const _wideBreakpoint = 900.0;

  int _selectedIndex = 0;
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
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

  Widget _badge(IconData icon) {
    return Badge(
      isLabelVisible: _unreadCount > 0,
      label: Text('$_unreadCount'),
      child: Icon(icon),
    );
  }

  List<Widget> _screens() {
    return [
      DashboardScreen(
        repository: widget.transactionRepository,
        documentRepository: widget.documentRepository,
        onAddOperation: _openAddOperation,
      ),
      OperationsScreen(
        repository: widget.transactionRepository,
        clientRepository: widget.clientRepository,
      ),
      ClientsScreen(
        repository: widget.clientRepository,
        transactionRepository: widget.transactionRepository,
        documentRepository: widget.documentRepository,
      ),
      InvoicesScreen(
        repository: widget.invoiceRepository,
        clientRepository: widget.clientRepository,
      ),
      ContractLibraryScreen(
        templateRepository: widget.templateRepository,
        draftRepository: widget.draftRepository,
        profileRepository: widget.profileRepository,
        riskAnalyzer: widget.riskAnalyzer,
        riskReportRepository: widget.riskReportRepository,
        documentRepository: widget.documentRepository,
        clientRepository: widget.clientRepository,
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
      ),
      DocumentArchiveScreen(
        documentRepository: widget.documentRepository,
      ),
      RiskShieldScreen(
        analyzer: widget.riskAnalyzer,
        filePicker: widget.textFilePicker,
        reportRepository: widget.riskReportRepository,
      ),
      NotificationCenterScreen(
        repository: widget.notificationRepository,
        notificationService: widget.notificationService,
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
      ),
      SettingsScreen(
        onLoadDemoData: widget.onLoadDemoData,
        onClearAllData: widget.onClearAllData,
        profileRepository: widget.profileRepository,
        activitySpheresService: widget.activitySpheresService,
        themeMode: widget.themeMode,
        onThemeModeChanged: widget.onThemeModeChanged,
      ),
    ];
  }

  List<NavigationDestination> _destinations() {
    return [
      const NavigationDestination(
        icon: Icon(Icons.dashboard_outlined),
        selectedIcon: Icon(Icons.dashboard),
        label: 'Дашборд',
      ),
      const NavigationDestination(
        icon: Icon(Icons.swap_vert_outlined),
        selectedIcon: Icon(Icons.swap_vert),
        label: 'Операции',
      ),
      const NavigationDestination(
        icon: Icon(Icons.people_outline),
        selectedIcon: Icon(Icons.people),
        label: 'Клиенты',
      ),
      const NavigationDestination(
        icon: Icon(Icons.receipt_long_outlined),
        selectedIcon: Icon(Icons.receipt_long),
        label: 'Счета',
      ),
      const NavigationDestination(
        icon: Icon(Icons.description_outlined),
        selectedIcon: Icon(Icons.description),
        label: 'Шаблоны',
      ),
      const NavigationDestination(
        icon: Icon(Icons.folder_copy_outlined),
        selectedIcon: Icon(Icons.folder_copy),
        label: 'Договоры',
      ),
      const NavigationDestination(
        icon: Icon(Icons.folder_open_outlined),
        selectedIcon: Icon(Icons.folder_open),
        label: 'Документы',
      ),
      const NavigationDestination(
        icon: Icon(Icons.shield_outlined),
        selectedIcon: Icon(Icons.shield),
        label: 'Проверка',
      ),
      NavigationDestination(
        icon: _badge(Icons.notifications_outlined),
        selectedIcon: _badge(Icons.notifications),
        label: 'Уведомления',
      ),
      const NavigationDestination(
        icon: Icon(Icons.assessment_outlined),
        selectedIcon: Icon(Icons.assessment),
        label: 'Отчёты',
      ),
      const NavigationDestination(
        icon: Icon(Icons.settings_outlined),
        selectedIcon: Icon(Icons.settings),
        label: 'Настройки',
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final screens = _screens();
    final destinations = _destinations();
    final wide = MediaQuery.sizeOf(context).width >= _wideBreakpoint;

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
              child: IndexedStack(index: _selectedIndex, children: screens),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _select,
        destinations: destinations,
      ),
    );
  }
}
