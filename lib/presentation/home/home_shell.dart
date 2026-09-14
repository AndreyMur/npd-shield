import 'package:flutter/material.dart';

import '../../data/files/text_file_picker.dart';
import '../../data/repositories/contract_draft_repository.dart';
import '../../data/repositories/contract_template_repository.dart';
import '../../data/repositories/contractor_profile_repository.dart';
import '../../data/repositories/document_repository.dart';
import '../../data/repositories/risk_report_repository.dart';
import '../../data/repositories/transaction_repository.dart';
import '../../domain/risk/risk_analyzer.dart';
import '../contracts/contract_archive_screen.dart';
import '../contracts/contract_library_screen.dart';
import '../dashboard/dashboard_screen.dart';
import '../documents/document_archive_screen.dart';
import '../risk/risk_shield_screen.dart';

/// Нижняя навигация приложения: дашборд, шаблоны, договоры и Risk Shield.
class HomeShell extends StatefulWidget {
  final TransactionRepository transactionRepository;
  final ContractTemplateRepository templateRepository;
  final ContractDraftRepository draftRepository;
  final ContractorProfileRepository profileRepository;
  final RiskAnalyzerUseCase riskAnalyzer;
  final RiskReportRepository riskReportRepository;
  final DocumentRepository documentRepository;
  final TextFilePicker textFilePicker;
  final void Function(ThemeMode mode) onThemeModeChanged;

  const HomeShell({
    super.key,
    required this.transactionRepository,
    required this.templateRepository,
    required this.draftRepository,
    required this.profileRepository,
    required this.riskAnalyzer,
    required this.riskReportRepository,
    required this.documentRepository,
    required this.textFilePicker,
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
            documentRepository: widget.documentRepository,
            onThemeModeChanged: widget.onThemeModeChanged,
          ),
          ContractLibraryScreen(
            templateRepository: widget.templateRepository,
            draftRepository: widget.draftRepository,
            profileRepository: widget.profileRepository,
            riskAnalyzer: widget.riskAnalyzer,
            riskReportRepository: widget.riskReportRepository,
            documentRepository: widget.documentRepository,
          ),
          ContractArchiveScreen(
            draftRepository: widget.draftRepository,
            templateRepository: widget.templateRepository,
            profileRepository: widget.profileRepository,
            riskAnalyzer: widget.riskAnalyzer,
            riskReportRepository: widget.riskReportRepository,
            documentRepository: widget.documentRepository,
            transactionRepository: widget.transactionRepository,
          ),
          DocumentArchiveScreen(
            documentRepository: widget.documentRepository,
          ),
          RiskShieldScreen(
            analyzer: widget.riskAnalyzer,
            filePicker: widget.textFilePicker,
            reportRepository: widget.riskReportRepository,
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
            label: 'Шаблоны',
          ),
          NavigationDestination(
            icon: Icon(Icons.folder_copy_outlined),
            selectedIcon: Icon(Icons.folder_copy),
            label: 'Договоры',
          ),
          NavigationDestination(
            icon: Icon(Icons.folder_open_outlined),
            selectedIcon: Icon(Icons.folder_open),
            label: 'Документы',
          ),
          NavigationDestination(
            icon: Icon(Icons.shield_outlined),
            selectedIcon: Icon(Icons.shield),
            label: 'Проверка',
          ),
        ],
      ),
    );
  }
}
