import '../database/database_service.dart';
import '../models/income_category.dart';

class IncomeRepository {
  final DatabaseService _db = DatabaseService();

  Future<List<IncomeCategory>> getAll() async {
    final db = await _db.database;
    final maps = await db.query(
      'income_categories',
      orderBy: 'created_at ASC',
    );
    return maps.map((map) => IncomeCategory.fromMap(map)).toList();
  }

  Future<IncomeCategory?> getById(int id) async {
    final db = await _db.database;
    final maps = await db.query(
      'income_categories',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return IncomeCategory.fromMap(maps.first);
  }

  Future<int> insert(IncomeCategory category) async {
    final db = await _db.database;
    return await db.insert('income_categories', category.toMap());
  }

  Future<int> update(IncomeCategory category) async {
    final db = await _db.database;
    return await db.update(
      'income_categories',
      category.toMap(),
      where: 'id = ?',
      whereArgs: [category.id],
    );
  }

  Future<int> delete(int id) async {
    final db = await _db.database;
    return await db.delete(
      'income_categories',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
