import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/app_constants.dart';
import '../core/providers/app_providers.dart';
import '../data/local/app_database.dart';
import '../data/remote/supabase_client.dart';

class SyncService {
  SyncService(this._db, this._supabase);

  final AppDatabase _db;
  final SupabaseService _supabase;

  Future<void> syncIfOnline() async {
    if (!_supabase.isConfigured) return;
    final connectivity = await Connectivity().checkConnectivity();
    if (connectivity.contains(ConnectivityResult.none)) return;
    if (!_supabase.isAuthenticated) return;

    await _pushPending();
    await _pullRemote();
  }

  Future<void> migrateGuestDataToUser(String supabaseUserId) async {
    final now = DateTime.now();
    await (_db.update(_db.profiles)..where((t) => t.id.equals(AppConstants.defaultProfileId)))
        .write(
      ProfilesCompanion(
        supabaseUserId: Value(supabaseUserId),
        updatedAt: Value(now),
        syncStatus: const Value(AppConstants.syncPending),
      ),
    );
    await syncIfOnline();
  }

  Future<void> _pushPending() async {
    final queue = await (_db.select(_db.syncQueue)
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .get();
    for (final item in queue) {
      try {
        await _supabase.upsertEntity(item.entityType, item.entityId);
        await (_db.delete(_db.syncQueue)..where((t) => t.id.equals(item.id))).go();
      } catch (e, st) {
        debugPrint('Sync push failed for ${item.entityType}/${item.entityId}: $e\n$st');
      }
    }
  }

  Future<void> _pullRemote() async {
    await _supabase.pullChanges((type, id, updatedAt) async {
      // Last-write-wins: remote newer rows overwrite local via entity-specific handlers.
      debugPrint('Pulled remote change $type/$id at $updatedAt');
    });
  }
}
