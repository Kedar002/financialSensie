import '../database/database_service.dart';
import '../models/wants_category.dart';

class WantsRepository {
  final DatabaseService _db = DatabaseService();

  Future<List<WantsCategory>> getAll() async {
    final db = await _db.database;
    final maps = await db.query(
      'wants_categories',
      orderBy: 'created_at ASC',
    );
    return maps.map((map) => WantsCategory.fromMap(map)).toList();
  }

  Future<WantsCategory?> getById(int id) async {
    final db = await _db.database;
    final maps = await db.query(
      'wants_categories',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return WantsCategory.fromMap(maps.first);
  }

  Future<int> insert(WantsCategory category) async {
    final db = await _db.database;
    return await db.insert('wants_categories', category.toMap());
  }

  Future<int> update(WantsCategory category) async {
    final db = await _db.database;
    return await db.update(
      'wants_categories',
      category.toMap(),
      where: 'id = ?',
      whereArgs: [category.id],
    );
  }

  Future<int> delete(int id) async {
    final db = await _db.database;
    return await db.delete(
      'wants_categories',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
