import 'dart:async';

import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'data/backup/backup_service.dart';
import 'data/built_in_templates.dart';
import 'data/database.dart';
import 'data/demo_data.dart';
import 'data/files/backup_file_picker.dart';
import 'data/files/export_file_saver.dart';
import 'data/files/file_picker_backup_file_picker.dart';
import 'data/files/file_picker_export_file_saver.dart';
import 'data/files/file_picker_text_file_picker.dart';
import 'data/files/text_file_picker.dart';
import 'data/notifications/firebase_push_notification_service.dart';
import 'data/notifications/flutter_local_notification_service.dart';
import 'data/notifications/notification_background_scheduler.dart';
import 'data/notifications/notification_check_runner.dart';
import 'data/repositories/client_repository.dart';
import 'data/repositories/isar_client_repository.dart';
import 'data/repositories/isar_contract_draft_repository.dart';
import 'data/repositories/isar_contract_template_repository.dart';
import 'data/repositories/isar_document_repository.dart';
import 'data/notifications/notification_service.dart';
import 'data/repositories/isar_invoice_repository.dart';
import 'data/repositories/invoice_repository.dart';
import 'data/repositories/isar_notification_repository.dart';
import 'data/repositories/isar_risk_marker_repository.dart';
import 'data/repositories/notification_repository.dart';
import 'data/repositories/notification_settings_repository.dart';
import 'data/repositories/isar_risk_report_repository.dart';
import 'data/repositories/isar_transaction_repository.dart';
import 'data/repositories/shared_prefs_contractor_profile_repository.dart';
import 'data/risk_markers.dart';
import 'data/services/activity_spheres_service.dart';
import 'data/services/data_reset_service.dart';
import 'data/services/first_run_service.dart';
import 'domain/risk/risk_analyzer.dart';
import 'presentation/home/home_shell.dart';
import 'presentation/onboarding/onboarding_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    final isar = await AppDatabase.open();
    final transactionRepository = IsarTransactionRepository(isar);
    final clientRepository = IsarClientRepository(isar);
    final invoiceRepository = IsarInvoiceRepository(isar, transactionRepository);

    final templateRepository = IsarContractTemplateRepository(isar);
    await seedBuiltInTemplates(templateRepository);
    final draftRepository = IsarContractDraftRepository(isar);
    final documentRepository = IsarDocumentRepository(isar);
    final profileRepository = SharedPrefsContractorProfileRepository();

    final riskMarkerRepository = IsarRiskMarkerRepository(isar);
    await seedRiskMarkers(riskMarkerRepository);
    final riskReportRepository = IsarRiskReportRepository(isar);
    final riskAnalyzer = RiskAnalyzerUseCase(await riskMarkerRepository.getAll());

    final notificationRepository = IsarNotificationRepository(isar);
    final notificationSettingsRepository =
        SharedPrefsNotificationSettingsRepository();
    final notificationService = FlutterLocalNotificationService();
    await _initializeNotifications(notificationService);

    final firstRunService = SharedPrefsFirstRunService();
    final activitySpheresService = SharedPrefsActivitySpheresService();
    final backupService = BackupService(
      isar: isar,
      profileRepository: profileRepository,
      activitySpheresService: activitySpheresService,
    );
    final dataResetService = DataResetService(
      transactionRepository: transactionRepository,
      clientRepository: clientRepository,
      documentRepository: documentRepository,
      invoiceRepository: invoiceRepository,
      contractDraftRepository: draftRepository,
      riskReportRepository: riskReportRepository,
      notificationRepository: notificationRepository,
      profileRepository: profileRepository,
      activitySpheresService: activitySpheresService,
      firstRunService: firstRunService,
    );

    runApp(
      NpdShieldApp(
        transactionRepository: transactionRepository,
        clientRepository: clientRepository,
        invoiceRepository: invoiceRepository,
        templateRepository: templateRepository,
        draftRepository: draftRepository,
        profileRepository: profileRepository,
        riskAnalyzer: riskAnalyzer,
        riskReportRepository: riskReportRepository,
        documentRepository: documentRepository,
        notificationRepository: notificationRepository,
        notificationService: notificationService,
        notificationSettingsRepository: notificationSettingsRepository,
        textFilePicker: const FilePickerTextFilePicker(),
        firstRunService: firstRunService,
        activitySpheresService: activitySpheresService,
        backupGateway: backupService,
        fileSaver: const FilePickerExportFileSaver(),
        backupFilePicker: const FilePickerBackupFilePicker(),
        dataResetService: dataResetService,
      ),
    );

    // Проверка условий уведомлений при запуске: на настольных платформах
    // фоновые задачи workmanager недоступны, поэтому это основной путь
    // формирования уведомлений. Выполняется после старта, не блокируя UI.
    unawaited(
      _runStartupNotificationCheck(
        transactionRepository: transactionRepository,
        invoiceRepository: invoiceRepository,
        notificationRepository: notificationRepository,
        settingsRepository: notificationSettingsRepository,
        notificationService: notificationService,
      ),
    );
  } catch (error) {
    runApp(const _StartupErrorApp());
  }
}

/// Прогоняет проверку уведомлений при запуске приложения.
///
/// Ошибки подавляются: сбой проверки не должен мешать работе приложения.
Future<void> _runStartupNotificationCheck({
  required IsarTransactionRepository transactionRepository,
  required IsarInvoiceRepository invoiceRepository,
  required IsarNotificationRepository notificationRepository,
  required SharedPrefsNotificationSettingsRepository settingsRepository,
  required FlutterLocalNotificationService notificationService,
}) async {
  try {
    final runner = NotificationCheckRunner(
      transactionRepository: transactionRepository,
      invoiceRepository: invoiceRepository,
      notificationRepository: notificationRepository,
      settingsRepository: settingsRepository,
      notificationService: notificationService,
    );
    await runner.run();
  } catch (error) {
    debugPrint('Проверка уведомлений при запуске не удалась: $error');
  }
}

