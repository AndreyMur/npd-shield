import 'package:isar/isar.dart';

import '../models/risk_marker.dart';
import 'risk_marker_repository.dart';

class IsarRiskMarkerRepository implements RiskMarkerRepository {
  final Isar isar;

  IsarRiskMarkerRepository(this.isar);

  @override
  Future<List<RiskMarker>> getAll() async {
    final markers = await isar.riskMarkers.where().findAll();
    markers.sort((a, b) {
      final bySeverity = a.severity.index.compareTo(b.severity.index);
      return bySeverity != 0 ? bySeverity : a.code.compareTo(b.code);
    });
    return markers;
  }

  @override
  Future<RiskMarker?> getByCode(String code) {
    return isar.riskMarkers.where().codeEqualTo(code).findFirst();
  }

  @override
  Future<void> put(RiskMarker marker) {
    return isar.writeTxn(() => isar.riskMarkers.put(marker));
  }

  @override
  Future<void> clear() {
    return isar.writeTxn(() => isar.riskMarkers.clear());
  }
}
