import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_components.dart';
import '../../core/widgets/app_toast.dart';
import '../../data/local/app_database.dart';
import '../../data/repositories/medicine_repository.dart';

class DoseConfirmScreen extends ConsumerStatefulWidget {
  const DoseConfirmScreen({super.key, required this.doseLogId});

  final String doseLogId;

  @override
  ConsumerState<DoseConfirmScreen> createState() => _DoseConfirmScreenState();
}

class _DoseConfirmScreenState extends ConsumerState<DoseConfirmScreen> {
  DoseLog? _dose;
  Medicine? _medicine;
  bool _loading = true;
  bool _notFound = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final repo = ref.read(medicineRepositoryProvider);
    final dose = await repo.getDoseLog(widget.doseLogId);
    if (!mounted) return;
    if (dose == null) {
      setState(() {
        _loading = false;
        _notFound = true;
      });
      return;
    }
    final medicine = await repo.getMedicine(dose.medicineId);
    if (!mounted) return;
    setState(() {
      _dose = dose;
      _medicine = medicine;
      _loading = false;
    });
  }

  Future<void> _run(Future<void> action, String toastMessage) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action;
      if (!mounted) return;
      AppToast.successThenPop(context, toastMessage);
    } catch (e) {
      if (!mounted) return;
      AppToast.error(context, 'Something went wrong. Please try again.');
      setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_notFound || _dose == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: const Text('Dose')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.containerPadding),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.medication_outlined, size: 48, color: AppColors.outline),
                const SizedBox(height: 16),
                Text('Dose not found', style: AppTypography.headlineLgMobile),
                const SizedBox(height: 8),
                Text(
                  'This reminder may have expired or was already logged.',
                  textAlign: TextAlign.center,
                  style: AppTypography.bodyMd,
                ),
                const SizedBox(height: 24),
                AppPrimaryButton(
                  label: 'Go back',
                  expanded: false,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final dose = _dose!;
    final name = _medicine?.name ?? 'Medicine';
    final dosage = _medicine?.dosage ?? '';
    final timeFmt = DateFormat('hh:mm a');
    final period = _periodLabel(dose.scheduledAt);
    final mealHint = _mealHint(period);
    final repo = ref.read(medicineRepositoryProvider);

    return Scaffold(
      backgroundColor: AppColors.primaryFixedDim.withValues(alpha: 0.08),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.containerPadding),
          child: Column(
            children: [
              const Spacer(flex: 1),
              Text('Right now', style: AppTypography.labelSm),
              const SizedBox(height: 8),
              Text(
                timeFmt.format(dose.scheduledAt),
                style: AppTypography.headlineXl.copyWith(color: AppColors.primary),
              ),
              const SizedBox(height: AppSpacing.sectionGap),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.containerPadding),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                  boxShadow: AppElevation.card,
                ),
                child: Column(
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainer,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.medication_liquid,
                        size: 36,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.stackGap),
                    Text(name, style: AppTypography.headlineLgMobile),
                    const SizedBox(height: 4),
                    Text(
                      dosage.isEmpty ? 'As prescribed' : dosage,
                      style: AppTypography.bodyMd,
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(AppRadius.full),
                      ),
                      child: Text(
                        mealHint,
                        style: AppTypography.labelSm.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.stackGap),
                    Text(
                      "It's time to take your $period medication.",
                      textAlign: TextAlign.center,
                      style: AppTypography.bodyMd,
                    ),
                  ],
                ),
              ),
              const Spacer(flex: 2),
              AppPrimaryButton(
                label: 'I took it',
                icon: Icons.check_circle_outline,
                onPressed: _busy
                    ? null
                    : () => _run(
                          repo.confirmDose(widget.doseLogId),
                          'Dose logged successfully',
                        ),
              ),
              const SizedBox(height: 12),
              AppOutlineButton(
                label: 'Snooze for 15m',
                icon: Icons.alarm,
                onPressed: _busy
                    ? null
                    : () => _run(
                          repo.snoozeDose(widget.doseLogId),
                          'Reminder snoozed for 15 minutes',
                        ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: _busy
                    ? null
                    : () => _run(
                          repo.skipDose(widget.doseLogId),
                          'Dose skipped',
                        ),
                child: Text(
                  'Skip Dose',
                  style: AppTypography.labelLg.copyWith(color: AppColors.onSurfaceVariant),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  String _periodLabel(DateTime time) {
    final hour = time.hour;
    if (hour < 12) return 'morning';
    if (hour < 17) return 'afternoon';
    return 'evening';
  }

  String _mealHint(String period) {
    return switch (period) {
      'morning' => 'After Breakfast',
      'afternoon' => 'After Lunch',
      _ => 'Before Bed',
    };
  }
}
