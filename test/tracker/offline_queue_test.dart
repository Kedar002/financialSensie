import 'package:flutter_test/flutter_test.dart';
import 'package:financesensei/features/tracker/core/services/stationary_detector.dart';
import 'package:financesensei/features/tracker/core/tracker_constants.dart';
import 'package:financesensei/features/tracker/core/models/location_data.dart';

// =============================================================================
// Proxy helpers
// =============================================================================

class ProxyClock {
  DateTime _now;
  ProxyClock([DateTime? start]) : _now = start ?? DateTime(2026, 4, 11, 8, 0);
  DateTime get now => _now;
  void advance(Duration d) => _now = _now.add(d);
}

GpsReading proxyGps({
  required double lat,
  required double lng,
  double speed = 0.0,
  double accuracy = 10.0,
  required DateTime timestamp,
}) {
  return GpsReading(
    latitude: lat,
    longitude: lng,
    speed: speed,
    accuracy: accuracy,
    timestamp: timestamp,
  );
}

const double homeLat = 18.5000;
const double homeLng = 73.8000;
const double nearHomeLat = 18.50008;
const double nearHomeLng = 73.80008;
const double farLat = 18.5020;
const double farLng = 73.8020;

// =============================================================================
// Simulated offline queue row (mirrors offline_location_queue SQLite row)
// =============================================================================

class QueuedLocation {
  final int id;
  final double latitude;
  final double longitude;
  final double accuracy;
  final double speed;
  final double heading;
  final int batteryLevel;
  final bool isCharging;
  final DateTime timestamp;
  final DateTime createdAt;

  QueuedLocation({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    required this.speed,
    required this.heading,
    required this.batteryLevel,
    required this.isCharging,
    required this.timestamp,
    required this.createdAt,
  });
}

// =============================================================================
// ForegroundTracker Simulator — mirrors _sendLocation() with offline queue
//
// Simulates the exact logic of the restructured _sendLocation():
// - Phase 1: GPS + detector (always runs if location service is on)
// - Phase 2: Firebase + queue (checks network, queues if offline, syncs on reconnect)
// =============================================================================

class FGTrackerOfflineSim {
  final StationaryDetector detector = StationaryDetector();

  bool isTracking = false;
  bool isPaused = false;
  bool isNetworkAvailable = true;
  bool isLocationServiceEnabled = true;

  // Simulated offline queue (mirrors SQLite offline_location_queue)
  final List<QueuedLocation> offlineQueue = [];
  int _nextQueueId = 1;

  // Firebase state
  final List<Map<String, dynamic>> firebaseWrites = [];
  Map<String, dynamic>? lastFirebaseDoc; // the locations/{deviceId} doc
  DateTime? lastFirebaseSendTime;
  int sendCount = 0;

  // Status-only writes (when location service is off)
  final List<Map<String, dynamic>> statusOnlyWrites = [];

  // Detector interval
  String settingsFrequency = 'smart';
  int settingsCustomSeconds = 60;
  Duration currentInterval = TrackerConstants.movingPollInterval;

  // Battery
  int batteryLevel = 75;
  bool isCharging = false;

  // Zone report interval for throttling
  Duration get zoneReportInterval => detector.zoneReportInterval;

  void start() {
    isTracking = true;
  }

