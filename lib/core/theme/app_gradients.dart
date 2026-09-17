import 'package:flutter/material.dart';

/// Градиентные токены дизайн-системы.
///
/// Брендовый градиент применяется на ключевых CTA, доход — на метриках
/// прибыли, риск — на индикаторах опасности, лимит — на шкале НПД.
abstract final class AppGradients {
  /// Брендовый градиент для светлой темы (primary → secondary).
  static const brand = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1E40AF), Color(0xFF3B82F6)],
  );

  /// Брендовый градиент для тёмной темы: светлее для контраста на тёмном фоне.
  static const brandDark = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF3B82F6), Color(0xFF60A5FA)],
  );

  /// Градиент дохода (success).
  static const income = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF047857), Color(0xFF10B981)],
  );

  /// Градиент риска (warning → destructive).
  static const risk = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFFF59E0B), Color(0xFFDC2626)],
  );

  /// Градиент шкалы лимита НПД (success → warning → destructive).
  static const limit = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFF059669), Color(0xFFF59E0B), Color(0xFFDC2626)],
  );
}

/// Цвета сфер деятельности.
///
/// Сфера «Все» не имеет собственного цвета — используется брендовый градиент.
abstract final class SphereColors {
  /// IT — синий.
  static const it = Color(0xFF2196F3);

  /// Логистика — оранжевый.
  static const logistics = Color(0xFFFF9800);
}
