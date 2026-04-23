import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'dart:math' as math;
import '../../../../core/database/database_service.dart';
import '../models/tracker_settings.dart';
import '../tracker_constants.dart';
import 'stationary_detector.dart';

/// Singleton that manages foreground location tracking independently of any
/// screen lifecycle. This ensures tracking continues when the user navigates
/// from the Tracker screen to the Viewer or elsewhere.
///
/// Responsibility: send GPS data to Firebase only.
/// Visit lifecycle (enter/exit detection, zone matching, auto-zone creation)
/// is handled exclusively by the background service to avoid duplicate writes.
class ForegroundTracker {
  ForegroundTracker._();
  static final ForegroundTracker instance = ForegroundTracker._();

  // --- Public observable state ---
  bool get isTracking => _isTracking;
  bool get isPaused => _isPaused;
  String get lastUpdate => _lastUpdate;
  int get sendCount => _sendCount;
  Duration get currentInterval => _currentInterval;
  String get currentMode => _currentMode;
  int get batteryLevel => _batteryLevel;
  bool get isCharging => _isCharging;

  /// Called whenever state changes so the UI can rebuild.
  VoidCallback? onStateChanged;

  // --- Private state ---
  bool _isTracking = false;
  bool _isPaused = false;
  String _lastUpdate = 'Never';
  int _sendCount = 0;
  Duration _currentInterval = TrackerConstants.movingPollInterval;
  String _currentMode = 'smart';
  int _batteryLevel = 0;
  bool _isCharging = false;

  Timer? _locationTimer;
  Timer? _offlineSyncTimer;
  StreamSubscription? _locateSub;
  StreamSubscription<List<ConnectivityResult>>? _connSub;
  final StationaryDetector _detector = StationaryDetector();

  String? _deviceId;

  // Cached frequency setting — updated each tick
  String _settingsFrequency = 'smart';
  int _settingsCustomSeconds = 60;

  /// Last time a location was sent to Firebase.
  /// Used to throttle Firebase writes when zone interval > poll interval.
  DateTime? _lastFirebaseSendTime;

  final _dbService = DatabaseService();

  /// Initialize and resume state from SharedPreferences.
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _isTracking = prefs.getBool('tracker_is_tracking') ?? false;
    _deviceId = prefs.getString('tracker_device_id') ??
        prefs.getString('tracker_paired_device_id');

    // Restore detector state (shared with BG service for consistent intervals)
    final stateJson = prefs.getString('tracker_detector_state');
    if (stateJson != null) {
      try {
        final restored = StationaryDetector.fromJson(
            jsonDecode(stateJson) as Map<String, dynamic>);
        _detector.restore(
          state: restored.state,
          anchorLat: restored.anchorLat,
          anchorLng: restored.anchorLng,
          visitStartTime: restored.visitStartTime,
        );
      } catch (_) {}
    }

    await _updateBattery();
    await _refreshSettings();

    // Load paused state
    final settings = await TrackerSettings.load();
    _isPaused = settings.isPaused;

