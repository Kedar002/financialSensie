import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';
import '../models/visit.dart';
import '../models/zone_settings.dart';
import '../models/geofence.dart';

class VisitFirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // --- Active Visit (single doc showing current state) ---

  Future<void> setActiveVisit(String deviceId, Visit visit) async {
    await _firestore.collection('active_visit').doc(deviceId).set({
      'latitude': visit.latitude,
      'longitude': visit.longitude,
      'arrivalTime': visit.arrivalTime.toIso8601String(),
      'zoneName': visit.zoneName,
      'zoneId': visit.zoneId,
      'batteryOnArrival': visit.batteryOnArrival,
    });
  }

  Future<void> clearActiveVisit(String deviceId) async {
    await _firestore.collection('active_visit').doc(deviceId).delete();
  }

  Stream<Visit?> activeVisitStream(String deviceId) {
    return _firestore
        .collection('active_visit')
        .doc(deviceId)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) return null;
      final data = snapshot.data()!;
      return Visit(
        latitude: (data['latitude'] as num).toDouble(),
        longitude: (data['longitude'] as num).toDouble(),
        arrivalTime: DateTime.parse(data['arrivalTime'] as String),
        zoneName: data['zoneName'] as String?,
        zoneId: data['zoneId'] as int?,
        batteryOnArrival: data['batteryOnArrival'] as int? ?? -1,
      );
    });
  }

  // --- Completed Visits ---

  Future<void> addVisit(String deviceId, Visit visit) async {
    await _firestore
        .collection('visits')
        .doc(deviceId)
        .collection('records')
        .add(visit.toFirestore());
  }

  Stream<List<Visit>> visitsStream(String deviceId, {int limit = 50}) {
    return _firestore
        .collection('visits')
        .doc(deviceId)
        .collection('records')
        .orderBy('arrivalTime', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      final visits = <Visit>[];
      for (final doc in snapshot.docs) {
        try {
          visits.add(Visit.fromFirestore(doc.data()));
        } catch (_) {
          // Skip malformed documents instead of breaking the whole list
        }
      }
      return visits;
    });
  }

  Future<List<Visit>> getVisitsByDate(String deviceId, DateTime date) async {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    final snapshot = await _firestore
        .collection('visits')
        .doc(deviceId)
        .collection('records')
        .where('arrivalTime',
            isGreaterThanOrEqualTo: start.toIso8601String())
        .where('arrivalTime', isLessThan: end.toIso8601String())
        .orderBy('arrivalTime')
        .get();
    return snapshot.docs
        .map((doc) => Visit.fromFirestore(doc.data()))
        .toList();
  }

  /// Propagate a zone rename to every completed visit record that already
  /// references the geofence. History rows store a denormalized zoneName, so
  /// without this they keep showing the auto-generated name after a rename.
  Future<void> renameZoneInVisits(
      String deviceId, int geofenceId, String newName) async {
    final snapshot = await _firestore
        .collection('visits')
        .doc(deviceId)
        .collection('records')
        .where('zoneId', isEqualTo: geofenceId)
        .get();
    if (snapshot.docs.isEmpty) return;
    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      batch.update(doc.reference, {'zoneName': newName});
    }
    await batch.commit();
  }

  /// Link past "Unknown" visit records (zoneId == null) whose anchor falls
  /// inside the given zone's radius. Firestore lacks geo predicates, so
  /// filtering happens client-side on the unlinked subset.
  Future<void> linkUnknownVisitsInRadius({
    required String deviceId,
    required int geofenceId,
    required String name,
    required double latitude,
    required double longitude,
    required double radiusMeters,
  }) async {
    final snapshot = await _firestore
        .collection('visits')
        .doc(deviceId)
        .collection('records')
        .where('zoneId', isNull: true)
        .get();
    if (snapshot.docs.isEmpty) return;
    final batch = _firestore.batch();
    var count = 0;
    for (final doc in snapshot.docs) {
      final data = doc.data();
      final lat = (data['latitude'] as num?)?.toDouble();
      final lng = (data['longitude'] as num?)?.toDouble();
      if (lat == null || lng == null) continue;
      final dist = _haversineMeters(lat, lng, latitude, longitude);
      if (dist <= radiusMeters) {
        batch.update(doc.reference, {
          'zoneId': geofenceId,
          'zoneName': name,
        });
        count++;
      }
    }
    if (count == 0) return;
    await batch.commit();
  }

  static double _haversineMeters(
      double lat1, double lng1, double lat2, double lng2) {
    const earthRadius = 6371000.0;
    final dLat = (lat2 - lat1) * math.pi / 180.0;
    final dLng = (lng2 - lng1) * math.pi / 180.0;
    final sinLat = math.sin(dLat / 2);
    final sinLng = math.sin(dLng / 2);
    final h = sinLat * sinLat +
        math.cos(lat1 * math.pi / 180.0) *
            math.cos(lat2 * math.pi / 180.0) *
            sinLng *
            sinLng;
    return 2 * earthRadius * math.asin(math.sqrt(h));
  }

  // --- Zone Settings (Viewer → Tracker sync) ---

  Future<void> saveZoneSettings(
      String deviceId, int geofenceId, ZoneSettings settings) async {
    await _firestore
        .collection('zone_settings')
        .doc(deviceId)
        .collection('zones')
        .doc(geofenceId.toString())
        .set(settings.toFirestore());
  }

  Future<void> deleteZoneSettings(String deviceId, int geofenceId) async {
    await _firestore
        .collection('zone_settings')
        .doc(deviceId)
        .collection('zones')
        .doc(geofenceId.toString())
        .delete();
  }

  Stream<List<ZoneSettings>> zoneSettingsStream(String deviceId) {
    return _firestore
        .collection('zone_settings')
        .doc(deviceId)
        .collection('zones')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ZoneSettings.fromFirestore(doc.data()))
            .toList());
  }

  // --- Geofences (synced to tracker) ---

  Future<void> saveGeofence(
      String deviceId, Geofence geofence) async {
    await _firestore
        .collection('geofences')
        .doc(deviceId)
        .collection('zones')
        .doc(geofence.id.toString())
        .set(geofence.toFirestore());
  }

  Future<void> deleteGeofence(String deviceId, int geofenceId) async {
    await _firestore
        .collection('geofences')
        .doc(deviceId)
        .collection('zones')
        .doc(geofenceId.toString())
        .delete();
  }

  Stream<List<Geofence>> geofencesStream(String deviceId) {
    return _firestore
        .collection('geofences')
        .doc(deviceId)
        .collection('zones')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Geofence.fromFirestore(
                  doc.data(),
                  localId: int.tryParse(doc.id),
                ))
            .toList());
  }

  /// Fetch GPS samples recorded between two timestamps. Used to draw the
  /// transit polyline between two adjacent visits. Returns samples ordered
  /// oldest→newest. Empty result means no trail was recorded (either the
  /// transit predates continuous logging, or the tracker was unreachable).
  Future<List<LatLng>> locationHistoryBetween(
      String deviceId, DateTime from, DateTime to) async {
    final snapshot = await _firestore
        .collection('location_history')
        .doc(deviceId)
        .collection('points')
        .where('timestamp',
            isGreaterThanOrEqualTo: Timestamp.fromDate(from))
        .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(to))
        .orderBy('timestamp')
        .get();
    return snapshot.docs
        .map((doc) {
          final data = doc.data();
          final lat = (data['latitude'] as num?)?.toDouble();
          final lng = (data['longitude'] as num?)?.toDouble();
          if (lat == null || lng == null) return null;
          return LatLng(lat, lng);
        })
        .whereType<LatLng>()
        .toList();
  }

  // --- Cleanup ---

  Future<void> deleteVisitsOlderThan(String deviceId, DateTime cutoff) async {
    final collection = _firestore
        .collection('visits')
        .doc(deviceId)
        .collection('records');
    final snapshots = await collection
        .where('arrivalTime',
            isLessThan: cutoff.toIso8601String())
        .limit(100)
        .get();
    if (snapshots.docs.isEmpty) return;
    final batch = _firestore.batch();
    for (final doc in snapshots.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }
}
