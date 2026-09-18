import '../../domain/help/help_article.dart';
import '../../domain/help/help_search.dart';
import '../help_articles.dart';

/// Репозиторий контента справочника «Помощь».
///
/// Контент встроен в приложение и доступен офлайн. Методы синхронные: набор
/// статей неизменен во время работы, поэтому чтение не требует ввода-вывода.
/// Добавление новой статьи сводится к дополнению `builtInHelpArticles` и не
/// затрагивает навигацию или экран справочника.
abstract class HelpRepository {
  /// Возвращает все статьи в порядке, заданном контентом.
  List<HelpArticle> getArticles();

  /// Возвращает статьи указанного раздела в порядке контента.
  List<HelpArticle> getArticlesBySection(HelpSection section);

  /// Возвращает статью по стабильному идентификатору или `null`.
  HelpArticle? getArticleById(String id);

  /// Возвращает разделы, в которых есть хотя бы одна статья, в порядке
  /// объявления [HelpSection].
  List<HelpSection> getSections();

  /// Возвращает статьи для блока «С чего начать».
  List<HelpArticle> getQuickStartArticles();

  /// Ищет статьи по заголовку и содержимому.
  ///
  /// Поиск выполняется офлайн по встроенному контенту и не требует сети.
  /// Пустой запрос возвращает пустой список.
  List<HelpArticle> search(String query);
}

/// Реализация репозитория на основе встроенного набора статей.
class EmbeddedHelpRepository implements HelpRepository {
  /// Статьи справочника. По умолчанию — встроенный контент приложения.
  final List<HelpArticle> articles;

  const EmbeddedHelpRepository({this.articles = builtInHelpArticles});

  @override
  List<HelpArticle> getArticles() => List.unmodifiable(articles);

  @override
  List<HelpArticle> getArticlesBySection(HelpSection section) {
    return List.unmodifiable(
      articles.where((article) => article.section == section),
    );
  }

  @override
  HelpArticle? getArticleById(String id) {
    for (final article in articles) {
      if (article.id == id) return article;
    }
    return null;
  }

  @override
  List<HelpSection> getSections() {
    final present = articles.map((article) => article.section).toSet();
    return List.unmodifiable(
      HelpSection.values.where(present.contains),
    );
  }

  @override
  List<HelpArticle> getQuickStartArticles() {
    return List.unmodifiable(articles.where((article) => article.quickStart));
  }

  @override
  List<HelpArticle> search(String query) {
    return searchHelpArticles(articles, query);
  }
}
