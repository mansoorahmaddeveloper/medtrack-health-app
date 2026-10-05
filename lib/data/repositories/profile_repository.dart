import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/providers/app_providers.dart';
import '../../core/utils/ids.dart';
import '../local/app_database.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(ref.watch(databaseProvider));
});

class ProfileRepository {
  ProfileRepository(this._db);

  final AppDatabase _db;

  Stream<Profile?> watchProfile() {
    return (_db.select(_db.profiles)
          ..where((t) => t.id.equals(AppConstants.defaultProfileId)))
        .watchSingleOrNull();
  }

  Future<Profile?> getProfile() {
    return (_db.select(_db.profiles)
          ..where((t) => t.id.equals(AppConstants.defaultProfileId)))
        .getSingleOrNull();
  }

  Future<void> upsertProfile({
    required String name,
    DateTime? dateOfBirth,
    String? bloodType,
    List<String> allergies = const [],
  }) async {
    final now = DateTime.now();
    await _db.into(_db.profiles).insertOnConflictUpdate(
          ProfilesCompanion(
            id: const Value(AppConstants.defaultProfileId),
            name: Value(name),
            dateOfBirth: Value(dateOfBirth),
            bloodType: Value(bloodType),
            allergiesJson: Value(encodeJsonList(allergies)),
            updatedAt: Value(now),
            syncStatus: const Value(AppConstants.syncPending),
          ),
        );
    await _db.into(_db.syncQueue).insert(
          SyncQueueCompanion.insert(
            entityType: 'profile',
            entityId: AppConstants.defaultProfileId,
            createdAt: now,
          ),
        );
  }

  Stream<List<EmergencyContact>> watchEmergencyContacts() {
    return (_db.select(_db.emergencyContacts)
          ..where((t) => t.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm.asc(t.name)]))
        .watch();
  }

  Future<void> addEmergencyContact({
    required String name,
    required String phone,
    String? relationship,
  }) async {
    final now = DateTime.now();
    final id = newId();
    await _db.into(_db.emergencyContacts).insert(
          EmergencyContactsCompanion.insert(
            id: id,
            profileId: AppConstants.defaultProfileId,
            name: name,
            phone: phone,
            relationship: Value(relationship),
            updatedAt: now,
          ),
        );
    await _db.into(_db.syncQueue).insert(
          SyncQueueCompanion.insert(
            entityType: 'emergencyContact',
            entityId: id,
            createdAt: now,
          ),
        );
  }

  Future<void> deleteEmergencyContact(String id) async {
    final now = DateTime.now();
    await (_db.update(_db.emergencyContacts)..where((t) => t.id.equals(id)))
        .write(
      EmergencyContactsCompanion(
        deletedAt: Value(now),
        updatedAt: Value(now),
        syncStatus: const Value(AppConstants.syncPending),
      ),
    );
  }
}
