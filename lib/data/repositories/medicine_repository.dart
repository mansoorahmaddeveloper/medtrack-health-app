import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/providers/app_providers.dart';
import '../../core/utils/ids.dart';
import '../local/app_database.dart';
import '../../services/reminder_scheduler.dart';

final medicineRepositoryProvider = Provider<MedicineRepository>((ref) {
  return MedicineRepository(
    ref.watch(databaseProvider),
    ref.watch(reminderSchedulerProvider),
  );
});

class MedicineRepository {
  MedicineRepository(this._db, this._scheduler);

  final AppDatabase _db;
  final ReminderScheduler _scheduler;

  Stream<List<Medicine>> watchMedicines() {
    return (_db.select(_db.medicines)
          ..where((t) => t.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm.asc(t.name)]))
        .watch();
  }

  Stream<List<DoseLog>> watchDoseLogs({String? medicineId}) {
    return (_db.select(_db.doseLogs)
          ..where((t) {
            var expr = t.deletedAt.isNull();
            if (medicineId != null) {
              expr = expr & t.medicineId.equals(medicineId);
            }
            return expr;
          })
          ..orderBy([(t) => OrderingTerm.desc(t.scheduledAt)]))
        .watch();
  }

  Future<String> saveMedicine({
    String? id,
    required String name,
    required String dosage,
    required List<String> scheduleTimes,
    required DateTime startDate,
    DateTime? endDate,
    bool isActive = true,
  }) async {
    final now = DateTime.now();
    final medicineId = id ?? newId();
    await _db.into(_db.medicines).insertOnConflictUpdate(
          MedicinesCompanion(
            id: Value(medicineId),
            profileId: const Value(AppConstants.defaultProfileId),
            name: Value(name),
            dosage: Value(dosage),
            scheduleTimesJson: Value(encodeJsonList(scheduleTimes)),
            startDate: Value(startDate),
            endDate: Value(endDate),
            isActive: Value(isActive),
            updatedAt: Value(now),
            syncStatus: const Value(AppConstants.syncPending),
          ),
        );
    await _scheduler.scheduleMedicine(medicineId);
    await _db.into(_db.syncQueue).insert(
          SyncQueueCompanion.insert(
            entityType: 'medicine',
            entityId: medicineId,
            createdAt: now,
          ),
        );
    return medicineId;
  }

  Future<void> confirmDose(String doseLogId) async {
    final now = DateTime.now();
    await (_db.update(_db.doseLogs)..where((t) => t.id.equals(doseLogId))).write(
      DoseLogsCompanion(
        status: const Value('taken'),
        confirmedAt: Value(now),
        updatedAt: Value(now),
        syncStatus: const Value(AppConstants.syncPending),
      ),
    );
    await _scheduler.cancelDoseReminders(doseLogId);
  }

  Future<void> snoozeDose(String doseLogId, {Duration delay = const Duration(minutes: 15)}) async {
    final dose = await getDoseLog(doseLogId);
    if (dose == null) return;
    final now = DateTime.now();
    final newTime = now.add(delay);
    await (_db.update(_db.doseLogs)..where((t) => t.id.equals(doseLogId))).write(
      DoseLogsCompanion(
        scheduledAt: Value(newTime),
        status: const Value('pending'),
        reminderCount: Value(dose.reminderCount + 1),
        updatedAt: Value(now),
        syncStatus: const Value(AppConstants.syncPending),
      ),
    );
    await _scheduler.rescheduleDoseReminder(doseLogId);
  }

  Future<void> skipDose(String doseLogId) async {
    final now = DateTime.now();
    await (_db.update(_db.doseLogs)..where((t) => t.id.equals(doseLogId))).write(
      DoseLogsCompanion(
        status: const Value('missed'),
        updatedAt: Value(now),
        syncStatus: const Value(AppConstants.syncPending),
      ),
    );
    await _scheduler.cancelDoseReminders(doseLogId);
  }

  Future<Medicine?> getMedicine(String id) {
    return (_db.select(_db.medicines)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  Future<DoseLog?> getDoseLog(String id) {
    return (_db.select(_db.doseLogs)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  Future<void> markMissedEndOfDay(DateTime day) async {
    final start = DateTime(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 1));
    final pending = await (_db.select(_db.doseLogs)
          ..where(
            (t) =>
                t.scheduledAt.isBiggerOrEqualValue(start) &
                t.scheduledAt.isSmallerThanValue(end) &
                t.status.equals('pending'),
          ))
        .get();
    final now = DateTime.now();
    for (final dose in pending) {
      await (_db.update(_db.doseLogs)..where((t) => t.id.equals(dose.id))).write(
        DoseLogsCompanion(
          status: const Value('missed'),
          updatedAt: Value(now),
          syncStatus: const Value(AppConstants.syncPending),
        ),
      );
    }
  }
}
