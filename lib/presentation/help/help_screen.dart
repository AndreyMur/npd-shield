import 'package:flutter/material.dart';

import '../../core/theme/app_tokens.dart';
import '../../core/widgets/widgets.dart';
import '../../data/repositories/help_repository.dart';
import '../../domain/help/help_article.dart';
import '../about/app_about.dart';
import 'help_article_screen.dart';

/// Экран раздела «Помощь».
///
/// Показывает блок «С чего начать» для новых пользователей и оглавление
/// справочника по разделам приложения. Поле поиска ищет статьи по заголовку и
/// содержимому офлайн, обновляя результаты по мере ввода. Статьи открываются в
/// отдельном экране [HelpArticleScreen].
class HelpScreen extends StatefulWidget {
  /// Открывает боковое меню навигации. Если задан, в шапке появляется
  /// кнопка-гамбургер (используется на телефоне).
  final VoidCallback? onOpenMenu;

  /// Репозиторий контента справочника.
  final HelpRepository repository;

  const HelpScreen({
    super.key,
    this.onOpenMenu,
    this.repository = const EmbeddedHelpRepository(),
  });

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openArticle(HelpArticle article) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            HelpArticleScreen(article: article, repository: widget.repository),
      ),
    );
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() => _query = '');
  }

  @override
  Widget build(BuildContext context) {
    final query = _query.trim();
    final isSearching = query.isNotEmpty;
    final results = isSearching
        ? widget.repository.search(query)
        : const <HelpArticle>[];

    return Scaffold(
      key: const Key('help_screen'),
      appBar: AppBar(
        title: const Text('Помощь'),
        leading: widget.onOpenMenu == null
            ? null
            : AppMenuButton(
                key: const Key('help_menu_button'),
                onPressed: widget.onOpenMenu!,
              ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            key: const Key('help_content_constraints'),
            constraints: const BoxConstraints(
              maxWidth: AppBreakpoints.contentMaxWidth,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.sm,
                    AppSpacing.md,
                    AppSpacing.sm,
                  ),
                  child: AppTextField(
                    key: const Key('help_search_field'),
                    controller: _searchController,
                    hint: 'Поиск по справочнику',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _query.isEmpty
                        ? null
                        : IconButton(
                            key: const Key('help_search_clear'),
                            tooltip: 'Очистить',
                            icon: const Icon(Icons.close),
                            onPressed: _clearSearch,
                          ),
                    onChanged: (value) => setState(() => _query = value),
                  ),
                ),
                Divider(height: 1, color: AppTokens.of(context).border),
                Expanded(
                  child: ListView(
                    key: isSearching
                        ? const Key('help_search_scroll')
                        : const Key('help_toc_scroll'),
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      AppSpacing.md,
                      AppSpacing.md,
                      AppSpacing.xl,
                    ),
                    children: isSearching
                        ? _buildSearchResults(query, results)
                        : _buildTableOfContents(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Содержимое экрана при активном поиске: результаты или пустое состояние.
  List<Widget> _buildSearchResults(String query, List<HelpArticle> results) {
    if (results.isEmpty) {
      return [
        _SearchEmptyState(query: query, onOpenTableOfContents: _clearSearch),
      ];
    }

    return [
      _SectionTitle(
        key: const Key('help_search_results_title'),
        title: 'Результаты поиска (${results.length})',
      ),
      const SizedBox(height: AppSpacing.xs),
      for (final article in results) ...[
        _SearchResultTile(article: article, onTap: () => _openArticle(article)),
        const SizedBox(height: AppSpacing.sm),
      ],
    ];
  }

  /// Обычное содержимое экрана: «С чего начать», оглавление и «О приложении».
  List<Widget> _buildTableOfContents() {
    final sections = widget.repository
        .getSections()
        .where((section) => section != HelpSection.gettingStarted)
        .toList();
    final quickStart = widget.repository.getQuickStartArticles();

    return [
      if (quickStart.isNotEmpty) ...[
        const _SectionTitle(
          key: Key('help_quick_start_title'),
          title: 'С чего начать',
        ),
        const SizedBox(height: AppSpacing.xs),
        for (final article in quickStart) ...[
          _QuickStartCard(article: article, onTap: () => _openArticle(article)),
          const SizedBox(height: AppSpacing.sm),
        ],
        const SizedBox(height: AppSpacing.sm),
      ],
      const _SectionTitle(
        key: Key('help_toc_title'),
        title: 'Разделы справочника',
      ),
      const SizedBox(height: AppSpacing.xs),
      for (final section in sections) ...[
        _SectionAccordion(
          section: section,
          articles: widget.repository.getArticlesBySection(section),
          onOpenArticle: _openArticle,
        ),
        const SizedBox(height: AppSpacing.sm),
      ],
      const SizedBox(height: AppSpacing.sm),
      _AboutEntry(onTap: () => showAppAboutDialog(context)),
    ];
  }
}

/// Заголовок секции экрана «Помощь».
class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      title,
      style: theme.textTheme.titleMedium?.copyWith(
        color: theme.colorScheme.primary,
      ),
    );
  }
}

/// Карточка статьи из блока «С чего начать».
class _QuickStartCard extends StatelessWidget {
  final HelpArticle article;
  final VoidCallback onTap;

  const _QuickStartCard({required this.article, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = AppTokens.of(context);
    return AppCard(
      key: Key('help_quick_start_${article.id}'),
      onTap: onTap,
      semanticLabel: 'Статья: ${article.title}',
      child: Row(
        children: [
          Container(
            width: AppSpacing.xl,
            height: AppSpacing.xl,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: tokens.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.button),
            ),
            child: Icon(Icons.rocket_launch_outlined, color: tokens.primary),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(article.title, style: theme.textTheme.titleSmall),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  article.summary,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: tokens.muted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Icon(Icons.chevron_right, color: tokens.muted),
        ],
      ),
    );
  }
}

/// Плитка результата поиска: название статьи и раздел, тап открывает статью.
class _SearchResultTile extends StatelessWidget {
  final HelpArticle article;
  final VoidCallback onTap;

  const _SearchResultTile({required this.article, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = AppTokens.of(context);
    return AppCard(
      key: Key('help_search_result_${article.id}'),
      onTap: onTap,
      semanticLabel: 'Результат поиска: ${article.title}',
      child: Row(
        children: [
          Icon(Icons.search, size: 20, color: tokens.primary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(article.title, style: theme.textTheme.titleSmall),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  article.section.label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: tokens.muted,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: tokens.muted),
        ],
      ),
    );
  }
}

/// Состояние «нет результатов» с предложением открыть оглавление.
class _SearchEmptyState extends StatelessWidget {
  final String query;
  final VoidCallback onOpenTableOfContents;

  const _SearchEmptyState({
    required this.query,
    required this.onOpenTableOfContents,
  });

  @override
  Widget build(BuildContext context) {
    return AppEmptyState(
      key: const Key('help_search_empty'),
      icon: Icons.search_off,
      title: 'Ничего не найдено',
      message:
          'По запросу «$query» статей не найдено. Измените запрос '
          'или откройте оглавление справочника.',
      action: AppButton(
        key: const Key('help_search_open_toc'),
        label: 'Открыть оглавление',
        icon: Icons.list_alt,
        variant: AppButtonVariant.secondary,
        onPressed: onOpenTableOfContents,
      ),
    );
  }
}

/// Раскрывающийся раздел оглавления со списком статей.
class _SectionAccordion extends StatelessWidget {
  final HelpSection section;
  final List<HelpArticle> articles;
  final ValueChanged<HelpArticle> onOpenArticle;

  const _SectionAccordion({
    required this.section,
    required this.articles,
    required this.onOpenArticle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = AppTokens.of(context);
    return AppCard(
      padding: EdgeInsets.zero,
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          key: Key('help_section_${section.name}'),
          title: Text(section.label, style: theme.textTheme.titleMedium),
          tilePadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          childrenPadding: const EdgeInsets.only(bottom: AppSpacing.xs),
          iconColor: tokens.primary,
          collapsedIconColor: tokens.muted,
          shape: const Border(),
          collapsedShape: const Border(),
          children: [
            for (final article in articles)
              ListTile(
                key: Key('help_article_${article.id}'),
                leading: Icon(Icons.article_outlined, color: tokens.primary),
                title: Text(article.title),
                subtitle: Text(
                  article.summary,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => onOpenArticle(article),
              ),
          ],
        ),
      ),
    );
  }
}

/// Точка входа в «О приложении» с версией и описанием.
class _AboutEntry extends StatelessWidget {
  final VoidCallback onTap;

  const _AboutEntry({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = AppTokens.of(context);
    return AppCard(
      key: const Key('help_about_entry'),
      onTap: onTap,
      semanticLabel: 'О приложении',
      child: Row(
        children: [
          Icon(Icons.info_outline, color: tokens.primary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('О приложении', style: theme.textTheme.titleSmall),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  'Версия $appVersion',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: tokens.muted,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: tokens.muted),
        ],
      ),
    );
  }
}
