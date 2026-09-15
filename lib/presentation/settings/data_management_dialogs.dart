import 'package:flutter/material.dart';

/// Подтверждение загрузки демонстрационных данных.
///
/// Демо-данные добавляются к текущим записям, а профиль ИП заменяется
/// демонстрационным, поэтому перед загрузкой пользователь должен явно
/// согласиться. Возвращает `true`, если загрузку подтвердили.
Future<bool> showDemoDataConfirmation(BuildContext context) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Загрузить демо-данные?'),
      content: const Text(
        'Демонстрационные операции и уведомления будут добавлены к вашим '
        'данным, а профиль ИП заменится демонстрационным. Убрать демо-данные '
        'можно полной очисткой.',
      ),
      actions: [
        TextButton(
          key: const Key('demo_load_cancel'),
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Отмена'),
        ),
        FilledButton(
          key: const Key('demo_load_confirm'),
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Загрузить'),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}

/// Подтверждение полной очистки данных.
///
/// Действие необратимо, поэтому кнопка подтверждения выделена цветом ошибки.
/// Возвращает `true`, если очистку подтвердили.
Future<bool> showDataResetConfirmation(BuildContext context) async {
  final scheme = Theme.of(context).colorScheme;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Очистить все данные?'),
      content: const Text(
        'Будут безвозвратно удалены операции, документы, договоры, отчёты, '
        'уведомления и профиль ИП. Приложение вернётся к первому запуску. '
        'Это действие нельзя отменить.',
      ),
      actions: [
        TextButton(
          key: const Key('data_reset_cancel'),
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Отмена'),
        ),
        FilledButton(
          key: const Key('data_reset_confirm'),
          style: FilledButton.styleFrom(
            backgroundColor: scheme.error,
            foregroundColor: scheme.onError,
          ),
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Очистить'),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}
