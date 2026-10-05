import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_constants.dart';
import '../../core/constants/routes.dart';
import '../../core/providers/app_providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_header.dart';
import '../../data/local/app_database.dart';
import '../../data/repositories/medicine_repository.dart';
import '../../data/repositories/profile_repository.dart';
import '../../data/repositories/visit_repository.dart';
import '../../data/repositories/vitals_repository.dart';

enum _MedCardState { completed, active, upcoming }

class _TodayMedItem {
  const _TodayMedItem({
    required this.medicine,
    required this.doseLog,
    required this.scheduledAt,
    required this.state,
    required this.periodLabel,
  });

  final Medicine medicine;
  final DoseLog? doseLog;
  final DateTime scheduledAt;
  final _MedCardState state;
  final String periodLabel;
}

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  String _firstName(String? fullName) {
    if (fullName == null || fullName.trim().isEmpty) return 'there';
    return fullName.trim().split(' ').first;
  }

  String _periodLabel(DateTime time) {
    final hour = time.hour;
    if (hour < 12) return 'Morning';
    if (hour < 17) return 'Noon';
    return 'Evening';
  }

  IconData _periodIcon(DateTime time) {
    final hour = time.hour;
    if (hour < 12) return Icons.wb_sunny_outlined;
    if (hour < 17) return Icons.wb_twilight_outlined;
    return Icons.nightlight_outlined;
  }

  List<_TodayMedItem> _buildTodayMeds(List<Medicine> medicines, List<DoseLog> logs) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = todayStart.add(const Duration(days: 1));

    final todayLogs = logs
        .where((l) => l.scheduledAt.isAfter(todayStart) && l.scheduledAt.isBefore(todayEnd))
        .toList()
      ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));

    final items = <_TodayMedItem>[];

    if (todayLogs.isNotEmpty) {
      for (final log in todayLogs) {
        final medicine = medicines.firstWhere(
          (m) => m.id == log.medicineId,
          orElse: () => Medicine(
            id: log.medicineId,
            profileId: log.profileId,
            name: 'Medicine',
            dosage: '',
            scheduleTimesJson: '[]',
            startDate: now,
            endDate: null,
            isActive: true,
            updatedAt: now,
            deletedAt: null,
            syncStatus: 'pending',
          ),
        );
        final state = switch (log.status) {
          'taken' => _MedCardState.completed,
          'pending' || 'late' =>
            log.scheduledAt.isBefore(now.add(const Duration(minutes: 30)))
                ? _MedCardState.active
                : _MedCardState.upcoming,
          _ => _MedCardState.upcoming,
        };
        items.add(
          _TodayMedItem(
            medicine: medicine,
            doseLog: log,
            scheduledAt: log.scheduledAt,
            state: state,
            periodLabel: _periodLabel(log.scheduledAt),
          ),
        );
      }
      return items;
    }

    for (final med in medicines.where((m) => m.isActive).take(3)) {
      final times = decodeJsonList(med.scheduleTimesJson);
      for (final timeStr in times) {
        final parts = timeStr.split(':');
        if (parts.length != 2) continue;
        final hour = int.tryParse(parts[0]);
        final minute = int.tryParse(parts[1]);
        if (hour == null || minute == null) continue;
        final scheduled = DateTime(now.year, now.month, now.day, hour, minute);
        final state = scheduled.isBefore(now)
            ? _MedCardState.active
            : _MedCardState.upcoming;
        items.add(
          _TodayMedItem(
            medicine: med,
            doseLog: null,
            scheduledAt: scheduled,
            state: state,
            periodLabel: _periodLabel(scheduled),
          ),
        );
      }
    }
    items.sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
    return items.take(3).toList();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileStream = ref.watch(profileRepositoryProvider).watchProfile();
    final medsStream = ref.watch(medicineRepositoryProvider).watchMedicines();
    final dosesStream = ref.watch(medicineRepositoryProvider).watchDoseLogs();
    final visitsStream = ref.watch(visitRepositoryProvider).watchVisits();
    final vitalsStream = ref.watch(vitalsRepositoryProvider).watchVitals(
          patientId: AppConstants.defaultProfileId,
          type: 'blood_pressure',
        );

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(AppRoutes.emergencyId),
        child: const Icon(Icons.badge_outlined),
      ),
      body: SafeArea(
        child: StreamBuilder(
          stream: profileStream,
          builder: (context, profileSnap) {
            return StreamBuilder(
              stream: medsStream,
              builder: (context, medsSnap) {
                return StreamBuilder(
                  stream: dosesStream,
                  builder: (context, dosesSnap) {
                    return StreamBuilder(
                      stream: visitsStream,
                      builder: (context, visitsSnap) {
                        return StreamBuilder(
                          stream: vitalsStream,
                          builder: (context, vitalsSnap) {
                            final profile = profileSnap.data;
                            final medicines = medsSnap.data ?? [];
                            final doses = dosesSnap.data ?? [];
                            final visits = visitsSnap.data ?? [];
                            final vitals = vitalsSnap.data ?? [];
                            final todayMeds = _buildTodayMeds(medicines, doses);
                            final takenCount =
                                todayMeds.where((m) => m.state == _MedCardState.completed).length;
                            final totalCount = todayMeds.length;

                            return ListView(
                              padding: const EdgeInsets.fromLTRB(0, 12, 0, 100),
                              children: [
                                const AppHeader(),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 20),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                const SizedBox(height: 20),
                                Text(
                                  '${_greeting()}, ${_firstName(profile?.name)}',
                                  style: Theme.of(context).textTheme.headlineMedium,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Here is your plan for today.',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                const SizedBox(height: 28),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      "Today's Meds",
                                      style: AppTypography.headlineLgMobile.copyWith(
                                        color: AppColors.primary,
                                        fontSize: 18,
                                      ),
                                    ),
                                    if (totalCount > 0)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.primary,
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          '$takenCount of $totalCount',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                if (todayMeds.isEmpty)
                                  _EmptyMedCard(
                                    onAdd: () => context.push(AppRoutes.addMedicine),
                                  )
                                else
                                  ...todayMeds.map(
                                    (item) => Padding(
                                      padding: const EdgeInsets.only(bottom: 10),
                                      child: _MedCard(
                                        item: item,
                                        periodIcon: _periodIcon(item.scheduledAt),
                                        onTakeNow: item.doseLog != null
                                            ? () => context.push(
                                                  '${AppRoutes.doseConfirm}/${item.doseLog!.id}',
                                                )
                                            : null,
                                      ),
                                    ),
                                  ),
                                const SizedBox(height: 28),
                                const Text(
                                  'Recent Activity',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                if (vitals.isNotEmpty)
                                  _ActivityCard(
                                    icon: Icons.favorite_outline,
                                    iconColor: const Color(0xFF7C3AED),
                                    iconBg: const Color(0xFFF3E8FF),
                                    title: 'Blood Pressure',
                                    value: vitals.first.valueSecondary != null
                                        ? '${vitals.first.valuePrimary.toInt()}/${vitals.first.valueSecondary!.toInt()}'
                                        : '${vitals.first.valuePrimary.toInt()}',
                                    unit: vitals.first.unit.isEmpty ? 'mmHg' : vitals.first.unit,
                                    subtitle:
                                        'Recorded ${DateFormat.jm().format(vitals.first.recordedAt)}',
                                  ),
                                if (visits.isNotEmpty) ...[
                                  if (vitals.isNotEmpty) const SizedBox(height: 10),
                                  _ActivityCard(
                                    icon: Icons.medical_services_outlined,
                                    iconColor: const Color(0xFFEA580C),
                                    iconBg: const Color(0xFFFFEDD5),
                                    title: visits.first.doctorName.isEmpty
                                        ? 'Doctor Visit'
                                        : '${visits.first.doctorName} Visit',
                                    value: visits.first.diagnosis.isEmpty
                                        ? 'Checkup completed'
                                        : visits.first.diagnosis,
                                    unit: null,
                                    subtitle: DateFormat.yMMMd().format(visits.first.visitDate),
                                  ),
                                ],
                                if (vitals.isEmpty && visits.isEmpty)
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: AppColors.outlineVariant),
                                    ),
                                    child: const Text(
                                      'No recent activity yet. Log a visit or vital to see it here.',
                                      style: TextStyle(color: AppColors.onSurfaceVariant),
                                    ),
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
            );
          },
        ),
      ),
    );
  }
}

class _MedCard extends StatelessWidget {
  const _MedCard({
    required this.item,
    required this.periodIcon,
    this.onTakeNow,
  });

  final _TodayMedItem item;
  final IconData periodIcon;
  final VoidCallback? onTakeNow;

  @override
  Widget build(BuildContext context) {
    final borderColor = switch (item.state) {
      _MedCardState.completed => AppColors.primary.withValues(alpha: 0.5),
      _MedCardState.active => AppColors.primary,
      _MedCardState.upcoming => AppColors.outlineVariant,
    };
    final borderWidth = item.state == _MedCardState.active ? 4.0 : 3.0;
    final isCompleted = item.state == _MedCardState.completed;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: borderWidth,
              decoration: BoxDecoration(
                color: borderColor,
                borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                child: Row(
                  children: [
                    Icon(periodIcon, color: AppColors.onSurfaceVariant, size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${item.medicine.name} (${item.medicine.dosage})',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: isCompleted ? AppColors.onSurfaceVariant : AppColors.onSurface,
                              decoration: isCompleted ? TextDecoration.lineThrough : null,
                              decorationColor: AppColors.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${item.periodLabel} • ${_mealHint(item.periodLabel)}',
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isCompleted)
                      const Icon(Icons.check_circle, color: AppColors.primary, size: 26)
                    else if (item.state == _MedCardState.active && onTakeNow != null)
                      FilledButton(
                        onPressed: onTakeNow,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.secondaryBright,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: const Text(
                          'Take Now',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                      )
                    else
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.outlineVariant, width: 2),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _mealHint(String period) {
    return switch (period) {
      'Morning' => 'With food',
      'Noon' => 'After lunch',
      _ => 'Before bed',
    };
  }
}

class _EmptyMedCard extends StatelessWidget {
  const _EmptyMedCard({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Column(
        children: [
          const Text(
            'No medicines scheduled for today.',
            style: TextStyle(color: AppColors.onSurfaceVariant),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: onAdd,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            child: const Text('Add medicine'),
          ),
        ],
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.value,
    required this.subtitle,
    this.unit,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String value;
  final String? unit;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: title == 'Blood Pressure' ? AppColors.primary : AppColors.onSurface,
                      ),
                    ),
                    if (unit != null) ...[
                      const SizedBox(width: 4),
                      Text(
                        unit!,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
