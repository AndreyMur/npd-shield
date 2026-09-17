import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:npd_shield/core/theme/app_theme.dart';
import 'package:npd_shield/core/theme/app_tokens.dart';
import 'package:npd_shield/core/widgets/widgets.dart';

/// Находит цвет focus-кольца у кнопки (foreground-рамка AppButton).
Color? _focusRingColor(WidgetTester tester) {
  final boxes = tester.widgetList<DecoratedBox>(
    find.descendant(
      of: find.byType(AppButton),
      matching: find.byType(DecoratedBox),
    ),
  );
  for (final box in boxes) {
    if (box.position != DecorationPosition.foreground) continue;
    final decoration = box.decoration;
    if (decoration is BoxDecoration && decoration.border is Border) {
      return (decoration.border as Border).top.color;
    }
  }
  return null;
}

/// Находит декорацию Ink внутри AppButton.
BoxDecoration _buttonInkDecoration(WidgetTester tester) {
  final ink = tester.widget<Ink>(
    find.descendant(of: find.byType(AppButton), matching: find.byType(Ink)),
  );
  return ink.decoration! as BoxDecoration;
}

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  ThemeData? theme,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: theme ?? AppTheme.light(null),
      home: Scaffold(body: Center(child: child)),
    ),
  );
}

void main() {
  final tokens = AppTokens.light;

  group('Карточки (#210)', () {
    testWidgets('AppCard рендерит содержимое и реагирует на нажатие',
        (tester) async {
      var tapped = false;
      await _pump(
        tester,
        AppCard(onTap: () => tapped = true, child: const Text('Карточка')),
      );

      expect(find.text('Карточка'), findsOneWidget);
      expect(find.byType(AnimatedScale), findsOneWidget);
      await tester.tap(find.text('Карточка'));
      expect(tapped, isTrue);
    });

    testWidgets('AppGradientCard использует брендовый градиент и onPrimary',
        (tester) async {
      await _pump(
        tester,
        const AppGradientCard(child: Text('Градиент')),
      );

      expect(find.text('Градиент'), findsOneWidget);
      final ink = tester.widget<Ink>(
        find.descendant(
          of: find.byType(AppGradientCard),
          matching: find.byType(Ink),
        ),
      );
      expect((ink.decoration! as BoxDecoration).gradient, tokens.brandGradient);

      final text = tester.widget<Text>(find.text('Градиент'));
      expect(text.style?.color, isNull);
      final merged = DefaultTextStyle.of(
        tester.element(find.text('Градиент')),
      ).style.color;
      expect(merged, tokens.onPrimary);
    });

    testWidgets('AppMetricCard показывает подпись, значение и caption',
        (tester) async {
      await _pump(
        tester,
        AppMetricCard(
          label: 'Доход',
          value: '1 000,00 ₽',
          caption: 'за месяц',
          icon: Icons.trending_up,
          accent: tokens.success,
        ),
      );

      expect(find.text('Доход'), findsOneWidget);
      expect(find.text('1 000,00 ₽'), findsOneWidget);
      expect(find.text('за месяц'), findsOneWidget);
      expect(find.byIcon(Icons.trending_up), findsOneWidget);
    });
  });

  group('Кнопки (#211)', () {
    testWidgets('primary использует градиент, touch-target ≥48 dp',
        (tester) async {
      await _pump(
        tester,
        AppButton(label: 'Дальше', onPressed: () {}),
      );

      expect(_buttonInkDecoration(tester).gradient, tokens.brandGradient);
      expect(tester.getSize(find.byType(AppButton)).height,
          greaterThanOrEqualTo(48));
    });

    testWidgets('secondary и destructive используют семантические цвета',
        (tester) async {
      await _pump(
        tester,
        AppButton(
          label: 'Вторичная',
          variant: AppButtonVariant.secondary,
          onPressed: () {},
        ),
      );
      expect(
        (_buttonInkDecoration(tester).border as Border).top.color,
        tokens.primary,
      );

      await _pump(
        tester,
        AppButton(
          label: 'Удалить',
          variant: AppButtonVariant.destructive,
          onPressed: () {},
        ),
      );
      expect(_buttonInkDecoration(tester).color, tokens.destructive);
    });

    testWidgets('text-вариант рендерит TextButton', (tester) async {
      await _pump(
        tester,
        AppButton(
          label: 'Текст',
          variant: AppButtonVariant.text,
          onPressed: () {},
        ),
      );

      expect(find.byType(TextButton), findsOneWidget);
      expect(find.text('Текст'), findsOneWidget);
    });

    testWidgets('disabled-кнопка не нажимается и теряет акцент',
        (tester) async {
      var tapped = false;
      await _pump(
        tester,
        AppButton(label: 'Недоступно', onPressed: null),
      );

      expect(_buttonInkDecoration(tester).gradient, isNull);
      expect(_buttonInkDecoration(tester).color, tokens.surfaceVariant);
      await tester.tap(find.text('Недоступно'));
      expect(tapped, isFalse);
    });

    testWidgets('loading показывает индикатор и блокирует нажатие',
        (tester) async {
      await _pump(
        tester,
        AppButton(label: 'Сохранить', loading: true, onPressed: () {}),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Сохранить'), findsNothing);
    });

    testWidgets('focus-кольцо появляется при фокусе без сдвига layout',
        (tester) async {
      final node = FocusNode();
      addTearDown(node.dispose);
      await _pump(
        tester,
        AppButton(label: 'Фокус', onPressed: () {}, focusNode: node),
      );

      final sizeBefore = tester.getSize(find.byType(AppButton));
      final ringBefore = _focusRingColor(tester);
      node.requestFocus();
      await tester.pumpAndSettle();

      final ringAfter = _focusRingColor(tester);
      expect(ringBefore!.a, 0);
      expect(ringAfter!.a, greaterThan(0));
      expect(ringAfter, tokens.primary);
      expect(tester.getSize(find.byType(AppButton)), sizeBefore);
    });
  });

  group('Поля ввода (#212)', () {
    testWidgets('label, hint и helper отображаются', (tester) async {
      await _pump(
        tester,
        const AppTextField(
          label: 'Сумма',
          hint: 'Например, 15000',
          helper: 'В рублях',
        ),
      );

      expect(find.text('Сумма'), findsOneWidget);
      expect(find.text('Например, 15000'), findsOneWidget);
      expect(find.text('В рублях'), findsOneWidget);
    });

    testWidgets('errorText показывает ошибку и заменяет helper',
        (tester) async {
      await _pump(
        tester,
        const AppTextField(
          label: 'Сумма',
          helper: 'В рублях',
          errorText: 'Некорректная сумма',
        ),
      );

      expect(find.text('Некорректная сумма'), findsOneWidget);
      expect(find.text('В рублях'), findsNothing);
    });

    testWidgets('disabled-поле недоступно для ввода', (tester) async {
      await _pump(
        tester,
        const AppTextField(label: 'Поле', enabled: false),
      );

      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.enabled, isFalse);
    });

    testWidgets('форма с validator показывает error-state', (tester) async {
      final key = GlobalKey<FormState>();
      await _pump(
        tester,
        Form(
          key: key,
          child: AppTextFormField(
            label: 'ИНН',
            validator: (value) =>
                (value == null || value.isEmpty) ? 'Укажите ИНН' : null,
          ),
        ),
      );

      key.currentState!.validate();
      await tester.pumpAndSettle();
      expect(find.text('Укажите ИНН'), findsOneWidget);
    });

    testWidgets('AppTextFormField touch-target ≥48 dp', (tester) async {
      await _pump(
        tester,
        const AppTextFormField(label: 'Поле'),
      );

      expect(
        tester.getSize(find.byType(TextFormField)).height,
        greaterThanOrEqualTo(48),
      );
    });
  });

  group('Чипы и сегмент-контролы (#213)', () {
    testWidgets('AppFilterChip переключается и держит touch-target ≥48 dp',
        (tester) async {
      var selected = false;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(null),
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) => AppFilterChip(
                label: 'IT',
                accent: AppTokens.light.sphereIt,
                selected: selected,
                onSelected: () => setState(() => selected = true),
              ),
            ),
          ),
        ),
      );

      expect(
        tester.getSize(find.byType(AppFilterChip)).height,
        greaterThanOrEqualTo(48),
      );
      await tester.tap(find.text('IT'));
      await tester.pumpAndSettle();
      expect(tester.widget<ChoiceChip>(find.byType(ChoiceChip)).selected, isTrue);
    });

    testWidgets('AppStatusChip показывает метку и иконку', (tester) async {
      await _pump(
        tester,
        AppStatusChip(
          label: 'Подписан',
          color: tokens.success,
          icon: Icons.verified_outlined,
        ),
      );

      expect(find.text('Подписан'), findsOneWidget);
      expect(find.byIcon(Icons.verified_outlined), findsOneWidget);
    });

    testWidgets('AppSegmentedControl меняет выбор и поддерживает акценты',
        (tester) async {
      var value = 'a';
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(null),
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) => AppSegmentedControl<String>(
                selected: value,
                onChanged: (next) => setState(() => value = next),
                segments: [
                  const AppSegmentOption(value: 'a', label: 'Альфа'),
                  AppSegmentOption(
                    value: 'b',
                    label: 'Бета',
                    accent: tokens.sphereLogistics,
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      expect(
        tester.getSize(find.byType(AppSegmentedControl<String>)).height,
        greaterThanOrEqualTo(48),
      );
      await tester.tap(find.text('Бета'));
      await tester.pumpAndSettle();
      expect(value, 'b');
    });

    testWidgets('StatusBanner поддерживает все типы', (tester) async {
      const cases = {
        StatusBannerType.info: Icons.info_outline,
        StatusBannerType.success: Icons.check_circle_outline,
        StatusBannerType.warning: Icons.warning_amber_rounded,
        StatusBannerType.danger: Icons.error_outline,
      };
      for (final entry in cases.entries) {
        await _pump(
          tester,
          StatusBanner(type: entry.key, message: 'Сообщение'),
        );
        expect(find.text('Сообщение'), findsOneWidget);
        expect(find.byIcon(entry.value), findsOneWidget);
      }
    });
  });

  group('Состояния empty/loading/error (#214)', () {
    testWidgets('AppEmptyState показывает заголовок, текст и действие',
        (tester) async {
      await _pump(
        tester,
        AppEmptyState(
          title: 'Пусто',
          message: 'Ничего нет',
          action: AppButton(label: 'Добавить', onPressed: () {}),
        ),
      );

      expect(find.text('Пусто'), findsOneWidget);
      expect(find.text('Ничего нет'), findsOneWidget);
      expect(find.text('Добавить'), findsOneWidget);
    });

    testWidgets('AppErrorState вызывает onRetry', (tester) async {
      var retried = false;
      await _pump(
        tester,
        AppErrorState(onRetry: () => retried = true),
      );

      await tester.tap(find.text('Повторить'));
      expect(retried, isTrue);
    });

    testWidgets('AppLoadingState показывает shimmer и skeleton',
        (tester) async {
      await _pump(tester, const AppLoadingState());
      await tester.pump();

      expect(find.byType(Shimmer), findsOneWidget);
      expect(find.byType(SkeletonBox), findsWidgets);
    });

    testWidgets('Shimmer уважает reduced-motion', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(null),
          home: MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: const Scaffold(
              body: Shimmer(child: SkeletonBox(width: 100)),
            ),
          ),
        ),
      );

      expect(find.byType(ShaderMask), findsNothing);
      expect(find.byType(SkeletonBox), findsOneWidget);
    });

    testWidgets('AppPressable даёт pressed-state', (tester) async {
      await _pump(
        tester,
        AppPressable(onTap: () {}, child: const Text('Нажми')),
      );

      expect(find.byType(AnimatedScale), findsOneWidget);
      expect(find.byType(InkWell), findsOneWidget);
    });
  });
}
