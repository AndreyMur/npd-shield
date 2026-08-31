import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:npd_shield/core/theme/app_theme.dart';

void main() {
  test('AppTheme.light builds a Material 3 light theme', () {
    final theme = AppTheme.light(null);
    expect(theme.useMaterial3, isTrue);
    expect(theme.brightness, Brightness.light);
  });

  test('AppTheme.dark builds a Material 3 dark theme', () {
    final theme = AppTheme.dark(null);
    expect(theme.useMaterial3, isTrue);
    expect(theme.brightness, Brightness.dark);
  });
}
