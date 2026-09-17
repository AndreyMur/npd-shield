import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:npd_shield/core/theme/app_motion.dart';

void main() {
  group('Длительности motion-токенов', () {
    test('переходы укладываются в 150–300 мс', () {
      for (final duration in [
        AppMotionDurations.quick,
        AppMotionDurations.medium,
        AppMotionDurations.slow,
      ]) {
        expect(duration, greaterThanOrEqualTo(AppMotion.minTransition));
        expect(duration, lessThanOrEqualTo(AppMotion.maxTransition));
      }
    });

    test('отклик микро-взаимодействий — 80–150 мс', () {
      expect(AppMotionDurations.micro, greaterThanOrEqualTo(AppMotion.minMicro));
      expect(AppMotionDurations.micro, lessThanOrEqualTo(AppMotion.maxMicro));
    });

    test('длительности возрастают, instant — нулевой', () {
      expect(AppMotionDurations.instant, Duration.zero);
      expect(AppMotionDurations.micro, lessThan(AppMotionDurations.quick));
      expect(AppMotionDurations.quick, lessThan(AppMotionDurations.medium));
      expect(AppMotionDurations.medium, lessThan(AppMotionDurations.slow));
    });
  });

  group('Кривые motion-токенов', () {
    test('вход — ease-out, выход — ease-in', () {
      expect(AppMotionCurves.enter, Curves.easeOut);
      expect(AppMotionCurves.exit, Curves.easeIn);
      expect(AppMotionCurves.standard, Curves.easeInOut);
    });
  });

  group('Reduced-motion', () {
    test('effective сводит анимацию к мгновенному переходу', () {
      expect(
        AppMotion.effective(
          reducedMotion: true,
          duration: AppMotionDurations.slow,
        ),
        Duration.zero,
      );
      expect(
        AppMotion.effective(
          reducedMotion: false,
          duration: AppMotionDurations.slow,
        ),
        AppMotionDurations.slow,
      );
    });

    Future<BuildContext> contextWith(
      WidgetTester tester, {
      required bool disableAnimations,
    }) async {
      late BuildContext captured;
      await tester.pumpWidget(
        MediaQuery(
          data: MediaQueryData(disableAnimations: disableAnimations),
          child: Builder(
            builder: (context) {
              captured = context;
              return const SizedBox();
            },
          ),
        ),
      );
      return captured;
    }

    testWidgets('флаг читается из MediaQuery', (tester) async {
      expect(
        AppMotion.reduced(await contextWith(tester, disableAnimations: true)),
        isTrue,
      );
      expect(
        AppMotion.reduced(await contextWith(tester, disableAnimations: false)),
        isFalse,
      );
    });

    testWidgets('resolve и хелперы возвращают мгновенный переход',
        (tester) async {
      final reduced = await contextWith(tester, disableAnimations: true);
      expect(
        AppMotion.resolve(reduced, AppMotionDurations.medium),
        Duration.zero,
      );
      expect(AppMotion.transition(reduced), Duration.zero);
      expect(AppMotion.microInteraction(reduced), Duration.zero);
      expect(AppMotion.enterCurve(reduced), Curves.linear);
      expect(AppMotion.exitCurve(reduced), Curves.linear);
    });

    testWidgets('без reduced-motion длительности сохраняются', (tester) async {
      final normal = await contextWith(tester, disableAnimations: false);
      expect(
        AppMotion.resolve(normal, AppMotionDurations.medium),
        AppMotionDurations.medium,
      );
      expect(AppMotion.transition(normal), AppMotionDurations.medium);
      expect(AppMotion.enterCurve(normal), AppMotionCurves.enter);
      expect(AppMotion.exitCurve(normal), AppMotionCurves.exit);
    });
  });
}
