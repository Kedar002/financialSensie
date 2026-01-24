import 'base_repository.dart';
import '../models/planned_expense.dart';

class PlannedExpenseRepository extends BaseRepository<PlannedExpense> {
  @override
  String get tableName => 'planned_expenses';

  @override
  PlannedExpense fromMap(Map<String, dynamic> map) => PlannedExpense.fromMap(map);

  @override
  Map<String, dynamic> toMap(PlannedExpense entity) => entity.toMap();

  Future<List<PlannedExpense>> getByUserId(int userId, {String? status}) async {
    final where = status != null
        ? 'user_id = ? AND status = ?'
        : 'user_id = ?';
    final whereArgs = status != null ? [userId, status] : [userId];

    final results = await db.query(
      tableName,
      where: where,
      whereArgs: whereArgs,
      orderBy: 'priority ASC, target_date ASC',
    );
    return results.map((map) => fromMap(map)).toList();
  }

  Future<List<PlannedExpense>> getActiveGoals(int userId) async {
    return await getByUserId(userId, status: 'active');
  }

  Future<double> getTotalMonthlyRequired(int userId) async {
    final goals = await getActiveGoals(userId);
    return goals.fold<double>(0.0, (sum, goal) => sum + goal.monthlyRequired);
  }

  Future<int> addGoal({
    required int userId,
    required String name,
    required double targetAmount,
    required DateTime targetDate,
    int priority = 1,
  }) async {
    final targetTimestamp = targetDate.millisecondsSinceEpoch ~/ 1000;
    final monthlyRequired = PlannedExpense.calculateMonthlyRequired(
      targetAmount,
      0,
      targetTimestamp,
    );

    final goal = PlannedExpense(
      userId: userId,
      name: name,
      targetAmount: targetAmount,
      targetDate: targetTimestamp,
      monthlyRequired: monthlyRequired,
      priority: priority,
      createdAt: timestamp,
      updatedAt: timestamp,
    );
    return await insert(goal);
  }

  Future<int> addToGoal(int goalId, double amount) async {
    final goal = await getById(goalId);
    if (goal == null) return 0;

    final newAmount = goal.currentAmount + amount;
    final newStatus = newAmount >= goal.targetAmount ? 'completed' : goal.status;

    return await db.update(
      tableName,
      {
        'current_amount': newAmount,
        'status': newStatus,
        'updated_at': timestamp,
      },
      where: 'id = ?',
      whereArgs: [goalId],
    );
  }

  /// Mark a goal as completed
  Future<int> markAsCompleted(int goalId) async {
    return await db.update(
      tableName,
      {
        'status': 'completed',
        'updated_at': timestamp,
      },
      where: 'id = ?',
      whereArgs: [goalId],
    );
  }

  /// Delete a goal
  Future<int> deleteGoal(int goalId) async {
    return await db.delete(
      tableName,
      where: 'id = ?',
      whereArgs: [goalId],
    );
  }
}
