import 'package:flutter/material.dart';

import '../../core/theme/app_tokens.dart';
import '../../core/widgets/widgets.dart';
import '../../data/repositories/help_repository.dart';
import '../../domain/help/help_article.dart';

/// Экран статьи справочника «Помощь».
///
/// Показывает краткое описание, пошаговую инструкцию, частые вопросы и
/// подсказки, переходы к связанным статьям и действующий дисклеймер. Связанные
/// статьи открываются поверх текущей — так пользователь может вернуться назад,
/// а кнопка «К оглавлению» возвращает сразу к списку разделов.
class HelpArticleScreen extends StatelessWidget {
  /// Статья, которую нужно показать.
  final HelpArticle article;

  /// Репозиторий, по которому разрешаются связанные статьи.
  final HelpRepository repository;

  const HelpArticleScreen({
    super.key,
    required this.article,
    required this.repository,
  });

  /// Разрешает идентификаторы связанных статей в существующие статьи.
  List<HelpArticle> _relatedArticles() {
    return [
      for (final id in article.relatedIds) ?repository.getArticleById(id),
    ];
  }

  void _openRelated(BuildContext context, HelpArticle related) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            HelpArticleScreen(article: related, repository: repository),
      ),
    );
  }

  void _backToTableOfContents(BuildContext context) {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final related = _relatedArticles();

    return Scaffold(
      key: const Key('help_article_screen'),
      appBar: AppBar(
        title: Text(article.title),
        actions: [
          IconButton(
            key: const Key('help_back_to_toc'),
            tooltip: 'К оглавлению',
            icon: const Icon(Icons.list_alt),
            onPressed: () => _backToTableOfContents(context),
          ),
        ],
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
            _SectionBadge(label: article.section.label),
            const SizedBox(height: AppSpacing.sm),
            Text(
              article.summary,
              key: const Key('help_article_summary'),
              style: theme.textTheme.bodyLarge,
            ),
            if (article.steps.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.lg),
              Text('Как пользоваться', style: theme.textTheme.titleMedium),
              const SizedBox(height: AppSpacing.sm),
              for (var index = 0; index < article.steps.length; index++)
                _StepTile(index: index + 1, text: article.steps[index]),
            ],
            if (article.faq.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Частые вопросы и подсказки',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.sm),
              for (var index = 0; index < article.faq.length; index++)
                _FaqCard(index: index, item: article.faq[index]),
            ],
            if (related.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.lg),
              Text('Связанные статьи', style: theme.textTheme.titleMedium),
              const SizedBox(height: AppSpacing.sm),
              for (final relatedArticle in related)
                _RelatedTile(
                  article: relatedArticle,
                  onTap: () => _openRelated(context, relatedArticle),
                ),
            ],
            const SizedBox(height: AppSpacing.lg),
            const _DisclaimerCard(key: Key('help_disclaimer')),
          ],
        ),
      ),
    );
  }
}

/// Бейдж раздела статьи.
class _SectionBadge extends StatelessWidget {
  final String label;

  const _SectionBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = AppTokens.of(context);
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xxs,
        ),
        decoration: BoxDecoration(
          color: tokens.primary.withValues(alpha: 0.12),
          borderRadius: AppRadius.chipRadius,
        ),
        child: Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(color: tokens.primary),
        ),
      ),
    );
  }
}

/// Нумерованный шаг инструкции.
class _StepTile extends StatelessWidget {
  final int index;
  final String text;

  const _StepTile({required this.index, required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = AppTokens.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: AppSpacing.lg,
            height: AppSpacing.lg,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: tokens.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Text(
              '$index',
              style: theme.textTheme.labelMedium?.copyWith(
                color: tokens.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xxs),
              child: Text(text, style: theme.textTheme.bodyMedium),
            ),
          ),
        ],
      ),
    );
  }
}

/// Карточка частого вопроса с ответом.
class _FaqCard extends StatelessWidget {
  final int index;
  final HelpFaqItem item;

  const _FaqCard({required this.index, required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = AppTokens.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: AppCard(
        key: Key('help_faq_$index'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.help_outline,
                  size: 18,
                  color: tokens.primary,
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    item.question,
                    style: theme.textTheme.titleSmall,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              item.answer,
              style: theme.textTheme.bodyMedium?.copyWith(color: tokens.muted),
            ),
          ],
        ),
      ),
    );
  }
}

/// Плитка перехода к связанной статье.
class _RelatedTile extends StatelessWidget {
  final HelpArticle article;
  final VoidCallback onTap;

  const _RelatedTile({required this.article, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = AppTokens.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: AppCard(
        key: Key('help_related_${article.id}'),
        onTap: onTap,
        semanticLabel: 'Связанная статья: ${article.title}',
        child: Row(
          children: [
            Icon(Icons.menu_book_outlined, size: 20, color: tokens.primary),
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
      ),
    );
  }
}

/// Карточка действующего дисклеймера о справочном характере материалов.
class _DisclaimerCard extends StatelessWidget {
  const _DisclaimerCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = AppTokens.of(context);
    return AppCard(
      color: tokens.surfaceVariant,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: 20, color: tokens.warningStrong),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              helpDisclaimerText,
              style: theme.textTheme.bodySmall?.copyWith(color: tokens.muted),
            ),
          ),
        ],
      ),
    );
  }
}
