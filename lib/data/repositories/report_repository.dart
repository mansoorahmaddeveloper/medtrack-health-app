import 'dart:io';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/providers/app_providers.dart';
import '../../core/utils/ids.dart';
import '../local/app_database.dart';
import '../../services/document_scan_service.dart';

final reportRepositoryProvider = Provider<ReportRepository>((ref) {
  return ReportRepository(
    ref.watch(databaseProvider),
    ref.watch(documentScanServiceProvider),
  );
});

class ReportRepository {
  ReportRepository(this._db, this._scanService);

  final AppDatabase _db;
  final DocumentScanService _scanService;

  Stream<List<Report>> watchReports({String? query}) {
    final q = query?.trim().toLowerCase();
    return (_db.select(_db.reports)
          ..where((t) {
            var expr = t.deletedAt.isNull();
            if (q != null && q.isNotEmpty) {
              expr = expr &
                  (t.title.lower().contains(q) | t.ocrText.lower().contains(q));
            }
            return expr;
          })
          ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
        .watch();
  }

  Future<Report?> getReport(String id) {
    return (_db.select(_db.reports)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  Future<String?> scanAndSaveReport({
    required String title,
    String? visitId,
  }) async {
    final file = await _scanService.scanDocument();
    if (file == null) return null;
    final dir = await getApplicationDocumentsDirectory();
    final reportsDir = Directory(p.join(dir.path, 'reports'));
    if (!await reportsDir.exists()) {
      await reportsDir.create(recursive: true);
    }
    final id = newId();
    final destPath = p.join(reportsDir.path, '$id.jpg');
    await file.copy(destPath);
    final ocrText = await _scanService.extractText(destPath);
    final now = DateTime.now();
    await _db.into(_db.reports).insert(
          ReportsCompanion.insert(
            id: id,
            profileId: AppConstants.defaultProfileId,
            title: title,
            imagePath: destPath,
            visitId: Value(visitId),
            ocrText: Value(ocrText),
            updatedAt: now,
          ),
        );
    await _db.into(_db.syncQueue).insert(
          SyncQueueCompanion.insert(
            entityType: 'report',
            entityId: id,
            createdAt: now,
          ),
        );
    return id;
  }

  Future<void> linkToVisit(String reportId, String? visitId) async {
    final now = DateTime.now();
    await (_db.update(_db.reports)..where((t) => t.id.equals(reportId))).write(
      ReportsCompanion(
        visitId: Value(visitId),
        updatedAt: Value(now),
        syncStatus: const Value(AppConstants.syncPending),
      ),
    );
  }
}
