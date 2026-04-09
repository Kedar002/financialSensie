import '../../../../core/database/database_service.dart';
import '../models/saved_location.dart';
import '../models/location_data.dart';

class SavedLocationRepository {
  final DatabaseService _db = DatabaseService();

  Future<int> save(LocationData location) async {
    final db = await _db.database;
    return db.insert('saved_locations', SavedLocation(
      latitude: location.latitude,
      longitude: location.longitude,
      accuracy: location.accuracy,
      speed: location.speed,
      heading: location.heading,
      batteryLevel: location.batteryLevel,
      isCharging: location.isCharging,
      timestamp: location.timestamp,
      savedAt: DateTime.now(),
    ).toMap());
  }

  Future<List<SavedLocation>> getAll() async {
    final db = await _db.database;
    final rows = await db.query(
      'saved_locations',
      orderBy: 'timestamp DESC',
    );
    return rows.map((r) => SavedLocation.fromMap(r)).toList();
  }

  Future<void> delete(int id) async {
    final db = await _db.database;
    await db.delete('saved_locations', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteAll() async {
    final db = await _db.database;
    await db.delete('saved_locations');
  }
}
