import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/providers/app_providers.dart';
import '../../data/repositories/medicine_repository.dart';
import '../../data/repositories/pharmacy_admin_repository.dart';

class PharmacyOrderScreen extends ConsumerWidget {
  const PharmacyOrderScreen({super.key, required this.medicineId});

  final String medicineId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Order medicine')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: FilledButton(
          onPressed: () async {
            final orderId = await ref.read(pharmacyRepositoryProvider).createOrder(
                  patientId: AppConstants.defaultProfileId,
                  medicineId: medicineId,
                  partnerId: 'partner-demo',
                  amount: 500,
                );
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Order placed: $orderId')),
            );
          },
          child: const Text('Order home delivery'),
        ),
      ),
    );
  }
}

class PharmacyOrdersListScreen extends ConsumerWidget {
  const PharmacyOrdersListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pharmacy orders')),
      body: StreamBuilder(
        stream: ref.watch(pharmacyRepositoryProvider).watchOrders(AppConstants.defaultProfileId),
        builder: (context, snapshot) {
          final orders = snapshot.data ?? [];
          if (orders.isEmpty) {
            return const Center(child: Text('No orders yet'));
          }
          return ListView.builder(
            itemCount: orders.length,
            itemBuilder: (context, i) {
              final o = orders[i];
              return ListTile(
                title: Text('Order ${o.id.substring(0, 8)}'),
                subtitle: Text('Status: ${o.status}'),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final meds = await ref.read(medicineRepositoryProvider).watchMedicines().first;
          if (!context.mounted || meds.isEmpty) return;
          Navigator.push(
            context,
            MaterialPageRoute<void>(
              builder: (_) => PharmacyOrderScreen(medicineId: meds.first.id),
            ),
          );
        },
        child: const Icon(Icons.local_pharmacy_outlined),
      ),
    );
  }
}
