import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/routes.dart';
import '../../data/repositories/doctor_repository.dart';
import '../../data/repositories/pharmacy_admin_repository.dart';

class AdminHomeScreen extends ConsumerWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('MedTrack Admin')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.verified_user_outlined),
            title: const Text('Doctor verification'),
            onTap: () => context.push(AppRoutes.adminDoctors),
          ),
          ListTile(
            leading: const Icon(Icons.people_outline),
            title: const Text('User management'),
            onTap: () => context.push(AppRoutes.adminUsers),
          ),
          ListTile(
            leading: const Icon(Icons.rate_review_outlined),
            title: const Text('Review moderation'),
            onTap: () => context.push(AppRoutes.adminReviews),
          ),
          ListTile(
            leading: const Icon(Icons.history),
            title: const Text('Audit log'),
            onTap: () => context.push(AppRoutes.adminAudit),
          ),
        ],
      ),
    );
  }
}

class AdminDoctorVerificationScreen extends ConsumerWidget {
  const AdminDoctorVerificationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(doctorRepositoryProvider);
    final admin = ref.watch(adminRepositoryProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Doctor verification queue')),
      body: StreamBuilder(
        stream: repo.watchPendingDoctors(),
        builder: (context, snapshot) {
          final doctors = snapshot.data ?? [];
          if (doctors.isEmpty) {
            return const Center(child: Text('No pending doctors'));
          }
          return ListView.builder(
            itemCount: doctors.length,
            itemBuilder: (context, i) {
              final d = doctors[i];
              return ListTile(
                title: Text(d.specialty),
                subtitle: Text('License: ${d.licenseNumber}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.check, color: Colors.green),
                      onPressed: () async {
                        await repo.setVerificationStatus(d.id, 'verified');
                        await admin.logAudit('verify_doctor', 'doctorProfile', d.id);
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.red),
                      onPressed: () async {
                        await repo.setVerificationStatus(d.id, 'rejected');
                        await admin.logAudit('reject_doctor', 'doctorProfile', d.id);
                      },
                    ),
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

class AdminUsersScreen extends ConsumerWidget {
  const AdminUsersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final admin = ref.watch(adminRepositoryProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Users')),
      body: StreamBuilder(
        stream: admin.watchUsers(),
        builder: (context, snapshot) {
          final users = snapshot.data ?? [];
          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, i) {
              final u = users[i];
              return ListTile(
                title: Text(u.name.isEmpty ? u.id : u.name),
                subtitle: Text('Role: ${u.role}'),
                trailing: IconButton(
                  icon: const Icon(Icons.block),
                  onPressed: () => admin.suspendUser(u.id),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class AdminReviewsScreen extends ConsumerWidget {
  const AdminReviewsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final admin = ref.watch(adminRepositoryProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Flagged reviews')),
      body: StreamBuilder(
        stream: admin.watchFlaggedReviews(),
        builder: (context, snapshot) {
          final reviews = snapshot.data ?? [];
          if (reviews.isEmpty) {
            return const Center(child: Text('No flagged reviews'));
          }
          return ListView.builder(
            itemCount: reviews.length,
            itemBuilder: (context, i) {
              final r = reviews[i];
              return ListTile(
                title: Text('${r.rating} stars'),
                subtitle: Text(r.reviewText),
              );
            },
          );
        },
      ),
    );
  }
}

class AdminAuditScreen extends ConsumerWidget {
  const AdminAuditScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final admin = ref.watch(adminRepositoryProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Audit log')),
      body: StreamBuilder(
        stream: admin.watchAuditLogs(),
        builder: (context, snapshot) {
          final logs = snapshot.data ?? [];
          return ListView.builder(
            itemCount: logs.length,
            itemBuilder: (context, i) {
              final log = logs[i];
              return ListTile(
                title: Text(log.action),
                subtitle: Text('${log.entityType} · ${log.createdAt.toLocal()}'),
              );
            },
          );
        },
      ),
    );
  }
}
