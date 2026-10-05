import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../services/ai_service.dart';

class AiMedicineScreen extends ConsumerStatefulWidget {
  const AiMedicineScreen({super.key});

  @override
  ConsumerState<AiMedicineScreen> createState() => _AiMedicineScreenState();
}

class _AiMedicineScreenState extends ConsumerState<AiMedicineScreen> {
  final _medicine = TextEditingController();
  final _condition = TextEditingController();
  String? _result;

  @override
  void dispose() {
    _medicine.dispose();
    _condition.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AI medicine insight')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(AppConstants.informationalDisclaimer),
          const SizedBox(height: 12),
          TextField(controller: _medicine, decoration: const InputDecoration(labelText: 'Medicine')),
          TextField(controller: _condition, decoration: const InputDecoration(labelText: 'Condition')),
          FilledButton(
            onPressed: () async {
              final text = await ref.read(aiServiceProvider).medicineInsight(
                    medicineName: _medicine.text.trim(),
                    condition: _condition.text.trim(),
                  );
              setState(() => _result = text);
            },
            child: const Text('Get insight'),
          ),
          if (_result != null) Text(_result!),
        ],
      ),
    );
  }
}

class AiTriageScreen extends ConsumerStatefulWidget {
  const AiTriageScreen({super.key});

  @override
  ConsumerState<AiTriageScreen> createState() => _AiTriageScreenState();
}

class _AiTriageScreenState extends ConsumerState<AiTriageScreen> {
  final _symptoms = TextEditingController();
  Map<String, String>? _result;

  @override
  void dispose() {
    _symptoms.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Symptom triage')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _symptoms,
            decoration: const InputDecoration(labelText: 'Describe symptoms'),
            maxLines: 4,
          ),
          FilledButton(
            onPressed: () async {
              final result = await ref.read(aiServiceProvider).symptomTriage(_symptoms.text.trim());
              setState(() => _result = result);
            },
            child: const Text('Suggest urgency'),
          ),
          if (_result != null) ...[
            Text('Specialist: ${_result!['specialist']}'),
            Text('Urgency: ${_result!['urgency']}'),
            Text(_result!['disclaimer'] ?? ''),
          ],
        ],
      ),
    );
  }
}

class SecondOpinionScreen extends ConsumerStatefulWidget {
  const SecondOpinionScreen({super.key});

  @override
  ConsumerState<SecondOpinionScreen> createState() => _SecondOpinionScreenState();
}

class _SecondOpinionScreenState extends ConsumerState<SecondOpinionScreen> {
  final _summary = TextEditingController();

  @override
  void dispose() {
    _summary.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Async second opinion')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _summary,
              decoration: const InputDecoration(labelText: 'Diagnosis / prescription summary'),
              maxLines: 5,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () async {
                final id = await ref.read(aiServiceProvider).requestSecondOpinion(
                      patientId: 'local-profile',
                      summary: _summary.text.trim(),
                    );
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Request submitted: $id')),
                );
              },
              child: const Text('Request (pay-per-use)'),
            ),
          ],
        ),
      ),
    );
  }
}
