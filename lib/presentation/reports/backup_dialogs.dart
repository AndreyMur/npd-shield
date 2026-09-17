import 'package:flutter/material.dart';

/// Подтверждение восстановления данных из резервной копии.
///
/// Импорт полностью заменяет текущие данные, поэтому перед восстановлением
/// пользователь должен явно согласиться. Возвращает `true`, если импорт
/// подтвердили.
Future<bool> showBackupImportConfirmation(
  BuildContext context, {
  required String fileName,
}) async {
  final scheme = Theme.of(context).colorScheme;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Восстановить данные из копии?'),
      content: Text(
        'Файл «$fileName» заменит все текущие данные приложения: операции, '
        'клиентов, счета, документы, договоры, отчёты, уведомления, профиль и '
        'сферы деятельности. Это действие нельзя отменить.',
      ),
      actions: [
        TextButton(
          key: const Key('backup_import_cancel'),
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('Отмена'),
        ),
        FilledButton(
          key: const Key('backup_import_confirm'),
          style: FilledButton.styleFrom(
            backgroundColor: scheme.error,
            foregroundColor: scheme.onError,
          ),
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: const Text('Восстановить'),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}
