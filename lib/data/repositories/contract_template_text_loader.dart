import 'package:flutter/services.dart';

import '../../data/built_in_templates.dart';

/// Загружает текст шаблона договора по его стабильному коду.
abstract class ContractTemplateTextLoader {
  /// Возвращает текст шаблона или бросает исключение, если шаблон не найден.
  Future<String> load(String code);
}

/// Читает тексты шаблонов из Assets приложения
/// (`assets/templates/<code>.txt`).
class AssetContractTemplateTextLoader implements ContractTemplateTextLoader {
  const AssetContractTemplateTextLoader();

  @override
  Future<String> load(String code) {
    return rootBundle.loadString(templateAssetPath(code));
  }
}
