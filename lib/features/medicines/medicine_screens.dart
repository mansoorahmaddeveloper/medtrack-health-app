import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/constants/routes.dart';
import '../../core/providers/app_providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_components.dart';
import '../../core/widgets/app_toast.dart';
import '../../data/repositories/medicine_repository.dart';

class MedicineListScreen extends ConsumerWidget {
  const MedicineListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(medicineRepositoryProvider);
    return AppScreen(
      title: 'Medicines',
      subtitle: 'Track doses and stay on schedule.',
      actions: [
        IconButton(
          icon: const Icon(Icons.insights_outlined),
          tooltip: 'Adherence',
          onPressed: () => context.push(AppRoutes.adherence),
        ),
      ],
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(AppRoutes.addMedicine),
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder(
        stream: repo.watchMedicines(),
        builder: (context, snapshot) {
          final meds = snapshot.data ?? [];
          if (meds.isEmpty) {
            return EmptyState(
              message: 'No medicines yet. Add your first prescription to start reminders.',
              actionLabel: 'Add medicine',
              onAction: () => context.push(AppRoutes.addMedicine),
              icon: Icons.medication_outlined,
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.containerPadding,
              0,
              AppSpacing.containerPadding,
              100,
            ),
            itemCount: meds.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.stackGap),
            itemBuilder: (context, i) {
              final m = meds[i];
              final times = decodeJsonList(m.scheduleTimesJson);
              return AppCard(
                leftAccent: m.isActive ? AppColors.primary : AppColors.outlineVariant,
                onTap: () {},
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.10),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.medication, color: AppColors.primary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(m.name, style: AppTypography.labelLg),
                          const SizedBox(height: 4),
                          Text(
                            '${m.dosage} • ${times.join(', ')}',
                            style: AppTypography.labelSm,
                          ),
                        ],
                      ),
                    ),
                    if (!m.isActive)
                      Text('Inactive', style: AppTypography.labelSm),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class AddMedicineScreen extends ConsumerStatefulWidget {
  const AddMedicineScreen({super.key});

  @override
  ConsumerState<AddMedicineScreen> createState() => _AddMedicineScreenState();
}

class _AddMedicineScreenState extends ConsumerState<AddMedicineScreen> {
  final _name = TextEditingController();
  final _dosage = TextEditingController();
  final _times = <TimeOfDay>[];

  @override
  void dispose() {
    _name.dispose();
    _dosage.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Add medicine')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.containerPadding),
        children: [
          AppTextField(controller: _name, label: 'Medicine name'),
          const SizedBox(height: AppSpacing.stackGap),
          AppTextField(controller: _dosage, label: 'Dosage'),
          const SizedBox(height: AppSpacing.stackGap),
          SectionHeader(
            title: 'Dose times',
            usePrimaryColor: false,
            trailing: IconButton(
              icon: const Icon(Icons.add_alarm),
              onPressed: () async {
                final t = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.now(),
                );
                if (t != null) setState(() => _times.add(t));
              },
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _times
                .map(
                  (t) => AppFilterChip(
                    label: t.format(context),
                    selected: true,
                    onTap: () => setState(() => _times.remove(t)),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: AppSpacing.sectionGap),
          AppPrimaryButton(
            label: 'Save medicine',
            onPressed: () async {
              if (_name.text.trim().isEmpty || _times.isEmpty) {
                AppToast.error(context, 'Name and at least one time are required');
                return;
              }
              final schedule = _times.map((t) {
                final h = t.hour.toString().padLeft(2, '0');
                final m = t.minute.toString().padLeft(2, '0');
                return '$h:$m';
              }).toList();
              await ref.read(medicineRepositoryProvider).saveMedicine(
                    name: _name.text.trim(),
                    dosage: _dosage.text.trim(),
                    scheduleTimes: schedule,
                    startDate: DateTime.now(),
                  );
              if (context.mounted) {
                AppToast.successThenPop(context, 'Medicine saved successfully');
              }
            },
          ),
        ],
      ),
    );
  }
}


class AdherenceScreen extends ConsumerWidget {
  const AdherenceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(medicineRepositoryProvider);
    final fmt = DateFormat.yMMMd().add_jm();
    return AppScreen(
      title: 'Adherence',
      subtitle: 'Your dose history over time.',
      body: StreamBuilder(
        stream: repo.watchDoseLogs(),
        builder: (context, snapshot) {
          final logs = snapshot.data ?? [];
          if (logs.isEmpty) {
            return const EmptyState(
              message: 'No dose history yet.',
              icon: Icons.event_note_outlined,
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.containerPadding,
              0,
              AppSpacing.containerPadding,
              AppSpacing.containerPadding,
            ),
            itemCount: logs.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.stackGap),
            itemBuilder: (context, i) {
              final log = logs[i];
              final color = switch (log.status) {
                'taken' => AppColors.primary,
                'missed' => AppColors.error,
                _ => AppColors.secondaryBright,
              };
              return AppCard(
                leftAccent: color,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(log.status.toUpperCase(), style: AppTypography.labelLg),
                    Text(fmt.format(log.scheduledAt), style: AppTypography.labelSm),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