  /// Mirrors _sendLocation() exactly.
  /// Returns a description of what happened for test assertions.
  String sendLocation(double lat, double lng, {
    double speed = 0.0,
    double accuracy = 10.0,
    required DateTime timestamp,
  }) {
    if (isPaused) return 'skipped_paused';

    // --- Phase 1: GPS + detector ---
    if (!isLocationServiceEnabled) {
      // Write status-only if online
      if (isNetworkAvailable) {
        statusOnlyWrites.add({
          'isNetworkAvailable': true,
          'isLocationServiceEnabled': false,
          'pendingQueueCount': offlineQueue.length,
          'timestamp': timestamp,
        });
        return 'status_only_location_off';
      }
      return 'location_off_and_offline';
    }

    final reading = proxyGps(
      lat: lat,
      lng: lng,
      speed: speed,
      accuracy: accuracy,
      timestamp: timestamp,
    );
    final result = detector.process(reading);

    // Adjust timer interval
    final fixedInterval = TrackerConstants.fixedIntervalForFrequency(
        settingsFrequency, settingsCustomSeconds);
    final nextInterval = fixedInterval ?? result.nextPollInterval;
    currentInterval = nextInterval;

    // --- Phase 2: Firebase + queue ---
    // Check throttle
    final reportInterval = detector.zoneReportInterval;
    final shouldSendFirebase = reportInterval == Duration.zero ||
        lastFirebaseSendTime == null ||
        timestamp.difference(lastFirebaseSendTime!) >= reportInterval;

    if (!shouldSendFirebase) {
      return 'gps_polled_firebase_throttled';
    }

    final pendingCount = offlineQueue.length;

    final data = {
      'latitude': lat,
      'longitude': lng,
      'timestamp': timestamp,
      'speed': speed,
      'accuracy': accuracy,
      'batteryLevel': batteryLevel,
      'isCharging': isCharging,
      'isNetworkAvailable': isNetworkAvailable,
      'isLocationServiceEnabled': true,
      'pendingQueueCount': pendingCount,
    };

    bool firebaseOk = false;
    if (isNetworkAvailable) {
      // Simulate successful Firebase write
      firebaseWrites.add(Map.from(data));
      lastFirebaseDoc = Map.from(data);
      lastFirebaseSendTime = timestamp;
      sendCount++;
      firebaseOk = true;

      // Sync pending
      _syncPending(timestamp);
    }

    if (!firebaseOk) {
      _queueLocation(
        lat: lat,
        lng: lng,
        speed: speed,
        accuracy: accuracy,
        heading: 0,
        timestamp: timestamp,
      );
      return 'queued_offline';
    }

    return 'firebase_sent';
  }

  void _queueLocation({
    required double lat,
    required double lng,
    required double speed,
    required double accuracy,
    required double heading,
    required DateTime timestamp,
  }) {
    // Cap queue at 1000
    if (offlineQueue.length >= 1000) {
      // Remove oldest 10
      offlineQueue.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      offlineQueue.removeRange(0, 10.clamp(0, offlineQueue.length));
    }
    offlineQueue.add(QueuedLocation(
      id: _nextQueueId++,
      latitude: lat,
      longitude: lng,
      accuracy: accuracy,
      speed: speed,
      heading: heading,
      batteryLevel: batteryLevel,
      isCharging: isCharging,
      timestamp: timestamp,
      createdAt: timestamp,
    ));
  }

  /// Sync up to 20 oldest queued locations, delete after sync.
  void _syncPending(DateTime now) {
    if (offlineQueue.isEmpty) return;
    offlineQueue.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    final toSync = offlineQueue.take(20).toList();
    for (final q in toSync) {
      firebaseWrites.add({
        'latitude': q.latitude,
        'longitude': q.longitude,
        'timestamp': q.timestamp,
        'speed': q.speed,
        'accuracy': q.accuracy,
        'batteryLevel': q.batteryLevel,
        'isCharging': q.isCharging,
        'isNetworkAvailable': true,
        'isLocationServiceEnabled': true,
        'pendingQueueCount': 0,
      });
      offlineQueue.remove(q);
    }
  }
}

// =============================================================================
// BackgroundService Simulator — mirrors processLocation() with status fields
// =============================================================================

class BGServiceOfflineSim {
  final StationaryDetector detector = StationaryDetector();

  bool isLocationServiceEnabled = true;

  // Simulated offline queue (shared with FG in real app, separate here for clarity)
  final List<QueuedLocation> offlineQueue = [];
  int _nextQueueId = 1;

  // Firebase state
  final List<Map<String, dynamic>> firebaseWrites = [];
  Map<String, dynamic>? lastFirebaseDoc;
  DateTime? lastFirebaseSendTime;
  bool firestoreAvailable = true; // simulates firestore != null && network OK

  int batteryLevel = 75;
  bool isCharging = false;

