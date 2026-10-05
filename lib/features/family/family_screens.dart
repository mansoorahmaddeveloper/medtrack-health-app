import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../core/constants/routes.dart';
import '../../core/providers/app_providers.dart';
import '../../data/repositories/family_repository.dart';
import '../../data/repositories/medicine_repository.dart';
import '../../data/repositories/profile_repository.dart';

class FamilyInviteScreen extends ConsumerWidget {
  const FamilyInviteScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Invite family')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: FilledButton(
          onPressed: () async {
            final code = await ref.read(familyRepositoryProvider).createInvite(
                  caregiverProfileId: 'pending-caregiver',
                  permissions: {
                    'view_meds': true,
                    'view_reports': true,
                    'view_vitals': false,
                    'log_vitals': false,
                  },
                );
            if (!context.mounted) return;
            await showDialog<void>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Invite code'),
                content: SelectableText(code),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
                ],
              ),
            );
          },
          child: const Text('Generate invite code'),
        ),
      ),
    );
  }
}

class LinkPatientScreen extends ConsumerStatefulWidget {
  const LinkPatientScreen({super.key});

  @override
  ConsumerState<LinkPatientScreen> createState() => _LinkPatientScreenState();
}

class _LinkPatientScreenState extends ConsumerState<LinkPatientScreen> {
  final _code = TextEditingController();

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Link to patient')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _code,
              decoration: const InputDecoration(labelText: 'Secret code'),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () async {
                final link = await ref.read(familyRepositoryProvider).redeemInviteCode(
                      _code.text.trim(),
                      'caregiver-local',
                    );
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(link == null ? 'Invalid or expired code' : 'Linked successfully'),
                  ),
                );
              },
              child: const Text('Link'),
            ),
          ],
        ),
      ),
    );
  }
}

class FamilyDashboardScreen extends ConsumerWidget {
  const FamilyDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final links = ref.watch(familyRepositoryProvider).watchLinksForPatient();
    final meds = ref.watch(medicineRepositoryProvider).watchMedicines();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Family dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.link),
            onPressed: () => context.push(AppRoutes.linkPatient),
          ),
        ],
      ),
      body: StreamBuilder(
        stream: links,
        builder: (context, snapshot) {
          final linkList = snapshot.data ?? [];
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text('Linked caregivers: ${linkList.length}'),
              const SizedBox(height: 12),
              StreamBuilder(
                stream: meds,
                builder: (context, medSnap) {
                  final medicines = medSnap.data ?? [];
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Patient: ${AppConstants.defaultProfileId}'),
                          const Text('Current medicines'),
                          ...medicines.map((m) => Text('• ${m.name} (${m.dosage})')),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

class FamilyHealthTreeScreen extends ConsumerWidget {
  const FamilyHealthTreeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Family health tree')),
      body: StreamBuilder(
        stream: ref.watch(profileRepositoryProvider).watchProfile(),
        builder: (context, snapshot) {
          final allergies = decodeJsonList(snapshot.data?.allergiesJson ?? '[]');
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text('Conditions & allergies from linked members'),
              ...allergies.map((a) => ListTile(title: Text(a), subtitle: const Text('Allergy'))),
            ],
          );
        },
      ),
    );
  }
}
