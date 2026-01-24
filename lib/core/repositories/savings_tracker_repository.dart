import '../database/database_service.dart';
import '../models/savings_tracker.dart';

/// Repository for savings tracker CRUD operations.
class SavingsTrackerRepository {
  final DatabaseService _db = DatabaseService();

  static const _tableName = 'savings_tracker';

  /// Get savings record for a specific month
  Future<SavingsTracker?> getByMonth(int userId, String month) async {
    final results = await _db.query(
      _tableName,
      where: 'user_id = ? AND month = ?',
      whereArgs: [userId, month],
      limit: 1,
    );

    if (results.isEmpty) return null;
    return SavingsTracker.fromMap(results.first);
  }

  /// Get savings history for a user (newest first)
  Future<List<SavingsTracker>> getHistory(int userId, {int limit = 24}) async {
    final results = await _db.query(
      _tableName,
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'month DESC',
      limit: limit,
    );

    return results.map((map) => SavingsTracker.fromMap(map)).toList();
  }

  /// Get all savings records for a specific year
  Future<List<SavingsTracker>> getByYear(int userId, int year) async {
    final yearStr = year.toString();
    final results = await _db.query(
      _tableName,
      where: 'user_id = ? AND month LIKE ?',
      whereArgs: [userId, '$yearStr-%'],
      orderBy: 'month ASC',
    );

    return results.map((map) => SavingsTracker.fromMap(map)).toList();
  }

  /// Check if a savings record exists for a month
  Future<bool> hasRecord(int userId, String month) async {
    final result = await getByMonth(userId, month);
    return result != null;
  }

  /// Get the latest savings record
  Future<SavingsTracker?> getLatest(int userId) async {
    final results = await _db.query(
      _tableName,
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'month DESC',
      limit: 1,
    );

    if (results.isEmpty) return null;
    return SavingsTracker.fromMap(results.first);
  }

  /// Save or update a savings record
  Future<int> save(SavingsTracker tracker) async {
    // Check if record already exists
    final existing = await getByMonth(tracker.userId, tracker.month);

    if (existing != null) {
      // Update existing record
      await _db.update(
        _tableName,
        tracker.toMap(),
        where: 'id = ?',
        whereArgs: [existing.id],
      );
      return existing.id!;
    } else {
      // Insert new record
      return await _db.insert(_tableName, tracker.toMap());
    }
  }

  /// Delete records older than specified months
  Future<int> deleteOlderThan(int userId, int months) async {
    final cutoffDate = DateTime.now().subtract(Duration(days: months * 30));
    final cutoffMonth = '${cutoffDate.year}-${cutoffDate.month.toString().padLeft(2, '0')}';

    return await _db.delete(
      _tableName,
      where: 'user_id = ? AND month < ?',
      whereArgs: [userId, cutoffMonth],
    );
  }

  /// Get total savings growth (difference between first and latest record)
  Future<double> getTotalGrowth(int userId) async {
    final history = await getHistory(userId, limit: 100);
    if (history.length < 2) return 0;

    final latest = history.first;
    final oldest = history.last;

    return latest.totalSavings - oldest.totalSavings;
  }

  /// Get average monthly savings
  Future<double> getAverageMonthly(int userId) async {
    final history = await getHistory(userId, limit: 12);
    if (history.length < 2) return 0;

    double totalGrowth = 0;
    for (int i = 0; i < history.length - 1; i++) {
      totalGrowth += history[i].totalSavings - history[i + 1].totalSavings;
    }

    return totalGrowth / (history.length - 1);
  }
}
