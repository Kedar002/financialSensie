import 'package:uuid/uuid.dart';
import '../database_service.dart';
import '../amount_converter.dart';
import '../../models/cycle_settings.dart';

/// Repository for expenses table.
class ExpenseRepository {
  final DatabaseService _db = DatabaseService();
  final Uuid _uuid = const Uuid();

  /// Get all expenses (excluding soft-deleted).
  Future<List<Map<String, dynamic>>> getAll() async {
    final db = await _db.database;
    return await db.query(
      'expenses',
      where: 'deleted_at IS NULL',
      orderBy: 'date DESC, created_at DESC',
    );
  }

  /// Get expense by ID.
  Future<Map<String, dynamic>?> getById(String id) async {
    final db = await _db.database;
    final results = await db.query(
      'expenses',
      where: 'id = ?',
      whereArgs: [id],
    );
    return results.isEmpty ? null : results.first;
  }

  /// Get expenses for a date range (for budget cycle).
  Future<List<Map<String, dynamic>>> getForDateRange(
    DateTime start,
    DateTime end,
  ) async {
    final db = await _db.database;
    return await db.query(
      'expenses',
      where: 'date BETWEEN ? AND ? AND deleted_at IS NULL',
      whereArgs: [
        start.toIso8601String().split('T')[0],
        end.toIso8601String().split('T')[0],
      ],
      orderBy: 'date DESC, created_at DESC',
    );
  }

  /// Get expenses for current cycle.
  Future<List<Map<String, dynamic>>> getForCurrentCycle(
    CycleSettings cycleSettings,
  ) async {
    final dates = cycleSettings.getCurrentCycleDates();
    return getForDateRange(dates.start, dates.end);
  }

  /// Get spending by category for a date range.
  Future<Map<String, int>> getSpendingByCategory(
    DateTime start,
    DateTime end,
  ) async {
    final db = await _db.database;
    final results = await db.rawQuery('''
      SELECT category, SUM(amount) as total
      FROM expenses
      WHERE date BETWEEN ? AND ? AND deleted_at IS NULL
      GROUP BY category
    ''', [
      start.toIso8601String().split('T')[0],
      end.toIso8601String().split('T')[0],
    ]);

    return {
      for (final row in results)
        row['category'] as String: (row['total'] as int?) ?? 0,
    };
  }

  /// Get recent expenses.
  Future<List<Map<String, dynamic>>> getRecent({int limit = 5}) async {
    final db = await _db.database;
    return await db.query(
      'expenses',
      where: 'deleted_at IS NULL',
      orderBy: 'created_at DESC',
      limit: limit,
    );
  }

  /// Insert a new expense.
  /// Returns the inserted expense ID.
  Future<String> insert({
    required double amount,
    required String category,
    required String subcategory,
    String? goalId,
    bool isFundContribution = false,
    required DateTime date,
    String? note,
  }) async {
    final db = await _db.database;
    final id = _uuid.v4();
    final now = DateTime.now().toIso8601String();

    await db.insert('expenses', {
      'id': id,
      'amount': AmountConverter.toPaise(amount),
      'category': category,
      'subcategory': subcategory,
      'goal_id': goalId,
      'is_fund_contribution': isFundContribution ? 1 : 0,
      'date': date.toIso8601String().split('T')[0],
      'note': note,
      'created_at': now,
      'updated_at': now,
    });

    return id;
  }

  /// Update an expense.
  Future<void> update(
    String id, {
    double? amount,
    String? category,
    String? subcategory,
    String? goalId,
    bool? isFundContribution,
    DateTime? date,
    String? note,
  }) async {
    final db = await _db.database;
    final updates = <String, dynamic>{
      'updated_at': DateTime.now().toIso8601String(),
    };

    if (amount != null) updates['amount'] = AmountConverter.toPaise(amount);
    if (category != null) updates['category'] = category;
    if (subcategory != null) updates['subcategory'] = subcategory;
    if (goalId != null) updates['goal_id'] = goalId;
    if (isFundContribution != null) {
      updates['is_fund_contribution'] = isFundContribution ? 1 : 0;
    }
    if (date != null) updates['date'] = date.toIso8601String().split('T')[0];
    if (note != null) updates['note'] = note;

    await db.update(
      'expenses',
      updates,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Soft delete an expense.
  Future<void> delete(String id) async {
    final db = await _db.database;
    await db.update(
      'expenses',
      {
        'deleted_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Permanently delete an expense.
  Future<void> hardDelete(String id) async {
    final db = await _db.database;
    await db.delete(
      'expenses',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Get total spending for a period.
  Future<int> getTotalSpending(DateTime start, DateTime end) async {
    final db = await _db.database;
    final result = await db.rawQuery('''
      SELECT SUM(amount) as total
      FROM expenses
      WHERE date BETWEEN ? AND ? AND deleted_at IS NULL
    ''', [
      start.toIso8601String().split('T')[0],
      end.toIso8601String().split('T')[0],
    ]);

    return (result.first['total'] as int?) ?? 0;
  }

  /// Get expense count for a period.
  Future<int> getCount(DateTime start, DateTime end) async {
    final db = await _db.database;
    final result = await db.rawQuery('''
      SELECT COUNT(*) as count
      FROM expenses
      WHERE date BETWEEN ? AND ? AND deleted_at IS NULL
    ''', [
      start.toIso8601String().split('T')[0],
      end.toIso8601String().split('T')[0],
    ]);

    return (result.first['count'] as int?) ?? 0;
  }
}
