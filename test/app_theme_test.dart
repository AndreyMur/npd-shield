import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:npd_shield/core/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('по умолчанию тема системная', () async {
    expect(await AppTheme.loadMode(), ThemeMode.system);
  });

  test('сохранённая тема применяется между запусками', () async {
    await AppTheme.saveMode(ThemeMode.dark);

    expect(await AppTheme.loadMode(), ThemeMode.dark);
  });

  test('каждая тема сохраняется и читается', () async {
    for (final mode in ThemeMode.values) {
      await AppTheme.saveMode(mode);
      expect(await AppTheme.loadMode(), mode);
    }
  });
}
