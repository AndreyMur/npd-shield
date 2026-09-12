import '../../data/models/contract_template.dart';

/// Критерии поиска и фильтрации библиотеки шаблонов.
class TemplateFilter {
  /// Поисковый запрос по названию, описанию, категории, ОКВЭД и примеру.
  final String query;

  /// Выбранная сфера (категория) или `null` — все категории.
  final TemplateSphere? sphere;

  const TemplateFilter({this.query = '', this.sphere});

  /// Есть ли активные условия фильтрации.
  bool get isActive => query.trim().isNotEmpty || sphere != null;
}

/// Фильтрует и упорядочивает шаблоны по [filter].
///
/// Поиск нечувствителен к регистру и ищет совпадение в названии, описании,
/// названии категории, коде ОКВЭД и примере заполнения. Рекомендованные
/// шаблоны поднимаются в начало списка, далее сортировка по сфере и названию.
List<Template> filterTemplates(
  List<Template> templates, {
  TemplateFilter filter = const TemplateFilter(),
}) {
  final query = filter.query.trim().toLowerCase();
  final result = templates.where((template) {
    if (filter.sphere != null && template.sphere != filter.sphere) {
      return false;
    }
    if (query.isEmpty) return true;
    return _searchIndex(template).contains(query);
  }).toList();

  result.sort((a, b) {
    if (a.recommended != b.recommended) {
      return a.recommended ? -1 : 1;
    }
    final bySphere = a.sphere.index.compareTo(b.sphere.index);
    return bySphere != 0 ? bySphere : a.title.compareTo(b.title);
  });
  return result;
}

String _searchIndex(Template template) {
  return [
    template.title,
    template.description,
    template.sphere.category,
    template.sphere.label,
    template.okved,
    template.example,
  ].join(' ').toLowerCase();
}