    if (_isTracking && !_isPaused && _locationTimer == null) {
      _startLocationUpdates();
    }
  }

  Future<void> _updateBattery() async {
    try {
      final battery = Battery();
      final level = await battery.batteryLevel;
      final state = await battery.batteryState;
      _batteryLevel = level;
      _isCharging = state == BatteryState.charging;
    } catch (_) {}
  }

  Future<bool> ensurePermissions() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return false;
    }
    if (permission == LocationPermission.deniedForever) return false;
    return true;
  }

  /// Start tracking. Returns error message or null on success.
  Future<String?> start(String deviceId) async {
    _deviceId = deviceId;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('tracker_is_tracking', true);
    await prefs.setString('tracker_device_id', deviceId);
    await prefs.setString('tracker_paired_device_id', deviceId);

    _isTracking = true;
    _startLocationUpdates();
    _notify();
    return null;
  }

  /// Stop tracking completely.
  Future<void> stop() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('tracker_is_tracking', false);

    _isTracking = false;
    _locationTimer?.cancel();
    _locationTimer = null;
    _offlineSyncTimer?.cancel();
    _offlineSyncTimer = null;
    _locateSub?.cancel();
    _locateSub = null;
    _connSub?.cancel();
    _connSub = null;
    _notify();
  }

  /// Pause tracking — keeps service alive but stops GPS polling.
  /// Resumes only when the user explicitly presses start.
  Future<void> pause() async {
    _isPaused = true;
    _locationTimer?.cancel();
    _locationTimer = null;
    // Save paused state to settings (persisted + synced to Firebase)
    final settings = await TrackerSettings.load();
    await settings.copyWith(isPaused: true).save();
    debugPrint('[FG] Tracking PAUSED');
    _notify();
  }

  /// Resume tracking after a pause.
  Future<void> resume() async {
    _isPaused = false;
    final settings = await TrackerSettings.load();
    await settings.copyWith(isPaused: false).save();
    debugPrint('[FG] Tracking RESUMED');
    if (_isTracking && _locationTimer == null) {
      _startLocationUpdates();
    }
    _notify();
  }

  /// Full reset (for role switch).
  Future<void> reset() async {
    await stop();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('tracker_role');
    await prefs.remove('tracker_device_id');
    await prefs.remove('tracker_is_tracking');
    await prefs.remove('tracker_detector_state');
  }

  // --- Core location loop ---

  void _startLocationUpdates() {
    _sendLocation();
    _locationTimer?.cancel();
    // Use fixed interval or detector's current recommendation for initial interval
    final fixedInterval = TrackerConstants.fixedIntervalForFrequency(
        _settingsFrequency, _settingsCustomSeconds);
    _currentInterval = fixedInterval ?? TrackerConstants.movingPollInterval;
    _locationTimer = Timer.periodic(_currentInterval, (_) => _sendLocation());
    _listenForLocateNow();
    _startOfflineSyncLoop();
  }

  /// Independent offline-queue drain loop. Runs every 60s regardless of the
  /// GPS timer state and independently of whether the current tick succeeded
  /// at writing. Also subscribes to connectivity changes so a reconnect
  /// triggers a sync attempt immediately.
  void _startOfflineSyncLoop() {
    _offlineSyncTimer?.cancel();
    _offlineSyncTimer =
        Timer.periodic(const Duration(seconds: 60), (_) => _drainQueue());
    _connSub?.cancel();
    _connSub = Connectivity().onConnectivityChanged.listen((results) {
      final online = !results.contains(ConnectivityResult.none);
      if (online) {
        debugPrint('[FG] Connectivity restored → draining offline queue');
        _drainQueue();
      }
    });
  }

  Future<void> _drainQueue() async {
    if (_deviceId == null) return;
    try {
      if (!await _checkNetwork()) return;
      final pending = await _getPendingCount();
      if (pending == 0) return;
      await _syncPending();
    } catch (e) {
      debugPrint('[FG] Drain queue error: $e');
    }
  }

  /// Get the correct interval based on frequency setting and detector result.
  /// For fixed modes, returns the fixed interval.
  /// For smart mode, uses the detector's recommended interval (which
  /// respects zone overrides and caps at maxExitDetectionInterval).
  Duration _resolveInterval(Duration detectorRecommended) {
    final fixedInterval = TrackerConstants.fixedIntervalForFrequency(
        _settingsFrequency, _settingsCustomSeconds);
    if (fixedInterval != null) {
      _currentMode = _settingsFrequency;
      return fixedInterval;
    }
    _currentMode = 'smart';
    return detectorRecommended;
  }

  /// Whether the full zone report interval has elapsed since last Firebase send.
  bool _shouldSendToFirebase() {
    final reportInterval = _detector.zoneReportInterval;
    if (reportInterval == Duration.zero) return true;
    if (_lastFirebaseSendTime == null) return true;
    return DateTime.now().difference(_lastFirebaseSendTime!) >= reportInterval;
  }

  /// Load frequency settings from SharedPreferences (called each tick).
  Future<void> _refreshSettings() async {
    final settings = await TrackerSettings.load();
    _settingsFrequency = settings.updateFrequency;
    _settingsCustomSeconds = settings.customFrequencySeconds;
  }

  void _listenForLocateNow() {
    if (_deviceId == null) return;
    _locateSub?.cancel();
    String? lastHandled;
    _locateSub = FirebaseFirestore.instance
        .collection('commands')
        .doc(_deviceId!)
        .snapshots()
        .listen((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) return;
      final locateNow = snapshot.data()!['locateNow'] as String?;
      if (locateNow != null && locateNow != lastHandled) {
        lastHandled = locateNow;
        _sendLocation();
      }
    }, onError: (_) {});
  }

  Future<void> _sendLocation() async {
    if (_deviceId == null) return;
    if (_isPaused) {
      debugPrint('[FG] Skipped — tracking is paused');
      return;
    }

    // --- Phase 1: GPS + detector (runs regardless of network) ---
    Position position;
    DetectorResult result;
    bool locationServiceEnabled = true;
    try {
      locationServiceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!locationServiceEnabled) {
        debugPrint('[FG] Location service disabled');
        // Still write status to Firebase if online so viewer knows
        await _writeStatusOnly(
            isNetworkAvailable: await _checkNetwork(),
            isLocationServiceEnabled: false);
        return;
      }

      position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      await _updateBattery();

      final reading = GpsReading(
        latitude: position.latitude,
        longitude: position.longitude,
        speed: position.speed,
        accuracy: position.accuracy,
        timestamp: DateTime.now(),
      );

      await _checkAndApplyZoneInterval(position.latitude, position.longitude);
      result = _detector.process(reading);

      // Persist detector state (runs even if Firebase fails)
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          'tracker_detector_state', jsonEncode(_detector.toJson()));

      // Adjust timer interval
      await _refreshSettings();
      final nextInterval = _resolveInterval(result.nextPollInterval);
      if (nextInterval != _currentInterval && _locationTimer != null) {
        debugPrint('[FG] Timer CHANGED: ${_currentInterval.inSeconds}s → ${nextInterval.inSeconds}s');
        _currentInterval = nextInterval;
        _locationTimer?.cancel();
        _locationTimer =
            Timer.periodic(_currentInterval, (_) => _sendLocation());
      }
    } catch (e) {
      debugPrint('[FG] GPS error: $e');
      return;
    }

    // --- Phase 2: Firebase write with offline queue fallback ---
    if (!_shouldSendToFirebase()) {
      debugPrint('[FG] GPS polled (exit detection), Firebase throttled');
      _lastUpdate = _formatTime(DateTime.now());
      _notify();
      return;
    }

    final isOnline = await _checkNetwork();
    final pendingCount = await _getPendingCount();

    final data = {
      'latitude': position.latitude,
      'longitude': position.longitude,
      'timestamp': FieldValue.serverTimestamp(),
      'speed': position.speed,
      'heading': position.heading,
      'accuracy': position.accuracy,
      'batteryLevel': _batteryLevel,
      'isCharging': _isCharging,
      'isNetworkAvailable': isOnline,
      'isLocationServiceEnabled': true,
      'pendingQueueCount': pendingCount,
    };

    bool firebaseOk = false;
    if (isOnline) {
      try {
        final firestore = FirebaseFirestore.instance;
        await firestore.collection('locations').doc(_deviceId!).set(data);
        await firestore
            .collection('location_history')
            .doc(_deviceId!)
            .collection('points')
            .add(data);
        _lastFirebaseSendTime = DateTime.now();
        _sendCount++;
        firebaseOk = true;
        debugPrint('[FG] Firebase sent #$_sendCount');
        await _syncPending();
      } catch (e) {
        debugPrint('[FG] Firebase write failed: $e');
      }
    }

    if (!firebaseOk) {
      await _queueLocation(position);
      debugPrint('[FG] Location queued offline (pending: ${pendingCount + 1})');
    }

    _lastUpdate = _formatTime(DateTime.now());
    debugPrint('[FG] Location polled at ${DateTime.now()} '
        '(mode=$_currentMode, every ${_currentInterval.inSeconds}s) '
        'state=${result.state.name}');
    _notify();
  }

  /// Write only device status fields to Firebase (no GPS data).
  /// Used when location service is disabled so the viewer knows.
  Future<void> _writeStatusOnly({
    required bool isNetworkAvailable,
    required bool isLocationServiceEnabled,
  }) async {
    if (!isNetworkAvailable || _deviceId == null) return;
    try {
      await FirebaseFirestore.instance
          .collection('locations')
          .doc(_deviceId!)
          .update({
        'isNetworkAvailable': isNetworkAvailable,
        'isLocationServiceEnabled': isLocationServiceEnabled,
        'pendingQueueCount': await _getPendingCount(),
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (_) {}
  }

  /// Check network connectivity.
  Future<bool> _checkNetwork() async {
    try {
      final result = await Connectivity().checkConnectivity();
      return !result.contains(ConnectivityResult.none);
    } catch (_) {
      return true; // assume online if check fails
    }
  }

  /// Get count of locations waiting in offline queue.
  Future<int> _getPendingCount() async {
    try {
      final db = await _dbService.database;
      return Sqflite.firstIntValue(
              await db.rawQuery(
                  'SELECT COUNT(*) FROM offline_location_queue')) ??
          0;
    } catch (_) {
      return 0;
    }
  }

  /// Queue a location to SQLite for later sync.
  Future<void> _queueLocation(Position position) async {
    try {
      final db = await _dbService.database;
      // Cap queue at 1000 to prevent unbounded growth
      final count = await _getPendingCount();
      if (count >= 1000) {
        await db.rawDelete(
            'DELETE FROM offline_location_queue WHERE id IN '
            '(SELECT id FROM offline_location_queue ORDER BY timestamp ASC LIMIT 10)');
      }
      await db.insert('offline_location_queue', {
        'latitude': position.latitude,
        'longitude': position.longitude,
        'accuracy': position.accuracy,
        'speed': position.speed,
        'heading': position.heading,
        'battery_level': _batteryLevel,
        'is_charging': _isCharging ? 1 : 0,
        'timestamp': DateTime.now().toIso8601String(),
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('[FG] Queue insert error: $e');
    }
  }

  /// Sync pending offline locations to Firebase.
  ///
  /// Writes each queued point to `location_history` (append-only timeline) —
  /// NOT to `locations/{deviceId}` which holds the *current* position. Writing
  /// a stale queued point to `locations` would clobber the actual current
  /// location on the viewer's map.
  ///
  /// Rows are deleted ONLY after their Firebase write succeeds. If the app is
  /// killed between write and delete, the next sync may re-send the same point
  /// into `location_history`. That's acceptable: users care far more about
  /// "my offline points showed up at all" than about rare duplicates.
  Future<void> _syncPending() async {
    if (_deviceId == null) return;
    try {
      final db = await _dbService.database;
      final pending = await db.query(
        'offline_location_queue',
        orderBy: 'timestamp ASC',
        limit: 20,
      );
      if (pending.isEmpty) return;
      final firestore = FirebaseFirestore.instance;
      int synced = 0;
      for (final row in pending) {
        final data = {
          'latitude': row['latitude'],
          'longitude': row['longitude'],
          'timestamp':
              Timestamp.fromDate(DateTime.parse(row['timestamp'] as String)),
          'speed': row['speed'],
          'heading': row['heading'],
          'accuracy': row['accuracy'],
          'batteryLevel': row['battery_level'],
          'isCharging': row['is_charging'] == 1,
          'isNetworkAvailable': true,
          'isLocationServiceEnabled': true,
          'pendingQueueCount': 0,
          'syncedFromQueue': true,
        };
        try {
          await firestore
              .collection('location_history')
              .doc(_deviceId!)
              .collection('points')
              .add(data);
          await db.delete('offline_location_queue',
              where: 'id = ?', whereArgs: [row['id']]);
          synced++;
        } catch (e) {
          // Stop on first failure — preserve order; don't keep trying.
          debugPrint('[FG] Sync write failed: $e — stopping drain');
          break;
        }
      }
      if (synced > 0) {
        debugPrint('[FG] Synced $synced queued locations to location_history');
      }
    } catch (e) {
      debugPrint('[FG] Sync pending error: $e');
    }
  }

  Future<void> _checkAndApplyZoneInterval(double lat, double lng) async {
    try {
      final db = await _dbService.database;
      final zones = await db.query('geofences');
      bool inZone = false;
      for (final z in zones) {
        final zLat = (z['latitude'] as num).toDouble();
        final zLng = (z['longitude'] as num).toDouble();
        final radius = (z['radius_meters'] as num).toDouble();
        final dist = _distanceMeters(lat, lng, zLat, zLng);
        if (dist <= radius) {
          inZone = true;
          final zoneId = z['id'] as int;
          try {
            final zsList = await db.query('zone_settings',
                where: 'geofence_id = ?', whereArgs: [zoneId]);
            if (zsList.isNotEmpty) {
              final interval =
                  zsList.first['update_interval_minutes'] as int? ?? 0;
              _detector.setZoneInterval(interval);
            } else {
              _detector.setZoneInterval(0);
            }
          } catch (_) {
            _detector.setZoneInterval(0);
          }
          break;
        }
      }
      if (!inZone) {
        _detector.setZoneInterval(0);
      }
    } catch (_) {
      _detector.setZoneInterval(0);
    }
  }

  static double _distanceMeters(
      double lat1, double lng1, double lat2, double lng2) {
    const metersPerDegree = 111320.0;
    final dLat = (lat1 - lat2) * metersPerDegree;
    final dLng =
        (lng1 - lng2) * metersPerDegree * math.cos(lat2 * math.pi / 180);
    return math.sqrt(dLat * dLat + dLng * dLng);
  }

  String _formatTime(DateTime time) {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    final s = time.second.toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  void _notify() {
    onStateChanged?.call();
  }
}
