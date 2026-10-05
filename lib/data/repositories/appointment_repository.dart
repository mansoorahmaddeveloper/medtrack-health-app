import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/providers/app_providers.dart';
import '../../core/utils/ids.dart';
import '../local/app_database.dart';

final appointmentRepositoryProvider = Provider<AppointmentRepository>((ref) {
  return AppointmentRepository(ref.watch(databaseProvider));
});

class AppointmentRepository {
  AppointmentRepository(this._db);

  final AppDatabase _db;

  Future<void> addAvailabilitySlot({
    required String doctorProfileId,
    required DateTime start,
    required DateTime end,
  }) async {
    final now = DateTime.now();
    await _db.into(_db.availabilitySlots).insert(
          AvailabilitySlotsCompanion.insert(
            id: newId(),
            doctorProfileId: doctorProfileId,
            startAt: start,
            endAt: end,
            updatedAt: now,
          ),
        );
  }

  Stream<List<AvailabilitySlot>> watchOpenSlots(String doctorProfileId) {
    return (_db.select(_db.availabilitySlots)
          ..where(
            (t) =>
                t.doctorProfileId.equals(doctorProfileId) &
                t.isBooked.equals(false) &
                t.deletedAt.isNull(),
          )
          ..orderBy([(t) => OrderingTerm.asc(t.startAt)]))
        .watch();
  }

  Future<String?> bookSlot({
    required String slotId,
    required String doctorProfileId,
    required String patientId,
    double? fee,
    double commissionRate = 0.1,
  }) async {
    return _db.transaction(() async {
      final slot = await (_db.select(_db.availabilitySlots)
            ..where((t) => t.id.equals(slotId)))
          .getSingleOrNull();
      if (slot == null || slot.isBooked) return null;
      final now = DateTime.now();
      await (_db.update(_db.availabilitySlots)..where((t) => t.id.equals(slotId)))
          .write(
        AvailabilitySlotsCompanion(
          isBooked: const Value(true),
          updatedAt: Value(now),
          syncStatus: const Value(AppConstants.syncPending),
        ),
      );
      final appointmentId = newId();
      await _db.into(_db.appointments).insert(
            AppointmentsCompanion.insert(
              id: appointmentId,
              doctorProfileId: doctorProfileId,
              patientId: patientId,
              slotStart: slot.startAt,
              slotEnd: slot.endAt,
              status: const Value('confirmed'),
              fee: Value(fee),
              commissionRate: Value(commissionRate),
              paymentStatus: const Value('pending'),
              updatedAt: now,
            ),
          );
      return appointmentId;
    });
  }

  Stream<List<Appointment>> watchPatientAppointments(String patientId) {
    return (_db.select(_db.appointments)
          ..where((t) => t.patientId.equals(patientId) & t.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm.asc(t.slotStart)]))
        .watch();
  }
}
