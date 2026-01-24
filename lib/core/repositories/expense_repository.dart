import 'base_repository.dart';
import '../models/fixed_expense.dart';
import '../models/variable_expense.dart';

class FixedExpenseRepository extends BaseRepository<FixedExpense> {
  @override
  String get tableName => 'fixed_expenses';

  @override
  FixedExpense fromMap(Map<String, dynamic> map) => FixedExpense.fromMap(map);

  @override
  Map<String, dynamic> toMap(FixedExpense entity) => entity.toMap();

  Future<List<FixedExpense>> getByUserId(int userId, {bool activeOnly = true}) async {
    final where = activeOnly ? 'user_id = ? AND is_active = 1' : 'user_id = ?';
    final results = await db.query(
      tableName,
      where: where,
      whereArgs: [userId],
      orderBy: 'amount DESC',
    );
    return results.map((map) => fromMap(map)).toList();
  }

  Future<double> getTotalMonthly(int userId) async {
    final expenses = await getByUserId(userId);
    return expenses.fold<double>(0.0, (sum, exp) => sum + exp.amount);
  }

  Future<double> getTotalEssential(int userId) async {
    final results = await db.query(
      tableName,
      where: 'user_id = ? AND is_active = 1 AND is_essential = 1',
      whereArgs: [userId],
    );
    final expenses = results.map((map) => fromMap(map)).toList();
    return expenses.fold<double>(0.0, (sum, exp) => sum + exp.amount);
  }

  Future<int> addExpense({
    required int userId,
    required String name,
    required double amount,
    required String category,
    bool isEssential = true,
    int? dueDay,
  }) async {
    final expense = FixedExpense(
      userId: userId,
      name: name,
      amount: amount,
      category: category,
      isEssential: isEssential,
      dueDay: dueDay,
      createdAt: timestamp,
      updatedAt: timestamp,
    );
    return await insert(expense);
  }
}

class VariableExpenseRepository extends BaseRepository<VariableExpense> {
  @override
  String get tableName => 'variable_expenses';

  @override
  VariableExpense fromMap(Map<String, dynamic> map) => VariableExpense.fromMap(map);

  @override
  Map<String, dynamic> toMap(VariableExpense entity) => entity.toMap();

  Future<List<VariableExpense>> getByUserId(int userId) async {
    final results = await db.query(
      tableName,
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'estimated_amount DESC',
    );
    return results.map((map) => fromMap(map)).toList();
  }

  Future<double> getTotalEstimated(int userId) async {
    final expenses = await getByUserId(userId);
    return expenses.fold<double>(0.0, (sum, exp) => sum + exp.estimatedAmount);
  }

  Future<double> getTotalEssential(int userId) async {
    final results = await db.query(
      tableName,
      where: 'user_id = ? AND is_essential = 1',
      whereArgs: [userId],
    );
    final expenses = results.map((map) => fromMap(map)).toList();
    return expenses.fold<double>(0.0, (sum, exp) => sum + exp.estimatedAmount);
  }

  Future<int> addExpense({
    required int userId,
    required String category,
    required double estimatedAmount,
    bool isEssential = false,
  }) async {
    final expense = VariableExpense(
      userId: userId,
      category: category,
      estimatedAmount: estimatedAmount,
      isEssential: isEssential,
      createdAt: timestamp,
      updatedAt: timestamp,
    );
    return await insert(expense);
  }
}
