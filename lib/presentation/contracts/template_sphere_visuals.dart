import 'package:flutter/material.dart';

import '../../core/theme/app_gradients.dart';
import '../../data/models/contract_template.dart';

/// Визуальные константы сфер деятельности для библиотеки шаблонов.
///
/// Цветовая маркировка берётся из дизайн-системы приложения:
/// IT — синий, Логистика — оранжевый, универсальные — нейтральный серо-синий.
extension TemplateSphereVisuals on TemplateSphere {
  Color get color => switch (this) {
    TemplateSphere.it => SphereColors.it,
    TemplateSphere.logistics => SphereColors.logistics,
    TemplateSphere.universal => SphereColors.universal,
  };

  IconData get icon => switch (this) {
    TemplateSphere.it => Icons.code,
    TemplateSphere.logistics => Icons.local_shipping,
    TemplateSphere.universal => Icons.description_outlined,
  };
}
