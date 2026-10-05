import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/providers/app_providers.dart';
import '../../core/utils/ids.dart';
import '../local/app_database.dart';

final vitalsRepositoryProvider = Provider<VitalsRepository>((ref) {
  return VitalsRepository(ref.watch(databaseProvider));
});

class VitalsRepository {
  VitalsRepository(this._db);

  final AppDatabase _db;

  Stream<List<Vital>> watchVitals({required String patientId, String? type}) {
    return (_db.select(_db.vitals)
          ..where((t) {
            var expr =
                t.patientId.equals(patientId) & t.deletedAt.isNull();
            if (type != null) expr = expr & t.type.equals(type);
            return expr;
          })
          ..orderBy([(t) => OrderingTerm.desc(t.recordedAt)]))
        .watch();
  }

  Future<void> logVital({
    required String patientId,
    required String type,
    required double valuePrimary,
    double? valueSecondary,
    required String unit,
    required String loggedByProfileId,
    DateTime? recordedAt,
  }) async {
    final now = DateTime.now();
    final id = newId();
    await _db.into(_db.vitals).insert(
          VitalsCompanion.insert(
            id: id,
            patientId: patientId,
            type: type,
            valuePrimary: valuePrimary,
            valueSecondary: Value(valueSecondary),
            unit: unit,
            loggedByProfileId: loggedByProfileId,
            recordedAt: recordedAt ?? now,
            updatedAt: now,
          ),
        );
    await _db.into(_db.syncQueue).insert(
          SyncQueueCompanion.insert(
            entityType: 'vital',
            entityId: id,
            createdAt: now,
          ),
        );
  }

  Stream<List<ConditionNote>> watchConditionNotes(String patientId) {
    return (_db.select(_db.conditionNotes)
          ..where((t) => t.patientId.equals(patientId) & t.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
        .watch();
  }

  Future<void> addConditionNote(String patientId, String text) async {
    final now = DateTime.now();
    final id = newId();
    await _db.into(_db.conditionNotes).insert(
          ConditionNotesCompanion.insert(
            id: id,
            patientId: patientId,
            noteBody: text,
            updatedAt: now,
          ),
        );
    await _db.into(_db.syncQueue).insert(
          SyncQueueCompanion.insert(
            entityType: 'conditionNote',
            entityId: id,
            createdAt: now,
          ),
        );
  }

  Future<String> triggerSos(String patientId) async {
    final now = DateTime.now();
    final id = newId();
    await _db.into(_db.sosAlerts).insert(
          SosAlertsCompanion.insert(
            id: id,
            patientId: patientId,
            triggeredAt: now,
            updatedAt: now,
          ),
        );
    await _db.into(_db.syncQueue).insert(
          SyncQueueCompanion.insert(
            entityType: 'sosAlert',
            entityId: id,
            createdAt: now,
          ),
        );
    return id;
  }
}
