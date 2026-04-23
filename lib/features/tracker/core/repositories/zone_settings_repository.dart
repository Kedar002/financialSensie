import '../../core/models/zone_settings.dart';
import '../../../../core/database/database_service.dart';

class ZoneSettingsRepository {
  final _db = DatabaseService();

  Future<int> insert(ZoneSettings settings) async {
    final db = await _db.database;
    return db.insert('zone_settings', settings.toMap());
  }

  Future<void> update(ZoneSettings settings) async {
    final db = await _db.database;
    await db.update(
      'zone_settings',
      settings.toMap(),
      where: 'id = ?',
      whereArgs: [settings.id],
    );
  }

  Future<void> upsertByGeofenceId(ZoneSettings settings) async {
    final db = await _db.database;
    final existing = await getByGeofenceId(settings.geofenceId);
    if (existing != null) {
      await db.update(
        'zone_settings',
        settings.toMap(),
        where: 'geofence_id = ?',
        whereArgs: [settings.geofenceId],
      );
    } else {
      await db.insert('zone_settings', settings.toMap());
    }
  }

  Future<ZoneSettings?> getByGeofenceId(int geofenceId) async {
    final db = await _db.database;
    final rows = await db.query(
      'zone_settings',
      where: 'geofence_id = ?',
      whereArgs: [geofenceId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return ZoneSettings.fromMap(rows.first);
  }

  Future<List<ZoneSettings>> getAll() async {
    final db = await _db.database;
    final rows = await db.query('zone_settings', orderBy: 'zone_name ASC');
    return rows.map(ZoneSettings.fromMap).toList();
  }

  Future<void> delete(int geofenceId) async {
    final db = await _db.database;
    await db.delete(
      'zone_settings',
      where: 'geofence_id = ?',
      whereArgs: [geofenceId],
    );
  }
}
