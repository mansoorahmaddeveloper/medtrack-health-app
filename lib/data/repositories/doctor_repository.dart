import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/providers/app_providers.dart';
import '../../core/utils/ids.dart';
import '../local/app_database.dart';

final doctorRepositoryProvider = Provider<DoctorRepository>((ref) {
  return DoctorRepository(ref.watch(databaseProvider));
});

class DoctorRepository {
  DoctorRepository(this._db);

  final AppDatabase _db;

  Future<String> registerDoctor({
    required String profileId,
    required String specialty,
    required String licenseNumber,
    String? clinic,
  }) async {
    final now = DateTime.now();
    final id = newId();
    await _db.into(_db.doctorProfiles).insert(
          DoctorProfilesCompanion.insert(
            id: id,
            profileId: profileId,
            specialty: specialty,
            licenseNumber: licenseNumber,
            clinic: Value(clinic),
            updatedAt: now,
          ),
        );
    await (_db.update(_db.profiles)..where((t) => t.id.equals(profileId))).write(
      ProfilesCompanion(
        role: const Value('doctor'),
        updatedAt: Value(now),
        syncStatus: const Value(AppConstants.syncPending),
      ),
    );
    return id;
  }

  Stream<List<DoctorProfile>> watchPendingDoctors() {
    return (_db.select(_db.doctorProfiles)
          ..where((t) => t.verificationStatus.equals('pending')))
        .watch();
  }

  Future<void> setVerificationStatus(String doctorId, String status) async {
    final now = DateTime.now();
    await (_db.update(_db.doctorProfiles)..where((t) => t.id.equals(doctorId)))
        .write(
      DoctorProfilesCompanion(
        verificationStatus: Value(status),
        verifiedAt: Value(status == 'verified' ? now : null),
        updatedAt: Value(now),
        syncStatus: const Value(AppConstants.syncPending),
      ),
    );
  }

  Future<void> linkPatient(String doctorProfileId, String patientId, String code) async {
    final now = DateTime.now();
    final id = newId();
    await _db.into(_db.doctorPatientLinks).insert(
          DoctorPatientLinksCompanion.insert(
            id: id,
            doctorProfileId: doctorProfileId,
            patientId: patientId,
            inviteCode: Value(code),
            updatedAt: now,
          ),
        );
  }

  Future<void> doctorUpdateMedicine({
    required String medicineId,
    required String name,
    required String dosage,
    required String patientProfileId,
  }) async {
    final now = DateTime.now();
    await (_db.update(_db.medicines)..where((t) => t.id.equals(medicineId))).write(
      MedicinesCompanion(
        name: Value(name),
        dosage: Value(dosage),
        updatedAt: Value(now),
        syncStatus: const Value(AppConstants.syncPending),
      ),
    );
    await _notifyPatient(
      patientProfileId,
      'Medicine updated',
      'Your doctor updated $name.',
      {'medicineId': medicineId},
    );
  }

  Future<void> addReview({
    required String doctorProfileId,
    required String patientId,
    required int rating,
    String reviewText = '',
  }) async {
    final now = DateTime.now();
    final id = newId();
    await _db.into(_db.reviews).insert(
          ReviewsCompanion.insert(
            id: id,
            doctorProfileId: doctorProfileId,
            patientId: patientId,
            rating: rating,
            reviewText: Value(reviewText),
            updatedAt: now,
          ),
        );
  }

  Future<List<Medicine>> activeMedicinesForPatient(String patientId) {
    return (_db.select(_db.medicines)
          ..where(
            (t) =>
                t.profileId.equals(patientId) &
                t.isActive.equals(true) &
                t.deletedAt.isNull(),
          ))
        .get();
  }

  Future<void> _notifyPatient(
    String patientId,
    String title,
    String body,
    Map<String, dynamic> payload,
  ) async {
    final now = DateTime.now();
    await _db.into(_db.appNotifications).insert(
          AppNotificationsCompanion.insert(
            id: newId(),
            recipientProfileId: patientId,
            title: title,
            body: body,
            payloadJson: Value(encodeJsonMap(payload)),
            createdAt: now,
            updatedAt: now,
          ),
        );
  }
}
