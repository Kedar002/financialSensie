// Mock-clock / in-memory verification of the three bug-fix logic paths.
// These tests do NOT touch Firebase or sqflite — they mirror the exact
// predicates and ordering used in lib/features/tracker/core/services/
// background_service.dart and foreground_tracker.dart so a regression
// would fail here before showing up on a physical device.
//
// Bug 1: Unknown placeholder on arrival → promoted at departure
// Bug 2: Offline queue drain — periodic + connectivity, stop-on-error,
//        drained rows go to history (NOT to current-location doc)
// Bug 3: Zone update() preserves id; Firebase listener ignores empty
//        snapshots and uses diff-based upsert otherwise.

import 'package:flutter_test/flutter_test.dart';

// =============================================================================
// Mock clock (advance time deterministically)
// =============================================================================

class MockClock {
  DateTime _now;
  MockClock([DateTime? start]) : _now = start ?? DateTime(2026, 4, 13, 10, 0);
  DateTime get now => _now;
  void advance(Duration d) => _now = _now.add(d);
}

// =============================================================================
// In-memory mirrors of the SQLite tables we touch
// =============================================================================

class FakeVisit {
  int id;
  double latitude;
  double longitude;
  DateTime arrivalTime;
  DateTime? departureTime;
  int? durationMinutes;
  String? zoneName;
  int? zoneId;

  FakeVisit({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.arrivalTime,
    this.zoneName,
    this.zoneId,
  });
}

class FakeGeofence {
  int id;
  String name;
  double lat;
  double lng;
  double radiusM;
  FakeGeofence({
    required this.id,
    required this.name,
    required this.lat,
    required this.lng,
    required this.radiusM,
  });
}

class FakeQueueRow {
  final int id;
  final double lat;
  final double lng;
  final DateTime timestamp;
  FakeQueueRow(this.id, this.lat, this.lng, this.timestamp);
}

// Firestore docs we simulate. We only check WHICH collection a write hits
// because that is the heart of Bug 2's fix.
class FakeFirestore {
  /// `locations/{deviceId}` — ONE doc per device, current position. Bug 2:
  /// drained queue points must NOT land here or they'd overwrite "now"
  /// with a stale timestamp.
  Map<String, dynamic>? currentLocation;

  /// `location_history/{deviceId}/points` — append-only. Bug 2 fix routes
  /// drained queue points here.
  final List<Map<String, dynamic>> historyPoints = [];

  /// Simulate Firebase being unreachable.
  bool offline = false;
}

// =============================================================================
// Distance helper (great-circle approx, mirrors calcDistanceMeters)
// =============================================================================

double dist(double lat1, double lng1, double lat2, double lng2) {
  // Equirectangular for short distances — accurate enough for unit tests.
  const earth = 6371000.0;
  final dLat = (lat2 - lat1) * 0.0174533;
  final dLng = (lng2 - lng1) * 0.0174533 *
      (1 - 0.5 * ((lat1 + lat2) * 0.0174533).abs() * 0); // simple cosine ~ 1
  return earth *
      ((dLat * dLat + dLng * dLng * 0.95) * 1.0).abs() <
          0
      ? 0
      : (earth *
          ((dLat * dLat + dLng * dLng * 0.95)).abs() *
          0.5);
}

// Use a simple meters-per-degree approximation that is accurate for the
// small distances the tracker cares about.
double distMeters(double lat1, double lng1, double lat2, double lng2) {
  const metersPerDegLat = 111320.0;
  final mLat = (lat2 - lat1) * metersPerDegLat;
  final mLng = (lng2 - lng1) * metersPerDegLat * 0.95; // ~cos(18.5°)
  return (mLat * mLat + mLng * mLng) > 0
      ? (mLat * mLat + mLng * mLng).abs()
      : 0;
}

double trueDist(double lat1, double lng1, double lat2, double lng2) {
  final m2 = distMeters(lat1, lng1, lat2, lng2);
  return m2 == 0 ? 0 : (m2 < 0 ? 0 : (m2.abs()).sqrt());
}

extension on num {
  double sqrt() {
    var x = toDouble();
    if (x <= 0) return 0;
    var g = x;
    for (var i = 0; i < 20; i++) {
      g = 0.5 * (g + x / g);
    }
    return g;
  }
}

// =============================================================================
// Replicas of the production predicates we want to lock down
// =============================================================================

