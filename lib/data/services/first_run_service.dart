import 'package:shared_preferences/shared_preferences.dart';

/// Режим старта, выбранный пользователем в онбординге.
enum StartMode {
  /// Начать с нуля — пустые, но рабочие экраны и ручное заполнение данных.
  fromScratch,

  /// Загрузить демонстрационные данные для ознакомления.
  demo;

  /// Стабильное строковое представление для локального хранилища.
  String get storageValue => name;

  /// Восстанавливает режим из значения хранилища, если оно известно.
  static StartMode? fromStorage(String? value) {
    for (final mode in StartMode.values) {
      if (mode.name == value) return mode;
    }
    return null;
  }
}

/// Хранит факт завершения онбординга и выбранный режим старта.
///
/// Значения лежат в локальном хранилище и переживают перезапуск приложения,
/// поэтому онбординг не показывается повторно, а приложение не теряет выбор
/// пользователя между запусками.
abstract class FirstRunService {
  /// Пройден ли онбординг хотя бы один раз.
  Future<bool> isOnboardingCompleted();

  /// Выбранный режим старта или `null`, если онбординг не пройден.
  Future<StartMode?> getStartMode();

  /// Отмечает онбординг пройденным и сохраняет выбранный режим.
  Future<void> completeOnboarding(StartMode mode);

  /// Сбрасывает состояние к «первому запуску» (используется при очистке данных).
  Future<void> reset();
}

/// Реализация [FirstRunService] поверх `SharedPreferences`.
class SharedPrefsFirstRunService implements FirstRunService {
  static const _completedKey = 'onboarding_completed';
  static const _startModeKey = 'onboarding_start_mode';

  @override
  Future<bool> isOnboardingCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_completedKey) ?? false;
  }

  @override
  Future<StartMode?> getStartMode() async {
    final prefs = await SharedPreferences.getInstance();
    return StartMode.fromStorage(prefs.getString(_startModeKey));
  }

  @override
  Future<void> completeOnboarding(StartMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_completedKey, true);
    await prefs.setString(_startModeKey, mode.storageValue);
  }

  @override
  Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_completedKey);
    await prefs.remove(_startModeKey);
  }
}