  /// Mirrors processLocation() with status fields.
  String processLocation(double lat, double lng, {
    double speed = 0.0,
    required DateTime timestamp,
  }) {
    if (!isLocationServiceEnabled) {
      return 'skip_location_disabled';
    }

    final reading = proxyGps(
      lat: lat,
      lng: lng,
      speed: speed,
      timestamp: timestamp,
    );
    final result = detector.process(reading);

    // Throttle check
    final zoneReport = detector.zoneReportInterval;
    final shouldSendFirebase = zoneReport == Duration.zero ||
        lastFirebaseSendTime == null ||
        timestamp.difference(lastFirebaseSendTime!) >= zoneReport;

    final pendingCount = offlineQueue.length;

    if (shouldSendFirebase) {
      final locData = {
        'latitude': lat,
        'longitude': lng,
        'timestamp': timestamp,
        'speed': speed,
        'batteryLevel': batteryLevel,
        'isCharging': isCharging,
        'motionState': result.state.name,
        'isNetworkAvailable': true,
        'isLocationServiceEnabled': true,
        'pendingQueueCount': pendingCount,
      };

      bool firebaseOk = false;
      if (firestoreAvailable) {
        firebaseWrites.add(Map.from(locData));
        lastFirebaseDoc = Map.from(locData);
        lastFirebaseSendTime = timestamp;
        firebaseOk = true;
        _syncPending();
      }

      if (!firebaseOk) {
        offlineQueue.add(QueuedLocation(
          id: _nextQueueId++,
          latitude: lat,
          longitude: lng,
          accuracy: 10,
          speed: speed,
          heading: 0,
          batteryLevel: batteryLevel,
          isCharging: isCharging,
          timestamp: timestamp,
          createdAt: timestamp,
        ));
        return 'queued_offline';
      }
      return 'firebase_sent';
    }

    return 'gps_polled_firebase_throttled';
  }

  void _syncPending() {
    if (offlineQueue.isEmpty) return;
    offlineQueue.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    final toSync = offlineQueue.take(20).toList();
    for (final q in toSync) {
      firebaseWrites.add({
        'latitude': q.latitude,
        'longitude': q.longitude,
        'timestamp': q.timestamp,
        'speed': q.speed,
        'batteryLevel': q.batteryLevel,
        'isCharging': q.isCharging,
        'isNetworkAvailable': true,
        'isLocationServiceEnabled': true,
        'pendingQueueCount': 0,
      });
      offlineQueue.remove(q);
    }
  }
}

// =============================================================================
// TESTS
// =============================================================================

