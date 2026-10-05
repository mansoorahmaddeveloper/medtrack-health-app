import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/local/app_database.dart';
import '../../data/remote/supabase_client.dart';
import '../../services/notification_service.dart';
import '../../services/push_notification_service.dart';
import '../../services/reminder_scheduler.dart';
import '../../services/sync_service.dart';

final pushNotificationServiceProvider = Provider<PushNotificationService>((ref) {
  return PushNotificationService();
});

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase(AppDatabase.openConnection());
  ref.onDispose(() => db.close());
  return db;
});

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

final reminderSchedulerProvider = Provider<ReminderScheduler>((ref) {
  return ReminderScheduler(
    ref.watch(databaseProvider),
    ref.watch(notificationServiceProvider),
  );
});

final syncServiceProvider = Provider<SyncService>((ref) {
  return SyncService(
    ref.watch(databaseProvider),
    ref.watch(supabaseServiceProvider),
  );
});

final supabaseServiceProvider = Provider<SupabaseService>((ref) {
  return SupabaseService();
});

String encodeJsonList(List<String> items) => jsonEncode(items);

List<String> decodeJsonList(String raw) {
  if (raw.isEmpty) return [];
  final decoded = jsonDecode(raw);
  if (decoded is! List) return [];
  return decoded.map((e) => e.toString()).toList();
}

Map<String, dynamic> decodeJsonMap(String raw) {
  if (raw.isEmpty) return {};
  final decoded = jsonDecode(raw);
  if (decoded is! Map) return {};
  return Map<String, dynamic>.from(decoded);
}

String encodeJsonMap(Map<String, dynamic> map) => jsonEncode(map);

final authStateProvider = StreamProvider<AuthState>((ref) {
  final supabase = ref.watch(supabaseServiceProvider);
  if (!supabase.isConfigured) {
    return Stream.value(const AuthState(AuthChangeEvent.initialSession, null));
  }
  return Supabase.instance.client.auth.onAuthStateChange;
});
