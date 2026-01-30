import '../database_service.dart';
import 'expense_repository.dart';
import 'settings_repository.dart';

/// Repository for monthly_snapshots table.
/// Pre-computed monthly summaries for Budget History.
class SnapshotRepository {
  final DatabaseService _db = DatabaseService();
  final ExpenseRepository _expenseRepo = ExpenseRepository();
  final SettingsRepository _settingsRepo = SettingsRepository();

  /// Get snapshot for a specific month.
  Future<Map<String, dynamic>?> getSnapshot(int year, int month) async {
    final db = await _db.database;
    final results = await db.query(
      'monthly_snapshots',
      where: 'year = ? AND month = ?',
      whereArgs: [year, month],
    );
    return results.isEmpty ? null : results.first;
  }

  /// Get all snapshots ordered by date (newest first).
  Future<List<Map<String, dynamic>>> getAllSnapshots({int limit = 24}) async {
    final db = await _db.database;
    return await db.query(
      'monthly_snapshots',
      orderBy: 'year DESC, month DESC',
      limit: limit,
    );
  }

  /// Generate or update a snapshot for a specific month.
  /// This aggregates expenses and calculates budget data.
  Future<Map<String, dynamic>> generateSnapshot(int year, int month) async {
    final db = await _db.database;
    final snapshotId = '$year-${month.toString().padLeft(2, '0')}';

    // Get cycle boundaries for this month
    final cycleStart = DateTime(year, month, 1);
    final cycleEnd = DateTime(year, month + 1, 0); // Last day of month

    // Get budget settings
    final income = await _settingsRepo.getMonthlyIncome();
    final needsPercent = await _settingsRepo.getNeedsPercent();
    final wantsPercent = await _settingsRepo.getWantsPercent();
    final savingsPercent = await _settingsRepo.getSavingsPercent();

    // Calculate budgets
    final totalBudget = income;
    final needsBudget = (income * needsPercent / 100).round();
    final wantsBudget = (income * wantsPercent / 100).round();
    final savingsBudget = (income * savingsPercent / 100).round();

    // Get spending by category
    final spending = await _expenseRepo.getSpendingByCategory(
      cycleStart,
      cycleEnd,
    );
    final needsSpent = spending['needs'] ?? 0;
    final wantsSpent = spending['wants'] ?? 0;
    final savingsSpent = spending['savings'] ?? 0;
    final totalSpent = needsSpent + wantsSpent + savingsSpent;

    // Get transaction count
    final transactionCount = await _expenseRepo.getCount(cycleStart, cycleEnd);

    final now = DateTime.now().toIso8601String();
    final snapshot = {
      'id': snapshotId,
      'year': year,
      'month': month,
      'total_budget': totalBudget,
      'needs_budget': needsBudget,
      'wants_budget': wantsBudget,
      'savings_budget': savingsBudget,
      'total_spent': totalSpent,
      'needs_spent': needsSpent,
      'wants_spent': wantsSpent,
      'savings_spent': savingsSpent,
      'remaining': totalBudget - totalSpent,
      'transaction_count': transactionCount,
      'updated_at': now,
    };

    // Check if snapshot exists
    final existing = await getSnapshot(year, month);
    if (existing == null) {
      snapshot['created_at'] = now;
      await db.insert('monthly_snapshots', snapshot);
    } else {
      await db.update(
        'monthly_snapshots',
        snapshot,
        where: 'id = ?',
        whereArgs: [snapshotId],
      );
    }

    return snapshot;
  }

  /// Ensure snapshots exist for current and previous month.
  /// Call this on app open.
  Future<void> ensureSnapshots() async {
    final now = DateTime.now();

    // Generate/update current month snapshot
    await generateSnapshot(now.year, now.month);

    // Generate previous month snapshot (finalize if not exists)
    final prev = DateTime(now.year, now.month - 1);
    await generateSnapshot(prev.year, prev.month);
  }

  /// Cleanup old snapshots (keep only last 24 months).
  Future<void> pruneOldSnapshots() async {
    final db = await _db.database;
    final cutoff = DateTime.now().subtract(const Duration(days: 730));
    await db.delete(
      'monthly_snapshots',
      where: 'year < ? OR (year = ? AND month < ?)',
      whereArgs: [cutoff.year, cutoff.year, cutoff.month],
    );
  }

  /// Get snapshots grouped by year (for Budget History screen).
  Future<Map<int, List<Map<String, dynamic>>>> getSnapshotsGroupedByYear({
    int limit = 24,
  }) async {
    final snapshots = await getAllSnapshots(limit: limit);
    final grouped = <int, List<Map<String, dynamic>>>{};

    for (final snapshot in snapshots) {
      final year = snapshot['year'] as int;
      grouped.putIfAbsent(year, () => []);
      grouped[year]!.add(snapshot);
    }

    return grouped;
  }
}
