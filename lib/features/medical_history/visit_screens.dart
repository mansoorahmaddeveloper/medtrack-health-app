import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/constants/routes.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_components.dart';
import '../../core/widgets/app_header.dart';
import '../../core/widgets/app_toast.dart';
import '../../data/local/app_database.dart';
import '../../data/repositories/visit_repository.dart';

class VisitListScreen extends ConsumerStatefulWidget {
  const VisitListScreen({super.key});

  @override
  ConsumerState<VisitListScreen> createState() => _VisitListScreenState();
}

class _VisitListScreenState extends ConsumerState<VisitListScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(visitRepositoryProvider);
    final fmt = DateFormat('MMM d, yyyy');

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(AppRoutes.addVisit),
        child: const Icon(Icons.add),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppHeader(),
            const SizedBox(height: AppSpacing.stackGap),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.containerPadding),
              child: Row(
                children: [
                  Expanded(
                    child: AppSearchField(
                      hint: 'Search history...',
                      onChanged: (v) => setState(() => _query = v),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Material(
                    color: AppColors.surfaceContainer,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    child: InkWell(
                      onTap: () => AppToast.success(context, 'Filters applied'),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      child: const SizedBox(
                        width: AppSpacing.touchTargetMin,
                        height: AppSpacing.touchTargetMin,
                        child: Icon(Icons.tune, color: AppColors.onSurfaceVariant),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.stackGap),
            Expanded(
              child: StreamBuilder<List<MedicalVisit>>(
                stream: repo.watchVisits(query: _query),
                builder: (context, snapshot) {
                  final visits = snapshot.data ?? [];
                  if (visits.isEmpty) {
                    return EmptyState(
                      message: 'No visits logged yet.',
                      actionLabel: 'Add visit',
                      onAction: () => context.push(AppRoutes.addVisit),
                      icon: Icons.history,
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.containerPadding,
                      0,
                      AppSpacing.containerPadding,
                      100,
                    ),
                    itemCount: visits.length,
                    itemBuilder: (context, i) {
                      final v = visits[i];
                      final accent = i.isEven ? AppColors.primary : AppColors.secondaryBright;
                      final iconColor = i.isEven ? AppColors.primary : AppColors.secondaryBright;
                      final icon = i.isEven ? Icons.medical_services_outlined : Icons.assignment_outlined;
                      return _TimelineVisitCard(
                        visit: v,
                        accent: accent,
                        icon: icon,
                        iconColor: iconColor,
                        dateLabel: fmt.format(v.visitDate),
                        onTap: () {
                          AppToast.success(context, 'Opening visit details');
                          context.push('${AppRoutes.visitDetail}/${v.id}');
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimelineVisitCard extends StatelessWidget {
  const _TimelineVisitCard({
    required this.visit,
    required this.accent,
    required this.icon,
    required this.iconColor,
    required this.dateLabel,
    required this.onTap,
  });

  final MedicalVisit visit;
  final Color accent;
  final IconData icon;
  final Color iconColor;
  final String dateLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 40,
            child: Column(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(color: iconColor, shape: BoxShape.circle),
                  child: Icon(icon, color: Colors.white, size: 18),
                ),
                Expanded(
                  child: Container(width: 2, color: AppColors.outlineVariant),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sectionGap),
              child: AppCard(
                leftAccent: accent,
                leftAccentWidth: 5,
                onTap: onTap,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            visit.doctorName.isEmpty ? 'Doctor' : visit.doctorName,
                            style: AppTypography.labelLg,
                          ),
                        ),
                        Text(dateLabel, style: AppTypography.labelSm),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      visit.diagnosis.isEmpty ? 'General Checkup' : visit.diagnosis,
                      style: AppTypography.bodyMd.copyWith(color: AppColors.onSurface),
                    ),
                    if (visit.notes.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        visit.notes,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.labelSm,
                      ),
                    ],
                    if (visit.clinic.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainer,
                          borderRadius: BorderRadius.circular(AppRadius.full),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.local_hospital_outlined, size: 14, color: AppColors.outline),
                            const SizedBox(width: 4),
                            Text(visit.clinic, style: AppTypography.labelSm),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AddVisitScreen extends ConsumerStatefulWidget {
  const AddVisitScreen({super.key, this.visitId});

  final String? visitId;

  @override
  ConsumerState<AddVisitScreen> createState() => _AddVisitScreenState();
}

class _AddVisitScreenState extends ConsumerState<AddVisitScreen> {
  final _doctor = TextEditingController();
  final _clinic = TextEditingController();
  final _diagnosis = TextEditingController();
  final _notes = TextEditingController();
  DateTime _date = DateTime.now();

  @override
  void dispose() {
    _doctor.dispose();
    _clinic.dispose();
    _diagnosis.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const AppHeader(showBack: true, title: 'Add Visit'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.containerPadding),
                children: [
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Date of Visit', style: AppTypography.labelLg),
                        const SizedBox(height: 4),
                        Text(
                          'When did this appointment happen?',
                          style: AppTypography.labelSm,
                        ),
                        const SizedBox(height: 12),
                        InkWell(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _date,
                              firstDate: DateTime(2000),
                              lastDate: DateTime.now(),
                            );
                            if (picked != null) setState(() => _date = picked);
                          },
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              hintText: 'mm/dd/yyyy',
                              suffixIcon: Icon(Icons.calendar_today, color: AppColors.primary),
                            ),
                            child: Text(
                              DateFormat('MM/dd/yyyy').format(_date),
                              style: AppTypography.bodyMd.copyWith(color: AppColors.onSurface),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.stackGap),
                  _LabeledField(
                    label: 'Doctor Name',
                    controller: _doctor,
                    hint: 'Dr. Smith',
                    icon: Icons.person_outline,
                  ),
                  const SizedBox(height: AppSpacing.stackGap),
                  _LabeledField(
                    label: 'Clinic / Hospital',
                    controller: _clinic,
                    hint: 'City General Hospital',
                    icon: Icons.local_hospital_outlined,
                  ),
                  const SizedBox(height: AppSpacing.stackGap),
                  _LabeledField(
                    label: 'Diagnosis',
                    controller: _diagnosis,
                    hint: 'Routine checkup, Hypertension…',
                    icon: Icons.assignment_outlined,
                  ),
                  const SizedBox(height: AppSpacing.stackGap),
                  Text('Notes', style: AppTypography.labelLg),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _notes,
                    maxLines: 4,
                    style: AppTypography.bodyMd.copyWith(color: AppColors.onSurface),
                    decoration: const InputDecoration(
                      hintText: 'Any specific instructions, next steps, or how you felt…',
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sectionGap),
                  AppPrimaryButton(
                    label: 'Save Visit',
                    icon: Icons.save_outlined,
                    onPressed: () async {
                      await ref.read(visitRepositoryProvider).saveVisit(
                            id: widget.visitId,
                            visitDate: _date,
                            doctorName: _doctor.text.trim(),
                            clinic: _clinic.text.trim(),
                            diagnosis: _diagnosis.text.trim(),
                            notes: _notes.text.trim(),
                          );
                      if (!context.mounted) return;
                      AppToast.success(context, 'Visit saved successfully');
                      context.pop();
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LabeledField extends StatelessWidget {
  const _LabeledField({
    required this.label,
    required this.controller,
    required this.hint,
    required this.icon,
  });

  final String label;
  final TextEditingController controller;
  final String hint;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.labelLg),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          style: AppTypography.bodyMd.copyWith(color: AppColors.onSurface),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: AppColors.primary),
          ),
        ),
      ],
    );
  }
}

class VisitDetailScreen extends ConsumerWidget {
  const VisitDetailScreen({super.key, required this.visitId});

  final String visitId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder(
      future: ref.read(visitRepositoryProvider).getVisit(visitId),
      builder: (context, snapshot) {
        final visit = snapshot.data;
        if (visit == null) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        return Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: Column(
              children: [
                const AppHeader(showBack: true, title: 'Visit Details'),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(AppSpacing.containerPadding),
                    children: [
                      AppCard(
                        leftAccent: AppColors.primary,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              visit.diagnosis.isEmpty ? 'Visit' : visit.diagnosis,
                              style: AppTypography.headlineLgMobile,
                            ),
                            const SizedBox(height: 8),
                            Text('${visit.doctorName} • ${visit.clinic}', style: AppTypography.bodyMd),
                            const SizedBox(height: 4),
                            Text(
                              DateFormat.yMMMd().format(visit.visitDate),
                              style: AppTypography.labelSm,
                            ),
                            if (visit.notes.isNotEmpty) ...[
                              const SizedBox(height: AppSpacing.stackGap),
                              Text(visit.notes, style: AppTypography.bodyMd),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
