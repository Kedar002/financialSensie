import '../../../../core/database/database_service.dart';
import '../models/offline_location.dart';

class OfflineLocationRepository {
  final DatabaseService _db = DatabaseService();

  Future<int> enqueue(OfflineLocation location) async {
    final db = await _db.database;
    return db.insert('offline_location_queue', location.toMap());
  }

  Future<List<OfflineLocation>> getPending() async {
    final db = await _db.database;
    final rows = await db.query(
      'offline_location_queue',
      orderBy: 'timestamp ASC',
    );
    return rows.map((r) => OfflineLocation.fromMap(r)).toList();
  }

  Future<void> delete(int id) async {
    final db = await _db.database;
    await db.delete('offline_location_queue', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> pendingCount() async {
    final db = await _db.database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM offline_location_queue');
    return result.first['count'] as int;
  }
}
