import 'base_repository.dart';
import '../models/financial_snapshot.dart';

class FinancialSnapshotRepository extends BaseRepository<FinancialSnapshot> {
  @override
  String get tableName => 'financial_snapshot';

  @override
  FinancialSnapshot fromMap(Map<String, dynamic> map) => FinancialSnapshot.fromMap(map);

  @override
  Map<String, dynamic> toMap(FinancialSnapshot entity) => entity.toMap();

  /// Get snapshot for a specific month
  Future<FinancialSnapshot?> getByMonth(int userId, String month) async {
    final results = await db.query(
      tableName,
      where: 'user_id = ? AND month = ?',
      whereArgs: [userId, month],
      limit: 1,
    );
    if (results.isEmpty) return null;
    return fromMap(results.first);
  }

  /// Get history of snapshots (newest first), up to limit
  Future<List<FinancialSnapshot>> getHistory(int userId, {int limit = 24}) async {
    final results = await db.query(
      tableName,
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'month DESC',
      limit: limit,
    );
    return results.map((map) => fromMap(map)).toList();
  }

  /// Get all snapshots for a specific year
  Future<List<FinancialSnapshot>> getByYear(int userId, int year) async {
    final yearPrefix = '$year-';
    final results = await db.rawQuery(
      'SELECT * FROM $tableName WHERE user_id = ? AND month LIKE ? ORDER BY month DESC',
      [userId, '$yearPrefix%'],
    );
    return results.map((map) => fromMap(map)).toList();
  }

  /// Check if snapshot exists for month
  Future<bool> hasSnapshot(int userId, String month) async {
    final snapshot = await getByMonth(userId, month);
    return snapshot != null;
  }

  /// Get latest snapshot
  Future<FinancialSnapshot?> getLatest(int userId) async {
    final results = await db.query(
      tableName,
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'month DESC',
      limit: 1,
    );
    if (results.isEmpty) return null;
    return fromMap(results.first);
  }

  /// Create or update snapshot for a month
  Future<int> saveSnapshot(FinancialSnapshot snapshot) async {
    final existing = await getByMonth(snapshot.userId, snapshot.month);

    if (existing != null) {
      // Update existing snapshot
      return await db.update(
        tableName,
        snapshot.copyWith(id: existing.id).toMap(),
        where: 'id = ?',
        whereArgs: [existing.id],
      );
    } else {
      // Insert new snapshot
      return await insert(snapshot);
    }
  }

  /// Delete snapshots older than given number of months
  Future<int> deleteOlderThan(int userId, {int months = 24}) async {
    final cutoffDate = DateTime.now().subtract(Duration(days: months * 30));
    final cutoffMonth = '${cutoffDate.year}-${cutoffDate.month.toString().padLeft(2, '0')}';

    return await db.delete(
      tableName,
      where: 'user_id = ? AND month < ?',
      whereArgs: [userId, cutoffMonth],
    );
  }

  /// Get count of snapshots for user
  Future<int> getSnapshotCount(int userId) async {
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM $tableName WHERE user_id = ?',
      [userId],
    );
    return result.first['count'] as int;
  }
}
