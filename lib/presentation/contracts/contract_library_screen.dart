import 'package:flutter/material.dart';

import '../../data/models/contract_template.dart';
import '../../data/repositories/contract_draft_repository.dart';
import '../../data/repositories/contract_template_repository.dart';
import '../../data/repositories/contractor_profile_repository.dart';
import 'contract_wizard_screen.dart';
import 'template_sphere_visuals.dart';

/// Экран «Библиотека шаблонов»: карточки встроенных договоров.
///
/// Карточка показывает название, описание, категорию и сферу шаблона.
/// По нажатию открывается [ContractFormScreen] для заполнения полей.
class ContractLibraryScreen extends StatefulWidget {
  final ContractTemplateRepository templateRepository;
  final ContractDraftRepository draftRepository;
  final ContractorProfileRepository profileRepository;

  const ContractLibraryScreen({
    super.key,
    required this.templateRepository,
    required this.draftRepository,
    required this.profileRepository,
  });

  @override
  State<ContractLibraryScreen> createState() => _ContractLibraryScreenState();
}

class _ContractLibraryScreenState extends State<ContractLibraryScreen> {
  late Future<List<Template>> _templatesFuture;

  @override
  void initState() {
    super.initState();
    _templatesFuture = widget.templateRepository.getAll();
  }

  void _reload() {
    setState(() {
      _templatesFuture = widget.templateRepository.getAll();
    });
  }

  Future<void> _openTemplate(Template template) async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ContractWizardScreen(
          template: template,
          draftRepository: widget.draftRepository,
          profileRepository: widget.profileRepository,
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
          return RefreshIndicator(
            onRefresh: () async {
              _reload();
              await _templatesFuture;
            },
            child: ListView.builder(
              key: const Key('template_library'),
              padding: const EdgeInsets.all(16),
              itemCount: templates.length,
              itemBuilder: (context, index) {
                final template = templates[index];
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
          );
        },
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
          'Сфера ${template.sphere.label}',
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
                          Text(
                            template.sphere.category,
                            style: theme.textTheme.labelMedium!.copyWith(
                              color: sphereColor,
                              fontWeight: FontWeight.w600,
                            ),
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
