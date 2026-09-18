import 'package:flutter/material.dart';

import '../../core/theme/app_icons.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/theme/app_typography.dart';

/// Боковое меню навигации для телефона.
///
/// Показывает все разделы приложения списком «иконка + текст» с уменьшенным
/// шрифтом. Активный раздел выделен цветом и заполненной иконкой, у пункта
/// «Уведомления» может отображаться счётчик непрочитанных.
class HomeMenuDrawer extends StatelessWidget {
  /// Индекс выбранного раздела.
  final int selectedIndex;

  /// Разделы в порядке отображения.
  final List<NavigationDestination> destinations;

  /// Вызывается при выборе раздела.
  final ValueChanged<int> onSelected;

  const HomeMenuDrawer({
    super.key,
    required this.selectedIndex,
    required this.destinations,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = AppTokens.of(context);
    return Drawer(
      key: const Key('home_menu_drawer'),
      backgroundColor: tokens.surface,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  AppIcon(
                    Icons.shield,
                    size: AppIconSize.lg,
                    color: tokens.primary,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text('NPD Shield', style: theme.textTheme.titleMedium),
                ],
              ),
            ),
            Divider(height: 1, color: tokens.border),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                itemCount: destinations.length,
                itemBuilder: (context, index) {
                  final destination = destinations[index];
                  final selected = index == selectedIndex;
                  return ListTile(
                    key: Key('home_menu_item_$index'),
                    selected: selected,
                    selectedTileColor: tokens.primary.withValues(alpha: 0.12),
                    leading: selected
                        ? destination.selectedIcon
                        : destination.icon,
                    title: Text(
                      destination.label,
                      style: AppTypography.menuLabel.copyWith(
                        color: selected ? tokens.primary : tokens.onSurface,
                      ),
                    ),
                    onTap: () => onSelected(index),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
