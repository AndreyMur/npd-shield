/// Офлайн-поиск по статьям справочника «Помощь».
///
/// Поиск работает по встроенному набору статей в памяти: сеть не используется,
/// поэтому результаты доступны без подключения к интернету. Совпадение ищется
/// по заголовку, краткому описанию, названию раздела, шагам инструкции,
/// вопросам и ответам. Заголовок и описание весят больше содержимого, поэтому
/// наиболее релевантные статьи оказываются выше.
library;

import 'help_article.dart';

/// Ищет статьи по запросу и возвращает их в порядке убывания релевантности.
///
/// Регистр не важен, лишние пробелы по краям запроса отбрасываются. Пустой
/// запрос возвращает пустой список — вызывающий код показывает оглавление.
List<HelpArticle> searchHelpArticles(
  List<HelpArticle> articles,
  String query,
) {
  final normalized = query.trim().toLowerCase();
  if (normalized.isEmpty) return const [];

  final matches = <({HelpArticle article, int score, int order})>[];
  for (var index = 0; index < articles.length; index++) {
    final article = articles[index];
    final score = _scoreArticle(article, normalized);
    if (score > 0) {
      matches.add((article: article, score: score, order: index));
    }
  }

  // При равной релевантности сохраняем исходный порядок контента.
  matches.sort((a, b) {
    final byScore = b.score.compareTo(a.score);
    return byScore != 0 ? byScore : a.order.compareTo(b.order);
  });

  return List.unmodifiable(
    [for (final match in matches) match.article],
  );
}

/// Считает релевантность статьи для нормализованного запроса.
///
/// Возвращает `0`, если статья не подходит. Заголовок — самый сильный сигнал,
/// затем описание и раздел; содержимое (шаги, вопросы, ответы) добавляет
/// меньший вклад, чтобы совпадения в заголовке были выше.
int _scoreArticle(HelpArticle article, String query) {
  var score = 0;

  if (article.title.toLowerCase().contains(query)) score += 100;
  if (article.summary.toLowerCase().contains(query)) score += 20;
  if (article.section.label.toLowerCase().contains(query)) score += 10;

  for (final step in article.steps) {
    if (step.toLowerCase().contains(query)) score += 5;
  }
  for (final item in article.faq) {
    if (item.question.toLowerCase().contains(query)) score += 8;
    if (item.answer.toLowerCase().contains(query)) score += 4;
  }

  return score;
}
