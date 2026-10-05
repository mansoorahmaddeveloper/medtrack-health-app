import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_constants.dart';
import '../../core/providers/app_providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_components.dart';
import '../../core/widgets/app_header.dart';
import '../../data/local/app_database.dart';
import '../../data/repositories/medicine_repository.dart';
import '../../data/repositories/profile_repository.dart';
import '../../data/repositories/vitals_repository.dart';

class EmergencyIdScreen extends ConsumerWidget {
  const EmergencyIdScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileRepo = ref.watch(profileRepositoryProvider);
    final medRepo = ref.watch(medicineRepositoryProvider);
    final vitalsRepo = ref.watch(vitalsRepositoryProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: StreamBuilder(
          stream: profileRepo.watchProfile(),
          builder: (context, profileSnap) {
            return StreamBuilder(
              stream: profileRepo.watchEmergencyContacts(),
              builder: (context, contactSnap) {
                return StreamBuilder(
                  stream: medRepo.watchMedicines(),
                  builder: (context, medSnap) {
                    return StreamBuilder(
                      stream: vitalsRepo.watchConditionNotes(AppConstants.defaultProfileId),
                      builder: (context, conditionSnap) {
                        final profile = profileSnap.data;
                        final contacts = contactSnap.data ?? [];
                        final meds = medSnap.data ?? [];
                        final conditions = conditionSnap.data ?? [];
                        final allergies = decodeJsonList(profile?.allergiesJson ?? '[]');
                        final primaryContact = contacts.isNotEmpty ? contacts.first : null;

                        final payload = jsonEncode({
                          'name': profile?.name ?? '',
                          'bloodType': profile?.bloodType,
                          'allergies': allergies,
                          'medications': meds.map((m) => '${m.name} ${m.dosage}').toList(),
                          'emergencyContacts': contacts
                              .map((c) => {'name': c.name, 'phone': c.phone})
                              .toList(),
                        });

                        return ListView(
                          padding: const EdgeInsets.only(bottom: 32),
                          children: [
                            const AppHeader(showBack: true, title: 'Emergency ID'),
                            Padding(
                              padding: const EdgeInsets.all(AppSpacing.containerPadding),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _MedicalIdCard(
                                    profile: profile,
                                    allergies: allergies,
                                    conditions: conditions,
                                  ),
                                  const SizedBox(height: AppSpacing.sectionGap),
                                  Text('EMERGENCY CONTACT', style: AppTypography.labelSm),
                                  const SizedBox(height: AppSpacing.stackGap),
                                  if (primaryContact != null)
                                    _EmergencyContactCard(contact: primaryContact)
                                  else
                                    _EmptyContactCard(),
                                  const SizedBox(height: AppSpacing.sectionGap),
                                  Center(
                                    child: QrImageView(
                                      data: payload,
                                      version: QrVersions.auto,
                                      size: 140,
                                      backgroundColor: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Scan for full emergency payload',
                                    textAlign: TextAlign.center,
                                    style: AppTypography.labelSm,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _MedicalIdCard extends StatelessWidget {
  const _MedicalIdCard({
    required this.profile,
    required this.allergies,
    required this.conditions,
  });

  final Profile? profile;
  final List<String> allergies;
  final List<ConditionNote> conditions;

  @override
  Widget build(BuildContext context) {
    final name = profile?.name.isNotEmpty == true ? profile!.name : 'Your name';
    final dob = profile?.dateOfBirth != null
        ? DateFormat('MMM d, yyyy').format(profile!.dateOfBirth!)
        : 'Not set';
    final bloodType = profile?.bloodType ?? '—';
    final initials = name
        .split(' ')
        .where((p) => p.isNotEmpty)
        .take(2)
        .map((p) => p[0].toUpperCase())
        .join();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: AppElevation.card,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: AppColors.error,
            child: Row(
              children: [
                const Icon(Icons.medical_services, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(
                  'MEDICAL ID',
                  style: AppTypography.labelLg.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
                const Spacer(),
                Icon(Icons.warning_amber_rounded, color: Colors.white.withValues(alpha: 0.9)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.gutter),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.primary, width: 3),
                        color: AppColors.primaryContainer,
                      ),
                      child: Center(
                        child: Text(
                          initials,
                          style: AppTypography.headlineLgMobile.copyWith(color: AppColors.primary),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name, style: AppTypography.headlineLgMobile),
                          const SizedBox(height: 4),
                          Text('DOB: $dob', style: AppTypography.bodyMd),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.gutter),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.errorContainer.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'BLOOD TYPE',
                              style: AppTypography.labelSm.copyWith(
                                color: AppColors.error,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              bloodType,
                              style: AppTypography.headlineLgMobile.copyWith(
                                color: AppColors.error,
                                fontSize: 28,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: AppCard(
                        leftAccent: AppColors.primary,
                        padding: const EdgeInsets.all(14),
                        elevated: false,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'CONDITIONS',
                              style: AppTypography.labelSm.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 6),
                            if (conditions.isEmpty)
                              Text('None listed', style: AppTypography.bodyMd)
                            else
                              ...conditions.take(3).map(
                                    (c) => Padding(
                                      padding: const EdgeInsets.only(bottom: 2),
                                      child: Text(c.noteBody, style: AppTypography.bodyMd),
                                    ),
                                  ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border(
                      left: BorderSide(color: AppColors.error, width: 4),
                      top: BorderSide(color: AppColors.outlineVariant),
                      right: BorderSide(color: AppColors.outlineVariant),
                      bottom: BorderSide(color: AppColors.outlineVariant),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.coronavirus_outlined, color: AppColors.error, size: 18),
                          const SizedBox(width: 6),
                          Text(
                            'SEVERE ALLERGIES',
                            style: AppTypography.labelSm.copyWith(
                              color: AppColors.error,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (allergies.isEmpty)
                        Text('None listed', style: AppTypography.bodyMd)
                      else
                        ...allergies.map(
                          (a) => Padding(
                            padding: const EdgeInsets.only(bottom: 2),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('• ', style: TextStyle(fontSize: 16)),
                                Expanded(child: Text(a, style: AppTypography.bodyMd)),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmergencyContactCard extends StatelessWidget {
  const _EmergencyContactCard({required this.contact});

  final EmergencyContact contact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.outlineVariant),
        boxShadow: AppElevation.card,
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.secondaryContainer,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person, color: AppColors.secondaryBright),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(contact.name, style: AppTypography.labelLg),
                Text(
                  contact.relationship ?? 'Emergency contact',
                  style: AppTypography.labelSm,
                ),
              ],
            ),
          ),
          Material(
            color: AppColors.primary,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () => launchUrl(Uri.parse('tel:${contact.phone}')),
              child: const SizedBox(
                width: 44,
                height: 44,
                child: Icon(Icons.phone, color: Colors.white, size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyContactCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Text('Add an emergency contact in Profile settings.', style: AppTypography.bodyMd),
    );
  }
}
