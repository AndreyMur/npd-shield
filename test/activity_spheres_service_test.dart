import 'package:flutter_test/flutter_test.dart';
import 'package:npd_shield/data/models/transaction.dart';
import 'package:npd_shield/data/services/activity_spheres_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('SharedPrefsActivitySpheresService', () {
    test('по умолчанию список сфер пуст', () async {
      expect(await SharedPrefsActivitySpheresService().load(), isEmpty);
    });

    test('save сохраняет выбранные сферы', () async {
      final service = SharedPrefsActivitySpheresService();

      await service.save([TransactionSphere.it, TransactionSphere.logistics]);

      expect(await service.load(), [
        TransactionSphere.it,
        TransactionSphere.logistics,
      ]);
    });

    test('выбор переживает создание нового экземпляра сервиса', () async {
      await SharedPrefsActivitySpheresService().save([
        TransactionSphere.logistics,
      ]);

      expect(await SharedPrefsActivitySpheresService().load(), [
        TransactionSphere.logistics,
      ]);
    });

    test('reset очищает выбор', () async {
      final service = SharedPrefsActivitySpheresService();
      await service.save([TransactionSphere.it]);

      await service.reset();

      expect(await service.load(), isEmpty);
    });

    test('неизвестные значения игнорируются', () async {
      SharedPreferences.setMockInitialValues({
        'activity_spheres': ['it', 'unknown', 'logistics'],
      });

      expect(await SharedPrefsActivitySpheresService().load(), [
        TransactionSphere.it,
        TransactionSphere.logistics,
      ]);
    });
  });
}
