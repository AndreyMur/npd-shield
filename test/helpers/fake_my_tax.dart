import 'package:npd_shield/data/deep_link/clipboard_writer.dart';
import 'package:npd_shield/data/deep_link/external_app_launcher.dart';

/// Фейковый запуск внешнего приложения для тестов deep link.
class FakeExternalAppLauncher implements ExternalAppLauncher {
  /// Установлено ли приложение «Мой налог».
  final bool installed;

  /// Результат попытки открыть приложение.
  final bool launchResult;

  /// Записанные проверки установки.
  final List<Uri> checked = [];

  /// Записанные попытки открытия.
  final List<Uri> opened = [];

  FakeExternalAppLauncher({this.installed = true, this.launchResult = true});

  @override
  Future<bool> isInstalled(Uri uri) async {
    checked.add(uri);
    return installed;
  }

  @override
  Future<bool> open(Uri uri) async {
    opened.add(uri);
    return launchResult;
  }
}

/// Фейковый буфер обмена: запоминает скопированные строки.
class FakeClipboardWriter implements ClipboardWriter {
  final List<String> writes = [];

  @override
  Future<void> write(String text) async {
    writes.add(text);
  }
}
