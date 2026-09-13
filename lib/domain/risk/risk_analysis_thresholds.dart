/// Пороги чувствительности анализатора рисков.
///
/// Значения подобраны при калибровке на тестовой базе договоров
/// (`test/fixtures/risk_contract_corpus.dart`) и снижают долю
/// ложноположительных срабатываний, не теряя реальные риски.
class RiskAnalysisThresholds {
  const RiskAnalysisThresholds({
    this.minMatchLength = 3,
    this.negationWindow = 28,
    this.negationPhrases = defaultNegationPhrases,
  });

  /// Минимальная длина совпадения (без пробелов по краям).
  ///
  /// Отсекает случайные короткие срабатывания внутри других слов.
  final int minMatchLength;

  /// Ширина окна поиска отрицания перед совпадением в символах.
  ///
  /// `0` полностью отключает проверку отрицаний. Отрицание ищется только в
  /// пределах текущего предложения, поэтому безопасные оговорки вида
  /// «Договор не является трудовым договором» не считаются риском.
  final int negationWindow;

  /// Фразы-отрицания, снимающие найденный риск в том же предложении.
  ///
  /// Список намеренно узкий: одиночное «не» в конструкции «не ниже
  /// минимального размера оплаты труда» не должно отменять реальный риск.
  final List<String> negationPhrases;

  /// Фразы-отрицания по умолчанию.
  static const List<String> defaultNegationPhrases = [
    'не является',
    'не являются',
    'не носит',
    'не носят',
    'не подчиняется',
    'не подчиняются',
    'не предоставляет',
    'не предоставляются',
    'не связан',
    'не связаны',
    'не признаётся',
    'не признается',
    'не влечёт',
    'не влечет',
    'не выполняет',
    'не осуществляет',
    'не состоит',
    'не имеет',
  ];

  /// Границы предложения, за которые отрицание не переносится.
  static final RegExp _clauseBoundary = RegExp(r'[.!?;\n]');

  /// Одиночное «не»/«ни» непосредственно перед совпадением.
  static final RegExp _immediateNegation = RegExp(
    r'(?<![\p{L}])(?:не|ни)\s*$',
    caseSensitive: false,
    unicode: true,
  );

  /// Проходит ли найденный фрагмент порог по длине.
  bool acceptsMatch(String matchedText) =>
      matchedText.trim().length >= minMatchLength;

  /// Отрицается ли совпадение, начинающееся в [start], контекстом слева.
  bool isNegated(String text, int start) {
    if (negationWindow <= 0 || start <= 0) return false;
    final windowStart = (start - negationWindow).clamp(0, text.length);
    final window = text.substring(windowStart, start);
    final boundary = window.lastIndexOf(_clauseBoundary);
    final clause =
        (boundary >= 0 ? window.substring(boundary + 1) : window).toLowerCase();
    if (_immediateNegation.hasMatch(clause)) return true;
    for (final phrase in negationPhrases) {
      if (clause.contains(phrase)) return true;
    }
    return false;
  }
}
