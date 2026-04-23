import 'package:geolocator/geolocator.dart';
import '../../core/models/visit.dart';
import '../../../../core/database/database_service.dart';

class VisitRepository {
  final _db = DatabaseService();

  /// Apply a zone rename to every visit that references the geofence.
  /// Visits denormalize zone_name at insert time, so renaming the geofence
  /// alone leaves history rows showing the old (or auto-generated) name.
  Future<List<int>> renameZone(int geofenceId, String newName) async {
    final db = await _db.database;
    final rows = await db.query(
      'visits',
      columns: ['id'],
      where: 'zone_id = ? AND (zone_name IS NULL OR zone_name != ?)',
      whereArgs: [geofenceId, newName],
    );
    if (rows.isEmpty) return const [];
    await db.update(
      'visits',
      {'zone_name': newName},
      where: 'zone_id = ?',
      whereArgs: [geofenceId],
    );
    return rows.map((r) => r['id'] as int).toList();
  }

  /// Retroactively link past "Unknown" visits (zone_id IS NULL) whose anchor
  /// falls inside the given zone's radius. Returns the ids that were updated
  /// so callers can mirror the change to Firestore.
  Future<List<int>> linkVisitsInRadius({
    required int geofenceId,
    required String name,
    required double latitude,
    required double longitude,
    required double radiusMeters,
  }) async {
    final db = await _db.database;
    final rows = await db.query(
      'visits',
      columns: ['id', 'latitude', 'longitude'],
      where: 'zone_id IS NULL',
    );
    final ids = <int>[];
    for (final row in rows) {
      final lat = (row['latitude'] as num).toDouble();
      final lng = (row['longitude'] as num).toDouble();
      final dist = Geolocator.distanceBetween(lat, lng, latitude, longitude);
      if (dist <= radiusMeters) {
        ids.add(row['id'] as int);
      }
    }
    if (ids.isEmpty) return const [];
    final placeholders = List.filled(ids.length, '?').join(',');
    await db.update(
      'visits',
      {'zone_name': name, 'zone_id': geofenceId},
      where: 'id IN ($placeholders)',
      whereArgs: ids,
    );
    return ids;
  }

  Future<int> insert(Visit visit) async {
    final db = await _db.database;
    return db.insert('visits', visit.toMap());
  }

  Future<void> update(Visit visit) async {
    final db = await _db.database;
    await db.update(
      'visits',
      visit.toMap(),
      where: 'id = ?',
      whereArgs: [visit.id],
    );
  }

  Future<void> finalize(int id, DateTime departureTime, int batteryOnDeparture) async {
    final db = await _db.database;
    final duration = departureTime
        .difference((await getById(id))!.arrivalTime)
        .inMinutes;
    await db.update(
      'visits',
      {
        'departure_time': departureTime.toIso8601String(),
        'duration_minutes': duration,
        'battery_on_departure': batteryOnDeparture,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<Visit?> getById(int id) async {
    final db = await _db.database;
    final rows = await db.query('visits', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return Visit.fromMap(rows.first);
  }

  /// Get the currently active (no departure) visit, if any.
  Future<Visit?> getActive() async {
    final db = await _db.database;
    final rows = await db.query(
      'visits',
      where: 'departure_time IS NULL',
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Visit.fromMap(rows.first);
  }

  /// Get visits for a specific date (local time).
  Future<List<Visit>> getByDate(DateTime date) async {
    final db = await _db.database;
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    final rows = await db.query(
      'visits',
      where: 'arrival_time >= ? AND arrival_time < ?',
      whereArgs: [start.toIso8601String(), end.toIso8601String()],
      orderBy: 'arrival_time ASC',
    );
    return rows.map(Visit.fromMap).toList();
  }

  /// Get all visits in a date range.
  Future<List<Visit>> getByDateRange(DateTime from, DateTime to) async {
    final db = await _db.database;
    final rows = await db.query(
      'visits',
      where: 'arrival_time >= ? AND arrival_time < ?',
      whereArgs: [from.toIso8601String(), to.toIso8601String()],
      orderBy: 'arrival_time ASC',
    );
    return rows.map(Visit.fromMap).toList();
  }

  /// Get recent visits (most recent first).
  Future<List<Visit>> getRecent({int limit = 50}) async {
    final db = await _db.database;
    final rows = await db.query(
      'visits',
      orderBy: 'arrival_time DESC',
      limit: limit,
    );
    return rows.map(Visit.fromMap).toList();
  }

  /// Get dates that have visits in a given month.
  Future<Set<DateTime>> getDatesWithVisits(int year, int month) async {
    final db = await _db.database;
    final start = DateTime(year, month);
    final end = DateTime(year, month + 1);
    final rows = await db.query(
      'visits',
      columns: ['arrival_time'],
      where: 'arrival_time >= ? AND arrival_time < ?',
      whereArgs: [start.toIso8601String(), end.toIso8601String()],
    );
    final dates = <DateTime>{};
    for (final row in rows) {
      final dt = DateTime.parse(row['arrival_time'] as String);
      dates.add(DateTime(dt.year, dt.month, dt.day));
    }
    return dates;
  }

  Future<void> delete(int id) async {
    final db = await _db.database;
    await db.delete('visits', where: 'id = ?', whereArgs: [id]);
  }

  /// Delete visits older than the given date.
  Future<int> deleteOlderThan(DateTime cutoff) async {
    final db = await _db.database;
    return db.delete(
      'visits',
      where: 'departure_time IS NOT NULL AND departure_time < ?',
      whereArgs: [cutoff.toIso8601String()],
    );
  }
}
