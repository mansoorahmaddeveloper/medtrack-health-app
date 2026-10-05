import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../core/constants/routes.dart';
import '../../data/repositories/vitals_repository.dart';

class VitalsScreen extends ConsumerStatefulWidget {
  const VitalsScreen({super.key});

  @override
  ConsumerState<VitalsScreen> createState() => _VitalsScreenState();
}

class _VitalsScreenState extends ConsumerState<VitalsScreen> {
  String _type = 'blood_pressure';
  final _primary = TextEditingController();
  final _secondary = TextEditingController();

  @override
  void dispose() {
    _primary.dispose();
    _secondary.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(vitalsRepositoryProvider);
    final vitalsStream = repo.watchVitals(
      patientId: AppConstants.defaultProfileId,
      type: _type,
    );
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vitals'),
        actions: [
          IconButton(
            icon: const Icon(Icons.note_alt_outlined),
            onPressed: () => context.push(AppRoutes.conditionNotes),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          DropdownButtonFormField<String>(
            value: _type,
            items: const [
              DropdownMenuItem(value: 'blood_pressure', child: Text('Blood pressure')),
              DropdownMenuItem(value: 'blood_sugar', child: Text('Blood sugar')),
              DropdownMenuItem(value: 'weight', child: Text('Weight')),
              DropdownMenuItem(value: 'temperature', child: Text('Temperature')),
            ],
            onChanged: (v) => setState(() => _type = v ?? _type),
          ),
          TextField(controller: _primary, decoration: const InputDecoration(labelText: 'Value')),
          if (_type == 'blood_pressure')
            TextField(controller: _secondary, decoration: const InputDecoration(labelText: 'Diastolic')),
          FilledButton(
            onPressed: () async {
              final p = double.tryParse(_primary.text.trim());
              if (p == null) return;
              await repo.logVital(
                patientId: AppConstants.defaultProfileId,
                type: _type,
                valuePrimary: p,
                valueSecondary: double.tryParse(_secondary.text.trim()),
                unit: _type == 'blood_pressure' ? 'mmHg' : '',
                loggedByProfileId: AppConstants.defaultProfileId,
              );
              _primary.clear();
              _secondary.clear();
            },
            child: const Text('Log vital'),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: StreamBuilder(
              stream: vitalsStream,
              builder: (context, snapshot) {
                final vitals = snapshot.data ?? [];
                if (vitals.isEmpty) {
                  return const Center(child: Text('No data for trend'));
                }
                return LineChart(
                  LineChartData(
                    lineBarsData: [
                      LineChartBarData(
                        spots: vitals
                            .asMap()
                            .entries
                            .map((e) => FlSpot(e.key.toDouble(), e.value.valuePrimary))
                            .toList(),
                        isCurved: true,
                        dotData: const FlDotData(show: true),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class ConditionNotesScreen extends ConsumerStatefulWidget {
  const ConditionNotesScreen({super.key});

  @override
  ConsumerState<ConditionNotesScreen> createState() => _ConditionNotesScreenState();
}

class _ConditionNotesScreenState extends ConsumerState<ConditionNotesScreen> {
  final _text = TextEditingController();

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(vitalsRepositoryProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Condition notes')),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          if (_text.text.trim().isEmpty) return;
          await repo.addConditionNote(AppConstants.defaultProfileId, _text.text.trim());
          _text.clear();
        },
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _text,
              decoration: const InputDecoration(labelText: 'How are you feeling?'),
              maxLines: 3,
            ),
          ),
          Expanded(
            child: StreamBuilder(
              stream: repo.watchConditionNotes(AppConstants.defaultProfileId),
              builder: (context, snapshot) {
                final notes = snapshot.data ?? [];
                return ListView.builder(
                  itemCount: notes.length,
                  itemBuilder: (context, i) {
                    final n = notes[i];
                    return ListTile(
                      title: Text(n.noteBody),
                      subtitle: Text(n.updatedAt.toLocal().toString()),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