/// Инициализирует доставку уведомлений: локальные, push и фоновые задачи.
///
/// Сбой любого из каналов (например, Firebase не сконфигурирован на Windows)
/// не должен мешать запуску приложения, поэтому ошибки здесь подавляются.
Future<void> _initializeNotifications(
  FlutterLocalNotificationService notificationService,
) async {
  try {
    await notificationService.initialize();
    await notificationService.requestPermission();

    final pushService = FirebasePushNotificationService();
    await pushService.initialize();

    final backgroundScheduler = WorkmanagerNotificationBackgroundScheduler();
    await backgroundScheduler.initialize();
    await backgroundScheduler.schedulePeriodicCheck();
  } catch (error) {
    debugPrint('Инициализация уведомлений не удалась: $error');
  }
}

class _StartupErrorApp extends StatelessWidget {
  const _StartupErrorApp();

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'NPD Shield',
      home: Scaffold(
        body: Center(child: Text('Не удалось инициализировать базу данных')),
      ),
    );
  }
}

class NpdShieldApp extends StatefulWidget {
  final IsarTransactionRepository transactionRepository;
  final ClientRepository clientRepository;
  final InvoiceRepository invoiceRepository;
  final IsarContractTemplateRepository templateRepository;
  final IsarContractDraftRepository draftRepository;
  final SharedPrefsContractorProfileRepository profileRepository;
  final RiskAnalyzerUseCase riskAnalyzer;
  final IsarRiskReportRepository riskReportRepository;
  final IsarDocumentRepository documentRepository;
  final NotificationRepository notificationRepository;
  final NotificationService notificationService;
  final NotificationSettingsRepository notificationSettingsRepository;
  final TextFilePicker textFilePicker;
  final FirstRunService firstRunService;
  final ActivitySpheresService activitySpheresService;
  final BackupGateway backupGateway;
  final ExportFileSaver fileSaver;
  final BackupFilePicker backupFilePicker;
  final DataResetService dataResetService;

  const NpdShieldApp({
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
    required this.firstRunService,
    required this.activitySpheresService,
    required this.backupGateway,
    required this.fileSaver,
    required this.backupFilePicker,
    required this.dataResetService,
  });

  @override
  State<NpdShieldApp> createState() => _NpdShieldAppState();
}

class _NpdShieldAppState extends State<NpdShieldApp> {
  ThemeMode _themeMode = ThemeMode.system;

  /// `null` пока состояние онбординга не загружено.
  bool? _onboardingCompleted;

  @override
  void initState() {
    super.initState();
    _loadTheme();
    _loadOnboardingState();
  }

  Future<void> _loadTheme() async {
    try {
      final mode = await AppTheme.loadMode();
      if (mounted) setState(() => _themeMode = mode);
    } catch (_) {
      // Keep the system default if the stored preference cannot be read.
    }
  }

  Future<void> _loadOnboardingState() async {
    bool completed;
    try {
      completed = await widget.firstRunService.isOnboardingCompleted();
    } catch (_) {
      completed = true;
    }
    if (mounted) setState(() => _onboardingCompleted = completed);
  }

  Future<void> _setThemeMode(ThemeMode mode) async {
    setState(() => _themeMode = mode);
    await AppTheme.saveMode(mode);
  }

  Future<void> _loadDemoData() {
    return loadDemoData(
      transactionRepository: widget.transactionRepository,
      notificationRepository: widget.notificationRepository,
      profileRepository: widget.profileRepository,
    );
  }

  Future<void> _clearAllData() async {
    await widget.dataResetService.resetAll();
    if (mounted) setState(() => _onboardingCompleted = false);
  }

  void _handleOnboardingCompleted() {
    setState(() => _onboardingCompleted = true);
  }

  @override
  Widget build(BuildContext context) {
    return DynamicColorBuilder(
      builder: (lightDynamic, darkDynamic) {
        return MaterialApp(
          title: 'NPD Shield',
          themeMode: _themeMode,
          theme: AppTheme.light(lightDynamic),
          darkTheme: AppTheme.dark(darkDynamic),
          home: _buildHome(),
        );
      },
    );
  }

  Widget _buildHome() {
    if (_onboardingCompleted == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (!_onboardingCompleted!) {
      return OnboardingScreen(
        activitySpheresService: widget.activitySpheresService,
        profileRepository: widget.profileRepository,
        firstRunService: widget.firstRunService,
        onLoadDemoData: _loadDemoData,
        onCompleted: _handleOnboardingCompleted,
      );
    }
    return HomeShell(
      transactionRepository: widget.transactionRepository,
      clientRepository: widget.clientRepository,
      invoiceRepository: widget.invoiceRepository,
      templateRepository: widget.templateRepository,
      draftRepository: widget.draftRepository,
      profileRepository: widget.profileRepository,
      riskAnalyzer: widget.riskAnalyzer,
      riskReportRepository: widget.riskReportRepository,
      documentRepository: widget.documentRepository,
      notificationRepository: widget.notificationRepository,
      notificationService: widget.notificationService,
      notificationSettingsRepository: widget.notificationSettingsRepository,
      textFilePicker: widget.textFilePicker,
      activitySpheresService: widget.activitySpheresService,
      backupGateway: widget.backupGateway,
      fileSaver: widget.fileSaver,
      backupFilePicker: widget.backupFilePicker,
      themeMode: _themeMode,
      onThemeModeChanged: _setThemeMode,
      onLoadDemoData: _loadDemoData,
      onClearAllData: _clearAllData,
    );
  }
}
