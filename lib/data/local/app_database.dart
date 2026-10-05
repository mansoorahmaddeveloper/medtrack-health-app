import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'tables/tables.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    Profiles,
    EmergencyContacts,
    MedicalVisits,
    Medicines,
    DoseLogs,
    Reports,
    UserAccounts,
    FamilyLinks,
    Vitals,
    ConditionNotes,
    SosAlerts,
    DoctorProfiles,
    DoctorPatientLinks,
    Appointments,
    AvailabilitySlots,
    Reviews,
    AppNotifications,
    PharmacyOrders,
    AuditLogs,
    SyncQueue,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          final now = DateTime.now();
          await into(profiles).insert(
            ProfilesCompanion.insert(
              id: 'local-profile',
              name: const Value(''),
              updatedAt: now,
            ),
          );
        },
      );

  static LazyDatabase openConnection() {
    return LazyDatabase(() async {
      final dir = await getApplicationDocumentsDirectory();
      final file = File(p.join(dir.path, 'medtrack.sqlite'));
      return NativeDatabase.createInBackground(file);
    });
  }
}
