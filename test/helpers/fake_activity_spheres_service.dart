import 'package:npd_shield/data/models/transaction.dart';
import 'package:npd_shield/data/services/activity_spheres_service.dart';

/// Фейковый сервис сфер деятельности для unit- и widget-тестов.
class FakeActivitySpheresService implements ActivitySpheresService {
  List<TransactionSphere> spheres;

  FakeActivitySpheresService([List<TransactionSphere>? initial])
    : spheres = initial ?? [];

  @override
  Future<List<TransactionSphere>> load() async => List.of(spheres);

  @override
  Future<void> save(List<TransactionSphere> value) async =>
      spheres = List.of(value);

  @override
  Future<void> reset() async => spheres = [];
}