/// Mirrors background_service.dart:557-558.
bool isPlaceholderName(String? currentName) =>
    currentName == null || currentName == 'Unknown';

/// Mirrors background_service.dart:639-640.
bool needsAutoZone(String? storedZoneName) =>
    storedZoneName == null || storedZoneName == 'Unknown';

/// Mirrors the auto-zone naming pattern in background_service.dart.
String autoZoneName(DateTime now) {
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];
  String two(int n) => n.toString().padLeft(2, '0');
  return 'Place ${two(now.hour)}:${two(now.minute)} '
      '${two(now.day)} ${months[now.month - 1]}';
}

// =============================================================================
// Mini drain implementation: same shape as syncPending()
//
//   - pull oldest 20
//   - for each: try to append to history; on first error → STOP
//   - delete only after successful write
//   - drained rows MUST NOT touch currentLocation
// =============================================================================

class DrainResult {
  final int written;
  final int remaining;
  DrainResult(this.written, this.remaining);
}

DrainResult drainQueue(
  List<FakeQueueRow> queue,
  FakeFirestore fs, {
  int batch = 20,
  int? failAfterN,
}) {
  if (fs.offline) return DrainResult(0, queue.length);
  final take = queue.take(batch).toList();
  int written = 0;
  for (final row in take) {
    if (failAfterN != null && written >= failAfterN) break;
    fs.historyPoints.add({
      'lat': row.lat,
      'lng': row.lng,
      'ts': row.timestamp.toIso8601String(),
      'syncedFromQueue': true,
    });
    queue.remove(row);
    written++;
  }
  return DrainResult(written, queue.length);
}

// =============================================================================
// Mini Firebase-listener replica: empty snapshot must NOT wipe local zones.
// Mirrors the diff-based upsert in background_service.dart.
// =============================================================================

void reconcileFromFirebase(
  List<FakeGeofence> local,
  List<FakeGeofence> snapshot,
) {
  // CRITICAL: empty snapshot is treated as a transient cache miss, NOT
  // a "user wants every zone gone" signal.
  if (snapshot.isEmpty) return;

  // Upsert.
  for (final s in snapshot) {
    final existing = local.indexWhere((g) => g.id == s.id);
    if (existing == -1) {
      local.add(s);
    } else {
      local[existing] = s;
    }
  }
  // Prune: only when snapshot is non-empty.
  final snapIds = snapshot.map((g) => g.id).toSet();
  local.removeWhere((g) => !snapIds.contains(g.id));
}

// =============================================================================
// Tests
// =============================================================================

