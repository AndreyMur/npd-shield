/// Модель справочника приложения «Помощь».
///
/// Справочник — это офлайн-набор статей, сгруппированных по разделам
/// приложения. Статья состоит из краткого описания, пошаговой инструкции,
/// частых вопросов/подсказок и ссылок на смежные статьи. Модель не зависит
/// от Flutter и хранилища: контент поставляется вместе с приложением
/// (см. `lib/data/help_articles.dart`).
library;

/// Действующий дисклеймер о справочном характере материалов справочника.
///
/// Показывается в каждой статье, чтобы пользователь понимал: материалы
/// носят справочный характер и не заменяют консультацию специалиста.
const String helpDisclaimerText =
    'Материалы справочника носят справочный характер и не заменяют '
    'консультацию специалиста. Перед принятием решений проверяйте актуальные '
    'требования законодательства.';

/// Раздел справочника, к которому относится статья.
///
/// Порядок объявления задаёт порядок вывода в оглавлении: сначала блок
/// «С чего начать», затем 11 рабочих разделов приложения, затем сквозные
/// сценарии. [isAppSection] отличает рабочие разделы от вспомогательных.
enum HelpSection {
  /// Вводный блок для новых пользователей.
  gettingStarted('С чего начать'),

  /// Раздел «Дашборд».
  dashboard('Дашборд'),

  /// Раздел «Операции».
  operations('Операции'),

  /// Раздел «Клиенты».
  clients('Клиенты'),

  /// Раздел «Счета».
  invoices('Счета'),

  /// Раздел «Шаблоны».
  templates('Шаблоны'),

  /// Раздел «Договоры».
  contracts('Договоры'),

  /// Раздел «Документы».
  documents('Документы'),

  /// Раздел «Проверка» (Risk Shield).
  riskShield('Проверка'),

  /// Раздел «Уведомления».
  notifications('Уведомления'),

  /// Раздел «Отчёты».
  reports('Отчёты'),

  /// Раздел «Настройки».
  settings('Настройки'),

  /// Сквозные сценарии, объединяющие несколько разделов.
  scenarios('Сквозные сценарии');

  const HelpSection(this.label);

  /// Человекочитаемое название раздела для оглавления и результатов поиска.
  final String label;

  /// Относится ли раздел к 11 рабочим разделам приложения.
  ///
  /// Вводный блок и сквозные сценарии — вспомогательные и не входят в
  /// обязательный набор разделов.
  bool get isAppSection => switch (this) {
    HelpSection.gettingStarted || HelpSection.scenarios => false,
    HelpSection.dashboard ||
    HelpSection.operations ||
    HelpSection.clients ||
    HelpSection.invoices ||
    HelpSection.templates ||
    HelpSection.contracts ||
    HelpSection.documents ||
    HelpSection.riskShield ||
    HelpSection.notifications ||
    HelpSection.reports ||
    HelpSection.settings => true,
  };
}

/// Частый вопрос или подсказка внутри статьи.
///
/// [question] — формулировка вопроса так, как её ищет пользователь,
/// [answer] — короткий практичный ответ.
class HelpFaqItem {
  /// Вопрос пользователя.
  final String question;

  /// Ответ или подсказка.
  final String answer;

  const HelpFaqItem({required this.question, required this.answer});
}

/// Статья справочника.
///
/// [id] — стабильный строковый идентификатор, по которому на статью ссылаются
/// связанные материалы. Он не зависит от порядка и заголовка, поэтому
/// добавление новых статей не требует правок навигационной логики.
class HelpArticle {
  /// Стабильный идентификатор статьи.
  final String id;

  /// Раздел, к которому относится статья.
  final HelpSection section;

  /// Заголовок статьи.
  final String title;

  /// Краткое описание: что это и зачем (1–3 предложения).
  final String summary;

  /// Пошаговая инструкция «как пользоваться».
  final List<String> steps;

  /// Частые вопросы и подсказки (может быть пустым).
  final List<HelpFaqItem> faq;

  /// Идентификаторы связанных статей.
  final List<String> relatedIds;

  /// Показывать ли статью в блоке «С чего начать».
  final bool quickStart;

  const HelpArticle({
    required this.id,
    required this.section,
    required this.title,
    required this.summary,
    this.steps = const [],
    this.faq = const [],
    this.relatedIds = const [],
    this.quickStart = false,
  });
}
