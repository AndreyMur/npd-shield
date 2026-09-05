import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'data/built_in_templates.dart';
import 'data/database.dart';
import 'data/repositories/isar_contract_draft_repository.dart';
import 'data/repositories/isar_contract_template_repository.dart';
import 'data/repositories/isar_transaction_repository.dart';
import 'data/repositories/shared_prefs_contractor_profile_repository.dart';
import 'data/seed_data.dart';
import 'presentation/home/home_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    final isar = await AppDatabase.open();
    final transactionRepository = IsarTransactionRepository(isar);
    await seedDashboardData(transactionRepository);

    final templateRepository = IsarContractTemplateRepository(isar);
    await seedBuiltInTemplates(templateRepository);
    final draftRepository = IsarContractDraftRepository(isar);
    final profileRepository = SharedPrefsContractorProfileRepository();
    await profileRepository.seedDemoIfEmpty();

    runApp(
      NpdShieldApp(
        transactionRepository: transactionRepository,
        templateRepository: templateRepository,
        draftRepository: draftRepository,
        profileRepository: profileRepository,
      ),
    );
  } catch (error) {
    runApp(const _StartupErrorApp());
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

  const NpdShieldApp({
    super.key,
    required this.transactionRepository,
    required this.templateRepository,
    required this.draftRepository,
    required this.profileRepository,
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
            onThemeModeChanged: _setThemeMode,
          ),
        );
      },
    );
  }
}
