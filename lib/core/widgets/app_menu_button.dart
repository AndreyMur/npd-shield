import 'package:flutter/material.dart';

/// Кнопка-гамбургер в шапке экрана для открытия бокового меню навигации.
///
/// Используется на всех экранах разделов на телефоне. Гарантирует
/// интерактивную область не меньше 48×48 dp и подпись «Меню» для
/// скринридеров.
class AppMenuButton extends StatelessWidget {
  /// Вызывается при нажатии.
  final VoidCallback onPressed;

  const AppMenuButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.menu),
      tooltip: 'Меню',
      onPressed: onPressed,
      constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
    );
  }
}
