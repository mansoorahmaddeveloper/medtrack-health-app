import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_constants.dart';
import '../../data/repositories/appointment_repository.dart';

class ManageSlotsScreen extends ConsumerStatefulWidget {
  const ManageSlotsScreen({super.key, this.doctorProfileId = 'local-doctor'});

  final String doctorProfileId;

  @override
  ConsumerState<ManageSlotsScreen> createState() => _ManageSlotsScreenState();
}

class _ManageSlotsScreenState extends ConsumerState<ManageSlotsScreen> {
  DateTime _start = DateTime.now().add(const Duration(days: 1));
  DateTime _end = DateTime.now().add(const Duration(days: 1, hours: 1));

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(appointmentRepositoryProvider);
    final fmt = DateFormat.yMMMd().add_jm();
    return Scaffold(
      appBar: AppBar(title: const Text('Manage slots')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(
            title: const Text('Slot start'),
            subtitle: Text(fmt.format(_start)),
            onTap: () async {
              final d = await showDatePicker(
                context: context,
                initialDate: _start,
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (d == null) return;
              if (!context.mounted) return;
              final t = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(_start));
              if (t != null) setState(() => _start = DateTime(d.year, d.month, d.day, t.hour, t.minute));
            },
          ),
          ListTile(
            title: const Text('Slot end'),
            subtitle: Text(fmt.format(_end)),
            onTap: () async {
              final d = await showDatePicker(
                context: context,
                initialDate: _end,
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (d == null) return;
              if (!context.mounted) return;
              final t = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(_end));
              if (t != null) setState(() => _end = DateTime(d.year, d.month, d.day, t.hour, t.minute));
            },
          ),
          FilledButton(
            onPressed: () => repo.addAvailabilitySlot(
              doctorProfileId: widget.doctorProfileId,
              start: _start,
              end: _end,
            ),
            child: const Text('Add open slot'),
          ),
          const Divider(),
          StreamBuilder(
            stream: repo.watchOpenSlots(widget.doctorProfileId),
            builder: (context, snapshot) {
              final slots = snapshot.data ?? [];
              return Column(
                children: slots
                    .map(
                      (s) => ListTile(
                        title: Text(fmt.format(s.startAt)),
                        subtitle: Text('Until ${fmt.format(s.endAt)}'),
                      ),
                    )
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class BookAppointmentScreen extends ConsumerWidget {
  const BookAppointmentScreen({super.key, this.doctorProfileId = 'local-doctor'});

  final String doctorProfileId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(appointmentRepositoryProvider);
    final fmt = DateFormat.yMMMd().add_jm();
    return Scaffold(
      appBar: AppBar(title: const Text('Book appointment')),
      body: StreamBuilder(
        stream: repo.watchOpenSlots(doctorProfileId),
        builder: (context, snapshot) {
          final slots = snapshot.data ?? [];
          if (slots.isEmpty) {
            return const Center(child: Text('No open slots'));
          }
          return ListView.builder(
            itemCount: slots.length,
            itemBuilder: (context, i) {
              final slot = slots[i];
              return ListTile(
                title: Text(fmt.format(slot.startAt)),
                subtitle: const Text('Auto-confirmed if available'),
                trailing: FilledButton(
                  onPressed: () async {
                    final id = await repo.bookSlot(
                      slotId: slot.id,
                      doctorProfileId: doctorProfileId,
                      patientId: AppConstants.defaultProfileId,
                      fee: 1500,
                    );
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(id == null ? 'Slot no longer available' : 'Booked — confirmation sent'),
                      ),
                    );
                  },
                  child: const Text('Book'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
