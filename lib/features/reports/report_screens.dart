import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/constants/routes.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_components.dart';
import '../../core/widgets/app_header.dart';
import '../../core/widgets/app_toast.dart';
import '../../data/local/app_database.dart';
import '../../data/repositories/report_repository.dart';
import '../../data/repositories/visit_repository.dart';

enum _ReportFilter { recent, all }

class ReportLibraryScreen extends ConsumerStatefulWidget {
  const ReportLibraryScreen({super.key});

  @override
  ConsumerState<ReportLibraryScreen> createState() => _ReportLibraryScreenState();
}

class _ReportLibraryScreenState extends ConsumerState<ReportLibraryScreen> {
  String _query = '';
  _ReportFilter _filter = _ReportFilter.recent;

  List<Report> _applyFilter(List<Report> reports) {
    var list = reports;
    if (_filter == _ReportFilter.recent) {
      final cutoff = DateTime.now().subtract(const Duration(days: 90));
      list = list.where((r) => r.updatedAt.isAfter(cutoff)).toList();
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(reportRepositoryProvider);
    final fmt = DateFormat('MMM d, yyyy');

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(AppRoutes.scanReport),
        child: const Icon(Icons.document_scanner_outlined),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppHeader(),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.containerPadding,
                AppSpacing.stackGap,
                AppSpacing.containerPadding,
                0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Report Library', style: AppTypography.headlineLgMobile),
                  const SizedBox(height: 4),
                  Text(
                    'Access all your medical documents and scans.',
                    style: AppTypography.bodyMd,
                  ),
                  const SizedBox(height: AppSpacing.stackGap),
                  Row(
                    children: [
                      AppFilterChip(
                        label: 'Recent',
                        selected: _filter == _ReportFilter.recent,
                        onTap: () {
                          setState(() => _filter = _ReportFilter.recent);
                          AppToast.success(context, 'Showing recent reports');
                        },
                      ),
                      const SizedBox(width: 8),
                      AppFilterChip(
                        label: 'All',
                        selected: _filter == _ReportFilter.all,
                        onTap: () {
                          setState(() => _filter = _ReportFilter.all);
                          AppToast.success(context, 'Showing all reports');
                        },
                      ),
                      const SizedBox(width: 8),
                      AppFilterChip(
                        label: 'Filter',
                        selected: false,
                        onTap: () => AppToast.success(context, 'Filter options applied'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.stackGap),
            Expanded(
              child: StreamBuilder<List<Report>>(
                stream: repo.watchReports(query: _query),
                builder: (context, snapshot) {
                  final reports = _applyFilter(snapshot.data ?? []);
                  if (reports.isEmpty) {
                    return EmptyState(
                      message: 'No reports yet. Scan a document to add one.',
                      actionLabel: 'Scan report',
                      onAction: () => context.push(AppRoutes.scanReport),
                      icon: Icons.description_outlined,
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.containerPadding,
                      0,
                      AppSpacing.containerPadding,
                      100,
                    ),
                    itemCount: reports.length,
                    separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.stackGap),
                    itemBuilder: (context, i) {
                      final r = reports[i];
                      final meta = _reportMeta(r.title);
                      return _ReportCard(
                        report: r,
                        tag: meta.tag,
                        tagColor: meta.color,
                        tagBg: meta.bg,
                        dateLabel: fmt.format(r.updatedAt),
                        onView: () {
                          AppToast.success(context, 'Opening report');
                          context.push('${AppRoutes.reportDetail}/${r.id}');
                        },
                        onDownload: () async {
                          if (File(r.imagePath).existsSync()) {
                            await Share.shareXFiles([XFile(r.imagePath)], text: r.title);
                            if (context.mounted) {
                              AppToast.success(context, 'Report ready to share');
                            }
                          } else {
                            AppToast.error(context, 'File not found');
                          }
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

class _ReportMeta {
  const _ReportMeta({required this.tag, required this.color, required this.bg});
  final String tag;
  final Color color;
  final Color bg;
}

_ReportMeta _reportMeta(String title) {
  final t = title.toLowerCase();
  if (t.contains('blood') || t.contains('panel') || t.contains('lab')) {
    return const _ReportMeta(
      tag: 'Blood Test',
      color: AppColors.error,
      bg: AppColors.errorContainer,
    );
  }
  if (t.contains('x-ray') || t.contains('xray') || t.contains('radiograph')) {
    return const _ReportMeta(
      tag: 'X-Ray',
      color: AppColors.secondaryBright,
      bg: AppColors.secondaryFixed,
    );
  }
  if (t.contains('prescription') || t.contains('lisinopril') || t.contains('renewal')) {
    return const _ReportMeta(tag: 'Prescription', color: AppColors.tertiary, bg: AppColors.tertiaryFixed);
  }
  if (t.contains('vaccin') || t.contains('flu') || t.contains('shot')) {
    return const _ReportMeta(tag: 'Vaccination', color: AppColors.outline, bg: AppColors.surfaceContainer);
  }
  return const _ReportMeta(tag: 'Document', color: AppColors.primary, bg: AppColors.surfaceContainer);
}

class _ReportCard extends StatelessWidget {
  const _ReportCard({
    required this.report,
    required this.tag,
    required this.tagColor,
    required this.tagBg,
    required this.dateLabel,
    required this.onView,
    required this.onDownload,
  });

  final Report report;
  final String tag;
  final Color tagColor;
  final Color tagBg;
  final String dateLabel;
  final VoidCallback onView;
  final VoidCallback onDownload;

  @override
  Widget build(BuildContext context) {
    final hasImage = File(report.imagePath).existsSync();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.5)),
        boxShadow: AppElevation.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasImage)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
              child: Stack(
                children: [
                  Image.file(
                    File(report.imagePath),
                    height: 140,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                  Positioned(
                    top: 10,
                    left: 10,
                    child: _TagChip(label: tag, color: tagColor, bg: tagBg),
                  ),
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
                    if (!hasImage) _TagChip(label: tag, color: tagColor, bg: tagBg),
                    if (!hasImage) const Spacer(),
                    if (hasImage) const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.download_outlined, color: AppColors.outline),
                      onPressed: onDownload,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                Text(report.title, style: AppTypography.labelLg),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.calendar_today_outlined, size: 14, color: AppColors.outline),
                        const SizedBox(width: 4),
                        Text(dateLabel, style: AppTypography.labelSm),
                      ],
                    ),
                    TextButton(
                      onPressed: onView,
                      child: Text(
                        'View →',
                        style: AppTypography.labelSm.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({required this.label, required this.color, required this.bg});

  final String label;
  final Color color;
  final Color bg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Text(
        label,
        style: AppTypography.labelSm.copyWith(color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class ScanReportScreen extends ConsumerStatefulWidget {
  const ScanReportScreen({super.key});

  @override
  ConsumerState<ScanReportScreen> createState() => _ScanReportScreenState();
}

class _ScanReportScreenState extends ConsumerState<ScanReportScreen> {
  final _title = TextEditingController();
  String? _visitId;

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final visitsStream = ref.watch(visitRepositoryProvider).watchVisits();
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const AppHeader(showBack: true, title: 'Scan Report'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.containerPadding),
                children: [
                  AppTextField(controller: _title, label: 'Report title'),
                  const SizedBox(height: AppSpacing.stackGap),
                  StreamBuilder(
                    stream: visitsStream,
                    builder: (context, snapshot) {
                      final visits = snapshot.data ?? [];
                      return DropdownButtonFormField<String?>(
                        value: _visitId,
                        decoration: const InputDecoration(labelText: 'Link to visit (optional)'),
                        items: [
                          const DropdownMenuItem(value: null, child: Text('None')),
                          ...visits.map(
                            (v) => DropdownMenuItem(
                              value: v.id,
                              child: Text(v.diagnosis.isEmpty ? v.doctorName : v.diagnosis),
                            ),
                          ),
                        ],
                        onChanged: (v) => setState(() => _visitId = v),
                      );
                    },
                  ),
                  const SizedBox(height: AppSpacing.sectionGap),
                  AppPrimaryButton(
                    label: 'Scan with camera',
                    icon: Icons.camera_alt_outlined,
                    onPressed: () async {
                      if (_title.text.trim().isEmpty) {
                        AppToast.error(context, 'Please enter a report title');
                        return;
                      }
                      final id = await ref.read(reportRepositoryProvider).scanAndSaveReport(
                            title: _title.text.trim(),
                            visitId: _visitId,
                          );
                      if (!context.mounted) return;
                      if (id == null) {
                        AppToast.error(context, 'Scan cancelled');
                        return;
                      }
                      AppToast.success(context, 'Report saved successfully');
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

class ReportDetailScreen extends ConsumerWidget {
  const ReportDetailScreen({super.key, required this.reportId});

  final String reportId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder(
      future: ref.read(reportRepositoryProvider).getReport(reportId),
      builder: (context, snapshot) {
        final report = snapshot.data;
        if (report == null) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        return Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: Column(
              children: [
                AppHeader(showBack: true, title: report.title),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(AppSpacing.containerPadding),
                    children: [
                      AppCard(
                        elevated: false,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (File(report.imagePath).existsSync())
                              ClipRRect(
                                borderRadius: BorderRadius.circular(AppRadius.md),
                                child: Image.file(File(report.imagePath)),
                              ),
                            if (report.ocrText.isNotEmpty) ...[
                              const SizedBox(height: AppSpacing.stackGap),
                              Text(report.ocrText, style: AppTypography.bodyMd),
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
