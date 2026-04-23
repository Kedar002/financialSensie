import 'package:flutter_test/flutter_test.dart';
import 'package:financesensei/features/tracker/core/services/stationary_detector.dart';
import 'package:financesensei/features/tracker/core/tracker_constants.dart';
import 'package:financesensei/features/tracker/core/models/tracker_settings.dart';

// =============================================================================
// Proxy GPS & Time Helpers
// =============================================================================

/// Simulated clock for proxy time — controls timestamps fed to the detector.
class ProxyClock {
  DateTime _now;
  ProxyClock([DateTime? start]) : _now = start ?? DateTime(2026, 4, 11, 8, 0);

  DateTime get now => _now;
  void advance(Duration d) => _now = _now.add(d);
}

/// Creates a proxy GPS reading at a given location and time.
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

// Reference point: "Home" zone center
const double homeLat = 18.5000;
const double homeLng = 73.8000;

// A point ~10m from home (well within 80m radius)
const double nearHomeLat = 18.50008;
const double nearHomeLng = 73.80008;

// A point ~200m from home (clearly outside 80m radius)
const double farFromHomeLat = 18.5020;
const double farFromHomeLng = 73.8020;

// A point ~500m from home (clearly moving away)
const double movingAwayLat = 18.5050;
const double movingAwayLng = 73.8050;

/// Helper: make a detector stationary at home.
void becomeStationary(StationaryDetector detector, ProxyClock clock) {
  for (int i = 0; i < 3; i++) {
    detector.process(proxyGps(
      lat: homeLat, lng: homeLng, speed: 0.5, timestamp: clock.now,
    ));
    clock.advance(const Duration(seconds: 30));
  }
}

