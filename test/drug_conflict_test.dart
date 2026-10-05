import 'package:flutter_test/flutter_test.dart';
import 'package:medtrack/services/drug_conflict_service.dart';
import 'package:medtrack/data/local/app_database.dart';

void main() {
  test('flags warfarin and aspirin interaction', () {
    final service = DrugConflictService();
    final flags = service.checkInteractions([
      Medicine(
        id: '1',
        profileId: 'p',
        name: 'Warfarin',
        dosage: '5mg',
        scheduleTimesJson: '[]',
        startDate: DateTime(2024),
        endDate: null,
        isActive: true,
        updatedAt: DateTime(2024),
        deletedAt: null,
        syncStatus: 'pending',
      ),
      Medicine(
        id: '2',
        profileId: 'p',
        name: 'Aspirin',
        dosage: '75mg',
        scheduleTimesJson: '[]',
        startDate: DateTime(2024),
        endDate: null,
        isActive: true,
        updatedAt: DateTime(2024),
        deletedAt: null,
        syncStatus: 'pending',
      ),
    ]);
    expect(flags.any((f) => f.contains('bleeding')), isTrue);
  });
}
