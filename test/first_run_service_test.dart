import 'package:flutter_test/flutter_test.dart';
import 'package:npd_shield/data/services/first_run_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('SharedPrefsFirstRunService', () {
    test('по умолчанию онбординг не завершён, режим не выбран', () async {
      final service = SharedPrefsFirstRunService();

      expect(await service.isOnboardingCompleted(), isFalse);
      expect(await service.getStartMode(), isNull);
    });

    test('completeOnboarding сохраняет флаг и выбранный режим', () async {
      final service = SharedPrefsFirstRunService();

      await service.completeOnboarding(StartMode.demo);

      expect(await service.isOnboardingCompleted(), isTrue);
      expect(await service.getStartMode(), StartMode.demo);
    });

    test('состояние переживает создание нового экземпляра сервиса', () async {
      await SharedPrefsFirstRunService().completeOnboarding(
        StartMode.fromScratch,
      );

      final fresh = SharedPrefsFirstRunService();

      expect(await fresh.isOnboardingCompleted(), isTrue);
      expect(await fresh.getStartMode(), StartMode.fromScratch);
    });

    test('reset возвращает состояние первого запуска', () async {
      final service = SharedPrefsFirstRunService();
      await service.completeOnboarding(StartMode.demo);

      await service.reset();

      expect(await service.isOnboardingCompleted(), isFalse);
      expect(await service.getStartMode(), isNull);
    });

    test('неизвестное значение режима трактуется как отсутствие выбора', () {
      expect(StartMode.fromStorage('unknown'), isNull);
      expect(StartMode.fromStorage(null), isNull);
      expect(StartMode.fromStorage('demo'), StartMode.demo);
    });
  });
}
