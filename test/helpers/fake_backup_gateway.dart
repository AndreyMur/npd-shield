import 'dart:typed_data';

import 'package:npd_shield/data/backup/backup_service.dart';

/// Фейковый шлюз резервного копирования для виджет-тестов.
class FakeBackupGateway implements BackupGateway {
  BackupFile? exportResult;
  Object? importError;

  int exportCalls = 0;
  final List<Uint8List> imported = [];

  FakeBackupGateway({this.exportResult, this.importError});

  @override
  Future<BackupFile> exportBackup() async {
    exportCalls++;
    return exportResult ??
        BackupFile(
          fileName: 'npd_shield_backup_2026-09-17_120000.json',
          bytes: Uint8List.fromList([0x7B, 0x7D]),
          createdAt: DateTime(2026, 9, 17, 12),
          counts: const BackupCounts(transactions: 2, clients: 1),
        );
  }

  @override
  Future<BackupImportResult> importBackup(Uint8List bytes) async {
    if (importError != null) throw importError!;
    imported.add(bytes);
    return const BackupImportResult(
      counts: BackupCounts(transactions: 5, clients: 2),
    );
  }
}
