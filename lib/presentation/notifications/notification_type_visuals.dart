import 'package:flutter/material.dart';

import '../../data/models/app_notification.dart';

/// Визуальные атрибуты типа уведомления для центра уведомлений.
extension NotificationTypeVisuals on NotificationType {
  /// Иконка типа для карточки и фильтров.
  IconData get icon => switch (this) {
    NotificationType.limit => Icons.speed_outlined,
    NotificationType.invoice => Icons.request_quote_outlined,
    NotificationType.anomaly => Icons.warning_amber_outlined,
    NotificationType.digest => Icons.insights_outlined,
  };

  /// Акцентный цвет типа в заданной цветовой схеме.
  Color color(ColorScheme scheme) => switch (this) {
    NotificationType.limit => scheme.primary,
    NotificationType.invoice => scheme.tertiary,
    NotificationType.anomaly => scheme.error,
    NotificationType.digest => scheme.secondary,
  };
}
