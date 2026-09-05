import 'package:flutter/material.dart';

import '../../data/models/contract_template.dart';

/// Визуальные константы сфер деятельности для библиотеки шаблонов.
///
/// Цветовая маркировка соответствует дизайн-системе приложения:
/// IT — синий, Логистика — оранжевый, универсальные — нейтральный серо-синий.
extension TemplateSphereVisuals on TemplateSphere {
  Color get color => switch (this) {
    TemplateSphere.it => const Color(0xFF2196F3),
    TemplateSphere.logistics => const Color(0xFFFF9800),
    TemplateSphere.universal => const Color(0xFF607D8B),
  };

  IconData get icon => switch (this) {
    TemplateSphere.it => Icons.code,
    TemplateSphere.logistics => Icons.local_shipping,
    TemplateSphere.universal => Icons.description_outlined,
  };
}
