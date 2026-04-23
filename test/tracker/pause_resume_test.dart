import 'package:flutter_test/flutter_test.dart';
import 'package:financesensei/features/tracker/core/services/stationary_detector.dart';
import 'package:financesensei/features/tracker/core/tracker_constants.dart';
import 'package:financesensei/features/tracker/core/models/tracker_settings.dart';

// =============================================================================
// Proxy helpers (shared with detector tests)
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
const double farFromHomeLat = 18.5020;
const double farFromHomeLng = 73.8020;
const double movingAwayLat = 18.5050;
const double movingAwayLng = 73.8050;

// =============================================================================
// ForegroundTracker Simulator
//
// Mirrors the EXACT state management logic of ForegroundTracker without
// platform dependencies (GPS, Firebase, SharedPreferences, Timer).
// This lets us test the pause/resume flow with proxy GPS and time.
// =============================================================================

class ForegroundTrackerSim {
  bool isTracking = false;
  bool isPaused = false;
  bool hasTimer = false;
  String lastAction = '';
  int gpsPollCount = 0;
  int firebaseSendCount = 0;
  DateTime? lastFirebaseSendTime;

  final StationaryDetector detector = StationaryDetector();
  String settingsFrequency = 'smart';
  int settingsCustomSeconds = 60;
  Duration currentInterval = TrackerConstants.movingPollInterval;

  /// Mirrors ForegroundTracker.start()
  void start() {
    isTracking = true;
    startLocationUpdates();
    lastAction = 'started';
  }

  /// Mirrors ForegroundTracker.stop()
  void stop() {
    isTracking = false;
    hasTimer = false;
    lastAction = 'stopped';
  }

  /// Mirrors ForegroundTracker.pause()
  void pause() {
    isPaused = true;
    hasTimer = false;
    lastAction = 'paused';
  }

  /// Mirrors ForegroundTracker.resume()
  void resume() {
    isPaused = false;
    if (isTracking && !hasTimer) {
      startLocationUpdates();
    }
    lastAction = 'resumed';
  }

  /// Mirrors _startLocationUpdates()
  void startLocationUpdates() {
    sendLocation(null, null); // initial send (async, not awaited in real code)
    hasTimer = true;
  }

  /// Mirrors _sendLocation() — pass proxy GPS reading to simulate a tick.
  /// Returns null if skipped (paused), or the DetectorResult.
  DetectorResult? sendLocation(double? lat, double? lng,
      {double speed = 0.0, double accuracy = 10.0, DateTime? timestamp}) {
    if (isPaused) {
      lastAction = 'skipped_paused';
      return null;
    }

    if (lat == null || lng == null) {
      // Initial call from startLocationUpdates — no GPS yet
      gpsPollCount++;
      return null;
    }

    final reading = proxyGps(
      lat: lat,
      lng: lng,
      speed: speed,
      accuracy: accuracy,
      timestamp: timestamp ?? DateTime.now(),
    );

    final result = detector.process(reading);
    gpsPollCount++;

    // Firebase throttling (mirrors _shouldSendToFirebase)
    final reportInterval = detector.zoneReportInterval;
    final shouldSend = reportInterval == Duration.zero ||
        lastFirebaseSendTime == null ||
        (timestamp ?? DateTime.now()).difference(lastFirebaseSendTime!) >=
            reportInterval;

    if (shouldSend) {
      firebaseSendCount++;
      lastFirebaseSendTime = timestamp ?? DateTime.now();
    }

    // Interval adjustment (mirrors _resolveInterval + timer recreation)
    final fixedInterval = TrackerConstants.fixedIntervalForFrequency(
        settingsFrequency, settingsCustomSeconds);
    final nextInterval = fixedInterval ?? result.nextPollInterval;
    if (nextInterval != currentInterval) {
      currentInterval = nextInterval;
    }

    return result;
  }

  /// Simulates what happens when user taps tracking screen circle while paused.
  /// This mirrors the CURRENT (buggy) _toggleTracking logic.
  void trackingScreenCircleTap() {
    if (!isTracking) {
      start();
    } else {
      stop(); // BUG: calls stop even when paused
    }
  }

