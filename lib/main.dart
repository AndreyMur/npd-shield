import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'data/database.dart';
import 'data/repositories/isar_transaction_repository.dart';
import 'data/repositories/transaction_repository.dart';
import 'data/seed_data.dart';
import 'presentation/dashboard/dashboard_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    final isar = await AppDatabase.open();
    final repository = IsarTransactionRepository(isar);
    await seedDashboardData(repository);
    runApp(NpdShieldApp(repository: repository));
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
  final TransactionRepository repository;

  const NpdShieldApp({super.key, required this.repository});

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
          home: DashboardScreen(
            repository: widget.repository,
            onThemeModeChanged: _setThemeMode,
          ),
        );
      },
    );
  }
}
