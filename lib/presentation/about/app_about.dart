import 'package:flutter/material.dart';

/// Название приложения.
const String appName = 'NPD Shield';

/// Текущая версия приложения.
const String appVersion = '1.0.0';

/// Краткое описание возможностей приложения.
const String appDescription =
    'Помощник самозанятого на НПД: учёт доходов и расходов, лимит '
    '2,4 млн ₽, налог 6%, генератор договоров, чеков и актов, проверка '
    'контрагентов и уведомления.';

/// Показывает системный диалог «О приложении» с версией и описанием.
void showAppAboutDialog(BuildContext context) {
  showAboutDialog(
    context: context,
    applicationName: appName,
    applicationVersion: appVersion,
    applicationIcon: const Icon(Icons.shield_outlined, size: 40),
    children: const [Text(appDescription)],
  );
}