  /// Simulates what _toggleTracking SHOULD do (fixed version).
  void trackingScreenCircleTapFixed() {
    if (isPaused) {
      resume(); // Handle paused state correctly
    } else if (!isTracking) {
      start();
    } else {
      stop();
    }
  }
}

// =============================================================================
// Background Service Simulator (simplified)
// =============================================================================

class BackgroundServiceSim {
  final StationaryDetector detector = StationaryDetector();
  bool hasTimer = true; // BG timer always runs (never cancelled on pause)
  String lastAction = '';
  int gpsPollCount = 0;

  // Simulates SharedPreferences (shared with FG)
  Map<String, dynamic> sharedPrefs;

  // Simulates Firebase data (what the listener receives)
  Map<String, dynamic>? firebaseData;

  BackgroundServiceSim(this.sharedPrefs);

  /// Simulates processLocation() — called on every timer tick.
  String processLocation(double lat, double lng,
      {double speed = 0.0, DateTime? timestamp}) {
    // Re-read settings from SharedPreferences (like prefs.reload + read)
    final settings = sharedPrefs['tracker_settings'] as Map<String, dynamic>?;
    if (settings != null) {
      final paused = settings['isPaused'] as bool? ?? false;
      if (paused) {
        lastAction = 'skipped_paused';
        return 'skipped_paused';
      }
    }

    // Process GPS
    final reading = proxyGps(
      lat: lat,
      lng: lng,
      speed: speed,
      timestamp: timestamp ?? DateTime.now(),
    );
    detector.process(reading);
    gpsPollCount++;
    lastAction = 'processed';
    return 'processed';
  }

  /// Simulates Firebase listener receiving settings update.
  /// This is the CURRENT (buggy) logic that overwrites SharedPreferences.
  void firebaseListenerReceives(Map<String, dynamic> data) {
    firebaseData = data;
    // BUG: writes ALL Firebase data to SharedPreferences including isPaused
    sharedPrefs['tracker_settings'] = Map<String, dynamic>.from(data);
  }

  /// Fixed version: preserve local isPaused when writing Firebase data.
  void firebaseListenerReceivesFixed(Map<String, dynamic> data) {
    firebaseData = data;
    final current =
        sharedPrefs['tracker_settings'] as Map<String, dynamic>? ?? {};
    final localPaused = current['isPaused'] as bool? ?? false;
    final merged = Map<String, dynamic>.from(data);
    merged['isPaused'] = localPaused; // Preserve local pause state
    sharedPrefs['tracker_settings'] = merged;
  }
}