void main() {
  // ===========================================================================
  // FG Tracker: basic online behavior (status fields present)
  // ===========================================================================
  group('FG online: status fields in Firebase writes', () {
    late FGTrackerOfflineSim fg;
    late ProxyClock clock;

    setUp(() {
      fg = FGTrackerOfflineSim();
      fg.start();
      clock = ProxyClock();
    });

    test('online write includes all 3 status fields', () {
      final action = fg.sendLocation(homeLat, homeLng,
          speed: 0.5, timestamp: clock.now);
      expect(action, 'firebase_sent');
      expect(fg.lastFirebaseDoc!['isNetworkAvailable'], true);
      expect(fg.lastFirebaseDoc!['isLocationServiceEnabled'], true);
      expect(fg.lastFirebaseDoc!['pendingQueueCount'], 0);
    });

    test('pendingQueueCount reflects actual queue size', () {
      // Go offline and queue 3 locations
      fg.isNetworkAvailable = false;
      for (int i = 0; i < 3; i++) {
        clock.advance(const Duration(seconds: 30));
        fg.sendLocation(homeLat, homeLng,
            speed: 0.5, timestamp: clock.now);
      }
      expect(fg.offlineQueue.length, 3);

      // Go online — next write should show pendingQueueCount = 3
      fg.isNetworkAvailable = true;
      clock.advance(const Duration(seconds: 30));
      fg.sendLocation(homeLat, homeLng,
          speed: 0.5, timestamp: clock.now);

      // The write that goes out has the pending count FROM BEFORE sync
      // (matches real code: count is read, then Firebase write, then syncPending)
      final lastWrite = fg.firebaseWrites
          .where((w) => w['pendingQueueCount'] != 0)
          .toList();
      // The first online write should have pendingCount=3
      expect(lastWrite.isNotEmpty, true);
      expect(lastWrite.first['pendingQueueCount'], 3);
    });
  });

  // ===========================================================================
  // FG Tracker: offline queue behavior
  // ===========================================================================
  group('FG offline queue: queue and sync', () {
    late FGTrackerOfflineSim fg;
    late ProxyClock clock;

    setUp(() {
      fg = FGTrackerOfflineSim();
      fg.start();
      clock = ProxyClock();
    });

    test('offline: locations queued to local DB', () {
      fg.isNetworkAvailable = false;

      final action = fg.sendLocation(homeLat, homeLng,
          speed: 0.5, timestamp: clock.now);
      expect(action, 'queued_offline');
      expect(fg.offlineQueue.length, 1);
      expect(fg.firebaseWrites.length, 0);
    });

    test('offline: multiple locations accumulate in queue', () {
      fg.isNetworkAvailable = false;

      for (int i = 0; i < 5; i++) {
        clock.advance(const Duration(seconds: 30));
        fg.sendLocation(homeLat + i * 0.0001, homeLng,
            speed: 0.5, timestamp: clock.now);
      }
      expect(fg.offlineQueue.length, 5);
      expect(fg.firebaseWrites.length, 0);
    });

    test('online after offline: queue is synced and cleared', () {
      fg.isNetworkAvailable = false;

      // Queue 3 locations
      for (int i = 0; i < 3; i++) {
        clock.advance(const Duration(seconds: 30));
        fg.sendLocation(homeLat, homeLng,
            speed: 0.5, timestamp: clock.now);
      }
      expect(fg.offlineQueue.length, 3);

      // Go online
      fg.isNetworkAvailable = true;
      clock.advance(const Duration(seconds: 30));
      final action = fg.sendLocation(homeLat, homeLng,
          speed: 0.5, timestamp: clock.now);
      expect(action, 'firebase_sent');

      // Queue should be drained
      expect(fg.offlineQueue.length, 0);

      // Firebase should have: 1 current write + 3 synced from queue = 4
      expect(fg.firebaseWrites.length, 4);
    });

    test('sync drains max 20 per tick', () {
      fg.isNetworkAvailable = false;

      // Queue 25 locations
      for (int i = 0; i < 25; i++) {
        clock.advance(const Duration(seconds: 30));
        fg.sendLocation(homeLat, homeLng,
            speed: 0.5, timestamp: clock.now);
      }
      expect(fg.offlineQueue.length, 25);

      // Go online — one tick
      fg.isNetworkAvailable = true;
      clock.advance(const Duration(seconds: 30));
      fg.sendLocation(homeLat, homeLng,
          speed: 0.5, timestamp: clock.now);

      // 20 synced + 1 current = 21 Firebase writes, 5 remain in queue
      expect(fg.offlineQueue.length, 5);
      expect(fg.firebaseWrites.length, 21);

      // Second tick drains the remaining 5
      clock.advance(const Duration(seconds: 30));
      fg.sendLocation(homeLat, homeLng,
          speed: 0.5, timestamp: clock.now);
      expect(fg.offlineQueue.length, 0);
      expect(fg.firebaseWrites.length, 27); // 21 + 5 synced + 1 current
    });

    test('queue cap at 1000: oldest entries removed', () {
      fg.isNetworkAvailable = false;

      // Queue exactly 1000 locations
      for (int i = 0; i < 1000; i++) {
        clock.advance(const Duration(seconds: 1));
        fg.sendLocation(homeLat + i * 0.00001, homeLng,
            speed: 0.5, timestamp: clock.now);
      }
      expect(fg.offlineQueue.length, 1000);

      // Queue one more — should cap: remove 10 oldest, add 1 = 991
      clock.advance(const Duration(seconds: 1));
      fg.sendLocation(homeLat, homeLng,
          speed: 0.5, timestamp: clock.now);
      expect(fg.offlineQueue.length, 991);
    });

    test('queue preserves GPS data correctly', () {
      fg.isNetworkAvailable = false;
      fg.batteryLevel = 42;
      fg.isCharging = true;

      fg.sendLocation(12.345, 67.890,
          speed: 3.5, accuracy: 15.0, timestamp: clock.now);

      expect(fg.offlineQueue.length, 1);
      final q = fg.offlineQueue.first;
      expect(q.latitude, 12.345);
      expect(q.longitude, 67.890);
      expect(q.speed, 3.5);
      expect(q.accuracy, 15.0);
      expect(q.batteryLevel, 42);
      expect(q.isCharging, true);
      expect(q.timestamp, clock.now);
    });
  });

  // ===========================================================================
  // FG Tracker: location service off
  // ===========================================================================
  group('FG: location service disabled', () {
    late FGTrackerOfflineSim fg;
    late ProxyClock clock;

    setUp(() {
      fg = FGTrackerOfflineSim();
      fg.start();
      clock = ProxyClock();
    });

    test('location off + online: writes status-only to Firebase', () {
      fg.isLocationServiceEnabled = false;
      fg.isNetworkAvailable = true;

      final action = fg.sendLocation(homeLat, homeLng, timestamp: clock.now);
      expect(action, 'status_only_location_off');
      expect(fg.statusOnlyWrites.length, 1);
      expect(fg.statusOnlyWrites.first['isLocationServiceEnabled'], false);
      expect(fg.statusOnlyWrites.first['isNetworkAvailable'], true);

      // No GPS data written to Firebase
      expect(fg.firebaseWrites.length, 0);
      // No queueing either (no GPS data to queue)
      expect(fg.offlineQueue.length, 0);
    });

    test('location off + offline: nothing happens', () {
      fg.isLocationServiceEnabled = false;
      fg.isNetworkAvailable = false;

      final action = fg.sendLocation(homeLat, homeLng, timestamp: clock.now);
      expect(action, 'location_off_and_offline');
      expect(fg.statusOnlyWrites.length, 0);
      expect(fg.firebaseWrites.length, 0);
      expect(fg.offlineQueue.length, 0);
    });

    test('location toggled off then on: resumes normal operation', () {
      // Start online and tracking normally
      fg.sendLocation(homeLat, homeLng,
          speed: 0.5, timestamp: clock.now);
      expect(fg.firebaseWrites.length, 1);

      // Location off
      fg.isLocationServiceEnabled = false;
      clock.advance(const Duration(seconds: 30));
      fg.sendLocation(homeLat, homeLng, timestamp: clock.now);
      expect(fg.firebaseWrites.length, 1); // no new GPS write
      expect(fg.statusOnlyWrites.length, 1);

      // Location back on
      fg.isLocationServiceEnabled = true;
      clock.advance(const Duration(seconds: 30));
      final action = fg.sendLocation(homeLat, homeLng,
          speed: 0.5, timestamp: clock.now);
      expect(action, 'firebase_sent');
      expect(fg.firebaseWrites.length, 2);
    });
  });

  // ===========================================================================
  // FG Tracker: network toggle scenarios with proxy GPS
  // ===========================================================================
  group('FG: network toggle scenarios', () {
    late FGTrackerOfflineSim fg;
    late ProxyClock clock;

    setUp(() {
      fg = FGTrackerOfflineSim();
      fg.start();
      clock = ProxyClock();
    });

    test('online → offline → online: full cycle', () {
      // Online: 2 writes
      fg.sendLocation(homeLat, homeLng,
          speed: 0.5, timestamp: clock.now);
      clock.advance(const Duration(seconds: 30));
      fg.sendLocation(nearHomeLat, nearHomeLng,
          speed: 0.3, timestamp: clock.now);
      expect(fg.firebaseWrites.length, 2);
      expect(fg.offlineQueue.length, 0);

      // Offline: 3 queued
      fg.isNetworkAvailable = false;
      for (int i = 0; i < 3; i++) {
        clock.advance(const Duration(seconds: 30));
        fg.sendLocation(homeLat, homeLng,
            speed: 0.5, timestamp: clock.now);
      }
      expect(fg.firebaseWrites.length, 2);
      expect(fg.offlineQueue.length, 3);

      // Online: 1 current + 3 synced
      fg.isNetworkAvailable = true;
      clock.advance(const Duration(seconds: 30));
      fg.sendLocation(homeLat, homeLng,
          speed: 0.5, timestamp: clock.now);
      expect(fg.offlineQueue.length, 0);
      expect(fg.firebaseWrites.length, 6); // 2 + 1 + 3
    });

    test('detector state preserved during offline period', () {
      // Become stationary while online
      for (int i = 0; i < 3; i++) {
        fg.sendLocation(homeLat, homeLng,
            speed: 0.5, timestamp: clock.now);
        clock.advance(const Duration(seconds: 30));
      }
      expect(fg.detector.state, MotionState.stationary);

      // Go offline — detector still processes GPS
      fg.isNetworkAvailable = false;
      for (int i = 0; i < 3; i++) {
        clock.advance(const Duration(seconds: 30));
        fg.sendLocation(nearHomeLat, nearHomeLng,
            speed: 0.2, timestamp: clock.now);
      }
      expect(fg.detector.state, MotionState.stationary);

      // Move while offline
      clock.advance(const Duration(seconds: 30));
      fg.sendLocation(farLat, farLng,
          speed: 5.0, timestamp: clock.now);
      expect(fg.detector.state, MotionState.maybeMoving);

      clock.advance(const Duration(seconds: 30));
      fg.sendLocation(farLat + 0.001, farLng,
          speed: 5.0, timestamp: clock.now);
      expect(fg.detector.state, MotionState.moving);
    });

    test('interval adjustment works during offline', () {
      fg.settingsFrequency = 'smart';

      // Moving interval while online
      fg.sendLocation(homeLat, homeLng,
          speed: 5.0, timestamp: clock.now);
      expect(fg.currentInterval, TrackerConstants.movingPollInterval);

      // Go offline, become stationary
      fg.isNetworkAvailable = false;
      for (int i = 0; i < 3; i++) {
        clock.advance(const Duration(seconds: 30));
        fg.sendLocation(homeLat, homeLng,
            speed: 0.3, timestamp: clock.now);
      }
      // Interval should update even though offline
      expect(fg.currentInterval, TrackerConstants.stationaryPollInterval);
    });
  });

  // ===========================================================================
  // FG Tracker: zone interval + offline queue interaction
  // ===========================================================================
  group('FG: zone interval with offline queue', () {
    late FGTrackerOfflineSim fg;
    late ProxyClock clock;

    setUp(() {
      fg = FGTrackerOfflineSim();
      fg.start();
      fg.settingsFrequency = 'smart';
      clock = ProxyClock();
    });

    test('zone interval throttles Firebase, queues when offline', () {
      // Become stationary
      for (int i = 0; i < 3; i++) {
        fg.sendLocation(homeLat, homeLng,
            speed: 0.3, timestamp: clock.now);
        clock.advance(const Duration(seconds: 30));
      }

      // Set 60-min zone interval (capped at 5 min for GPS poll)
      fg.detector.setZoneInterval(60);

      // While online: GPS polls at 5 min, Firebase throttled to 60 min
      fg.firebaseWrites.clear();
      int throttledCount = 0;

      for (int i = 0; i < 12; i++) {
        // 12 × 5 min = 60 min
        clock.advance(const Duration(minutes: 5));
        final action = fg.sendLocation(nearHomeLat, nearHomeLng,
            speed: 0.1, timestamp: clock.now);
        if (action == 'gps_polled_firebase_throttled') throttledCount++;
      }

      // First write goes through (no lastFirebaseSendTime for zone report),
      // then throttled until 60 min passes
      expect(fg.firebaseWrites.length, greaterThanOrEqualTo(1));
      expect(throttledCount, greaterThan(0));
    });

    test('offline in zone: GPS polls queued, throttling still applies', () {
      // Become stationary in zone
      for (int i = 0; i < 3; i++) {
        fg.sendLocation(homeLat, homeLng,
            speed: 0.3, timestamp: clock.now);
        clock.advance(const Duration(seconds: 30));
      }
      fg.detector.setZoneInterval(60);

      // Go offline
      fg.isNetworkAvailable = false;
      fg.offlineQueue.clear();

      int queuedCount = 0;
      int throttledCount = 0;

      for (int i = 0; i < 12; i++) {
        clock.advance(const Duration(minutes: 5));
        final action = fg.sendLocation(nearHomeLat, nearHomeLng,
            speed: 0.1, timestamp: clock.now);
        if (action == 'queued_offline') queuedCount++;
        if (action == 'gps_polled_firebase_throttled') throttledCount++;
      }

      // Throttled writes should still apply — only non-throttled polls get queued
      expect(throttledCount, greaterThan(0));
      // The ones that weren't throttled but were offline get queued
      expect(queuedCount, greaterThanOrEqualTo(1));
    });
  });

  // ===========================================================================
  // FG + BG: both services' status fields
  // ===========================================================================
  group('BG service: status fields in Firebase writes', () {
    late BGServiceOfflineSim bg;
    late ProxyClock clock;

    setUp(() {
      bg = BGServiceOfflineSim();
      clock = ProxyClock();
    });

    test('BG online write includes all status fields', () {
      bg.processLocation(homeLat, homeLng,
          speed: 0.5, timestamp: clock.now);
      expect(bg.lastFirebaseDoc!['isNetworkAvailable'], true);
      expect(bg.lastFirebaseDoc!['isLocationServiceEnabled'], true);
      expect(bg.lastFirebaseDoc!['pendingQueueCount'], 0);
    });

    test('BG offline: queues and shows pending count on reconnect', () {
      bg.firestoreAvailable = false;

      for (int i = 0; i < 5; i++) {
        clock.advance(const Duration(seconds: 30));
        bg.processLocation(homeLat, homeLng,
            speed: 0.5, timestamp: clock.now);
      }
      expect(bg.offlineQueue.length, 5);

      // Reconnect
      bg.firestoreAvailable = true;
      clock.advance(const Duration(seconds: 30));
      bg.processLocation(homeLat, homeLng,
          speed: 0.5, timestamp: clock.now);

      // pendingQueueCount in the main write was 5 (read BEFORE sync)
      final mainWrite = bg.firebaseWrites.first;
      expect(mainWrite['pendingQueueCount'], 5);

      // Queue should be drained
      expect(bg.offlineQueue.length, 0);
    });

    test('BG location disabled: skips entirely', () {
      bg.isLocationServiceEnabled = false;
      final action = bg.processLocation(homeLat, homeLng,
          speed: 0.5, timestamp: clock.now);
      expect(action, 'skip_location_disabled');
      expect(bg.firebaseWrites.length, 0);
    });
  });

  // ===========================================================================
  // LocationData model: status field parsing
  // ===========================================================================
  group('LocationData model: status fields', () {
    test('fromMap with all status fields', () {
      final data = LocationData.fromMap({
        'latitude': 18.5,
        'longitude': 73.8,
        'timestamp': null,
        'isNetworkAvailable': false,
        'isLocationServiceEnabled': false,
        'pendingQueueCount': 42,
      });
      expect(data.isNetworkAvailable, false);
      expect(data.isLocationServiceEnabled, false);
      expect(data.pendingQueueCount, 42);
    });

    test('fromMap with missing status fields (backward compat)', () {
      final data = LocationData.fromMap({
        'latitude': 18.5,
        'longitude': 73.8,
        'timestamp': null,
      });
      expect(data.isNetworkAvailable, true);
      expect(data.isLocationServiceEnabled, true);
      expect(data.pendingQueueCount, 0);
    });

    test('toMap includes status fields', () {
      final data = LocationData(
        latitude: 18.5,
        longitude: 73.8,
        timestamp: DateTime(2026, 1, 1),
        isNetworkAvailable: false,
        isLocationServiceEnabled: false,
        pendingQueueCount: 7,
      );
      final map = data.toMap();
      expect(map['isNetworkAvailable'], false);
      expect(map['isLocationServiceEnabled'], false);
      expect(map['pendingQueueCount'], 7);
    });

    test('default values are safe', () {
      final data = LocationData(
        latitude: 0,
        longitude: 0,
        timestamp: DateTime(2026, 1, 1),
      );
      expect(data.isNetworkAvailable, true);
      expect(data.isLocationServiceEnabled, true);
      expect(data.pendingQueueCount, 0);
    });
  });

  // ===========================================================================
  // Edge cases and race conditions
  // ===========================================================================
  group('Edge cases', () {
    late FGTrackerOfflineSim fg;
    late ProxyClock clock;

    setUp(() {
      fg = FGTrackerOfflineSim();
      fg.start();
      clock = ProxyClock();
    });

    test('rapid network flapping: no data loss', () {
      int totalSends = 0;
      for (int i = 0; i < 10; i++) {
        // Alternate online/offline every tick
        fg.isNetworkAvailable = (i % 2 == 0);
        clock.advance(const Duration(seconds: 30));
        fg.sendLocation(homeLat + i * 0.0001, homeLng,
            speed: 0.5, timestamp: clock.now);
        totalSends++;
      }

      // All locations should be accounted for:
      // either in firebaseWrites (direct + synced) or still in queue
      final firebaseCount = fg.firebaseWrites.length;
      final queueCount = fg.offlineQueue.length;
      // Every send results in either a firebase write or a queue entry
      // (synced entries also become firebase writes)
      // Since we sync on each online tick, most queue entries get synced
      expect(firebaseCount + queueCount, greaterThanOrEqualTo(totalSends));
    });

    test('pause while offline: queue preserved, resume works', () {
      fg.isNetworkAvailable = false;

      // Queue some locations
      for (int i = 0; i < 3; i++) {
        clock.advance(const Duration(seconds: 30));
        fg.sendLocation(homeLat, homeLng,
            speed: 0.5, timestamp: clock.now);
      }
      expect(fg.offlineQueue.length, 3);

      // Pause
      fg.isPaused = true;
      clock.advance(const Duration(minutes: 30));

      final action = fg.sendLocation(homeLat, homeLng, timestamp: clock.now);
      expect(action, 'skipped_paused');
      expect(fg.offlineQueue.length, 3); // Queue preserved

      // Resume + go online
      fg.isPaused = false;
      fg.isNetworkAvailable = true;
      clock.advance(const Duration(seconds: 30));
      fg.sendLocation(homeLat, homeLng,
          speed: 0.5, timestamp: clock.now);

      // Queue synced
      expect(fg.offlineQueue.length, 0);
    });

    test('offline for extended period: queue grows but stays bounded', () {
      fg.isNetworkAvailable = false;

      // Simulate 24 hours of offline tracking at 30s intervals
      // That's 2880 ticks — but queue caps at 1000
      for (int i = 0; i < 1050; i++) {
        clock.advance(const Duration(seconds: 30));
        fg.sendLocation(homeLat + (i % 100) * 0.00001, homeLng,
            speed: 0.5, timestamp: clock.now);
      }

      // Queue should be capped near 1000 (after cap logic fires)
      expect(fg.offlineQueue.length, lessThanOrEqualTo(1000));
      expect(fg.offlineQueue.length, greaterThan(900));
    });

    test('synced items are deleted from queue (not duplicated)', () {
      fg.isNetworkAvailable = false;

      // Queue 5 locations
      for (int i = 0; i < 5; i++) {
        clock.advance(const Duration(seconds: 30));
        fg.sendLocation(homeLat, homeLng,
            speed: 0.5, timestamp: clock.now);
      }

      // Go online
      fg.isNetworkAvailable = true;
      clock.advance(const Duration(seconds: 30));
      fg.sendLocation(homeLat, homeLng,
          speed: 0.5, timestamp: clock.now);

      // Queue empty
      expect(fg.offlineQueue.length, 0);

      // Go online again — no more syncing (queue is empty)
      final writesBefore = fg.firebaseWrites.length;
      clock.advance(const Duration(seconds: 30));
      fg.sendLocation(homeLat, homeLng,
          speed: 0.5, timestamp: clock.now);

      // Only 1 new write (current location), no re-syncs
      expect(fg.firebaseWrites.length, writesBefore + 1);
    });
  });
}
