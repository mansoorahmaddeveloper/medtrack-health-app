import 'dart:math';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/providers/app_providers.dart';
import '../../core/utils/ids.dart';
import '../local/app_database.dart';

final familyRepositoryProvider = Provider<FamilyRepository>((ref) {
  return FamilyRepository(ref.watch(databaseProvider));
});

class FamilyRepository {
  FamilyRepository(this._db);

  final AppDatabase _db;
  final _random = Random.secure();

  String _generateInviteCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    return List.generate(8, (_) => chars[_random.nextInt(chars.length)]).join();
  }

  Future<String> createInvite({
    required String caregiverProfileId,
    required Map<String, bool> permissions,
    Duration validity = const Duration(hours: 24),
  }) async {
    final now = DateTime.now();
    final id = newId();
    final code = _generateInviteCode();
    await _db.into(_db.familyLinks).insert(
          FamilyLinksCompanion.insert(
            id: id,
            patientId: AppConstants.defaultProfileId,
            caregiverId: caregiverProfileId,
            inviteCode: Value(code),
            permissionsJson: Value(encodeJsonMap(permissions)),
            expiresAt: Value(now.add(validity)),
            updatedAt: now,
          ),
        );
    return code;
  }

  Stream<List<FamilyLink>> watchLinksForPatient() {
    return (_db.select(_db.familyLinks)
          ..where(
            (t) =>
                t.patientId.equals(AppConstants.defaultProfileId) &
                t.revokedAt.isNull() &
                t.deletedAt.isNull(),
          ))
        .watch();
  }

  Future<void> revokeLink(String linkId) async {
    final now = DateTime.now();
    await (_db.update(_db.familyLinks)..where((t) => t.id.equals(linkId))).write(
      FamilyLinksCompanion(
        revokedAt: Value(now),
        updatedAt: Value(now),
        syncStatus: const Value(AppConstants.syncPending),
      ),
    );
  }

  Future<FamilyLink?> redeemInviteCode(String code, String caregiverId) async {
    final link = await (_db.select(_db.familyLinks)
          ..where(
            (t) =>
                t.inviteCode.equals(code) &
                t.revokedAt.isNull() &
                t.deletedAt.isNull(),
          ))
        .getSingleOrNull();
    if (link == null) return null;
    if (link.expiresAt != null && link.expiresAt!.isBefore(DateTime.now())) {
      return null;
    }
    final now = DateTime.now();
    await (_db.update(_db.familyLinks)..where((t) => t.id.equals(link.id))).write(
      FamilyLinksCompanion(
        caregiverId: Value(caregiverId),
        updatedAt: Value(now),
        syncStatus: const Value(AppConstants.syncPending),
      ),
    );
    return link;
  }
}
