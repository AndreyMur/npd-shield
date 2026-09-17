import '../../data/models/app_notification.dart';

/// Настройки уведомлений: включённые типы, пороги лимита, сроки напоминаний
/// и тихие часы.
///
/// Модель чистая (без зависимости от Flutter), чтобы движок уведомлений можно
/// было проверять unit-тестами и запускать в фоновом изоляте. Время тихих
/// часов хранится в минутах от полуночи: так модель не зависит от `TimeOfDay`.
class NotificationSettings {
  /// Включены ли уведомления о лимите.
  final bool limitEnabled;

  /// Включены ли напоминания о счетах.
  final bool invoiceEnabled;

  /// Включены ли предупреждения об аномалиях.
  final bool anomalyEnabled;

  /// Включён ли еженедельный дайджест.
  final bool digestEnabled;

  /// Включены ли тихие часы.
  final bool quietHoursEnabled;

  /// Начало тихих часов в минутах от полуночи (по умолчанию 22:00).
  final int quietHoursStartMinutes;

  /// Конец тихих часов в минутах от полуночи (по умолчанию 08:00).
  final int quietHoursEndMinutes;

  /// Пороги лимита (доли от 0 до 1), при пересечении которых формируется
  /// уведомление. По умолчанию 80/90/95/100%.
  final List<double> limitThresholds;

  /// Сроки напоминаний о счетах в днях до оплаты. По умолчанию 14/7/3.
  final Set<int> invoiceReminderDays;

  const NotificationSettings({
    this.limitEnabled = true,
    this.invoiceEnabled = true,
    this.anomalyEnabled = true,
    this.digestEnabled = true,
    this.quietHoursEnabled = true,
    this.quietHoursStartMinutes = 22 * 60,
    this.quietHoursEndMinutes = 8 * 60,
    this.limitThresholds = const [0.8, 0.9, 0.95, 1.0],
    this.invoiceReminderDays = const {14, 7, 3},
  });

  /// Настройки по умолчанию: все типы включены, тихие часы 22:00–08:00.
  static const NotificationSettings defaults = NotificationSettings();

  /// Включён ли указанный тип уведомлений.
  bool isTypeEnabled(NotificationType type) => switch (type) {
    NotificationType.limit => limitEnabled,
    NotificationType.invoice => invoiceEnabled,
    NotificationType.anomaly => anomalyEnabled,
    NotificationType.digest => digestEnabled,
  };

  /// Попадает ли момент [time] в тихие часы.
  ///
  /// Тихие часы могут пересекать полночь (например, 22:00–08:00): тогда
  /// условие — «время после начала или до конца». Если начало и конец
  /// совпадают, тихие часы считаются выключенными.
  bool isQuietAt(DateTime time) {
    if (!quietHoursEnabled) return false;
    final start = _normalizeMinutes(quietHoursStartMinutes);
    final end = _normalizeMinutes(quietHoursEndMinutes);
    if (start == end) return false;
    final minutes = time.hour * 60 + time.minute;
    if (start < end) return minutes >= start && minutes < end;
    return minutes >= start || minutes < end;
  }

  /// Копия настроек с изменёнными полями.
  NotificationSettings copyWith({
    bool? limitEnabled,
    bool? invoiceEnabled,
    bool? anomalyEnabled,
    bool? digestEnabled,
    bool? quietHoursEnabled,
    int? quietHoursStartMinutes,
    int? quietHoursEndMinutes,
    List<double>? limitThresholds,
    Set<int>? invoiceReminderDays,
  }) {
    return NotificationSettings(
      limitEnabled: limitEnabled ?? this.limitEnabled,
      invoiceEnabled: invoiceEnabled ?? this.invoiceEnabled,
      anomalyEnabled: anomalyEnabled ?? this.anomalyEnabled,
      digestEnabled: digestEnabled ?? this.digestEnabled,
      quietHoursEnabled: quietHoursEnabled ?? this.quietHoursEnabled,
      quietHoursStartMinutes:
          quietHoursStartMinutes ?? this.quietHoursStartMinutes,
      quietHoursEndMinutes:
          quietHoursEndMinutes ?? this.quietHoursEndMinutes,
      limitThresholds: limitThresholds ?? this.limitThresholds,
      invoiceReminderDays: invoiceReminderDays ?? this.invoiceReminderDays,
    );
  }

  /// Представление для хранения в `SharedPreferences` (JSON-совместимое).
  Map<String, Object?> toJson() => {
    'limitEnabled': limitEnabled,
    'invoiceEnabled': invoiceEnabled,
    'anomalyEnabled': anomalyEnabled,
    'digestEnabled': digestEnabled,
    'quietHoursEnabled': quietHoursEnabled,
    'quietHoursStartMinutes': quietHoursStartMinutes,
    'quietHoursEndMinutes': quietHoursEndMinutes,
    'limitThresholds': [...limitThresholds]..sort(),
    'invoiceReminderDays': invoiceReminderDays.toList()..sort(),
  };

  /// Восстанавливает настройки из [json], подставляя значения по умолчанию
  /// для отсутствующих или некорректных полей.
  factory NotificationSettings.fromJson(Map<String, Object?> json) {
    const fallback = NotificationSettings.defaults;
    return NotificationSettings(
      limitEnabled: _asBool(json['limitEnabled'], fallback.limitEnabled),
      invoiceEnabled: _asBool(json['invoiceEnabled'], fallback.invoiceEnabled),
      anomalyEnabled: _asBool(json['anomalyEnabled'], fallback.anomalyEnabled),
      digestEnabled: _asBool(json['digestEnabled'], fallback.digestEnabled),
      quietHoursEnabled: _asBool(
        json['quietHoursEnabled'],
        fallback.quietHoursEnabled,
      ),
      quietHoursStartMinutes: _asMinutes(
        json['quietHoursStartMinutes'],
        fallback.quietHoursStartMinutes,
      ),
      quietHoursEndMinutes: _asMinutes(
        json['quietHoursEndMinutes'],
        fallback.quietHoursEndMinutes,
      ),
      limitThresholds: _asDoubleList(
        json['limitThresholds'],
        fallback.limitThresholds,
      ),
      invoiceReminderDays: _asIntSet(
        json['invoiceReminderDays'],
        fallback.invoiceReminderDays,
      ),
    );
  }

  static int _normalizeMinutes(int value) => value.clamp(0, 24 * 60 - 1);

  static bool _asBool(Object? value, bool fallback) =>
      value is bool ? value : fallback;

  static int _asMinutes(Object? value, int fallback) {
    if (value is num) {
      final rounded = value.round();
      return rounded >= 0 && rounded < 24 * 60 ? rounded : fallback;
    }
    return fallback;
  }

  static List<double> _asDoubleList(Object? value, List<double> fallback) {
    if (value is! List || value.isEmpty) return fallback;
    final result = <double>[];
    for (final item in value) {
      if (item is num && item > 0) result.add(item.toDouble());
    }
    return result.isEmpty ? fallback : result;
  }

  static Set<int> _asIntSet(Object? value, Set<int> fallback) {
    if (value is! List || value.isEmpty) return fallback;
    final result = <int>{};
    for (final item in value) {
      if (item is num && item > 0) result.add(item.round());
    }
    return result.isEmpty ? fallback : result;
  }
}
