import 'package:flutter/material.dart';

import '../../core/theme/app_tokens.dart';
import '../../core/widgets/widgets.dart';
import '../../data/models/contract_template.dart';
import '../../data/pdf/contract_pdf_font_loader.dart';
import '../../data/pdf/contract_pdf_share_service.dart';
import '../../data/repositories/client_repository.dart';
import '../../data/repositories/contract_draft_repository.dart';
import '../../data/repositories/contract_template_repository.dart';
import '../../data/repositories/contract_template_text_loader.dart';
import '../../data/repositories/contractor_profile_repository.dart';
import '../../data/repositories/document_repository.dart';
import '../../data/repositories/risk_report_repository.dart';
import '../../domain/contracts/template_catalog.dart';
import '../../domain/risk/risk_analyzer.dart';
import 'contract_wizard_screen.dart';
import 'template_sphere_visuals.dart';

/// Экран «Библиотека шаблонов»: карточки встроенных договоров.
///
/// Карточка показывает название, описание, категорию, сферу, ОКВЭД, пример
/// заполнения и пометку «Рекомендовано». Доступны поиск и фильтрация по
/// категории (типу деятельности). По нажатию открывается [ContractWizardScreen].
class ContractLibraryScreen extends StatefulWidget {
  final ContractTemplateRepository templateRepository;
  final ContractDraftRepository draftRepository;
  final ContractorProfileRepository profileRepository;

  /// Необязательные зависимости мастера, переопределяемые в тестах.
  final ContractTemplateTextLoader? templateTextLoader;
  final ContractPdfGenerator? pdfGenerator;
  final ContractPdfFontLoader? fontLoader;
  final ContractPdfShareService? shareService;
  final Widget Function()? previewBuilder;

  /// Анализатор рисков Risk Shield для автопроверки созданного договора.
  final RiskAnalyzerUseCase? riskAnalyzer;

  /// Репозиторий истории проверок Risk Shield.
  final RiskReportRepository? riskReportRepository;

  /// Репозиторий архива документов. Если задан — созданные договоры
  /// сохраняются в единый архив для экспорта в PDF.
  final DocumentRepository? documentRepository;

  /// Справочник клиентов. Если задан — заказчика можно выбрать из него.
  final ClientRepository? clientRepository;

  const ContractLibraryScreen({
    super.key,
    required this.templateRepository,
    required this.draftRepository,
    required this.profileRepository,
    this.templateTextLoader,
    this.pdfGenerator,
    this.fontLoader,
    this.shareService,
    this.previewBuilder,
    this.riskAnalyzer,
    this.riskReportRepository,
    this.documentRepository,
    this.clientRepository,
  });

  @override
  State<ContractLibraryScreen> createState() => _ContractLibraryScreenState();
}

class _ContractLibraryScreenState extends State<ContractLibraryScreen> {
  late Future<List<Template>> _templatesFuture;
  final _searchController = TextEditingController();
  String _query = '';
  TemplateSphere? _selectedSphere;

