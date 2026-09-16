import 'package:flutter/material.dart';

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
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || snapshot.data == null) {
            return const Center(child: Text('Не удалось загрузить шаблоны'));
          }
          final templates = snapshot.data!;
          if (templates.isEmpty) {
            return const Center(child: Text('Шаблонов пока нет'));
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
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: TextField(
            key: const Key('template_search_field'),
            controller: _searchController,
            onChanged: (value) => setState(() => _query = value),
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Поиск по названию, описанию, ОКВЭД',
              prefixIcon: const Icon(Icons.search),
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
              isDense: true,
              border: const OutlineInputBorder(),
            ),
          ),
        ),
        _CategoryFilterBar(
          selected: _selectedSphere,
          onSelected: _selectSphere,
        ),
        Expanded(
          child: visible.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'Ничего не найдено. Измените запрос или категорию.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () async {
                    _reload();
                    await _templatesFuture;
                  },
                  child: ListView.builder(
                    key: const Key('template_library'),
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                    itemCount: visible.length,
                    itemBuilder: (context, index) {
                      final template = visible[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
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
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          _CategoryChip(
            key: const Key('template_filter_all'),
            label: 'Все',
            color: Theme.of(context).colorScheme.primary,
            selected: selected == null,
            onSelected: () => onSelected(null),
          ),
          for (final sphere in TemplateSphere.values) ...[
            const SizedBox(width: 8),
            _CategoryChip(
              key: Key('template_filter_${sphere.name}'),
              label: sphere.category,
              color: sphere.color,
              selected: selected == sphere,
              onSelected: () => onSelected(sphere),
            ),
          ],
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onSelected;

  const _CategoryChip({
    super.key,
    required this.label,
    required this.color,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
      selectedColor: color.withValues(alpha: 0.18),
      side: BorderSide(
        color: selected ? color : Theme.of(context).colorScheme.outlineVariant,
      ),
      labelStyle: TextStyle(
        color: selected ? color : Theme.of(context).colorScheme.onSurface,
        fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
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
    final sphereColor = template.sphere.color;

    return Semantics(
      button: true,
      label:
          'Шаблон: ${template.title}. '
          'Категория ${template.sphere.category}. '
          'Сфера ${template.sphere.label}. '
          '${template.okved.isEmpty ? '' : 'ОКВЭД ${template.okved}. '}'
          '${template.recommended ? 'Рекомендовано. ' : ''}'
          '${template.example.isEmpty ? '' : 'Пример: ${template.example}'}',
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
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
                        color: sphereColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(template.sphere.icon, color: Colors.white),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  template.sphere.category,
                                  style: theme.textTheme.labelMedium!.copyWith(
                                    color: sphereColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              if (template.recommended)
                                _RecommendedBadge(color: sphereColor),
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
                const SizedBox(height: 10),
                Text(
                  template.description,
                  style: theme.textTheme.bodyMedium,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                if (template.example.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  _ExampleRow(example: template.example, color: sphereColor),
                ],
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _SphereChip(
                      label: 'Категория: ${template.sphere.category}',
                      color: sphereColor,
                    ),
                    _SphereChip(
                      label: 'Сфера: ${template.sphere.label}',
                      color: sphereColor,
                    ),
                    if (template.okved.isNotEmpty)
                      _SphereChip(
                        label: 'ОКВЭД: ${template.okved}',
                        color: sphereColor,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Пометка «Рекомендовано» для наиболее безопасных шаблонов.
class _RecommendedBadge extends StatelessWidget {
  final Color color;

  const _RecommendedBadge({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified_outlined, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            'Рекомендовано',
            style: Theme.of(context).textTheme.labelSmall!
                .copyWith(color: color, fontWeight: FontWeight.w600),
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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.lightbulb_outline, size: 16, color: color),
        const SizedBox(width: 6),
        Expanded(
          child: Text('Пример: $example', style: theme.textTheme.bodySmall),
        ),
      ],
    );
  }
}

class _SphereChip extends StatelessWidget {
  final String label;
  final Color color;

  const _SphereChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium!.copyWith(color: color),
      ),
    );
  }
}
