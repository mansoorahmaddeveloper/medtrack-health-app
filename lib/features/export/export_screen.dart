import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:go_router/go_router.dart';



import '../../core/providers/app_providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_components.dart';
import '../../core/widgets/app_toast.dart';
import '../../services/pdf_export_service.dart';



final pdfExportServiceProvider = Provider<PdfExportService>((ref) {

  return PdfExportService(ref.watch(databaseProvider));

});



class ExportScreen extends ConsumerStatefulWidget {

  const ExportScreen({super.key});



  @override

  ConsumerState<ExportScreen> createState() => _ExportScreenState();

}



class _ExportScreenState extends ConsumerState<ExportScreen> {

  bool _medicationHistory = true;

  bool _recentVisits = true;

  bool _scannedReports = false;

  bool _vitals = false;

  bool _exporting = false;



  Future<void> _export() async {

    if (!_medicationHistory && !_recentVisits && !_scannedReports && !_vitals) {

      AppToast.error(context, 'Select at least one record type');

      return;

    }

    setState(() => _exporting = true);

    try {

      await ref.read(pdfExportServiceProvider).exportCategoriesAndShare(

            includeMedicationHistory: _medicationHistory,

            includeRecentVisits: _recentVisits,

            includeScannedReports: _scannedReports,

            includeVitals: _vitals,

          );

      if (mounted) AppToast.success(context, 'PDF generated and ready to share');

    } finally {

      if (mounted) setState(() => _exporting = false);

    }

  }



  @override

  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor: AppColors.background,

      body: SafeArea(

        child: Column(

          crossAxisAlignment: CrossAxisAlignment.start,

          children: [

            Padding(

              padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),

              child: Row(

                children: [

                  IconButton(

                    icon: const Icon(Icons.close, color: AppColors.primary),

                    onPressed: () => context.pop(),

                  ),

                  Expanded(

                    child: Text(

                      'Share Records',

                      textAlign: TextAlign.center,

                      style: AppTypography.headlineLgMobile.copyWith(color: AppColors.primary),

                    ),

                  ),

                  const SizedBox(width: 48),

                ],

              ),

            ),

            Expanded(

              child: ListView(

                padding: const EdgeInsets.all(AppSpacing.containerPadding),

                children: [

                  Text('Select Records to Share', style: AppTypography.headlineLgMobile),

                  const SizedBox(height: 8),

                  Text(

                    'Choose the medical records you want to include in the generated PDF for your doctor or caregiver.',

                    style: AppTypography.bodyMd,

                  ),

                  const SizedBox(height: AppSpacing.sectionGap),

                  _RecordOptionCard(

                    icon: Icons.medication_outlined,

                    title: 'Medication History',

                    subtitle: 'Last 30 days of taken and missed doses.',

                    selected: _medicationHistory,

                    onChanged: (v) => setState(() => _medicationHistory = v),

                  ),

                  const SizedBox(height: AppSpacing.stackGap),

                  _RecordOptionCard(

                    icon: Icons.event_note_outlined,

                    title: 'Recent Visits',

                    subtitle: 'Notes from recent appointments.',

                    selected: _recentVisits,

                    onChanged: (v) => setState(() => _recentVisits = v),

                  ),

                  const SizedBox(height: AppSpacing.stackGap),

                  _RecordOptionCard(

                    icon: Icons.description_outlined,

                    title: 'Scanned Reports',

                    subtitle: 'Lab results and uploaded documents.',

                    selected: _scannedReports,

                    onChanged: (v) => setState(() => _scannedReports = v),

                  ),

                  const SizedBox(height: AppSpacing.stackGap),

                  _RecordOptionCard(

                    icon: Icons.monitor_heart_outlined,

                    title: 'Vitals & Metrics',

                    subtitle: 'Blood pressure, weight, and pulse trends.',

                    selected: _vitals,

                    onChanged: (v) => setState(() => _vitals = v),

                  ),

                ],

              ),

            ),

            Padding(

              padding: const EdgeInsets.all(AppSpacing.containerPadding),

              child: AppPrimaryButton(

                label: _exporting ? 'Generating…' : 'Generate & Share PDF',

                icon: Icons.ios_share,

                onPressed: _exporting ? null : _export,

              ),

            ),

          ],

        ),

      ),

    );

  }

}



class _RecordOptionCard extends StatelessWidget {

  const _RecordOptionCard({

    required this.icon,

    required this.title,

    required this.subtitle,

    required this.selected,

    required this.onChanged,

  });



  final IconData icon;

  final String title;

  final String subtitle;

  final bool selected;

  final ValueChanged<bool> onChanged;



  @override

  Widget build(BuildContext context) {

    return AppCard(

      elevated: true,

      padding: const EdgeInsets.all(16),

      child: Row(

        children: [

          Container(

            width: 44,

            height: 44,

            decoration: BoxDecoration(

              color: AppColors.primary.withValues(alpha: 0.12),

              shape: BoxShape.circle,

            ),

            child: Icon(icon, color: AppColors.primary, size: 22),

          ),

          const SizedBox(width: 14),

          Expanded(

            child: Column(

              crossAxisAlignment: CrossAxisAlignment.start,

              children: [

                Text(title, style: AppTypography.labelLg),

                const SizedBox(height: 2),

                Text(subtitle, style: AppTypography.labelSm),

              ],

            ),

          ),

          Checkbox(

            value: selected,

            onChanged: (v) => onChanged(v ?? false),

            activeColor: AppColors.onSurface,

            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),

          ),

        ],

      ),

    );

  }

}


