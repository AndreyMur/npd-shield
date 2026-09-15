import 'package:shared_preferences/shared_preferences.dart';

import '../models/transaction.dart';

/// Хранит выбранные пользователем сферы деятельности.
///
/// Сферы выбираются в онбординге и используются интерфейсом, чтобы показывать
/// только актуальные разделы учёта. Значения лежат в локальном хранилище и
/// переживают перезапуск приложения.
abstract class ActivitySpheresService {
  /// Выбранные сферы в порядке, заданном пользователем.
  Future<List<TransactionSphere>> load();

  /// Сохраняет выбранные сферы.
  Future<void> save(List<TransactionSphere> spheres);

  /// Сбрасывает выбор (используется при полной очистке данных).
  Future<void> reset();
}

/// Реализация [ActivitySpheresService] поверх `SharedPreferences`.
class SharedPrefsActivitySpheresService implements ActivitySpheresService {
  static const _key = 'activity_spheres';

  @override
  Future<List<TransactionSphere>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key);
    if (raw == null) return const [];
    return [
      for (final value in raw)
        ...TransactionSphere.values.where((sphere) => sphere.name == value),
    ];
  }

  @override
  Future<void> save(List<TransactionSphere> spheres) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, [
      for (final sphere in spheres) sphere.name,
    ]);
  }

  @override
  Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
