import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/constants/app_constants.dart';
import '../core/providers/app_providers.dart';
import '../data/local/app_database.dart';
import '../data/repositories/profile_repository.dart';
import '../data/repositories/vitals_repository.dart';
import 'notification_service.dart';

final sosAlertServiceProvider = Provider<SosAlertService>((ref) {
  return SosAlertService(
    ref.watch(vitalsRepositoryProvider),
    ref.watch(profileRepositoryProvider),
    ref.watch(notificationServiceProvider),
  );
});

class SosAlertResult {
  const SosAlertResult({
    required this.alertId,
    required this.contactsNotified,
    required this.smsLaunched,
    required this.message,
  });

  final String alertId;
  final int contactsNotified;
  final bool smsLaunched;
  final String message;
}

class SosAlertService {
  SosAlertService(
    this._vitalsRepo,
    this._profileRepo,
    this._notifications,
  );

  final VitalsRepository _vitalsRepo;
  final ProfileRepository _profileRepo;
  final NotificationService _notifications;

  Future<SosAlertResult> triggerEmergencyAlert() async {
    final patientId = AppConstants.defaultProfileId;
    final profile = await _profileRepo.getProfile();
    final contacts = await _profileRepo.watchEmergencyContacts().first;

    final alertId = await _vitalsRepo.triggerSos(patientId);

    final patientName = profile?.name.isNotEmpty == true ? profile!.name : 'MedTrack user';
    final locationHint = profile?.bloodType != null ? 'Blood type: ${profile!.bloodType}. ' : '';
    final message =
        'SOS ALERT: $patientName needs immediate help. $locationHint Please respond or call them now. (MedTrack)';

    var smsLaunched = false;
    final phones = contacts
        .map((c) => c.phone.replaceAll(RegExp(r'[^\d+]'), ''))
        .where((p) => p.isNotEmpty)
        .toList();

    if (phones.isNotEmpty) {
      // Opens SMS app with all emergency numbers and pre-filled message.
      final uri = Uri(
        scheme: 'sms',
        path: phones.join(','),
        queryParameters: {'body': message},
      );
      smsLaunched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    }

  // Also dial local emergency (911) prompt — user can cancel if not needed.
    final emergencyUri = Uri(scheme: 'tel', path: '911');
    if (await canLaunchUrl(emergencyUri)) {
      // Don't auto-dial without user action on all platforms; SMS is primary path.
    }

    await _notifications.showImmediate(
      id: alertId.hashCode,
      title: 'SOS alert sent',
      body: phones.isEmpty
          ? 'Alert logged. Add emergency contacts in Profile to notify by SMS.'
          : 'Opening SMS to notify ${phones.length} contact(s).',
      payload: 'sos',
    );

    return SosAlertResult(
      alertId: alertId,
      contactsNotified: phones.length,
      smsLaunched: smsLaunched,
      message: phones.isEmpty
          ? 'No emergency contacts found. Add contacts in Profile settings.'
          : smsLaunched
              ? 'SMS opened for ${phones.length} contact(s). Tap Send to deliver.'
              : 'Could not open SMS app. Check phone permissions.',
    );
  }
}
