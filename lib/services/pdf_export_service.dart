import 'dart:io';



import 'package:drift/drift.dart';

import 'package:intl/intl.dart';

import 'package:path_provider/path_provider.dart';

import 'package:pdf/pdf.dart';

import 'package:pdf/widgets.dart' as pw;

import 'package:share_plus/share_plus.dart';



import '../core/constants/app_constants.dart';

import '../core/providers/app_providers.dart';

import '../data/local/app_database.dart';



class PdfExportService {

  PdfExportService(this._db);



  final AppDatabase _db;

  final _dateFormat = DateFormat.yMMMd();



  Future<void> exportAndShare({

    required List<String> visitIds,

    required List<String> medicineIds,

    required List<String> reportIds,

  }) async {

    await _export(

      visitIds: visitIds,

      medicineIds: medicineIds,

      reportIds: reportIds,

      includeVitals: false,

      doseLogs: const [],

      vitals: const [],

    );

  }



  Future<void> exportCategoriesAndShare({

    bool includeMedicationHistory = false,

    bool includeRecentVisits = false,

    bool includeScannedReports = false,

    bool includeVitals = false,

  }) async {

    final visits = includeRecentVisits

        ? await (_db.select(_db.medicalVisits)

              ..where((t) => t.deletedAt.isNull())

              ..orderBy([(t) => OrderingTerm.desc(t.visitDate)]))

            .get()

        : <MedicalVisit>[];



    final medicines = includeMedicationHistory

        ? await (_db.select(_db.medicines)

              ..where((t) => t.deletedAt.isNull() & t.isActive.equals(true)))

            .get()

        : <Medicine>[];



    final reports = includeScannedReports

        ? await (_db.select(_db.reports)..where((t) => t.deletedAt.isNull())).get()

        : <Report>[];



    final cutoff = DateTime.now().subtract(const Duration(days: 30));

    final doseLogs = includeMedicationHistory

        ? await (_db.select(_db.doseLogs)

              ..where((t) => t.scheduledAt.isBiggerOrEqualValue(cutoff)))

            .get()

        : <DoseLog>[];



    final vitals = includeVitals

        ? await (_db.select(_db.vitals)

              ..where((t) =>

                  t.patientId.equals(AppConstants.defaultProfileId) & t.deletedAt.isNull())

              ..orderBy([(t) => OrderingTerm.desc(t.recordedAt)]))

            .get()

        : <Vital>[];



    await _export(

      visitIds: visits.map((v) => v.id).toList(),

      medicineIds: medicines.map((m) => m.id).toList(),

      reportIds: reports.map((r) => r.id).toList(),

      includeVitals: includeVitals,

      doseLogs: doseLogs,

      vitals: vitals,

    );

  }



  Future<void> _export({

    required List<String> visitIds,

    required List<String> medicineIds,

    required List<String> reportIds,

    required bool includeVitals,

    required List<DoseLog> doseLogs,

    required List<Vital> vitals,

  }) async {

    final profile = await (_db.select(_db.profiles)

          ..where((t) => t.id.equals(AppConstants.defaultProfileId)))

        .getSingleOrNull();



    final visits = visitIds.isEmpty

        ? <MedicalVisit>[]

        : await (_db.select(_db.medicalVisits)

              ..where((t) => t.id.isIn(visitIds)))

            .get();

    final medicines = medicineIds.isEmpty

        ? <Medicine>[]

        : await (_db.select(_db.medicines)

              ..where((t) => t.id.isIn(medicineIds)))

            .get();

    final reports = reportIds.isEmpty

        ? <Report>[]

        : await (_db.select(_db.reports)

              ..where((t) => t.id.isIn(reportIds)))

            .get();



    final doc = pw.Document();

    doc.addPage(

      pw.MultiPage(

        pageFormat: PdfPageFormat.a4,

        build: (context) => [

          pw.Header(

            level: 0,

            child: pw.Text('MedTrack Health Summary',

                style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),

          ),

          if (profile != null) ...[

            pw.Text('Name: ${profile.name}'),

            if (profile.bloodType != null) pw.Text('Blood type: ${profile.bloodType}'),

            pw.Text('Allergies: ${decodeJsonList(profile.allergiesJson).join(', ')}'),

            pw.SizedBox(height: 12),

          ],

          if (visits.isNotEmpty) ...[

            pw.Header(level: 1, text: 'Medical visits'),

            ...visits.map(

              (v) => pw.Bullet(

                text:

                    '${_dateFormat.format(v.visitDate)} — ${v.diagnosis} (${v.doctorName}, ${v.clinic})',

              ),

            ),

            pw.SizedBox(height: 12),

          ],

          if (medicines.isNotEmpty) ...[

            pw.Header(level: 1, text: 'Medicines'),

            ...medicines.map((m) => pw.Bullet(text: '${m.name} — ${m.dosage}')),

            pw.SizedBox(height: 12),

          ],

          if (doseLogs.isNotEmpty) ...[

            pw.Header(level: 1, text: 'Medication adherence (last 30 days)'),

            ...doseLogs.map(

              (d) => pw.Bullet(

                text:

                    '${_dateFormat.format(d.scheduledAt)} — ${d.status}${d.confirmedAt != null ? ' at ${DateFormat.jm().format(d.confirmedAt!)}' : ''}',

              ),

            ),

            pw.SizedBox(height: 12),

          ],

          if (reports.isNotEmpty) ...[

            pw.Header(level: 1, text: 'Reports'),

            ...reports.map((r) => pw.Bullet(text: r.title)),

            pw.SizedBox(height: 12),

          ],

          if (includeVitals && vitals.isNotEmpty) ...[

            pw.Header(level: 1, text: 'Vitals & metrics'),

            ...vitals.map((v) {

              final value = v.valueSecondary != null

                  ? '${v.valuePrimary}/${v.valueSecondary}'

                  : '${v.valuePrimary}';

              return pw.Bullet(

                text:

                    '${_dateFormat.format(v.recordedAt)} — ${v.type}: $value ${v.unit}',

              );

            }),

          ],

        ],

      ),

    );



    final bytes = await doc.save();

    final dir = await getTemporaryDirectory();

    final temp = File('${dir.path}/medtrack_export.pdf');

    await temp.writeAsBytes(bytes);

    await Share.shareXFiles([XFile(temp.path)], text: 'MedTrack health summary');

  }

}


