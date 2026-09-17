import 'package:flutter/material.dart';

import '../../core/theme/app_tokens.dart';
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

  /// Акцентный цвет типа на основе семантических токенов.
  Color color(AppTokens tokens) => switch (this) {
    NotificationType.limit => tokens.primary,
    NotificationType.invoice => tokens.secondary,
    NotificationType.anomaly => tokens.destructive,
    NotificationType.digest => tokens.success,
  };
}
