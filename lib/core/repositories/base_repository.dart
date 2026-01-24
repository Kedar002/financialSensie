import '../database/database_service.dart';

abstract class BaseRepository<T> {
  final DatabaseService _db = DatabaseService();

  String get tableName;

  T fromMap(Map<String, dynamic> map);
  Map<String, dynamic> toMap(T entity);

  DatabaseService get db => _db;

  int get timestamp => DateTime.now().millisecondsSinceEpoch ~/ 1000;

  Future<int> insert(T entity) async {
    return await _db.insert(tableName, toMap(entity));
  }

  Future<List<T>> getAll({String? orderBy}) async {
    final results = await _db.query(tableName, orderBy: orderBy);
    return results.map((map) => fromMap(map)).toList();
  }

  Future<T?> getById(int id) async {
    final results = await _db.query(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (results.isEmpty) return null;
    return fromMap(results.first);
  }

  Future<int> update(T entity, int id) async {
    return await _db.update(
      tableName,
      toMap(entity),
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> delete(int id) async {
    return await _db.delete(tableName, where: 'id = ?', whereArgs: [id]);
  }
}
