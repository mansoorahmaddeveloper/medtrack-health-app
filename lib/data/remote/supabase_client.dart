import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Configure via `--dart-define=SUPABASE_URL=` and `SUPABASE_ANON_KEY=`.
class SupabaseService {
  SupabaseService();

  static const _url = String.fromEnvironment('SUPABASE_URL');
  static const _anonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  bool get isConfigured => _url.isNotEmpty && _anonKey.isNotEmpty;

  bool get isAuthenticated =>
      isConfigured && Supabase.instance.client.auth.currentSession != null;

  Future<void> initialize() async {
    if (!isConfigured) return;
    await Supabase.initialize(url: _url, anonKey: _anonKey);
  }

  SupabaseClient get client {
    if (!isConfigured) {
      throw StateError('Supabase is not configured. Set SUPABASE_URL and SUPABASE_ANON_KEY.');
    }
    return Supabase.instance.client;
  }

  Future<void> signInWithOtp({String? email, String? phone}) async {
    if (email != null) {
      await client.auth.signInWithOtp(email: email);
    } else if (phone != null) {
      await client.auth.signInWithOtp(phone: phone);
    }
  }

  Future<AuthResponse> verifyOtp({
    required String token,
    String? email,
    String? phone,
  }) {
    if (email != null) {
      return client.auth.verifyOTP(email: email, token: token, type: OtpType.email);
    }
    return client.auth.verifyOTP(phone: phone!, token: token, type: OtpType.sms);
  }

  Future<void> signOut() => client.auth.signOut();

  Future<void> upsertEntity(String entityType, String entityId) async {
    if (!isAuthenticated) return;
    await client.from('sync_entities').upsert({
      'entity_type': entityType,
      'entity_id': entityId,
      'payload': {'id': entityId},
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  Future<void> pullChanges(
    Future<void> Function(String type, String id, DateTime updatedAt) onChange,
  ) async {
    if (!isAuthenticated) return;
    final rows = await client
        .from('sync_entities')
        .select()
        .order('updated_at', ascending: false)
        .limit(100);
    for (final row in rows) {
      final map = Map<String, dynamic>.from(row as Map);
      final updatedAt = DateTime.parse(map['updated_at'] as String);
      await onChange(map['entity_type'] as String, map['entity_id'] as String, updatedAt);
    }
  }

  RealtimeChannel subscribeToPatient(String patientId, void Function(Map<String, dynamic>) onEvent) {
    return client
        .channel('patient:$patientId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'dose_logs',
          filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'profile_id', value: patientId),
          callback: (payload) => onEvent(payload.newRecord),
        )
        .subscribe();
  }

  Future<Map<String, dynamic>> invokeAiFunction(
    String name,
    Map<String, dynamic> body,
  ) async {
    final response = await client.functions.invoke(name, body: body);
    return Map<String, dynamic>.from(response.data as Map);
  }
}
