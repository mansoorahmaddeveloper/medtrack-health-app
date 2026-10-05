import 'package:drift/drift.dart';

import '../core/constants/app_constants.dart';
import '../core/providers/app_providers.dart';
import '../core/utils/ids.dart';
import '../data/local/app_database.dart';
import 'notification_service.dart';

class ReminderScheduler {
  ReminderScheduler(this._db, this._notifications);

  final AppDatabase _db;
  final NotificationService _notifications;

  Future<void> rescheduleAllActiveMedicines() async {
    final meds = await (_db.select(_db.medicines)
          ..where((t) => t.deletedAt.isNull() & t.isActive.equals(true)))
        .get();
    for (final med in meds) {
      await scheduleMedicine(med.id);
    }
  }

  Future<void> scheduleMedicine(String medicineId) async {
    final medicine = await (_db.select(_db.medicines)
          ..where((t) => t.id.equals(medicineId)))
        .getSingleOrNull();
    if (medicine == null || !medicine.isActive) return;

    final times = decodeJsonList(medicine.scheduleTimesJson);
    final now = DateTime.now();
    for (final timeStr in times) {
      final parts = timeStr.split(':');
      if (parts.length != 2) continue;
      final hour = int.tryParse(parts[0]);
      final minute = int.tryParse(parts[1]);
      if (hour == null || minute == null) continue;

      var scheduled = DateTime(now.year, now.month, now.day, hour, minute);
      if (scheduled.isBefore(now)) {
        scheduled = scheduled.add(const Duration(days: 1));
      }

      final dayStart = DateTime(scheduled.year, scheduled.month, scheduled.day);
      final dayEnd = dayStart.add(const Duration(days: 1));
      final existingForDay = await (_db.select(_db.doseLogs)
            ..where(
              (t) =>
                  t.medicineId.equals(medicineId) &
                  t.scheduledAt.isBiggerOrEqualValue(dayStart) &
                  t.scheduledAt.isSmallerThanValue(dayEnd) &
                  t.deletedAt.isNull(),
            ))
          .get();

      DoseLog? existing;
      for (final d in existingForDay) {
        if (d.scheduledAt.hour == hour && d.scheduledAt.minute == minute) {
          existing = d;
          break;
        }
      }

      final doseId = existing?.id ?? newId();
      if (existing == null) {
        await _db.into(_db.doseLogs).insert(
              DoseLogsCompanion.insert(
                id: doseId,
                medicineId: medicineId,
                profileId: medicine.profileId,
                scheduledAt: scheduled,
                updatedAt: now,
              ),
            );
      }

      await _scheduleDoseNotifications(
        doseId: doseId,
        medicineName: medicine.name,
        dosage: medicine.dosage,
        scheduledAt: existing?.scheduledAt ?? scheduled,
      );
    }
  }

  Future<void> rescheduleDoseReminder(String doseLogId) async {
    final dose = await (_db.select(_db.doseLogs)..where((t) => t.id.equals(doseLogId)))
        .getSingleOrNull();
    if (dose == null) return;
    final medicine = await (_db.select(_db.medicines)
          ..where((t) => t.id.equals(dose.medicineId)))
        .getSingleOrNull();
    if (medicine == null) return;

    await _notifications.cancelDoseReminders(doseLogId);
    await _scheduleDoseNotifications(
      doseId: doseLogId,
      medicineName: medicine.name,
      dosage: medicine.dosage,
      scheduledAt: dose.scheduledAt,
    );
  }

  Future<void> cancelDoseReminders(String doseLogId) async {
    await _notifications.cancelDoseReminders(doseLogId);
  }

  Future<void> _scheduleDoseNotifications({
    required String doseId,
    required String medicineName,
    required String dosage,
    required DateTime scheduledAt,
  }) async {
    final payload = 'dose:$doseId';
    await _notifications.schedule(
      id: doseId.hashCode,
      title: 'Time for $medicineName',
      body: 'Tap to confirm you took $dosage',
      when: scheduledAt,
      payload: payload,
    );
    await _notifications.schedule(
      id: doseId.hashCode + 1,
      title: 'Reminder: $medicineName',
      body: 'Please confirm your dose',
      when: scheduledAt.add(AppConstants.doseFollowUpDelay),
      payload: payload,
    );
  }

  /// Marks pending doses as late after follow-up window without confirmation.
  Future<void> processFollowUps() async {
    final cutoff = DateTime.now().subtract(AppConstants.doseFollowUpDelay);
    final pending = await (_db.select(_db.doseLogs)
          ..where(
            (t) => t.status.equals('pending') & t.scheduledAt.isSmallerThanValue(cutoff),
          ))
        .get();
    final now = DateTime.now();
    for (final dose in pending) {
      await (_db.update(_db.doseLogs)..where((t) => t.id.equals(dose.id))).write(
        DoseLogsCompanion(
          status: const Value('late'),
          reminderCount: Value(dose.reminderCount + 1),
          updatedAt: Value(now),
          syncStatus: const Value(AppConstants.syncPending),
        ),
      );
      final medicine = await (_db.select(_db.medicines)
            ..where((t) => t.id.equals(dose.medicineId)))
          .getSingleOrNull();
      if (medicine != null) {
        await _notifications.schedule(
          id: dose.id.hashCode + dose.reminderCount + 10,
          title: 'Still waiting: ${medicine.name}',
          body: 'Tap to confirm your dose',
          when: now.add(AppConstants.doseFollowUpDelay),
          payload: 'dose:${dose.id}',
        );
      }
    }
  }
}
