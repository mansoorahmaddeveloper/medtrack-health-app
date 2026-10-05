import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/providers/app_providers.dart';
import '../../core/utils/ids.dart';
import '../local/app_database.dart';

final pharmacyRepositoryProvider = Provider<PharmacyRepository>((ref) {
  return PharmacyRepository(ref.watch(databaseProvider));
});

class PharmacyRepository {
  PharmacyRepository(this._db);

  final AppDatabase _db;

  Future<String> createOrder({
    required String patientId,
    required String medicineId,
    String? partnerId,
    double? amount,
  }) async {
    final now = DateTime.now();
    final id = newId();
    await _db.into(_db.pharmacyOrders).insert(
          PharmacyOrdersCompanion.insert(
            id: id,
            patientId: patientId,
            medicineId: medicineId,
            partnerId: Value(partnerId),
            amount: Value(amount),
            updatedAt: now,
          ),
        );
    await _db.into(_db.syncQueue).insert(
          SyncQueueCompanion.insert(
            entityType: 'pharmacyOrder',
            entityId: id,
            createdAt: now,
          ),
        );
    return id;
  }

  Stream<List<PharmacyOrder>> watchOrders(String patientId) {
    return (_db.select(_db.pharmacyOrders)
          ..where((t) => t.patientId.equals(patientId) & t.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
        .watch();
  }
}

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  return AdminRepository(ref.watch(databaseProvider));
});

class AdminRepository {
  AdminRepository(this._db);

  final AppDatabase _db;

  Stream<List<Profile>> watchUsers() {
    return (_db.select(_db.profiles)..where((t) => t.deletedAt.isNull())).watch();
  }

  Stream<List<Review>> watchFlaggedReviews() {
    return (_db.select(_db.reviews)..where((t) => t.flagged.equals(true))).watch();
  }

  Future<void> suspendUser(String profileId) async {
    final now = DateTime.now();
    await (_db.update(_db.profiles)..where((t) => t.id.equals(profileId))).write(
      ProfilesCompanion(
        deletedAt: Value(now),
        updatedAt: Value(now),
        syncStatus: const Value(AppConstants.syncPending),
      ),
    );
    await logAudit('suspend_user', 'profile', profileId);
  }

  Future<void> logAudit(String action, String entityType, String? entityId,
      {Map<String, dynamic>? metadata}) async {
    await _db.into(_db.auditLogs).insert(
          AuditLogsCompanion.insert(
            id: newId(),
            action: action,
            entityType: entityType,
            entityId: Value(entityId),
            metadataJson: Value(encodeJsonMap(metadata ?? {})),
            createdAt: DateTime.now(),
          ),
        );
  }

  Stream<List<AuditLog>> watchAuditLogs() {
    return (_db.select(_db.auditLogs)
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .watch();
  }
}
