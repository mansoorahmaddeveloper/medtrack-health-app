import 'package:drift/drift.dart';

class Profiles extends Table {
  TextColumn get id => text()();
  TextColumn get name => text().withDefault(const Constant(''))();
  DateTimeColumn get dateOfBirth => dateTime().nullable()();
  TextColumn get bloodType => text().nullable()();
  TextColumn get allergiesJson => text().withDefault(const Constant('[]'))();
  TextColumn get role => text().withDefault(const Constant('patient'))();
  TextColumn get supabaseUserId => text().nullable()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  TextColumn get syncStatus => text().withDefault(const Constant('pending'))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class EmergencyContacts extends Table {
  TextColumn get id => text()();
  TextColumn get profileId => text().references(Profiles, #id)();
  TextColumn get name => text()();
  TextColumn get phone => text()();
  TextColumn get relationship => text().nullable()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  TextColumn get syncStatus => text().withDefault(const Constant('pending'))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class MedicalVisits extends Table {
  TextColumn get id => text()();
  TextColumn get profileId => text().references(Profiles, #id)();
  DateTimeColumn get visitDate => dateTime()();
  TextColumn get doctorName => text().withDefault(const Constant(''))();
  TextColumn get clinic => text().withDefault(const Constant(''))();
  TextColumn get diagnosis => text().withDefault(const Constant(''))();
  TextColumn get notes => text().withDefault(const Constant(''))();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  TextColumn get syncStatus => text().withDefault(const Constant('pending'))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class Medicines extends Table {
  TextColumn get id => text()();
  TextColumn get profileId => text().references(Profiles, #id)();
  TextColumn get name => text()();
  TextColumn get dosage => text().withDefault(const Constant(''))();
  TextColumn get scheduleTimesJson => text().withDefault(const Constant('[]'))();
  DateTimeColumn get startDate => dateTime()();
  DateTimeColumn get endDate => dateTime().nullable()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  TextColumn get syncStatus => text().withDefault(const Constant('pending'))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class DoseLogs extends Table {
  TextColumn get id => text()();
  TextColumn get medicineId => text().references(Medicines, #id)();
  TextColumn get profileId => text().references(Profiles, #id)();
  DateTimeColumn get scheduledAt => dateTime()();
  TextColumn get status => text().withDefault(const Constant('pending'))();
  DateTimeColumn get confirmedAt => dateTime().nullable()();
  IntColumn get reminderCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  TextColumn get syncStatus => text().withDefault(const Constant('pending'))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class Reports extends Table {
  TextColumn get id => text()();
  TextColumn get profileId => text().references(Profiles, #id)();
  TextColumn get title => text()();
  TextColumn get imagePath => text()();
  TextColumn get visitId => text().nullable().references(MedicalVisits, #id)();
  TextColumn get ocrText => text().withDefault(const Constant(''))();
  TextColumn get remoteStoragePath => text().nullable()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  TextColumn get syncStatus => text().withDefault(const Constant('pending'))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class UserAccounts extends Table {
  TextColumn get id => text()();
  TextColumn get supabaseUserId => text().nullable()();
  TextColumn get email => text().nullable()();
  TextColumn get phone => text().nullable()();
  TextColumn get role => text().withDefault(const Constant('patient'))();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  TextColumn get syncStatus => text().withDefault(const Constant('pending'))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class FamilyLinks extends Table {
  TextColumn get id => text()();
  TextColumn get patientId => text().references(Profiles, #id)();
  TextColumn get caregiverId => text().references(Profiles, #id)();
  TextColumn get inviteCode => text().nullable()();
  TextColumn get permissionsJson => text().withDefault(const Constant('{}'))();
  DateTimeColumn get expiresAt => dateTime().nullable()();
  DateTimeColumn get revokedAt => dateTime().nullable()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  TextColumn get syncStatus => text().withDefault(const Constant('pending'))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class Vitals extends Table {
  TextColumn get id => text()();
  TextColumn get patientId => text().references(Profiles, #id)();
  TextColumn get type => text()();
  RealColumn get valuePrimary => real()();
  RealColumn get valueSecondary => real().nullable()();
  TextColumn get unit => text()();
  TextColumn get loggedByProfileId => text().references(Profiles, #id)();
  DateTimeColumn get recordedAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  TextColumn get syncStatus => text().withDefault(const Constant('pending'))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class ConditionNotes extends Table {
  TextColumn get id => text()();
  TextColumn get patientId => text().references(Profiles, #id)();
  TextColumn get noteBody => text()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  TextColumn get syncStatus => text().withDefault(const Constant('pending'))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class SosAlerts extends Table {
  TextColumn get id => text()();
  TextColumn get patientId => text().references(Profiles, #id)();
  DateTimeColumn get triggeredAt => dateTime()();
  TextColumn get acknowledgedByJson => text().withDefault(const Constant('[]'))();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  TextColumn get syncStatus => text().withDefault(const Constant('pending'))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class DoctorProfiles extends Table {
  TextColumn get id => text()();
  TextColumn get profileId => text().references(Profiles, #id)();
  TextColumn get specialty => text()();
  TextColumn get licenseNumber => text()();
  TextColumn get clinic => text().nullable()();
  TextColumn get verificationStatus => text().withDefault(const Constant('pending'))();
  DateTimeColumn get verifiedAt => dateTime().nullable()();
  BoolColumn get analyticsSubscribed => boolean().withDefault(const Constant(false))();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  TextColumn get syncStatus => text().withDefault(const Constant('pending'))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class DoctorPatientLinks extends Table {
  TextColumn get id => text()();
  TextColumn get doctorProfileId => text().references(DoctorProfiles, #id)();
  TextColumn get patientId => text().references(Profiles, #id)();
  TextColumn get inviteCode => text().nullable()();
  DateTimeColumn get revokedAt => dateTime().nullable()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  TextColumn get syncStatus => text().withDefault(const Constant('pending'))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class Appointments extends Table {
  TextColumn get id => text()();
  TextColumn get doctorProfileId => text().references(DoctorProfiles, #id)();
  TextColumn get patientId => text().references(Profiles, #id)();
  DateTimeColumn get slotStart => dateTime()();
  DateTimeColumn get slotEnd => dateTime()();
  TextColumn get status => text().withDefault(const Constant('pending'))();
  RealColumn get fee => real().nullable()();
  RealColumn get commissionRate => real().nullable()();
  TextColumn get paymentStatus => text().nullable()();
  BoolColumn get smsConfirmationSent => boolean().withDefault(const Constant(false))();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  TextColumn get syncStatus => text().withDefault(const Constant('pending'))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class AvailabilitySlots extends Table {
  TextColumn get id => text()();
  TextColumn get doctorProfileId => text().references(DoctorProfiles, #id)();
  DateTimeColumn get startAt => dateTime()();
  DateTimeColumn get endAt => dateTime()();
  BoolColumn get isBooked => boolean().withDefault(const Constant(false))();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  TextColumn get syncStatus => text().withDefault(const Constant('pending'))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class Reviews extends Table {
  TextColumn get id => text()();
  TextColumn get doctorProfileId => text().references(DoctorProfiles, #id)();
  TextColumn get patientId => text().references(Profiles, #id)();
  IntColumn get rating => integer()();
  TextColumn get reviewText => text().withDefault(const Constant(''))();
  BoolColumn get flagged => boolean().withDefault(const Constant(false))();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  TextColumn get syncStatus => text().withDefault(const Constant('pending'))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class AppNotifications extends Table {
  TextColumn get id => text()();
  TextColumn get recipientProfileId => text().references(Profiles, #id)();
  TextColumn get title => text()();
  TextColumn get body => text()();
  TextColumn get payloadJson => text().withDefault(const Constant('{}'))();
  BoolColumn get isRead => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  TextColumn get syncStatus => text().withDefault(const Constant('pending'))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class PharmacyOrders extends Table {
  TextColumn get id => text()();
  TextColumn get patientId => text().references(Profiles, #id)();
  TextColumn get medicineId => text().references(Medicines, #id)();
  TextColumn get status => text().withDefault(const Constant('pending'))();
  TextColumn get partnerId => text().nullable()();
  RealColumn get amount => real().nullable()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  TextColumn get syncStatus => text().withDefault(const Constant('pending'))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class AuditLogs extends Table {
  TextColumn get id => text()();
  TextColumn get actorProfileId => text().nullable()();
  TextColumn get action => text()();
  TextColumn get entityType => text()();
  TextColumn get entityId => text().nullable()();
  TextColumn get metadataJson => text().withDefault(const Constant('{}'))();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class SyncQueue extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get entityType => text()();
  TextColumn get entityId => text()();
  TextColumn get operation => text().withDefault(const Constant('upsert'))();
  DateTimeColumn get createdAt => dateTime()();
}
