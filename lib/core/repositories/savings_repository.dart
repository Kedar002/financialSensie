import '../database/database_service.dart';
import '../models/savings_goal.dart';

class SavingsRepository {
  final DatabaseService _db = DatabaseService();

  Future<List<SavingsGoal>> getAll() async {
    final db = await _db.database;
    final maps = await db.query(
      'savings_goals',
      orderBy: 'created_at ASC',
    );
    return maps.map((map) => SavingsGoal.fromMap(map)).toList();
  }

  Future<SavingsGoal?> getById(int id) async {
    final db = await _db.database;
    final maps = await db.query(
      'savings_goals',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return SavingsGoal.fromMap(maps.first);
  }

  Future<int> insert(SavingsGoal goal) async {
    final db = await _db.database;
    return await db.insert('savings_goals', goal.toMap());
  }

  Future<int> update(SavingsGoal goal) async {
    final db = await _db.database;
    return await db.update(
      'savings_goals',
      goal.toMap(),
      where: 'id = ?',
      whereArgs: [goal.id],
    );
  }

  Future<int> delete(int id) async {
    final db = await _db.database;
    return await db.delete(
      'savings_goals',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> addMoney(int id, int amount) async {
    final goal = await getById(id);
    if (goal == null) return 0;

    final updated = goal.copyWith(saved: goal.saved + amount);
    return await update(updated);
  }

  Future<int> getTotalSaved() async {
    final goals = await getAll();
    return goals.fold<int>(0, (sum, goal) => sum + goal.saved);
  }
}
