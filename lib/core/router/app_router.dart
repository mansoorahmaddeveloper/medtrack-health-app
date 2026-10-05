import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../constants/routes.dart';
import '../navigation/app_navigator.dart';
import '../../features/admin/admin_screens.dart';
import '../../features/ai/ai_screens.dart';
import '../../features/appointments/appointment_screens.dart';
import '../../features/auth/auth_screens.dart';
import '../../features/doctor/doctor_screens.dart';
import '../../features/emergency_id/emergency_id_screen.dart';
import '../../features/export/export_screen.dart';
import '../../features/family/family_screens.dart';
import '../../features/home/home_screen.dart';
import '../../features/medical_history/visit_screens.dart';
import '../../features/medicines/dose_confirm_screen.dart';
import '../../features/medicines/medicine_screens.dart';
import '../../features/pharmacy/pharmacy_screens.dart';
import '../../features/profile/profile_screens.dart';
import '../../features/reports/report_screens.dart';
import '../../features/shell/patient_shell.dart';
import '../../features/sos/sos_screen.dart';
import '../../features/vitals/vitals_screens.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    initialLocation: AppRoutes.home,
    routes: [
      ShellRoute(
        builder: (context, state, child) => PatientShell(child: child),
        routes: [
          GoRoute(path: AppRoutes.home, builder: (_, __) => const HomeScreen()),
          GoRoute(path: AppRoutes.medicines, builder: (_, __) => const MedicineListScreen()),
          GoRoute(path: AppRoutes.history, builder: (_, __) => const VisitListScreen()),
          GoRoute(path: AppRoutes.reports, builder: (_, __) => const ReportLibraryScreen()),
          GoRoute(path: AppRoutes.profile, builder: (_, __) => const ProfileScreen()),
        ],
      ),
      GoRoute(path: AppRoutes.editProfile, builder: (_, __) => const EditProfileScreen()),
      GoRoute(path: AppRoutes.emergencyContacts, builder: (_, __) => const EmergencyContactsScreen()),
      GoRoute(path: AppRoutes.emergencyId, builder: (_, __) => const EmergencyIdScreen()),
      GoRoute(path: AppRoutes.addVisit, builder: (_, __) => const AddVisitScreen()),
      GoRoute(
        path: '${AppRoutes.visitDetail}/:id',
        builder: (_, state) => VisitDetailScreen(visitId: state.pathParameters['id']!),
      ),
      GoRoute(path: AppRoutes.addMedicine, builder: (_, __) => const AddMedicineScreen()),
      GoRoute(
        path: '${AppRoutes.doseConfirm}/:id',
        builder: (_, state) => DoseConfirmScreen(doseLogId: state.pathParameters['id']!),
      ),
      GoRoute(path: AppRoutes.adherence, builder: (_, __) => const AdherenceScreen()),
      GoRoute(path: AppRoutes.scanReport, builder: (_, __) => const ScanReportScreen()),
      GoRoute(
        path: '${AppRoutes.reportDetail}/:id',
        builder: (_, state) => ReportDetailScreen(reportId: state.pathParameters['id']!),
      ),
      GoRoute(path: AppRoutes.export, builder: (_, __) => const ExportScreen()),
      GoRoute(path: AppRoutes.login, builder: (_, __) => const LoginScreen()),
      GoRoute(
        path: AppRoutes.otp,
        builder: (_, state) {
          final extra = state.extra as Map<String, String?>? ?? {};
          return OtpVerifyScreen(email: extra['email'], phone: extra['phone']);
        },
      ),
      GoRoute(path: AppRoutes.familyDashboard, builder: (_, __) => const FamilyDashboardScreen()),
      GoRoute(path: AppRoutes.familyInvite, builder: (_, __) => const FamilyInviteScreen()),
      GoRoute(path: AppRoutes.linkPatient, builder: (_, __) => const LinkPatientScreen()),
      GoRoute(path: AppRoutes.vitals, builder: (_, __) => const VitalsScreen()),
      GoRoute(path: AppRoutes.conditionNotes, builder: (_, __) => const ConditionNotesScreen()),
      GoRoute(path: AppRoutes.familyHealthTree, builder: (_, __) => const FamilyHealthTreeScreen()),
      GoRoute(path: AppRoutes.sos, builder: (_, __) => const SosScreen()),
      GoRoute(path: AppRoutes.doctorSignup, builder: (_, __) => const DoctorSignupScreen()),
      GoRoute(path: AppRoutes.doctorDashboard, builder: (_, __) => const DoctorDashboardScreen()),
      GoRoute(
        path: '${AppRoutes.doctorPatient}/:id',
        builder: (_, state) => DoctorPatientScreen(patientId: state.pathParameters['id']!),
      ),
      GoRoute(path: AppRoutes.doctorAnalytics, builder: (_, __) => const DoctorAnalyticsScreen()),
      GoRoute(path: AppRoutes.manageSlots, builder: (_, __) => const ManageSlotsScreen()),
      GoRoute(path: AppRoutes.bookAppointment, builder: (_, __) => const BookAppointmentScreen()),
      GoRoute(path: AppRoutes.aiMedicine, builder: (_, __) => const AiMedicineScreen()),
      GoRoute(path: AppRoutes.aiTriage, builder: (_, __) => const AiTriageScreen()),
      GoRoute(path: AppRoutes.secondOpinion, builder: (_, __) => const SecondOpinionScreen()),
      GoRoute(
        path: '${AppRoutes.pharmacyOrder}/:medicineId',
        builder: (_, state) => PharmacyOrderScreen(medicineId: state.pathParameters['medicineId']!),
      ),
      GoRoute(path: '/pharmacy/orders', builder: (_, __) => const PharmacyOrdersListScreen()),
      GoRoute(path: AppRoutes.adminHome, builder: (_, __) => const AdminHomeScreen()),
      GoRoute(path: AppRoutes.adminDoctors, builder: (_, __) => const AdminDoctorVerificationScreen()),
      GoRoute(path: AppRoutes.adminUsers, builder: (_, __) => const AdminUsersScreen()),
      GoRoute(path: AppRoutes.adminReviews, builder: (_, __) => const AdminReviewsScreen()),
      GoRoute(path: AppRoutes.adminAudit, builder: (_, __) => const AdminAuditScreen()),
    ],
  );
  AppNavigator.bind(router);
  return router;
});

final adminRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.adminHome,
    routes: [
      GoRoute(path: AppRoutes.adminHome, builder: (_, __) => const AdminHomeScreen()),
      GoRoute(path: AppRoutes.adminDoctors, builder: (_, __) => const AdminDoctorVerificationScreen()),
      GoRoute(path: AppRoutes.adminUsers, builder: (_, __) => const AdminUsersScreen()),
      GoRoute(path: AppRoutes.adminReviews, builder: (_, __) => const AdminReviewsScreen()),
      GoRoute(path: AppRoutes.adminAudit, builder: (_, __) => const AdminAuditScreen()),
    ],
  );
});