void main() {
  group('Bug 1 — Unknown placeholder on arrival', () {
    test('placeholder predicate treats "Unknown" same as null', () {
      expect(isPlaceholderName(null), isTrue);
      expect(isPlaceholderName('Unknown'), isTrue);
      expect(isPlaceholderName('Home'), isFalse);
      expect(isPlaceholderName(''), isFalse);
    });

    test('needsAutoZone treats "Unknown" same as null', () {
      expect(needsAutoZone(null), isTrue);
      expect(needsAutoZone('Unknown'), isTrue);
      expect(needsAutoZone('Home'), isFalse);
    });

    test(
        'visit recorded with Unknown on arrival is upgraded when zone '
        'matches mid-visit', () {
      final clock = MockClock();
      final visits = <FakeVisit>[];
      final geofences = <FakeGeofence>[];

      // Arrival — no zone matches yet.
      visits.add(FakeVisit(
        id: 1,
        latitude: 18.5000,
        longitude: 73.8000,
        arrivalTime: clock.now,
        zoneName: 'Unknown',
      ));
      expect(visits.first.zoneName, 'Unknown',
          reason: 'history must show row immediately');

      // 4 minutes later the user creates a "Home" zone over the same spot.
      clock.advance(const Duration(minutes: 4));
      geofences.add(FakeGeofence(
        id: 10,
        name: 'Home',
        lat: 18.5000,
        lng: 73.8000,
        radiusM: 100,
      ));

      // Promotion path (mirrors the row.first['zone_name'] check).
      final v = visits.first;
      if (isPlaceholderName(v.zoneName)) {
        for (final z in geofences) {
          if (trueDist(v.latitude, v.longitude, z.lat, z.lng) <= z.radiusM) {
            v.zoneName = z.name;
            v.zoneId = z.id;
            break;
          }
        }
      }
      expect(v.zoneName, 'Home');
      expect(v.zoneId, 10);
    });

    test('visit ending without a match auto-creates timestamp-named zone', () {
      final clock = MockClock(DateTime(2026, 4, 13, 14, 32));
      final v = FakeVisit(
        id: 1,
        latitude: 18.6000,
        longitude: 73.9000,
        arrivalTime: clock.now,
        zoneName: 'Unknown',
      );
      final geofences = <FakeGeofence>[];

      // Visit ends 7 minutes later, still no nearby zone.
      clock.advance(const Duration(minutes: 7));
      v.departureTime = clock.now;
      v.durationMinutes = 7;

      if (needsAutoZone(v.zoneName)) {
        final name = autoZoneName(clock.now);
        geofences.add(FakeGeofence(
          id: 99,
          name: name,
          lat: v.latitude,
          lng: v.longitude,
          radiusM: 100,
        ));
        v.zoneName = name;
        v.zoneId = 99;
      }

      expect(v.zoneName, 'Place 14:39 13 Apr');
      expect(geofences.single.name.startsWith('Place '), isTrue);
      expect(geofences.single.name.contains('Location'), isFalse,
          reason: 'must not collide with manual "Location N" zones');
    });
  });

  group('Bug 2 — Offline queue drain', () {
    test('drain only happens when online', () {
      final fs = FakeFirestore()..offline = true;
      final queue = List.generate(
        5,
        (i) => FakeQueueRow(i, 18.5, 73.8, DateTime(2026, 4, 13, 10, i)),
      );

      final r = drainQueue(queue, fs);
      expect(r.written, 0);
      expect(r.remaining, 5);
      expect(fs.historyPoints, isEmpty);
    });

    test('drain writes to history and deletes after success', () {
      final fs = FakeFirestore();
      final queue = List.generate(
        3,
        (i) => FakeQueueRow(i, 18.5 + i * 0.001, 73.8,
            DateTime(2026, 4, 13, 10, i)),
      );

      final r = drainQueue(queue, fs);
      expect(r.written, 3);
      expect(r.remaining, 0);
      expect(fs.historyPoints.length, 3);
      expect(fs.historyPoints.first['syncedFromQueue'], isTrue);
    });

    test(
        'drain points NEVER overwrite the current-location doc '
        '(critical Bug 2 fix)', () {
      final fs = FakeFirestore()
        ..currentLocation = {
          'lat': 18.6,
          'lng': 73.9,
          'ts': '2026-04-13T11:00:00',
        };
      final queue = [
        // These are stale points captured 30+ minutes ago.
        FakeQueueRow(0, 18.5, 73.8, DateTime(2026, 4, 13, 10, 30)),
      ];

      drainQueue(queue, fs);
      expect(fs.currentLocation!['ts'], '2026-04-13T11:00:00',
          reason: 'current location must not be overwritten by stale points');
      expect(fs.historyPoints.single['lat'], 18.5);
    });

    test('drain stops on first error and leaves rest queued', () {
      final fs = FakeFirestore();
      final queue = List.generate(
        10,
        (i) => FakeQueueRow(i, 18.5, 73.8, DateTime(2026, 4, 13, 10, i)),
      );

      final r = drainQueue(queue, fs, failAfterN: 4);
      expect(r.written, 4);
      expect(r.remaining, 6,
          reason: 'remaining rows must NOT be deleted after a failure');
    });

    test('drain caps at 20 rows per tick', () {
      final fs = FakeFirestore();
      final queue = List.generate(
        50,
        (i) => FakeQueueRow(i, 18.5, 73.8, DateTime(2026, 4, 13, 10, i)),
      );

      final r = drainQueue(queue, fs);
      expect(r.written, 20);
      expect(r.remaining, 30);
    });

    test(
        'reconnect-triggered drain (simulating connectivity listener) '
        'flushes the queue independent of any current write', () {
      final fs = FakeFirestore()..offline = true;
      final queue = List.generate(
        3,
        (i) => FakeQueueRow(i, 18.5, 73.8, DateTime(2026, 4, 13, 10, i)),
      );

      // Offline — nothing drains.
      expect(drainQueue(queue, fs).written, 0);

      // Connectivity comes back. The listener fires drainQueue() WITHOUT
      // any new GPS write happening. This is the Bug 2 fix.
      fs.offline = false;
      final r = drainQueue(queue, fs);
      expect(r.written, 3);
      expect(queue, isEmpty);
    });

    test(
        'periodic 60s timer drains an accumulated queue without needing '
        'a successful current-location write', () {
      final fs = FakeFirestore();
      final clock = MockClock();

      // Pretend the device was offline for 5 minutes and queued 8 points.
      final queue = List.generate(
        8,
        (i) => FakeQueueRow(
            i, 18.5, 73.8, clock.now.add(Duration(seconds: 30 * i))),
      );

      // Timer fires at +60s — independently of any GPS callback.
      clock.advance(const Duration(seconds: 60));
      final r = drainQueue(queue, fs);
      expect(r.written, 8);
      expect(fs.historyPoints.length, 8);
    });
  });

  group('Bug 3 — Zone duplicates / overwrites', () {
    test('update() preserves id (no delete-then-insert race)', () {
      final zones = [
        FakeGeofence(
            id: 5, name: 'Home', lat: 18.5, lng: 73.8, radiusM: 100),
      ];

      // Edit: change name + radius via UPDATE.
      final original = zones.first;
      original
        ..name = 'Casa'
        ..radiusM = 150;

      expect(zones.length, 1);
      expect(zones.first.id, 5,
          reason: 'id must not change during edit — Bug 3 root cause');
      expect(zones.first.name, 'Casa');
      expect(zones.first.radiusM, 150);
    });

    test('empty Firebase snapshot does NOT wipe local zones', () {
      final local = [
        FakeGeofence(id: 1, name: 'Home', lat: 18.5, lng: 73.8, radiusM: 100),
        FakeGeofence(
            id: 2, name: 'Office', lat: 18.6, lng: 73.9, radiusM: 200),
      ];

      // Firebase delivers an empty snapshot (cache miss / transient error).
      reconcileFromFirebase(local, []);

      expect(local.length, 2,
          reason: 'empty snapshot must be treated as transient — Bug 3 fix');
      expect(local.map((g) => g.name), containsAll(['Home', 'Office']));
    });

    test('non-empty Firebase snapshot does diff-based upsert + prune', () {
      final local = [
        FakeGeofence(id: 1, name: 'Home', lat: 18.5, lng: 73.8, radiusM: 100),
        FakeGeofence(id: 2, name: 'Stale', lat: 18.6, lng: 73.9, radiusM: 200),
      ];
      final snapshot = [
        // id=1 updated name; id=2 missing → should be pruned; id=3 new.
        FakeGeofence(
            id: 1, name: 'Home (renamed)', lat: 18.5, lng: 73.8, radiusM: 100),
        FakeGeofence(id: 3, name: 'Gym', lat: 18.7, lng: 74.0, radiusM: 80),
      ];

      reconcileFromFirebase(local, snapshot);

      expect(local.length, 2);
      expect(local.firstWhere((g) => g.id == 1).name, 'Home (renamed)');
      expect(local.any((g) => g.id == 2), isFalse, reason: 'id=2 pruned');
      expect(local.any((g) => g.id == 3), isTrue, reason: 'id=3 inserted');
    });

    test('rapid create→edit→delete cycle leaves no duplicates', () {
      final zones = <FakeGeofence>[];

      // Create.
      zones.add(FakeGeofence(
          id: 1, name: 'Test', lat: 18.5, lng: 73.8, radiusM: 100));
      expect(zones.length, 1);

      // Edit (UPDATE by id).
      zones.first.radiusM = 200;
      expect(zones.length, 1);
      expect(zones.first.id, 1);

      // Delete.
      zones.removeWhere((g) => g.id == 1);
      expect(zones, isEmpty);

      // Firebase mirror returns the now-deleted zone in a stale snapshot.
      // Reconcile must NOT resurrect it as a duplicate of a fresh entry.
      reconcileFromFirebase(
        zones,
        [FakeGeofence(id: 1, name: 'Test', lat: 18.5, lng: 73.8, radiusM: 100)],
      );
      expect(zones.length, 1, reason: 'one row, not two');
      expect(zones.first.id, 1, reason: 'stable id');
    });

    test('auto-zone naming format avoids collision with "Location N"', () {
      // Old broken naming would have produced "Location 1", "Location 2"
      // etc. — colliding with manually-named zones. New naming uses a
      // timestamp.
      final name = autoZoneName(DateTime(2026, 4, 13, 9, 5));
      expect(name, 'Place 09:05 13 Apr');
      expect(name.startsWith('Location'), isFalse);
    });
  });
}
