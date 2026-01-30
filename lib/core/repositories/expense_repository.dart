import '../database/database_service.dart';
import '../models/expense.dart';
import 'savings_repository.dart';

class ExpenseRepository {
  final DatabaseService _db = DatabaseService();
  final SavingsRepository _savingsRepository = SavingsRepository();

  Future<List<Expense>> getAll() async {
    final db = await _db.database;
    final maps = await db.query(
      'expenses',
      orderBy: 'date DESC, created_at DESC',
    );
    return maps.map((map) => Expense.fromMap(map)).toList();
  }

  Future<List<Expense>> getByDateRange(DateTime start, DateTime end) async {
    final db = await _db.database;
    final maps = await db.query(
      'expenses',
      where: 'date >= ? AND date <= ?',
      whereArgs: [start.toIso8601String(), end.toIso8601String()],
      orderBy: 'date DESC, created_at DESC',
    );
    return maps.map((map) => Expense.fromMap(map)).toList();
  }

  Future<List<Expense>> getByMonth(int year, int month) async {
    final start = DateTime(year, month, 1);
    final end = DateTime(year, month + 1, 0, 23, 59, 59);
    return getByDateRange(start, end);
  }

  Future<List<Expense>> getRecent({int limit = 5}) async {
    final db = await _db.database;
    final maps = await db.query(
      'expenses',
      orderBy: 'created_at DESC',
      limit: limit,
    );
    return maps.map((map) => Expense.fromMap(map)).toList();
  }

  Future<Expense?> getById(int id) async {
    final db = await _db.database;
    final maps = await db.query(
      'expenses',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return Expense.fromMap(maps.first);
  }

  Future<int> insert(Expense expense) async {
    final db = await _db.database;
    return await db.insert('expenses', expense.toMap());
  }

  Future<int> update(Expense expense) async {
    final db = await _db.database;
    return await db.update(
      'expenses',
      expense.toMap(),
      where: 'id = ?',
      whereArgs: [expense.id],
    );
  }

  Future<int> delete(int id) async {
    // Get the expense first to check if it's a savings expense
    final expense = await getById(id);

    final db = await _db.database;
    final result = await db.delete(
      'expenses',
      where: 'id = ?',
      whereArgs: [id],
    );

    // Refund to savings goal if this was a savings expense
    // Note: expense.amount is in paise, goal.saved is in rupees
    if (result > 0 && expense != null && expense.type == 'savings' && expense.categoryId != null) {
      final goal = await _savingsRepository.getById(expense.categoryId!);
      if (goal != null) {
        final refundInRupees = (expense.amount / 100).round();
        final newSaved = goal.saved + refundInRupees;
        await _savingsRepository.update(goal.copyWith(saved: newSaved));
      }
    }

    return result;
  }

  Future<int> getTotalIncome({DateTime? start, DateTime? end}) async {
    final expenses = start != null && end != null
        ? await getByDateRange(start, end)
        : await getAll();
    return expenses
        .where((e) => e.type == 'income')
        .fold<int>(0, (sum, e) => sum + e.amount);
  }

  Future<int> getTotalSpent({DateTime? start, DateTime? end}) async {
    final expenses = start != null && end != null
        ? await getByDateRange(start, end)
        : await getAll();
    return expenses
        .where((e) => e.type != 'income')
        .fold<int>(0, (sum, e) => sum + e.amount);
  }

  Future<Map<String, int>> getSpentByType({DateTime? start, DateTime? end}) async {
    final expenses = start != null && end != null
        ? await getByDateRange(start, end)
        : await getAll();

    final result = <String, int>{
      'needs': 0,
      'wants': 0,
      'savings': 0,
    };

    for (final expense in expenses) {
      if (expense.type != 'income' && result.containsKey(expense.type)) {
        result[expense.type] = result[expense.type]! + expense.amount;
      }
    }

    return result;
  }

  /// Get spent amounts grouped by category ID for a specific type
  Future<Map<int, int>> getSpentByCategory(String type, {DateTime? start, DateTime? end}) async {
    final expenses = start != null && end != null
        ? await getByDateRange(start, end)
        : await getAll();

    final result = <int, int>{};

    for (final expense in expenses) {
      if (expense.type == type && expense.categoryId != null) {
        result[expense.categoryId!] = (result[expense.categoryId!] ?? 0) + expense.amount;
      }
    }

    return result;
  }
}
