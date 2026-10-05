abstract final class AppConstants {
  static const String appName = 'MedTrack';
  static const String defaultProfileId = 'local-profile';
  static const Duration doseFollowUpDelay = Duration(minutes: 5);
  static const String syncPending = 'pending';
  static const String syncSynced = 'synced';
  static const String informationalDisclaimer =
      'Informational only — not medical advice. Consult a licensed professional.';
}

enum UserRole { patient, family, doctor, admin }

enum DoseStatus { pending, taken, missed, late }

enum FamilyPermissionScope { full, limited }

enum AppointmentStatus { pending, confirmed, cancelled, completed }

enum DoctorVerificationStatus { pending, verified, rejected }

enum SyncEntityType {
  profile,
  emergencyContact,
  medicalVisit,
  medicine,
  doseLog,
  report,
  userAccount,
  familyLink,
  vital,
  conditionNote,
  sosAlert,
  doctorProfile,
  doctorPatientLink,
  appointment,
  review,
  notification,
  pharmacyOrder,
}
