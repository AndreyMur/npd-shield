import 'package:flutter/material.dart';

import '../../core/theme/app_tokens.dart';
import '../../data/models/risk_marker.dart';
import '../../domain/risk/safety_index.dart';

/// Визуальные параметры уровней риска.
///
/// Уровень передаётся одновременно цветом (семантический токен темы), иконкой
/// и текстовой меткой — цвет не является единственным носителем смысла.
extension RiskSeverityVisuals on RiskSeverity {
  /// Семантический цвет уровня из токенов текущей темы.
  Color color(AppTokens tokens) => switch (this) {
    RiskSeverity.critical => tokens.destructive,
    RiskSeverity.medium => tokens.warningStrong,
    RiskSeverity.low => tokens.success,
  };

  /// Иконка уровня — различается для каждого уровня риска.
  IconData get icon => switch (this) {
    RiskSeverity.critical => Icons.gpp_bad_outlined,
    RiskSeverity.medium => Icons.warning_amber_rounded,
    RiskSeverity.low => Icons.info_outline,
  };
}

/// Визуальные параметры зон индекса безопасности.
extension SafetyLevelVisuals on SafetyLevel {
  /// Семантический цвет зоны из токенов текущей темы.
  Color color(AppTokens tokens) => switch (this) {
    SafetyLevel.green => tokens.success,
    SafetyLevel.yellow => tokens.warningStrong,
    SafetyLevel.red => tokens.destructive,
  };

  /// Иконка зоны — различается для каждой зоны безопасности.
  IconData get icon => switch (this) {
    SafetyLevel.green => Icons.verified_outlined,
    SafetyLevel.yellow => Icons.warning_amber_rounded,
    SafetyLevel.red => Icons.gpp_bad_outlined,
  };
}