void main() {
  // ===========================================================================
  // Basic pause/resume state transitions
  // ===========================================================================
  group('Pause/Resume: basic state transitions', () {
    late ForegroundTrackerSim fg;

    setUp(() {
      fg = ForegroundTrackerSim();
    });

    test('start → pause → state correct', () {
      fg.start();
      expect(fg.isTracking, true);
      expect(fg.isPaused, false);
      expect(fg.hasTimer, true);

      fg.pause();
      expect(fg.isTracking, true); // Still "tracking" but paused
      expect(fg.isPaused, true);
      expect(fg.hasTimer, false); // Timer cancelled
    });

    test('start → pause → resume → timer restarts', () {
      fg.start();
      fg.pause();

      expect(fg.hasTimer, false);
      expect(fg.isTracking, true);

      fg.resume();
      expect(fg.isPaused, false);
      expect(fg.isTracking, true);
      expect(fg.hasTimer, true); // Timer restarted
    });

    test('pause → GPS polls are skipped', () {
      fg.start();
      final countBefore = fg.gpsPollCount;

      fg.pause();
      fg.sendLocation(homeLat, homeLng);
      fg.sendLocation(homeLat, homeLng);
      fg.sendLocation(homeLat, homeLng);

      // Only the initial poll from start() counted, not the 3 during pause
      expect(fg.gpsPollCount, countBefore);
      expect(fg.lastAction, 'skipped_paused');
    });

    test('resume → GPS polls work again', () {
      final clock = ProxyClock();
      fg.start();
      fg.pause();

      fg.resume();
      final result = fg.sendLocation(homeLat, homeLng,
          speed: 0.5, timestamp: clock.now);

      expect(result, isNotNull);
      expect(fg.gpsPollCount, greaterThan(1)); // initial + this one
    });

    test('double pause is safe', () {
      fg.start();
      fg.pause();
      fg.pause(); // Second pause — should not crash
      expect(fg.isPaused, true);
      expect(fg.hasTimer, false);
    });

    test('double resume is safe', () {
      fg.start();
      fg.pause();
      fg.resume();
      fg.resume(); // Second resume — should not crash or create duplicate timer
      expect(fg.isPaused, false);
      expect(fg.hasTimer, true);
    });

    test('resume without prior start does nothing', () {
      // Never started, just try resume
      fg.resume();
      expect(fg.isTracking, false);
      expect(fg.hasTimer, false); // No timer since not tracking
    });
  });

  // ===========================================================================
  // BUG: Tracking screen circle tap during pause calls stop()
  // ===========================================================================
  group('BUG: Tracking screen circle tap during pause', () {
    late ForegroundTrackerSim fg;

    setUp(() {
      fg = ForegroundTrackerSim();
    });

    test('BUG: tapping circle while paused calls stop(), breaking resume', () {
      fg.start();
      fg.pause();

      // User sees grey circle on tracking screen, taps it thinking "resume"
      fg.trackingScreenCircleTap();

      // BUG: isTracking is now FALSE — stop() was called
      expect(fg.isTracking, false,
          reason: 'BUG: circle tap during pause calls stop()');

      // Now user goes to settings and taps "Resume"
      fg.resume();

      // BUG: timer NOT restarted because isTracking is false
      expect(fg.hasTimer, false,
          reason: 'BUG: resume fails because isTracking was set to false');
    });

    test('FIX: circle tap while paused should resume instead of stop', () {
      fg.start();
      fg.pause();

      // Fixed version: recognizes paused state
      fg.trackingScreenCircleTapFixed();

      expect(fg.isTracking, true);
      expect(fg.isPaused, false);
      expect(fg.hasTimer, true,
          reason: 'FIX: circle tap during pause calls resume()');
    });
  });

  // ===========================================================================
  // BUG: BG Firebase listener overwrites isPaused with stale data
  // ===========================================================================
  group('BUG: BG Firebase listener overwrites isPaused', () {
    test('BUG: stale Firebase data reverts resume to paused', () {
      final sharedPrefs = <String, dynamic>{
        'tracker_settings': {
          'updateFrequency': 'smart',
          'customFrequencySeconds': 60,
          'isPaused': false,
        }
      };
      final bg = BackgroundServiceSim(sharedPrefs);
      final clock = ProxyClock();

      // Step 1: User pauses — settings saved locally
      sharedPrefs['tracker_settings'] = {
        'updateFrequency': 'smart',
        'customFrequencySeconds': 60,
        'isPaused': true,
      };

      // BG reads paused state — skips
      var action = bg.processLocation(homeLat, homeLng, timestamp: clock.now);
      expect(action, 'skipped_paused');

      // Step 2: User resumes — settings saved locally
      sharedPrefs['tracker_settings'] = {
        'updateFrequency': 'smart',
        'customFrequencySeconds': 60,
        'isPaused': false,
      };

      // BG should now process
      clock.advance(const Duration(seconds: 30));
      action = bg.processLocation(homeLat, homeLng, timestamp: clock.now);
      expect(action, 'processed');

      // Step 3: BUG — Firebase listener delivers STALE data (isPaused: true)
      // This happens because Firebase sync is async and may lag
      bg.firebaseListenerReceives({
        'updateFrequency': 'smart',
        'customFrequencySeconds': 60,
        'isPaused': true, // STALE — user already resumed!
      });

      // BUG: SharedPreferences now has isPaused=true again
      final settings =
          sharedPrefs['tracker_settings'] as Map<String, dynamic>;
      expect(settings['isPaused'], true,
          reason: 'BUG: stale Firebase data reverted isPaused to true');

      // BG next tick reads isPaused=true → skips!
      clock.advance(const Duration(seconds: 30));
      action = bg.processLocation(homeLat, homeLng, timestamp: clock.now);
      expect(action, 'skipped_paused',
          reason: 'BUG: BG service thinks tracking is still paused');
    });

    test('FIX: Firebase listener preserves local isPaused', () {
      final sharedPrefs = <String, dynamic>{
        'tracker_settings': {
          'updateFrequency': 'smart',
          'customFrequencySeconds': 60,
          'isPaused': false,
        }
      };
      final bg = BackgroundServiceSim(sharedPrefs);
      final clock = ProxyClock();

      // User resumes — isPaused=false locally
      sharedPrefs['tracker_settings'] = {
        'updateFrequency': 'smart',
        'customFrequencySeconds': 60,
        'isPaused': false,
      };

      // Stale Firebase data arrives with isPaused=true
      bg.firebaseListenerReceivesFixed({
        'updateFrequency': 'smart',
        'customFrequencySeconds': 60,
        'isPaused': true, // stale
      });

      // FIX: local isPaused=false is preserved
      final settings =
          sharedPrefs['tracker_settings'] as Map<String, dynamic>;
      expect(settings['isPaused'], false,
          reason: 'FIX: local isPaused preserved despite stale Firebase');

      // BG processes normally
      clock.advance(const Duration(seconds: 30));
      final action =
          bg.processLocation(homeLat, homeLng, timestamp: clock.now);
      expect(action, 'processed',
          reason: 'FIX: BG service respects local isPaused=false');
    });
  });

  // ===========================================================================
  // Pause/resume with detector state (proxy GPS scenarios)
  // ===========================================================================
  group('Pause/resume with detector state', () {
    late ForegroundTrackerSim fg;
    late ProxyClock clock;

    setUp(() {
      fg = ForegroundTrackerSim();
      clock = ProxyClock();
    });

    test('pause while stationary → resume still at same place → visit continues', () {
      fg.start();

      // Become stationary
      for (int i = 0; i < 3; i++) {
        fg.sendLocation(homeLat, homeLng,
            speed: 0.5, timestamp: clock.now);
        clock.advance(const Duration(seconds: 30));
      }
      expect(fg.detector.state, MotionState.stationary);
      final visitStart = fg.detector.visitStartTime;

      // Pause
      fg.pause();
      clock.advance(const Duration(hours: 1));

      // Resume — still at same place
      fg.resume();
      final r = fg.sendLocation(nearHomeLat, nearHomeLng,
          speed: 0.1, timestamp: clock.now);

      expect(r!.state, MotionState.stationary);
      expect(r.visitEnded, false);
      expect(fg.detector.visitStartTime, visitStart); // Same visit
    });

    test('pause while stationary → resume at different place → visit ends', () {
      fg.start();

      // Become stationary
      for (int i = 0; i < 3; i++) {
        fg.sendLocation(homeLat, homeLng,
            speed: 0.5, timestamp: clock.now);
        clock.advance(const Duration(seconds: 30));
      }
      expect(fg.detector.state, MotionState.stationary);

      // Pause, user moves during pause
      fg.pause();
      clock.advance(const Duration(hours: 1));

      // Resume — user is now far away
      fg.resume();
      final r1 = fg.sendLocation(movingAwayLat, movingAwayLng,
          speed: 5.0, timestamp: clock.now);
      expect(r1!.state, MotionState.maybeMoving);

      clock.advance(const Duration(seconds: 30));
      final r2 = fg.sendLocation(movingAwayLat + 0.001, movingAwayLng,
          speed: 5.0, timestamp: clock.now);
      expect(r2!.state, MotionState.moving);
      expect(r2.visitEnded, true);
    });

    test('pause while moving → resume stopped → new stationary detected', () {
      fg.start();

      // Moving
      fg.sendLocation(homeLat, homeLng,
          speed: 5.0, timestamp: clock.now);
      expect(fg.detector.state, MotionState.moving);

      // Pause
      fg.pause();
      clock.advance(const Duration(minutes: 30));

      // Resume — stopped at new location
      fg.resume();
      for (int i = 0; i < 3; i++) {
        fg.sendLocation(farFromHomeLat, farFromHomeLng,
            speed: 0.3, timestamp: clock.now);
        clock.advance(const Duration(seconds: 30));
      }

      expect(fg.detector.state, MotionState.stationary);
    });

    test('pause while in zone → resume → zone interval still capped', () {
      fg.start();

      // Become stationary
      for (int i = 0; i < 3; i++) {
        fg.sendLocation(homeLat, homeLng,
            speed: 0.5, timestamp: clock.now);
        clock.advance(const Duration(seconds: 30));
      }

      // Set zone interval
      fg.detector.setZoneInterval(60);
      fg.sendLocation(nearHomeLat, nearHomeLng,
          speed: 0.1, timestamp: clock.now);
      expect(fg.currentInterval, TrackerConstants.maxExitDetectionInterval);

      // Pause
      fg.pause();
      clock.advance(const Duration(minutes: 30));

      // Resume
      fg.resume();
      final r = fg.sendLocation(nearHomeLat, nearHomeLng,
          speed: 0.1, timestamp: clock.now);

      // Zone interval still capped at 5 min
      expect(r!.nextPollInterval, TrackerConstants.maxExitDetectionInterval);
      expect(fg.detector.zoneReportInterval, const Duration(minutes: 60));
    });

    test('multiple pause/resume cycles maintain correct state', () {
      fg.start();

      // Become stationary
      for (int i = 0; i < 3; i++) {
        fg.sendLocation(homeLat, homeLng,
            speed: 0.5, timestamp: clock.now);
        clock.advance(const Duration(seconds: 30));
      }
      expect(fg.detector.state, MotionState.stationary);

      // Cycle 1: pause + resume
      fg.pause();
      clock.advance(const Duration(minutes: 10));
      fg.resume();
      fg.sendLocation(nearHomeLat, nearHomeLng,
          speed: 0.1, timestamp: clock.now);
      expect(fg.detector.state, MotionState.stationary);

      // Cycle 2: pause + resume
      fg.pause();
      clock.advance(const Duration(minutes: 10));
      fg.resume();
      fg.sendLocation(nearHomeLat, nearHomeLng,
          speed: 0.1, timestamp: clock.now);
      expect(fg.detector.state, MotionState.stationary);

      // Cycle 3: pause, move, resume
      fg.pause();
      clock.advance(const Duration(minutes: 10));
      fg.resume();
      fg.sendLocation(movingAwayLat, movingAwayLng,
          speed: 5.0, timestamp: clock.now);
      expect(fg.detector.state, MotionState.maybeMoving);

      clock.advance(const Duration(seconds: 30));
      final r = fg.sendLocation(movingAwayLat + 0.001, movingAwayLng,
          speed: 5.0, timestamp: clock.now);
      expect(r!.visitEnded, true);
    });
  });

  // ===========================================================================
  // TrackerSettings isPaused serialization edge cases
  // ===========================================================================
  group('TrackerSettings isPaused edge cases', () {
    test('settings round-trip with all fields', () {
      const settings = TrackerSettings(
        updateFrequency: 'power_saver',
        customFrequencySeconds: 120,
        isPaused: true,
      );
      final json = settings.toJson();
      final restored = TrackerSettings.fromJson(json);

      expect(restored.updateFrequency, 'power_saver');
      expect(restored.customFrequencySeconds, 120);
      expect(restored.isPaused, true);
    });

    test('copyWith preserves other fields when toggling isPaused', () {
      const settings = TrackerSettings(
        updateFrequency: 'realtime',
        customFrequencySeconds: 15,
        isPaused: false,
      );

      final paused = settings.copyWith(isPaused: true);
      expect(paused.updateFrequency, 'realtime');
      expect(paused.customFrequencySeconds, 15);
      expect(paused.isPaused, true);
    });
  });
}
