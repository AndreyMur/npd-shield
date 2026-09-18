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
/// справочника по разделам приложения. Статьи открываются в отдельном экране
/// [HelpArticleScreen]. Поиск появится на следующем этапе и пока неактивен.
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
  void _openArticle(HelpArticle article) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            HelpArticleScreen(article: article, repository: widget.repository),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sections = widget.repository
        .getSections()
        .where((section) => section != HelpSection.gettingStarted)
        .toList();
    final quickStart = widget.repository.getQuickStartArticles();

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
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.md,
            AppSpacing.xl,
          ),
          children: [
            const AppTextField(
              key: Key('help_search_field'),
              enabled: false,
              hint: 'Поиск по справочнику',
              prefixIcon: Icon(Icons.search),
            ),
            const SizedBox(height: AppSpacing.lg),
            if (quickStart.isNotEmpty) ...[
              const _SectionTitle(
                key: Key('help_quick_start_title'),
                title: 'С чего начать',
              ),
              const SizedBox(height: AppSpacing.xs),
              for (final article in quickStart) ...[
                _QuickStartCard(
                  article: article,
                  onTap: () => _openArticle(article),
                ),
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
            _AboutEntry(
              onTap: () => showAppAboutDialog(context),
            ),
          ],
        ),
      ),
    );
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
          tilePadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
          ),
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
