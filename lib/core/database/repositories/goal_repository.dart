import 'package:uuid/uuid.dart';
import '../database_service.dart';
import '../amount_converter.dart';

/// Repository for goals and goal_contributions tables.
class GoalRepository {
  final DatabaseService _db = DatabaseService();
  final Uuid _uuid = const Uuid();

  // ============ GOALS ============

  /// Get all active goals.
  Future<List<Map<String, dynamic>>> getActiveGoals() async {
    final db = await _db.database;
    return await db.query(
      'goals',
      where: "status = 'active' AND deleted_at IS NULL",
      orderBy: 'target_date ASC',
    );
  }

  /// Get all goals (including completed).
  Future<List<Map<String, dynamic>>> getAllGoals() async {
    final db = await _db.database;
    return await db.query(
      'goals',
      where: 'deleted_at IS NULL',
      orderBy: 'status DESC, target_date ASC',
    );
  }

  /// Get goal by ID.
  Future<Map<String, dynamic>?> getById(String id) async {
    final db = await _db.database;
    final results = await db.query(
      'goals',
      where: 'id = ?',
      whereArgs: [id],
    );
    return results.isEmpty ? null : results.first;
  }

  /// Get total saved across all active goals.
  Future<int> getTotalSaved() async {
    final db = await _db.database;
    final result = await db.rawQuery('''
      SELECT SUM(current_amount) as total
      FROM goals
      WHERE status = 'active' AND deleted_at IS NULL
    ''');
    return (result.first['total'] as int?) ?? 0;
  }

  /// Get total target across all active goals.
  Future<int> getTotalTarget() async {
    final db = await _db.database;
    final result = await db.rawQuery('''
      SELECT SUM(target_amount) as total
      FROM goals
      WHERE status = 'active' AND deleted_at IS NULL
    ''');
    return (result.first['total'] as int?) ?? 0;
  }

  /// Insert a new goal.
  Future<String> insert({
    required String name,
    required double targetAmount,
    required DateTime targetDate,
    required String instrument,
  }) async {
    final db = await _db.database;
    final id = _uuid.v4();
    final now = DateTime.now().toIso8601String();

    await db.insert('goals', {
      'id': id,
      'name': name,
      'target_amount': AmountConverter.toPaise(targetAmount),
      'current_amount': 0,
      'target_date': targetDate.toIso8601String().split('T')[0],
      'instrument': instrument,
      'status': 'active',
      'created_at': now,
      'updated_at': now,
    });

    return id;
  }

  /// Update a goal.
  Future<void> update(
    String id, {
    String? name,
    double? targetAmount,
    DateTime? targetDate,
    String? instrument,
    String? status,
  }) async {
    final db = await _db.database;
    final updates = <String, dynamic>{
      'updated_at': DateTime.now().toIso8601String(),
    };

    if (name != null) updates['name'] = name;
    if (targetAmount != null) {
      updates['target_amount'] = AmountConverter.toPaise(targetAmount);
    }
    if (targetDate != null) {
      updates['target_date'] = targetDate.toIso8601String().split('T')[0];
    }
    if (instrument != null) updates['instrument'] = instrument;
    if (status != null) updates['status'] = status;

    await db.update(
      'goals',
      updates,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Soft delete a goal.
  Future<void> delete(String id) async {
    final db = await _db.database;
    await db.update(
      'goals',
      {
        'deleted_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ============ CONTRIBUTIONS ============

  /// Get contributions for a goal.
  Future<List<Map<String, dynamic>>> getContributions(String goalId) async {
    final db = await _db.database;
    return await db.query(
      'goal_contributions',
      where: 'goal_id = ?',
      whereArgs: [goalId],
      orderBy: 'date DESC, created_at DESC',
    );
  }

  /// Add a contribution to a goal.
  /// Also updates the goal's current_amount.
  Future<String> addContribution({
    required String goalId,
    required double amount,
    String? expenseId,
    String type = 'contribution',
    DateTime? date,
    String? note,
  }) async {
    final db = await _db.database;
    final id = _uuid.v4();
    final now = DateTime.now();
    final amountPaise = AmountConverter.toPaise(amount);

    // Insert contribution
    await db.insert('goal_contributions', {
      'id': id,
      'goal_id': goalId,
      'expense_id': expenseId,
      'amount': amountPaise,
      'type': type,
      'date': (date ?? now).toIso8601String().split('T')[0],
      'note': note,
      'created_at': now.toIso8601String(),
    });

    // Update goal's current_amount
    await db.rawUpdate('''
      UPDATE goals
      SET current_amount = current_amount + ?,
          updated_at = ?,
          status = CASE
            WHEN current_amount + ? >= target_amount THEN 'completed'
            ELSE status
          END,
          completed_at = CASE
            WHEN current_amount + ? >= target_amount AND completed_at IS NULL
            THEN ?
            ELSE completed_at
          END
      WHERE id = ?
    ''', [
      amountPaise,
      now.toIso8601String(),
      amountPaise,
      amountPaise,
      now.toIso8601String(),
      goalId,
    ]);

    return id;
  }

  /// Reverse a contribution (for expense deletion).
  Future<void> reverseContribution({
    required String goalId,
    required double amount,
    required String expenseId,
    String? note,
  }) async {
    await addContribution(
      goalId: goalId,
      amount: -amount,
      expenseId: expenseId,
      type: 'withdrawal',
      note: note ?? 'Reversed: expense deleted',
    );
  }

  /// Adjust a contribution (for expense amount change).
  Future<void> adjustContribution({
    required String goalId,
    required double difference,
    required String expenseId,
    String? note,
  }) async {
    if (difference == 0) return;
    await addContribution(
      goalId: goalId,
      amount: difference,
      expenseId: expenseId,
      type: 'adjustment',
      note: note ?? 'Adjusted: expense modified',
    );
  }
}
