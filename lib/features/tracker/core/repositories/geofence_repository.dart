import '../../../../core/database/database_service.dart';
import '../models/geofence.dart';

class GeofenceRepository {
  final DatabaseService _db = DatabaseService();

  Future<List<Geofence>> getAll() async {
    final db = await _db.database;
    final rows = await db.query('geofences', orderBy: 'created_at DESC');
    return rows.map((r) => Geofence.fromMap(r)).toList();
  }

  Future<int> insert(Geofence geofence) async {
    final db = await _db.database;
    return db.insert('geofences', geofence.toMap());
  }

  Future<void> update(Geofence geofence) async {
    if (geofence.id == null) {
      throw ArgumentError('Cannot update a geofence without an id');
    }
    final db = await _db.database;
    await db.update(
      'geofences',
      geofence.toMap(),
      where: 'id = ?',
      whereArgs: [geofence.id],
    );
  }

  Future<void> delete(int id) async {
    final db = await _db.database;
    await db.delete('geofences', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> count() async {
    final db = await _db.database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM geofences');
    return result.first['count'] as int;
  }
}
