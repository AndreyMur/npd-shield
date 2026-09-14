import '../../data/deep_link/clipboard_writer.dart';
import '../../data/deep_link/external_app_launcher.dart';
import 'my_tax_deep_link.dart';

/// Итог попытки перейти в «Мой налог».
enum MyTaxOpenOutcome {
  /// Deep link открыт во внешнем приложении.
  opened,

  /// Приложение недоступно — данные скопированы в буфер обмена.
  copied,
}

/// Результат открытия deep link: итог, ссылка и текст для буфера обмена.
class MyTaxOpenResult {
  final MyTaxOpenOutcome outcome;
  final Uri uri;
  final String clipboardText;

  const MyTaxOpenResult({
    required this.outcome,
    required this.uri,
    required this.clipboardText,
  });

  /// Deep link успешно открыт во внешнем приложении.
  bool get opened => outcome == MyTaxOpenOutcome.opened;

  /// Сработал fallback: данные скопированы в буфер обмена.
  bool get copied => outcome == MyTaxOpenOutcome.copied;
}

/// Переход в приложение «Мой налог» с fallback на буфер обмена.
///
/// Сначала проверяет, установлено ли приложение, способное открыть deep link,
/// и пытается открыть его во внешнем приложении. Если приложение не найдено
/// или запуск не удался, данные расчёта копируются в буфер обмена, чтобы
/// пользователь мог ввести их вручную.
class MyTaxDeepLinkService {
  final ExternalAppLauncher launcher;
  final ClipboardWriter clipboard;

  const MyTaxDeepLinkService({
    this.launcher = const UrlLauncherExternalAppLauncher(),
    this.clipboard = const SystemClipboardWriter(),
  });

  /// Открывает [link] во внешнем приложении или копирует данные в буфер.
  Future<MyTaxOpenResult> open(MyTaxDeepLink link) async {
    final uri = link.uri;
    var installed = false;
    try {
      installed = await launcher.isInstalled(uri);
    } catch (_) {
      installed = false;
    }
    if (installed) {
      var launched = false;
      try {
        launched = await launcher.open(uri);
      } catch (_) {
        launched = false;
      }
      if (launched) {
        return MyTaxOpenResult(
          outcome: MyTaxOpenOutcome.opened,
          uri: uri,
          clipboardText: link.clipboardText,
        );
      }
    }
    return copy(link);
  }

  /// Копирует данные расчёта в буфер обмена.
  Future<MyTaxOpenResult> copy(MyTaxDeepLink link) async {
    final text = link.clipboardText;
    await clipboard.write(text);
    return MyTaxOpenResult(
      outcome: MyTaxOpenOutcome.copied,
      uri: link.uri,
      clipboardText: text,
    );
  }
}
