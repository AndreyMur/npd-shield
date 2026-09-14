import 'package:url_launcher/url_launcher.dart';

/// Открывает внешние приложения по deep link.
///
/// Абстракция над `url_launcher` позволяет подменять запуск в тестах и
/// проверять сценарии «приложение установлено / не установлено».
abstract class ExternalAppLauncher {
  /// Установлено ли приложение, способное открыть [uri].
  Future<bool> isInstalled(Uri uri);

  /// Открывает [uri] во внешнем приложении.
  ///
  /// Возвращает `false`, если приложение не установлено или запуск не удался.
  Future<bool> open(Uri uri);
}

/// Реализация [ExternalAppLauncher] на базе пакета `url_launcher`.
///
/// Deep link открывается в режиме [LaunchMode.externalApplication], то есть
/// во внешнем приложении «Мой налог», а не во встроенном браузере.
class UrlLauncherExternalAppLauncher implements ExternalAppLauncher {
  const UrlLauncherExternalAppLauncher();

  @override
  Future<bool> isInstalled(Uri uri) => canLaunchUrl(uri);

  @override
  Future<bool> open(Uri uri) async {
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }
}
