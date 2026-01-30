import '../database/database_service.dart';
import '../models/needs_category.dart';

class NeedsRepository {
  final DatabaseService _db = DatabaseService();

  Future<List<NeedsCategory>> getAll() async {
    final db = await _db.database;
    final maps = await db.query(
      'needs_categories',
      orderBy: 'created_at ASC',
    );
    return maps.map((map) => NeedsCategory.fromMap(map)).toList();
  }

  Future<NeedsCategory?> getById(int id) async {
    final db = await _db.database;
    final maps = await db.query(
      'needs_categories',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return NeedsCategory.fromMap(maps.first);
  }

  Future<int> insert(NeedsCategory category) async {
    final db = await _db.database;
    return await db.insert('needs_categories', category.toMap());
  }

  Future<int> update(NeedsCategory category) async {
    final db = await _db.database;
    return await db.update(
      'needs_categories',
      category.toMap(),
      where: 'id = ?',
      whereArgs: [category.id],
    );
  }

  Future<int> delete(int id) async {
    final db = await _db.database;
    return await db.delete(
      'needs_categories',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
