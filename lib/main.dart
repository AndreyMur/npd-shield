import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'data/built_in_templates.dart';
import 'data/database.dart';
import 'data/files/file_picker_text_file_picker.dart';
import 'data/files/text_file_picker.dart';
import 'data/notifications/firebase_push_notification_service.dart';
import 'data/notifications/flutter_local_notification_service.dart';
import 'data/notifications/notification_background_scheduler.dart';
import 'data/repositories/isar_contract_draft_repository.dart';
import 'data/repositories/isar_contract_template_repository.dart';
import 'data/repositories/isar_document_repository.dart';
import 'data/notifications/notification_service.dart';
import 'data/repositories/isar_notification_repository.dart';
import 'data/repositories/isar_risk_marker_repository.dart';
import 'data/repositories/notification_repository.dart';
import 'data/repositories/isar_risk_report_repository.dart';
import 'data/repositories/isar_transaction_repository.dart';
import 'data/repositories/shared_prefs_contractor_profile_repository.dart';
import 'data/risk_markers.dart';
import 'domain/risk/risk_analyzer.dart';
import 'presentation/home/home_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    final isar = await AppDatabase.open();
    final transactionRepository = IsarTransactionRepository(isar);

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
    final notificationService = FlutterLocalNotificationService();
    await _initializeNotifications(notificationService);

    runApp(
      NpdShieldApp(
        transactionRepository: transactionRepository,
        templateRepository: templateRepository,
        draftRepository: draftRepository,
        profileRepository: profileRepository,
        riskAnalyzer: riskAnalyzer,
        riskReportRepository: riskReportRepository,
        documentRepository: documentRepository,
        notificationRepository: notificationRepository,
        notificationService: notificationService,
        textFilePicker: const FilePickerTextFilePicker(),
      ),
    );
  } catch (error) {
    runApp(const _StartupErrorApp());
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
  final IsarContractTemplateRepository templateRepository;
  final IsarContractDraftRepository draftRepository;
  final SharedPrefsContractorProfileRepository profileRepository;
  final RiskAnalyzerUseCase riskAnalyzer;
  final IsarRiskReportRepository riskReportRepository;
  final IsarDocumentRepository documentRepository;
  final NotificationRepository notificationRepository;
  final NotificationService notificationService;
  final TextFilePicker textFilePicker;

  const NpdShieldApp({
    super.key,
    required this.transactionRepository,
    required this.templateRepository,
    required this.draftRepository,
    required this.profileRepository,
    required this.riskAnalyzer,
    required this.riskReportRepository,
    required this.documentRepository,
    required this.notificationRepository,
    required this.notificationService,
    required this.textFilePicker,
  });

  @override
  State<NpdShieldApp> createState() => _NpdShieldAppState();
}

class _NpdShieldAppState extends State<NpdShieldApp> {
  ThemeMode _themeMode = ThemeMode.system;

  @override
  void initState() {
    super.initState();
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    try {
      final mode = await AppTheme.loadMode();
      if (mounted) setState(() => _themeMode = mode);
    } catch (_) {
      // Keep the system default if the stored preference cannot be read.
    }
  }

  Future<void> _setThemeMode(ThemeMode mode) async {
    setState(() => _themeMode = mode);
    await AppTheme.saveMode(mode);
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
          home: HomeShell(
            transactionRepository: widget.transactionRepository,
            templateRepository: widget.templateRepository,
            draftRepository: widget.draftRepository,
            profileRepository: widget.profileRepository,
            riskAnalyzer: widget.riskAnalyzer,
            riskReportRepository: widget.riskReportRepository,
            documentRepository: widget.documentRepository,
            notificationRepository: widget.notificationRepository,
            notificationService: widget.notificationService,
            textFilePicker: widget.textFilePicker,
            onThemeModeChanged: _setThemeMode,
          ),
        );
      },
    );
  }
}
