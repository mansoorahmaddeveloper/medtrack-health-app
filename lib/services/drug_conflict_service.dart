import '../data/local/app_database.dart';

class DrugConflictService {
  List<String> checkInteractions(List<Medicine> medicines) {
    final names = medicines.map((m) => m.name.toLowerCase()).toList();
    final flags = <String>[];
    if (names.any((n) => n.contains('warfarin')) &&
        names.any((n) => n.contains('aspirin'))) {
      flags.add('Warfarin + aspirin may increase bleeding risk.');
    }
    final seen = <String>{};
    for (final med in medicines) {
      final key = med.name.toLowerCase().trim();
      if (seen.contains(key)) {
        flags.add('Duplicate prescription detected for ${med.name}.');
      }
      seen.add(key);
    }
    if (names.length >= 5) {
      flags.add('Multiple active medicines — review interactions with your doctor.');
    }
    return flags;
  }
}
