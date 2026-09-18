import 'package:flutter/material.dart';

import '../../core/theme/app_tokens.dart';
import '../../core/widgets/widgets.dart';

/// Экран раздела «Помощь».
///
/// Содержит справочник по приложению. На текущем этапе — базовый скаффолд:
/// заголовок, поле поиска (пока неактивное) и пустой список разделов.
class HelpScreen extends StatelessWidget {
  /// Открывает боковое меню навигации. Если задан, в шапке появляется
  /// кнопка-гамбургер (используется на телефоне).
  final VoidCallback? onOpenMenu;

  const HelpScreen({super.key, this.onOpenMenu});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('help_screen'),
      appBar: AppBar(
        title: const Text('Помощь'),
        leading: onOpenMenu == null
            ? null
            : AppMenuButton(
                key: const Key('help_menu_button'),
                onPressed: onOpenMenu!,
              ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.sm,
                AppSpacing.md,
                AppSpacing.xs,
              ),
              child: const AppTextField(
                key: Key('help_search_field'),
                enabled: false,
                hint: 'Поиск по справочнику',
                prefixIcon: Icon(Icons.search),
              ),
            ),
            const Expanded(
              child: AppEmptyState(
                key: Key('help_sections_empty'),
                icon: Icons.help_outline,
                title: 'Справочник пока пуст',
                message:
                    'Скоро здесь появятся статьи по всем разделам приложения.',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
