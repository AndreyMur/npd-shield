import 'package:npd_shield/data/models/risk_marker.dart';
import 'package:npd_shield/data/repositories/risk_report_repository.dart';

/// Фейковый репозиторий отчётов о рисках для unit-тестов.
class FakeRiskReportRepository implements RiskReportRepository {
  final List<RiskReport> reports;
  int _nextId = 1;

  FakeRiskReportRepository([List<RiskReport>? initial])
    : reports = initial ?? [];

  @override
  Future<int> save(RiskReport report) async {
    final index = reports.indexWhere(
      (item) => item.id == report.id && report.id != 0,
    );
    if (index >= 0) {
      reports[index] = report;
      return report.id;
    }
    report.id = _nextId++;
    reports.add(report);
    return report.id;
  }

  @override
  Future<RiskReport?> getById(int id) async {
    for (final report in reports) {
      if (report.id == id) return report;
    }
    return null;
  }

  @override
  Future<List<RiskReport>> getAll() async {
    final result = List.of(reports);
    result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return result;
  }

  @override
  Future<void> delete(int id) async {
    reports.removeWhere((report) => report.id == id);
  }

  @override
  Future<void> clear() async => reports.clear();
}
