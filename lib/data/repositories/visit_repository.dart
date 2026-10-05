import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/providers/app_providers.dart';
import '../../core/utils/ids.dart';
import '../local/app_database.dart';

final visitRepositoryProvider = Provider<VisitRepository>((ref) {
  return VisitRepository(ref.watch(databaseProvider));
});

class VisitRepository {
  VisitRepository(this._db);

  final AppDatabase _db;

  Stream<List<MedicalVisit>> watchVisits({String? query}) {
    final q = query?.trim().toLowerCase();
    return (_db.select(_db.medicalVisits)
          ..where((t) {
            var expr = t.deletedAt.isNull();
            if (q != null && q.isNotEmpty) {
              expr = expr &
                  (t.doctorName.lower().contains(q) |
                      t.clinic.lower().contains(q) |
                      t.diagnosis.lower().contains(q) |
                      t.notes.lower().contains(q));
            }
            return expr;
          })
          ..orderBy([(t) => OrderingTerm.desc(t.visitDate)]))
        .watch();
  }

  Future<MedicalVisit?> getVisit(String id) {
    return (_db.select(_db.medicalVisits)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  Future<String> saveVisit({
    String? id,
    required DateTime visitDate,
    required String doctorName,
    required String clinic,
    required String diagnosis,
    required String notes,
  }) async {
    final now = DateTime.now();
    final visitId = id ?? newId();
    await _db.into(_db.medicalVisits).insertOnConflictUpdate(
          MedicalVisitsCompanion(
            id: Value(visitId),
            profileId: const Value(AppConstants.defaultProfileId),
            visitDate: Value(visitDate),
            doctorName: Value(doctorName),
            clinic: Value(clinic),
            diagnosis: Value(diagnosis),
            notes: Value(notes),
            updatedAt: Value(now),
            syncStatus: const Value(AppConstants.syncPending),
          ),
        );
    await _db.into(_db.syncQueue).insert(
          SyncQueueCompanion.insert(
            entityType: 'medicalVisit',
            entityId: visitId,
            createdAt: now,
          ),
        );
    return visitId;
  }

  Future<void> deleteVisit(String id) async {
    final now = DateTime.now();
    await (_db.update(_db.medicalVisits)..where((t) => t.id.equals(id))).write(
      MedicalVisitsCompanion(
        deletedAt: Value(now),
        updatedAt: Value(now),
        syncStatus: const Value(AppConstants.syncPending),
      ),
    );
  }
}
