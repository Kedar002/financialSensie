import '../database/database_service.dart';
import '../models/cycle_settings.dart';

class CycleSettingsRepository {
  final DatabaseService _db = DatabaseService();

  /// Get current cycle settings (creates default if none exists)
  Future<CycleSettings> get() async {
    final db = await _db.database;
    final maps = await db.query('cycle_settings', where: 'id = 1');

    if (maps.isEmpty) {
      // Create default settings
      final defaultSettings = CycleSettings.createDefault();
      await db.insert('cycle_settings', defaultSettings.toMap());
      return defaultSettings;
    }

    return CycleSettings.fromMap(maps.first);
  }

  /// Update cycle settings
  Future<void> update(CycleSettings settings) async {
    final db = await _db.database;
    await db.update(
      'cycle_settings',
      settings.toMap(),
      where: 'id = 1',
    );
  }

  /// Update pay cycle day and recalculate dates
  Future<CycleSettings> updatePayCycleDay(int day) async {
    final updated = CycleSettings.createDefault(payCycleDay: day);
    await update(updated);
    return updated;
  }

  /// Move to next cycle (called when starting new cycle)
  Future<CycleSettings> startNextCycle() async {
    final current = await get();
    final next = current.nextCycle();
    await update(next);
    return next;
  }
}
