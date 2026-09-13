import 'package:flutter/material.dart';

import '../../data/models/risk_marker.dart';
import 'risk_report_view.dart';

/// Экран повторного просмотра ранее сохранённого результата проверки.
class RiskReportDetailScreen extends StatelessWidget {
  /// Ранее сохранённый отчёт из истории.
  final RiskReport report;

  const RiskReportDetailScreen({super.key, required this.report});

  @override
  Widget build(BuildContext context) {
    final title = report.sourceName.isEmpty ? 'Результат проверки' : report.sourceName;
    return Scaffold(
      key: const Key('risk_report_detail_screen'),
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        child: RiskReportView(
          report: report,
          fileName: report.sourceName,
        ),
      ),
    );
  }
}
