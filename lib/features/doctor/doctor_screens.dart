import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../core/constants/routes.dart';
import '../../data/repositories/doctor_repository.dart';
import '../../services/drug_conflict_service.dart';

final drugConflictServiceProvider = Provider<DrugConflictService>((ref) {
  return DrugConflictService();
});

class DoctorSignupScreen extends ConsumerStatefulWidget {
  const DoctorSignupScreen({super.key});

  @override
  ConsumerState<DoctorSignupScreen> createState() => _DoctorSignupScreenState();
}

class _DoctorSignupScreenState extends ConsumerState<DoctorSignupScreen> {
  final _specialty = TextEditingController();
  final _license = TextEditingController();
  final _clinic = TextEditingController();

  @override
  void dispose() {
    _specialty.dispose();
    _license.dispose();
    _clinic.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Doctor signup')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Verification is free and merit-based. Your account stays pending until an admin approves your license.',
          ),
          const SizedBox(height: 16),
          TextField(controller: _specialty, decoration: const InputDecoration(labelText: 'Specialty')),
          TextField(controller: _license, decoration: const InputDecoration(labelText: 'License number')),
          TextField(controller: _clinic, decoration: const InputDecoration(labelText: 'Clinic')),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () async {
              await ref.read(doctorRepositoryProvider).registerDoctor(
                    profileId: AppConstants.defaultProfileId,
                    specialty: _specialty.text.trim(),
                    licenseNumber: _license.text.trim(),
                    clinic: _clinic.text.trim(),
                  );
              if (context.mounted) context.push(AppRoutes.doctorDashboard);
            },
            child: const Text('Submit for verification'),
          ),
        ],
      ),
    );
  }
}

class DoctorDashboardScreen extends ConsumerWidget {
  const DoctorDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pending = ref.watch(doctorRepositoryProvider).watchPendingDoctors();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Doctor dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics_outlined),
            onPressed: () => context.push(AppRoutes.doctorAnalytics),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(
            title: const Text('Manage availability'),
            onTap: () => context.push(AppRoutes.manageSlots),
          ),
          ListTile(
            title: const Text('Connected patients'),
            subtitle: const Text('View history, reports, medicines, vitals'),
            onTap: () => context.push('${AppRoutes.doctorPatient}/${AppConstants.defaultProfileId}'),
          ),
          StreamBuilder(
            stream: pending,
            builder: (context, snapshot) {
              final doctors = snapshot.data ?? [];
              return Text('Your verification status: ${doctors.isEmpty ? 'submitted' : doctors.first.verificationStatus}');
            },
          ),
        ],
      ),
    );
  }
}

class DoctorPatientScreen extends ConsumerStatefulWidget {
  const DoctorPatientScreen({super.key, required this.patientId});

  final String patientId;

  @override
  ConsumerState<DoctorPatientScreen> createState() => _DoctorPatientScreenState();
}

class _DoctorPatientScreenState extends ConsumerState<DoctorPatientScreen> {
  final _name = TextEditingController();
  final _dosage = TextEditingController();
  final _review = TextEditingController();
  int _rating = 5;

  @override
  void dispose() {
    _name.dispose();
    _dosage.dispose();
    _review.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(doctorRepositoryProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Patient chart')),
      body: FutureBuilder(
        future: repo.activeMedicinesForPatient(widget.patientId),
        builder: (context, snapshot) {
          final meds = snapshot.data ?? [];
          final conflicts = ref.read(drugConflictServiceProvider).checkInteractions(meds);
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (conflicts.isNotEmpty)
                Card(
                  color: Colors.orange.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Medicine alerts', style: TextStyle(fontWeight: FontWeight.bold)),
                        ...conflicts.map((c) => Text('• $c')),
                      ],
                    ),
                  ),
                ),
              ...meds.map((m) => ListTile(title: Text(m.name), subtitle: Text(m.dosage))),
              const Divider(),
              TextField(controller: _name, decoration: const InputDecoration(labelText: 'Update medicine name')),
              TextField(controller: _dosage, decoration: const InputDecoration(labelText: 'Update dosage')),
              FilledButton(
                onPressed: meds.isEmpty
                    ? null
                    : () => repo.doctorUpdateMedicine(
                          medicineId: meds.first.id,
                          name: _name.text.trim().isEmpty ? meds.first.name : _name.text.trim(),
                          dosage: _dosage.text.trim().isEmpty ? meds.first.dosage : _dosage.text.trim(),
                          patientProfileId: widget.patientId,
                        ),
                child: const Text('Update medicine (notifies patient)'),
              ),
              const SizedBox(height: 24),
              DropdownButtonFormField<int>(
                value: _rating,
                items: List.generate(5, (i) => DropdownMenuItem(value: i + 1, child: Text('${i + 1} stars'))),
                onChanged: (v) => setState(() => _rating = v ?? 5),
              ),
              TextField(controller: _review, decoration: const InputDecoration(labelText: 'Review')),
              FilledButton(
                onPressed: () async {
                  await repo.addReview(
                    doctorProfileId: 'local-doctor',
                    patientId: widget.patientId,
                    rating: _rating,
                    reviewText: _review.text.trim(),
                  );
                },
                child: const Text('Submit review'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class DoctorAnalyticsScreen extends ConsumerWidget {
  const DoctorAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Panel analytics')),
      body: const Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          'Paid add-on: adherence trends and attention-needed flags across your patient panel. '
          'Subscribe once you have real patient volume on MedTrack.',
        ),
      ),
    );
  }
}
