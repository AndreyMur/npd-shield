import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:npd_shield/core/theme/app_theme.dart';
import 'package:npd_shield/core/theme/app_typography.dart';

/// Golden-тесты типо-шкалы на кириллице.
///
/// Эталоны сгенерированы на Windows (`flutter test --update-goldens`).
/// Растеризация шрифтов зависит от платформы, поэтому на других ОС тесты
/// пропускаются, чтобы не давать ложных падений в Linux-CI.
void main() {
  final skipGolden = !Platform.isWindows;

  setUpAll(() async {
    await _loadFonts();
  });

  testWidgets(
    'типо-шкала на кириллице',
    (tester) async {
      tester.view.physicalSize = const Size(460, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(null),
          home: const Scaffold(
            body: Center(child: _TypographySample()),
          ),
        ),
      );

      await expectLater(
        find.byKey(const Key('typography_golden')),
        matchesGoldenFile('goldens/typography_scale.png'),
      );
    },
    skip: skipGolden,
  );
}

class _TypographySample extends StatelessWidget {
  const _TypographySample();

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      key: const Key('typography_golden'),
      child: Container(
        width: 420,
        height: 560,
        color: Colors.white,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: const [
            Text('Доход', style: AppTypography.display),
            SizedBox(height: 12),
            Text('Типографика', style: AppTypography.headline),
            SizedBox(height: 12),
            Text('Заголовок карточки', style: AppTypography.title),
            SizedBox(height: 12),
            Text(
              'Основной текст: Ёё Жж Щщ Ъъ Ыы Ээ Юю Яя',
              style: AppTypography.body,
            ),
            SizedBox(height: 12),
            Text('Подпись и лейбл', style: AppTypography.label),
            SizedBox(height: 20),
            Text('1 234 567,89 ₽', style: AppTypography.metricLarge),
            SizedBox(height: 8),
            Text('987 654,32 ₽', style: AppTypography.metric),
            SizedBox(height: 8),
            Text('янв 2026', style: AppTypography.metricLabel),
          ],
        ),
      ),
    );
  }
}

Future<void> _loadFonts() async {
  await _register(AppFonts.inter, const [
    'Inter-Regular.ttf',
    'Inter-Medium.ttf',
    'Inter-SemiBold.ttf',
    'Inter-Bold.ttf',
  ]);
  await _register(AppFonts.jetBrainsMono, const [
    'JetBrainsMono-Regular.ttf',
    'JetBrainsMono-Medium.ttf',
    'JetBrainsMono-Bold.ttf',
  ]);
}

Future<void> _register(String family, List<String> files) async {
  final loader = FontLoader(family);
  for (final file in files) {
    loader.addFont(_readFont(file));
  }
  await loader.load();
}

Future<ByteData> _readFont(String file) async {
  final bytes = await File('assets/fonts/$file').readAsBytes();
  return ByteData.sublistView(bytes);
}
