import 'package:flutter/material.dart';

import '../../data/repositories/contract_draft_repository.dart';
import '../../data/repositories/contract_template_repository.dart';
import '../../data/repositories/contractor_profile_repository.dart';
import '../../data/repositories/transaction_repository.dart';
import '../contracts/contract_library_screen.dart';
import '../dashboard/dashboard_screen.dart';

/// Нижняя навигация приложения: дашборд и библиотека шаблонов договоров.
class HomeShell extends StatefulWidget {
  final TransactionRepository transactionRepository;
  final ContractTemplateRepository templateRepository;
  final ContractDraftRepository draftRepository;
  final ContractorProfileRepository profileRepository;
  final void Function(ThemeMode mode) onThemeModeChanged;

  const HomeShell({
    super.key,
    required this.transactionRepository,
    required this.templateRepository,
    required this.draftRepository,
    required this.profileRepository,
    required this.onThemeModeChanged,
  });

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          DashboardScreen(
            repository: widget.transactionRepository,
            onThemeModeChanged: widget.onThemeModeChanged,
          ),
          ContractLibraryScreen(
            templateRepository: widget.templateRepository,
            draftRepository: widget.draftRepository,
            profileRepository: widget.profileRepository,
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Дашборд',
          ),
          NavigationDestination(
            icon: Icon(Icons.description_outlined),
            selectedIcon: Icon(Icons.description),
            label: 'Договоры',
          ),
        ],
      ),
    );
  }
}