  @override
  void initState() {
    super.initState();
    _templatesFuture = widget.templateRepository.getAll();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _reload() {
    setState(() {
      _templatesFuture = widget.templateRepository.getAll();
    });
  }

  void _selectSphere(TemplateSphere? sphere) {
    setState(() => _selectedSphere = sphere);
  }

  Future<void> _openTemplate(Template template) async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ContractWizardScreen(
          template: template,
          draftRepository: widget.draftRepository,
          profileRepository: widget.profileRepository,
          templateTextLoader: widget.templateTextLoader,
          pdfGenerator: widget.pdfGenerator,
          fontLoader: widget.fontLoader,
          shareService: widget.shareService,
          previewBuilder: widget.previewBuilder,
          riskAnalyzer: widget.riskAnalyzer,
          riskReportRepository: widget.riskReportRepository,
          documentRepository: widget.documentRepository,
          clientRepository: widget.clientRepository,
        ),
      ),
    );
    if (created == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Черновик договора сохранён')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Библиотека шаблонов')),
      body: FutureBuilder<List<Template>>(
        future: _templatesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const AppLoadingState(semanticLabel: 'Загрузка шаблонов');
          }
          if (snapshot.hasError || snapshot.data == null) {
            return AppErrorState(
              message: 'Не удалось загрузить шаблоны',
              retryKey: const Key('template_library_retry'),
              onRetry: _reload,
            );
          }
          final templates = snapshot.data!;
          if (templates.isEmpty) {
            return const AppEmptyState(
              icon: Icons.description_outlined,
              title: 'Шаблонов пока нет',
              message: 'Библиотека шаблонов пуста.',
            );
          }
          return _buildCatalog(templates);
        },
      ),
    );
  }

  Widget _buildCatalog(List<Template> templates) {
    final visible = filterTemplates(
      templates,
      filter: TemplateFilter(query: _query, sphere: _selectedSphere),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.md,
            0,
          ),
          child: AppTextField(
            key: const Key('template_search_field'),
            controller: _searchController,
            hint: 'Поиск по названию, описанию, ОКВЭД',
            dense: true,
            prefixIcon: const Icon(Icons.search),
            onChanged: (value) => setState(() => _query = value),
            suffixIcon: _query.isEmpty
                ? null
                : IconButton(
                    key: const Key('template_search_clear'),
                    tooltip: 'Очистить поиск',
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _query = '');
                    },
                  ),
          ),
        ),
        _CategoryFilterBar(
          selected: _selectedSphere,
          onSelected: _selectSphere,
        ),
        Expanded(
          child: visible.isEmpty
              ? const AppEmptyState(
                  icon: Icons.search_off,
                  title: 'Ничего не найдено',
                  message: 'Измените запрос или категорию.',
                )
              : RefreshIndicator(
                  onRefresh: () async {
                    _reload();
                    await _templatesFuture;
                  },
                  child: ListView.builder(
                    key: const Key('template_library'),
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      AppSpacing.xxs,
                      AppSpacing.md,
                      AppSpacing.md,
                    ),
                    itemCount: visible.length,
                    itemBuilder: (context, index) {
                      final template = visible[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: _TemplateCard(
                          key: Key('template_card_${template.code}'),
                          template: template,
                          onTap: () => _openTemplate(template),
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }
}

/// Панель фильтрации шаблонов по категории (сфере деятельности).
class _CategoryFilterBar extends StatelessWidget {
  final TemplateSphere? selected;
  final ValueChanged<TemplateSphere?> onSelected;

  const _CategoryFilterBar({required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    final tokens = AppTokens.of(context);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.xs,
      ),
      child: Row(
        children: [
          AppFilterChip(
            key: const Key('template_filter_all'),
            label: 'Все',
            accent: tokens.primary,
            selected: selected == null,
            onSelected: () => onSelected(null),
          ),
          for (final sphere in TemplateSphere.values) ...[
            const SizedBox(width: AppSpacing.xs),
            AppFilterChip(
              key: Key('template_filter_${sphere.name}'),
              label: sphere.category,
              accent: sphere.color,
              icon: sphere.icon,
              selected: selected == sphere,
              onSelected: () => onSelected(sphere),
            ),
          ],
        ],
      ),
    );
  }
}

class _TemplateCard extends StatelessWidget {
  final Template template;
  final VoidCallback onTap;

  const _TemplateCard({super.key, required this.template, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = AppTokens.of(context);
    final sphereColor = template.sphere.color;

    return AppCard(
      onTap: onTap,
      semanticLabel:
          'Шаблон: ${template.title}. '
          'Категория ${template.sphere.category}. '
          'Сфера ${template.sphere.label}. '
          '${template.okved.isEmpty ? '' : 'ОКВЭД ${template.okved}. '}'
          '${template.recommended ? 'Рекомендовано. ' : ''}'
          '${template.example.isEmpty ? '' : 'Пример: ${template.example}'}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: sphereColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(AppRadius.button),
                ),
                child: Icon(template.sphere.icon, color: sphereColor),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            template.sphere.category,
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: sphereColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (template.recommended)
                          AppStatusChip(
                            label: 'Рекомендовано',
                            color: sphereColor,
                            icon: Icons.verified_outlined,
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      template.title,
                      style: theme.textTheme.titleMedium,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            template.description,
            style: theme.textTheme.bodyMedium?.copyWith(color: tokens.muted),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          if (template.example.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            _ExampleRow(example: template.example, color: sphereColor),
          ],
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              AppStatusChip(
                label: 'Категория: ${template.sphere.category}',
                color: sphereColor,
              ),
              AppStatusChip(
                label: 'Сфера: ${template.sphere.label}',
                color: sphereColor,
              ),
              if (template.okved.isNotEmpty)
                AppStatusChip(
                  label: 'ОКВЭД: ${template.okved}',
                  color: sphereColor,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Строка с примером заполнения шаблона.
class _ExampleRow extends StatelessWidget {
  final String example;
  final Color color;

  const _ExampleRow({required this.example, required this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = AppTokens.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.lightbulb_outline, size: 16, color: color),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Text(
            'Пример: $example',
            style: theme.textTheme.bodySmall?.copyWith(color: tokens.muted),
          ),
        ),
      ],
    );
  }
}
