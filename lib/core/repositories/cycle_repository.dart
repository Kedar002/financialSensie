import '../database/database_service.dart';
import '../models/cycle_history.dart';

class CycleRepository {
  final DatabaseService _db = DatabaseService();

  /// Get all archived cycles ordered by most recent first
  Future<List<CycleHistory>> getAll() async {
    final db = await _db.database;
    final maps = await db.query(
      'cycle_history',
      orderBy: 'cycle_end DESC',
    );
    return maps.map((map) => CycleHistory.fromMap(map)).toList();
  }

  /// Get recent cycles (up to 10 years = ~120 cycles)
  Future<List<CycleHistory>> getRecent({int limit = 120}) async {
    final db = await _db.database;
    final maps = await db.query(
      'cycle_history',
      orderBy: 'cycle_end DESC',
      limit: limit,
    );
    return maps.map((map) => CycleHistory.fromMap(map)).toList();
  }

  /// Get a specific cycle by ID
  Future<CycleHistory?> getById(int id) async {
    final db = await _db.database;
    final maps = await db.query(
      'cycle_history',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return CycleHistory.fromMap(maps.first);
  }

  /// Archive the current cycle to history
  Future<int> archiveCycle(CycleHistory cycle) async {
    final db = await _db.database;
    return await db.insert('cycle_history', cycle.toMap());
  }

  /// Reset budget categories for new cycle
  /// This resets needs and wants category amounts to 0
  Future<void> resetBudgetCategories() async {
    final db = await _db.database;

    // Reset needs categories amounts to 0
    await db.update(
      'needs_categories',
      {'amount': 0},
    );

    // Reset wants categories amounts to 0
    await db.update(
      'wants_categories',
      {'amount': 0},
    );
  }

  /// Complete cycle: archive and reset for new cycle
  Future<void> completeCycle({
    required String cycleName,
    required DateTime cycleStart,
    required DateTime cycleEnd,
    required int totalIncome,
    required int totalSpent,
    required int needsSpent,
    required int wantsSpent,
    required int savingsAdded,
  }) async {
    final remaining = totalIncome - totalSpent - savingsAdded;

    // Archive the cycle
    final cycle = CycleHistory(
      cycleName: cycleName,
      cycleStart: cycleStart,
      cycleEnd: cycleEnd,
      totalIncome: totalIncome,
      totalSpent: totalSpent,
      needsSpent: needsSpent,
      wantsSpent: wantsSpent,
      savingsAdded: savingsAdded,
      remaining: remaining,
    );

    await archiveCycle(cycle);

    // Reset budget categories for new cycle
    await resetBudgetCategories();
  }

  /// Delete a cycle from history
  Future<int> delete(int id) async {
    final db = await _db.database;
    return await db.delete(
      'cycle_history',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