void main() {
  // ===========================================================================
  // Test Group 1: Normal Stationary Detection & Exit
  // ===========================================================================
  group('Normal stationary detection and exit', () {
    late StationaryDetector detector;
    late ProxyClock clock;

    setUp(() {
      detector = StationaryDetector();
      clock = ProxyClock();
    });

    test('moving → maybeStationary on first slow reading', () {
      final result = detector.process(proxyGps(
        lat: homeLat,
        lng: homeLng,
        speed: 0.5,
        timestamp: clock.now,
      ));

      expect(detector.state, MotionState.maybeStationary);
      expect(result.state, MotionState.maybeStationary);
      expect(result.visitStarted, false);
    });

    test('maybeStationary → stationary after 3 near-anchor readings', () {
      detector.process(proxyGps(
        lat: homeLat, lng: homeLng, speed: 0.5, timestamp: clock.now,
      ));
      clock.advance(const Duration(seconds: 30));

      detector.process(proxyGps(
        lat: nearHomeLat, lng: nearHomeLng, speed: 0.3, timestamp: clock.now,
      ));
      clock.advance(const Duration(seconds: 30));

      final result = detector.process(proxyGps(
        lat: homeLat, lng: homeLng, speed: 0.2, timestamp: clock.now,
      ));

      expect(detector.state, MotionState.stationary);
      expect(result.visitStarted, true);
      expect(result.visitStartTime, isNotNull);
      expect(result.anchorLat, isNotNull);
      expect(result.anchorLng, isNotNull);
    });

    test('stationary → maybeMoving → moving (visit ends correctly)', () {
      becomeStationary(detector, clock);
      expect(detector.state, MotionState.stationary);

      clock.advance(const Duration(minutes: 5));

      final r1 = detector.process(proxyGps(
        lat: farFromHomeLat, lng: farFromHomeLng, speed: 3.0,
        timestamp: clock.now,
      ));
      expect(detector.state, MotionState.maybeMoving);
      expect(r1.visitEnded, false);

      clock.advance(const Duration(seconds: 30));

      final r2 = detector.process(proxyGps(
        lat: movingAwayLat, lng: movingAwayLng, speed: 5.0,
        timestamp: clock.now,
      ));
      expect(detector.state, MotionState.moving);
      expect(r2.visitEnded, true);
      expect(r2.departureTime, isNotNull);
      expect(r2.visitStartTime, isNotNull);
    });

    test('maybeMoving → back to stationary on GPS drift', () {
      becomeStationary(detector, clock);

      detector.process(proxyGps(
        lat: farFromHomeLat, lng: farFromHomeLng, speed: 2.0,
        timestamp: clock.now,
      ));
      expect(detector.state, MotionState.maybeMoving);

      clock.advance(const Duration(seconds: 30));

      final result = detector.process(proxyGps(
        lat: nearHomeLat, lng: nearHomeLng, speed: 0.3,
        timestamp: clock.now,
      ));
      expect(detector.state, MotionState.stationary);
      expect(result.visitEnded, false);
    });
  });

  // ===========================================================================
  // Test Group 2: Smart Mode Auto-Update Interval Transitions
  // ===========================================================================
  group('Smart mode auto-update intervals', () {
    late StationaryDetector detector;
    late ProxyClock clock;

    setUp(() {
      detector = StationaryDetector();
      clock = ProxyClock();
    });

    test('moving state returns 30s poll interval', () {
      final result = detector.process(proxyGps(
        lat: homeLat, lng: homeLng, speed: 5.0,
        timestamp: clock.now,
      ));

      expect(result.state, MotionState.moving);
      expect(result.nextPollInterval, TrackerConstants.movingPollInterval);
      expect(result.nextPollInterval.inSeconds, 30);
    });

    test('maybeStationary state returns 30s poll interval', () {
      final result = detector.process(proxyGps(
        lat: homeLat, lng: homeLng, speed: 0.5,
        timestamp: clock.now,
      ));

      expect(result.state, MotionState.maybeStationary);
      expect(result.nextPollInterval, TrackerConstants.movingPollInterval);
      expect(result.nextPollInterval.inSeconds, 30);
    });

    test('stationary state returns 120s poll interval', () {
      becomeStationary(detector, clock);

      final result = detector.process(proxyGps(
        lat: nearHomeLat, lng: nearHomeLng, speed: 0.2, timestamp: clock.now,
      ));
      expect(result.nextPollInterval, TrackerConstants.stationaryPollInterval);
      expect(result.nextPollInterval.inSeconds, 120);
    });

    test('maybeMoving state returns 30s poll interval (fast exit detection)', () {
      becomeStationary(detector, clock);

      final result = detector.process(proxyGps(
        lat: farFromHomeLat, lng: farFromHomeLng, speed: 3.0,
        timestamp: clock.now,
      ));
      expect(result.state, MotionState.maybeMoving);
      expect(result.nextPollInterval, TrackerConstants.movingPollInterval);
      expect(result.nextPollInterval.inSeconds, 30);
    });

    test('interval transitions through full lifecycle: 30→30→120→30→30', () {
      final intervals = <int>[];

      // Moving
      var r = detector.process(proxyGps(
        lat: homeLat, lng: homeLng, speed: 5.0, timestamp: clock.now,
      ));
      intervals.add(r.nextPollInterval.inSeconds);
      clock.advance(const Duration(seconds: 30));

      // maybeStationary
      r = detector.process(proxyGps(
        lat: homeLat, lng: homeLng, speed: 0.5, timestamp: clock.now,
      ));
      intervals.add(r.nextPollInterval.inSeconds);
      clock.advance(const Duration(seconds: 30));

      // Still maybeStationary
      r = detector.process(proxyGps(
        lat: nearHomeLat, lng: nearHomeLng, speed: 0.3, timestamp: clock.now,
      ));
      intervals.add(r.nextPollInterval.inSeconds);
      clock.advance(const Duration(seconds: 30));

      // Stationary confirmed
      r = detector.process(proxyGps(
        lat: homeLat, lng: homeLng, speed: 0.2, timestamp: clock.now,
      ));
      intervals.add(r.nextPollInterval.inSeconds);
      clock.advance(const Duration(seconds: 120));

      // Still stationary
      r = detector.process(proxyGps(
        lat: nearHomeLat, lng: nearHomeLng, speed: 0.1, timestamp: clock.now,
      ));
      intervals.add(r.nextPollInterval.inSeconds);
      clock.advance(const Duration(seconds: 120));

      // maybeMoving
      r = detector.process(proxyGps(
        lat: farFromHomeLat, lng: farFromHomeLng, speed: 3.0, timestamp: clock.now,
      ));
      intervals.add(r.nextPollInterval.inSeconds);
      clock.advance(const Duration(seconds: 30));

      // Moving confirmed
      r = detector.process(proxyGps(
        lat: movingAwayLat, lng: movingAwayLng, speed: 5.0, timestamp: clock.now,
      ));
      intervals.add(r.nextPollInterval.inSeconds);

      expect(intervals, [30, 30, 30, 120, 120, 30, 30]);
    });
  });

  // ===========================================================================
  // Test Group 3: Zone Interval Override (with exit detection cap)
  // ===========================================================================
  group('Zone interval override', () {
    late StationaryDetector detector;
    late ProxyClock clock;

    setUp(() {
      detector = StationaryDetector();
      clock = ProxyClock();
    });

    test('small zone interval (≤5min) applied directly when stationary', () {
      becomeStationary(detector, clock);

      // 3-minute zone interval is below the 5-min cap → used directly
      detector.setZoneInterval(3);
      final result = detector.process(proxyGps(
        lat: nearHomeLat, lng: nearHomeLng, speed: 0.1, timestamp: clock.now,
      ));
      expect(result.nextPollInterval, const Duration(minutes: 3));
    });

    test('5-minute zone interval applied directly (equals cap)', () {
      becomeStationary(detector, clock);

      detector.setZoneInterval(5);
      final result = detector.process(proxyGps(
        lat: nearHomeLat, lng: nearHomeLng, speed: 0.1, timestamp: clock.now,
      ));
      expect(result.nextPollInterval, const Duration(minutes: 5));
    });

    test('FIX: large zone interval (60min) capped at 5min for exit detection', () {
      becomeStationary(detector, clock);

      detector.setZoneInterval(60);
      final result = detector.process(proxyGps(
        lat: nearHomeLat, lng: nearHomeLng, speed: 0.1, timestamp: clock.now,
      ));

      // Poll interval is capped at 5 minutes for GPS exit detection
      expect(result.nextPollInterval, TrackerConstants.maxExitDetectionInterval);
      expect(result.nextPollInterval.inMinutes, 5);

      // But the full zone interval is still available for Firebase throttling
      expect(detector.zoneReportInterval, const Duration(minutes: 60));
    });

    test('zone interval NOT applied when maybeMoving', () {
      becomeStationary(detector, clock);
      detector.setZoneInterval(60);

      final result = detector.process(proxyGps(
        lat: farFromHomeLat, lng: farFromHomeLng, speed: 3.0,
        timestamp: clock.now,
      ));

      expect(result.state, MotionState.maybeMoving);
      expect(result.nextPollInterval, TrackerConstants.movingPollInterval);
      expect(result.nextPollInterval.inSeconds, 30);
    });

    test('zone interval NOT applied when moving', () {
      detector.setZoneInterval(60);

      final result = detector.process(proxyGps(
        lat: homeLat, lng: homeLng, speed: 5.0, timestamp: clock.now,
      ));

      expect(result.state, MotionState.moving);
      expect(result.nextPollInterval, TrackerConstants.movingPollInterval);
    });

    test('zone interval cleared returns to default stationary interval', () {
      becomeStationary(detector, clock);

      detector.setZoneInterval(60);
      var result = detector.process(proxyGps(
        lat: nearHomeLat, lng: nearHomeLng, speed: 0.1, timestamp: clock.now,
      ));
      expect(result.nextPollInterval, TrackerConstants.maxExitDetectionInterval);

      detector.setZoneInterval(0);
      clock.advance(const Duration(seconds: 30));
      result = detector.process(proxyGps(
        lat: nearHomeLat, lng: nearHomeLng, speed: 0.1, timestamp: clock.now,
      ));
      expect(result.nextPollInterval, TrackerConstants.stationaryPollInterval);
      expect(result.nextPollInterval.inSeconds, 120);
      expect(detector.zoneReportInterval, Duration.zero);
    });

    test('zoneReportInterval returns full interval regardless of cap', () {
      becomeStationary(detector, clock);

      detector.setZoneInterval(120);
      expect(detector.zoneReportInterval, const Duration(minutes: 120));

      detector.setZoneInterval(0);
      expect(detector.zoneReportInterval, Duration.zero);

      detector.setZoneInterval(3);
      expect(detector.zoneReportInterval, const Duration(minutes: 3));
    });
  });

  // ===========================================================================
  // FIX VERIFIED: Zone exit detected within 5 minutes (was 60 min blind spot)
  // ===========================================================================
  group('FIX 1: Zone exit detection with capped interval', () {
    late StationaryDetector detector;
    late ProxyClock clock;

    setUp(() {
      detector = StationaryDetector();
      clock = ProxyClock();
    });

    test('60-min zone: GPS polls every 5 min, exit detected within 5 min', () {
      becomeStationary(detector, clock);
      final visitStart = detector.visitStartTime!;

      // Set 60-minute zone interval
      detector.setZoneInterval(60);
      final result = detector.process(proxyGps(
        lat: nearHomeLat, lng: nearHomeLng, speed: 0.1, timestamp: clock.now,
      ));

      // Poll interval is capped at 5 minutes (not 60)
      expect(result.nextPollInterval.inMinutes, 5,
          reason: 'FIX: GPS polls every 5 min for exit detection');

      // Simulate: user leaves at T+20min. GPS polls at T+25min (5-min interval)
      clock.advance(const Duration(minutes: 25));

      final exitResult = detector.process(proxyGps(
        lat: movingAwayLat, lng: movingAwayLng, speed: 5.0,
        timestamp: clock.now,
      ));
      expect(exitResult.state, MotionState.maybeMoving);

      // 30s later, second far reading confirms exit
      clock.advance(const Duration(seconds: 30));
      final confirmResult = detector.process(proxyGps(
        lat: movingAwayLat + 0.001, lng: movingAwayLng, speed: 5.0,
        timestamp: clock.now,
      ));
      expect(confirmResult.state, MotionState.moving);
      expect(confirmResult.visitEnded, true);

      // Departure is recorded at T+~25min, within 5 minutes of actual departure
      final departureOffset =
          confirmResult.departureTime!.difference(visitStart);
      expect(departureOffset.inMinutes, lessThan(30),
          reason: 'FIX: departure detected within 5 min of actual exit');
    });

    test('60-min zone: multiple 5-min polls while still stationary', () {
      becomeStationary(detector, clock);
      detector.setZoneInterval(60);

      // Simulate 12 polls over 60 minutes (every 5 min) while stationary
      for (int i = 0; i < 12; i++) {
        final r = detector.process(proxyGps(
          lat: nearHomeLat, lng: nearHomeLng, speed: 0.2, timestamp: clock.now,
        ));
        expect(r.state, MotionState.stationary);
        expect(r.nextPollInterval.inMinutes, 5);
        expect(r.visitEnded, false);
        clock.advance(const Duration(minutes: 5));
      }

      // Still stationary after 60 min of polling
      expect(detector.state, MotionState.stationary);
    });

    test('FIX: departure time accuracy is within 5 minutes', () {
      becomeStationary(detector, clock);
      final visitStart = detector.visitStartTime!;

      detector.setZoneInterval(60);
      detector.process(proxyGps(
        lat: nearHomeLat, lng: nearHomeLng, speed: 0.1, timestamp: clock.now,
      ));

      // Stay for 10 minutes (two 5-min polls)
      clock.advance(const Duration(minutes: 5));
      detector.process(proxyGps(
        lat: nearHomeLat, lng: nearHomeLng, speed: 0.1, timestamp: clock.now,
      ));
      clock.advance(const Duration(minutes: 5));
      detector.process(proxyGps(
        lat: nearHomeLat, lng: nearHomeLng, speed: 0.1, timestamp: clock.now,
      ));

      // User leaves — next 5-min poll detects exit
      clock.advance(const Duration(minutes: 5));
      detector.process(proxyGps(
        lat: farFromHomeLat, lng: farFromHomeLng, speed: 3.0,
        timestamp: clock.now,
      ));
      final firstFarTime = clock.now;

      clock.advance(const Duration(seconds: 30));
      final result = detector.process(proxyGps(
        lat: movingAwayLat, lng: movingAwayLng, speed: 5.0,
        timestamp: clock.now,
      ));

      expect(result.visitEnded, true);
      // Departure time should be firstFarTime (within seconds, not 60 min late)
      final error = result.departureTime!.difference(firstFarTime);
      expect(error.inSeconds.abs(), lessThan(5),
          reason: 'FIX: departure timestamp is accurate to the GPS poll');
    });
  });

  // ===========================================================================
  // FIX VERIFIED: FG and BG now use same interval logic
  // ===========================================================================
  group('FIX 2: FG uses detector nextPollInterval (no more hardcoded switch)', () {
    late StationaryDetector detector;
    late ProxyClock clock;

    setUp(() {
      detector = StationaryDetector();
      clock = ProxyClock();
    });

    test('FIX: both FG and BG use result.nextPollInterval (consistent)', () {
      becomeStationary(detector, clock);

      detector.setZoneInterval(60);
      final result = detector.process(proxyGps(
        lat: nearHomeLat, lng: nearHomeLng, speed: 0.1, timestamp: clock.now,
      ));

      // Both services now use the same value: result.nextPollInterval
      final interval = result.nextPollInterval;

      // Should be 5 min (capped), not 120s (old hardcoded) or 60min (uncapped)
      expect(interval, TrackerConstants.maxExitDetectionInterval);
      expect(interval.inMinutes, 5);
    });

    test('FIX: FG interval responds to zone changes', () {
      becomeStationary(detector, clock);

      // 3-minute zone: both FG and BG should use 3 min
      detector.setZoneInterval(3);
      var result = detector.process(proxyGps(
        lat: nearHomeLat, lng: nearHomeLng, speed: 0.1, timestamp: clock.now,
      ));
      expect(result.nextPollInterval, const Duration(minutes: 3));

      // 60-minute zone: both FG and BG should use 5 min (capped)
      detector.setZoneInterval(60);
      result = detector.process(proxyGps(
        lat: nearHomeLat, lng: nearHomeLng, speed: 0.1, timestamp: clock.now,
      ));
      expect(result.nextPollInterval, const Duration(minutes: 5));

      // No zone: both should use 120s default
      detector.setZoneInterval(0);
      result = detector.process(proxyGps(
        lat: nearHomeLat, lng: nearHomeLng, speed: 0.1, timestamp: clock.now,
      ));
      expect(result.nextPollInterval, const Duration(seconds: 120));
    });
  });

  // ===========================================================================
  // FIX VERIFIED: Departure time accurate with zone intervals
  // ===========================================================================
  group('FIX 5: Departure time accuracy', () {
    late StationaryDetector detector;
    late ProxyClock clock;

    setUp(() {
      detector = StationaryDetector();
      clock = ProxyClock();
    });

    test('with 30s default interval, departure time is accurate', () {
      becomeStationary(detector, clock);

      // Stay for 10 minutes
      for (int i = 0; i < 5; i++) {
        detector.process(proxyGps(
          lat: nearHomeLat, lng: nearHomeLng, speed: 0.2, timestamp: clock.now,
        ));
        clock.advance(const Duration(seconds: 120));
      }

      // First far reading
      detector.process(proxyGps(
        lat: farFromHomeLat, lng: farFromHomeLng, speed: 3.0,
        timestamp: clock.now,
      ));
      final firstFarTime = clock.now;
      clock.advance(const Duration(seconds: 30));

      // Confirm exit
      final result = detector.process(proxyGps(
        lat: movingAwayLat, lng: movingAwayLng, speed: 5.0,
        timestamp: clock.now,
      ));

      expect(result.visitEnded, true);
      final error = result.departureTime!.difference(firstFarTime);
      expect(error.inSeconds.abs(), lessThan(5));
    });

    test('FIX: with 60-min zone interval, departure is max 5 min late (not 60)', () {
      becomeStationary(detector, clock);
      final visitStart = detector.visitStartTime!;

      detector.setZoneInterval(60);

      // User stays for 15 minutes with 5-min polling (3 polls)
      for (int i = 0; i < 3; i++) {
        detector.process(proxyGps(
          lat: nearHomeLat, lng: nearHomeLng, speed: 0.1, timestamp: clock.now,
        ));
        clock.advance(const Duration(minutes: 5));
      }

      // User left at ~T+15min. Next 5-min poll catches them gone.
      // (worst case: user left right after last poll, so detection is 5 min late)
      detector.process(proxyGps(
        lat: movingAwayLat, lng: movingAwayLng, speed: 5.0,
        timestamp: clock.now,
      ));
      clock.advance(const Duration(seconds: 30));

      final result = detector.process(proxyGps(
        lat: movingAwayLat + 0.001, lng: movingAwayLng, speed: 5.0,
        timestamp: clock.now,
      ));

      expect(result.visitEnded, true);

      // Departure offset from visit start
      final departureOffset =
          result.departureTime!.difference(visitStart);
      // Should be ~16.5 min (15 min of polls + detection), NOT 61+ min
      expect(departureOffset.inMinutes, lessThan(20),
          reason: 'FIX: departure is within ~5 min of actual exit, not 60 min');
    });
  });

  // ===========================================================================
  // GPS Accuracy Filtering
  // ===========================================================================
  group('GPS accuracy filtering', () {
    late StationaryDetector detector;
    late ProxyClock clock;

    setUp(() {
      detector = StationaryDetector();
      clock = ProxyClock();
    });

    test('readings with accuracy > 100m are ignored', () {
      final result = detector.process(proxyGps(
        lat: homeLat, lng: homeLng, speed: 0.5,
        accuracy: 150.0,
        timestamp: clock.now,
      ));

      expect(detector.state, MotionState.moving);
      expect(result.state, MotionState.moving);
    });

    test('high accuracy reading after low accuracy one still works', () {
      detector.process(proxyGps(
        lat: homeLat, lng: homeLng, speed: 0.5,
        accuracy: 200.0, timestamp: clock.now,
      ));
      expect(detector.state, MotionState.moving);

      clock.advance(const Duration(seconds: 30));

      detector.process(proxyGps(
        lat: homeLat, lng: homeLng, speed: 0.5,
        accuracy: 10.0, timestamp: clock.now,
      ));
      expect(detector.state, MotionState.maybeStationary);
    });

    test('low accuracy during stationary does not trigger false exit', () {
      becomeStationary(detector, clock);

      final result = detector.process(proxyGps(
        lat: movingAwayLat, lng: movingAwayLng, speed: 10.0,
        accuracy: 150.0, timestamp: clock.now,
      ));
      expect(detector.state, MotionState.stationary);
    });
  });

  // ===========================================================================
  // State Persistence & Restore
  // ===========================================================================
  group('State persistence and restore', () {
    late ProxyClock clock;

    setUp(() {
      clock = ProxyClock();
    });

    test('toJson/fromJson preserves full state during stationary', () {
      final detector = StationaryDetector();
      becomeStationary(detector, clock);

      final json = detector.toJson();
      final restored = StationaryDetector.fromJson(json);

      expect(restored.state, MotionState.stationary);
      expect(restored.anchorLat, isNotNull);
      expect(restored.anchorLng, isNotNull);
      expect(restored.visitStartTime, isNotNull);
    });

    test('restored detector continues visit correctly', () {
      final detector = StationaryDetector();
      becomeStationary(detector, clock);

      final json = detector.toJson();
      final restored = StationaryDetector.fromJson(json);

      clock.advance(const Duration(minutes: 5));
      restored.process(proxyGps(
        lat: farFromHomeLat, lng: farFromHomeLng, speed: 3.0,
        timestamp: clock.now,
      ));
      clock.advance(const Duration(seconds: 30));

      final result = restored.process(proxyGps(
        lat: movingAwayLat, lng: movingAwayLng, speed: 5.0,
        timestamp: clock.now,
      ));

      expect(result.visitEnded, true);
      expect(result.departureTime, isNotNull);
    });
  });

  // ===========================================================================
  // Edge Cases
  // ===========================================================================
  group('Edge cases', () {
    late StationaryDetector detector;
    late ProxyClock clock;

    setUp(() {
      detector = StationaryDetector();
      clock = ProxyClock();
    });

    test('fast speed prevents stationary detection', () {
      for (int i = 0; i < 5; i++) {
        detector.process(proxyGps(
          lat: homeLat, lng: homeLng, speed: 2.0,
          timestamp: clock.now,
        ));
        clock.advance(const Duration(seconds: 30));
      }
      expect(detector.state, MotionState.moving);
    });

    test('maybeStationary resets to moving on distant reading', () {
      detector.process(proxyGps(
        lat: homeLat, lng: homeLng, speed: 0.5, timestamp: clock.now,
      ));
      expect(detector.state, MotionState.maybeStationary);

      clock.advance(const Duration(seconds: 30));

      detector.process(proxyGps(
        lat: farFromHomeLat, lng: farFromHomeLng, speed: 0.5,
        timestamp: clock.now,
      ));
      expect(detector.state, MotionState.moving);
    });

    test('zone interval changes mid-visit are respected (with capping)', () {
      becomeStationary(detector, clock);

      // 3-min zone interval (below cap) → used directly
      detector.setZoneInterval(3);
      var r = detector.process(proxyGps(
        lat: nearHomeLat, lng: nearHomeLng, speed: 0.1, timestamp: clock.now,
      ));
      expect(r.nextPollInterval, const Duration(minutes: 3));

      // 30-min zone interval (above cap) → capped at 5 min
      detector.setZoneInterval(30);
      clock.advance(const Duration(minutes: 3));
      r = detector.process(proxyGps(
        lat: nearHomeLat, lng: nearHomeLng, speed: 0.1, timestamp: clock.now,
      ));
      expect(r.nextPollInterval, TrackerConstants.maxExitDetectionInterval);
      expect(r.nextPollInterval.inMinutes, 5);
      // But report interval is still the full 30 min
      expect(detector.zoneReportInterval, const Duration(minutes: 30));

      // Clear zone interval → back to default 120s
      detector.setZoneInterval(0);
      clock.advance(const Duration(minutes: 5));
      r = detector.process(proxyGps(
        lat: nearHomeLat, lng: nearHomeLng, speed: 0.1, timestamp: clock.now,
      ));
      expect(r.nextPollInterval, TrackerConstants.stationaryPollInterval);
    });
  });

  // ===========================================================================
  // Pause Feature: Detector state preserved during pause gap
  // ===========================================================================
  group('Pause feature: detector state during pause', () {
    late StationaryDetector detector;
    late ProxyClock clock;

    setUp(() {
      detector = StationaryDetector();
      clock = ProxyClock();
    });

    test('detector state preserved during pause (no readings fed)', () {
      becomeStationary(detector, clock);
      expect(detector.state, MotionState.stationary);
      final visitStart = detector.visitStartTime;
      final anchorLat = detector.anchorLat;

      // Simulate pause: no readings for 2 hours
      clock.advance(const Duration(hours: 2));

      // State should still be stationary — detector holds state
      expect(detector.state, MotionState.stationary);
      expect(detector.visitStartTime, visitStart);
      expect(detector.anchorLat, anchorLat);
    });

    test('resume after pause: still near anchor → stays stationary', () {
      becomeStationary(detector, clock);

      // Pause for 1 hour (no readings)
      clock.advance(const Duration(hours: 1));

      // Resume: user is still at the same place
      final result = detector.process(proxyGps(
        lat: nearHomeLat, lng: nearHomeLng, speed: 0.1, timestamp: clock.now,
      ));

      expect(result.state, MotionState.stationary);
      expect(result.visitEnded, false);
      expect(result.visitStarted, false);
    });

    test('resume after pause: user has moved → exit detected', () {
      becomeStationary(detector, clock);

      // Pause for 1 hour (no readings)
      clock.advance(const Duration(hours: 1));

      // Resume: user is now far away
      final r1 = detector.process(proxyGps(
        lat: movingAwayLat, lng: movingAwayLng, speed: 5.0,
        timestamp: clock.now,
      ));
      expect(r1.state, MotionState.maybeMoving);

      clock.advance(const Duration(seconds: 30));

      final r2 = detector.process(proxyGps(
        lat: movingAwayLat + 0.001, lng: movingAwayLng, speed: 5.0,
        timestamp: clock.now,
      ));
      expect(r2.state, MotionState.moving);
      expect(r2.visitEnded, true);
      expect(r2.departureTime, isNotNull);
    });

    test('pause during moving → resume detects new stationary', () {
      // Start moving
      detector.process(proxyGps(
        lat: homeLat, lng: homeLng, speed: 5.0, timestamp: clock.now,
      ));
      expect(detector.state, MotionState.moving);

      // Pause for 30 min
      clock.advance(const Duration(minutes: 30));

      // Resume: user is now stopped at a new location
      for (int i = 0; i < 3; i++) {
        detector.process(proxyGps(
          lat: farFromHomeLat, lng: farFromHomeLng, speed: 0.3,
          timestamp: clock.now,
        ));
        clock.advance(const Duration(seconds: 30));
      }

      expect(detector.state, MotionState.stationary);
    });

    test('persist/restore across pause preserves visit', () {
      becomeStationary(detector, clock);
      final visitStart = detector.visitStartTime;

      // Serialize (simulates what happens when FG tracker persists state)
      final json = detector.toJson();

      // Simulate pause gap
      clock.advance(const Duration(hours: 1));

      // Restore into fresh detector (simulates app restart after pause)
      final restored = StationaryDetector.fromJson(json);
      expect(restored.state, MotionState.stationary);
      expect(restored.visitStartTime, visitStart);

      // Resume: user moved
      restored.process(proxyGps(
        lat: movingAwayLat, lng: movingAwayLng, speed: 5.0,
        timestamp: clock.now,
      ));
      clock.advance(const Duration(seconds: 30));

      final result = restored.process(proxyGps(
        lat: movingAwayLat + 0.001, lng: movingAwayLng, speed: 5.0,
        timestamp: clock.now,
      ));

      expect(result.visitEnded, true);
      // Visit duration includes the pause gap (arrival to detection)
      expect(result.departureTime, isNotNull);
      expect(result.visitStartTime, visitStart);
    });

    test('zone interval preserved across pause', () {
      becomeStationary(detector, clock);
      detector.setZoneInterval(60);

      final r = detector.process(proxyGps(
        lat: nearHomeLat, lng: nearHomeLng, speed: 0.1, timestamp: clock.now,
      ));
      expect(r.nextPollInterval, TrackerConstants.maxExitDetectionInterval);
      expect(detector.zoneReportInterval, const Duration(minutes: 60));

      // Pause for 30 min (no readings)
      clock.advance(const Duration(minutes: 30));

      // Resume — zone interval still applies
      final r2 = detector.process(proxyGps(
        lat: nearHomeLat, lng: nearHomeLng, speed: 0.1, timestamp: clock.now,
      ));
      expect(r2.nextPollInterval, TrackerConstants.maxExitDetectionInterval);
      expect(r2.state, MotionState.stationary);
    });
  });

  // ===========================================================================
  // TrackerSettings model: isPaused field
  // ===========================================================================
  group('TrackerSettings isPaused', () {
    test('default isPaused is false', () {
      const settings = TrackerSettings();
      expect(settings.isPaused, false);
    });

    test('toJson/fromJson preserves isPaused=true', () {
      const settings = TrackerSettings(isPaused: true);
      final json = settings.toJson();
      expect(json['isPaused'], true);

      final restored = TrackerSettings.fromJson(json);
      expect(restored.isPaused, true);
    });

    test('toJson/fromJson preserves isPaused=false', () {
      const settings = TrackerSettings(isPaused: false);
      final json = settings.toJson();
      expect(json['isPaused'], false);

      final restored = TrackerSettings.fromJson(json);
      expect(restored.isPaused, false);
    });

    test('fromJson handles missing isPaused (defaults to false)', () {
      final restored = TrackerSettings.fromJson({
        'updateFrequency': 'smart',
        'customFrequencySeconds': 60,
      });
      expect(restored.isPaused, false);
    });

    test('copyWith toggles isPaused', () {
      const settings = TrackerSettings();
      expect(settings.isPaused, false);

      final paused = settings.copyWith(isPaused: true);
      expect(paused.isPaused, true);
      expect(paused.updateFrequency, 'smart'); // other fields unchanged

      final resumed = paused.copyWith(isPaused: false);
      expect(resumed.isPaused, false);
    });
  });
}
