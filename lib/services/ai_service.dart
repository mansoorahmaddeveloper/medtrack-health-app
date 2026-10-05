import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/app_constants.dart';
import '../core/providers/app_providers.dart';
import '../data/remote/supabase_client.dart';

final aiServiceProvider = Provider<AiService>((ref) {
  return AiService(ref.watch(supabaseServiceProvider));
});

class AiService {
  AiService(this._supabase);

  final SupabaseService _supabase;

  Future<String> medicineInsight({
    required String medicineName,
    required String condition,
  }) async {
    if (!_supabase.isConfigured) {
      return '${AppConstants.informationalDisclaimer}\n\n'
          'General info for $medicineName related to $condition is unavailable offline.';
    }
    final data = await _supabase.invokeAiFunction('ai-medicine-insight', {
      'medicine': medicineName,
      'condition': condition,
    });
    return '${AppConstants.informationalDisclaimer}\n\n${data['summary'] ?? ''}';
  }

  Future<Map<String, String>> symptomTriage(String symptoms) async {
    if (!_supabase.isConfigured) {
      return {
        'specialist': 'General physician',
        'urgency': 'soon',
        'disclaimer': AppConstants.informationalDisclaimer,
      };
    }
    final data = await _supabase.invokeAiFunction('ai-symptom-triage', {
      'symptoms': symptoms,
    });
    return {
      'specialist': '${data['specialist'] ?? 'General physician'}',
      'urgency': '${data['urgency'] ?? 'soon'}',
      'disclaimer': AppConstants.informationalDisclaimer,
    };
  }

  Future<String> requestSecondOpinion({
    required String patientId,
    required String summary,
  }) async {
    if (!_supabase.isConfigured) {
      return 'Second opinion requests require an online account.';
    }
    final data = await _supabase.invokeAiFunction('ai-second-opinion', {
      'patient_id': patientId,
      'summary': summary,
    });
    return data['request_id']?.toString() ?? 'submitted';
  }
}
