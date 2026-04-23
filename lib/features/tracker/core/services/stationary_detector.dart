import 'dart:math' as math;
import '../tracker_constants.dart';

/// Motion state of the tracker.
enum MotionState { moving, maybeStationary, stationary, maybeMoving }

/// A single GPS reading fed into the detector.
class GpsReading {
  final double latitude;
  final double longitude;
  final double speed;
  final double accuracy;
  final DateTime timestamp;

  const GpsReading({
    required this.latitude,
    required this.longitude,
    required this.speed,
    required this.accuracy,
    required this.timestamp,
  });
}

/// Result returned after processing each GPS reading.
class DetectorResult {
  /// Current motion state after this reading.
  final MotionState state;

  /// If a visit just started (state transitioned to stationary).
  final bool visitStarted;

  /// If a visit just ended (state transitioned from maybeMoving to moving).
  final bool visitEnded;

  /// Anchor point of the current/just-ended visit.
  final double? anchorLat;
  final double? anchorLng;

  /// When the visit started (null if no active visit).
  final DateTime? visitStartTime;

  /// When the person actually departed (first movement detection).
  /// Only set when visitEnded is true.
  final DateTime? departureTime;

  /// Recommended next poll interval.
  final Duration nextPollInterval;

  const DetectorResult({
    required this.state,
    this.visitStarted = false,
    this.visitEnded = false,
    this.anchorLat,
    this.anchorLng,
    this.visitStartTime,
    this.departureTime,
    required this.nextPollInterval,
  });
}

/// Pure-logic state machine for detecting stationary visits.
/// No external dependencies — takes GPS readings in, returns state changes out.
class StationaryDetector {
  StationaryDetector();

  MotionState _state = MotionState.moving;
  int _nearCount = 0;
  int _farCount = 0;
  double? _anchorLat;
  double? _anchorLng;
  DateTime? _visitStartTime;

  /// Timestamp of the first near-anchor reading (actual arrival time).
  DateTime? _firstNearTimestamp;

  /// Timestamp of the first far-from-anchor reading (actual departure time).
  DateTime? _firstFarTimestamp;

  /// Per-zone custom interval override (minutes). 0 = use defaults.
  int _zoneIntervalMinutes = 0;

  MotionState get state => _state;
  double? get anchorLat => _anchorLat;
  double? get anchorLng => _anchorLng;
  DateTime? get visitStartTime => _visitStartTime;

  /// The full zone interval (uncapped) for Firebase send throttling.
  /// Returns Duration.zero if no zone interval is set.
  Duration get zoneReportInterval => _zoneIntervalMinutes > 0
      ? Duration(minutes: _zoneIntervalMinutes)
      : Duration.zero;

  /// Restore state after a service restart.
  void restore({
    required MotionState state,
    double? anchorLat,
    double? anchorLng,
    DateTime? visitStartTime,
    DateTime? firstNearTimestamp,
    DateTime? firstFarTimestamp,
    int nearCount = 0,
    int farCount = 0,
  }) {
    _state = state;
    _anchorLat = anchorLat;
    _anchorLng = anchorLng;
    _visitStartTime = visitStartTime;
    _firstNearTimestamp = firstNearTimestamp;
    _firstFarTimestamp = firstFarTimestamp;
    _nearCount = nearCount;
    _farCount = farCount;
  }

  /// Update the per-zone interval when the tracker enters/exits a zone.
  void setZoneInterval(int minutes) {
    _zoneIntervalMinutes = minutes;
  }

  /// Process a GPS reading and return the result.
  DetectorResult process(GpsReading reading) {
    // Ignore low-quality readings for state transitions.
    if (reading.accuracy > TrackerConstants.maxAccuracyMeters) {
      return DetectorResult(
        state: _state,
        anchorLat: _anchorLat,
        anchorLng: _anchorLng,
        visitStartTime: _visitStartTime,
        nextPollInterval: _currentInterval(),
      );
    }

    switch (_state) {
      case MotionState.moving:
        return _processMoving(reading);
      case MotionState.maybeStationary:
        return _processMaybeStationary(reading);
      case MotionState.stationary:
        return _processStationary(reading);
      case MotionState.maybeMoving:
        return _processMaybeMoving(reading);
    }
  }

  DetectorResult _processMoving(GpsReading reading) {
    if (reading.speed < TrackerConstants.stationarySpeedThreshold) {
      // Slow — start a candidate anchor.
      _anchorLat = reading.latitude;
      _anchorLng = reading.longitude;
      _nearCount = 1;
      _firstNearTimestamp = reading.timestamp;
      _state = MotionState.maybeStationary;
    }
    return DetectorResult(
      state: _state,
      anchorLat: _anchorLat,
      anchorLng: _anchorLng,
      nextPollInterval: _currentInterval(),
    );
  }

  DetectorResult _processMaybeStationary(GpsReading reading) {
    final dist = _distanceMeters(
        reading.latitude, reading.longitude, _anchorLat!, _anchorLng!);

    if (dist <= TrackerConstants.stationaryRadiusMeters &&
        reading.speed < TrackerConstants.stationarySpeedThreshold) {
      // Update anchor as running average for stability.
      _anchorLat = (_anchorLat! * _nearCount + reading.latitude) /
          (_nearCount + 1);
      _anchorLng = (_anchorLng! * _nearCount + reading.longitude) /
          (_nearCount + 1);
      _nearCount++;

      if (_nearCount >= TrackerConstants.stationaryConfirmCount) {
        _state = MotionState.stationary;
        // Use the actual first near-anchor timestamp as visit start
        _visitStartTime = _firstNearTimestamp ?? reading.timestamp;
        _farCount = 0;
        return DetectorResult(
          state: _state,
          visitStarted: true,
          anchorLat: _anchorLat,
          anchorLng: _anchorLng,
          visitStartTime: _visitStartTime,
          nextPollInterval: _currentInterval(),
        );
      }
    } else {
      // Moved away — back to moving.
      _state = MotionState.moving;
      _anchorLat = null;
      _anchorLng = null;
      _nearCount = 0;
      _firstNearTimestamp = null;
    }
    return DetectorResult(
      state: _state,
      anchorLat: _anchorLat,
      anchorLng: _anchorLng,
      nextPollInterval: _currentInterval(),
    );
  }

  DetectorResult _processStationary(GpsReading reading) {
    final dist = _distanceMeters(
        reading.latitude, reading.longitude, _anchorLat!, _anchorLng!);

    if (dist > TrackerConstants.stationaryRadiusMeters ||
        reading.speed >= TrackerConstants.stationarySpeedThreshold) {
      _farCount = 1;
      _firstFarTimestamp = reading.timestamp;
      _state = MotionState.maybeMoving;
    }
    return DetectorResult(
      state: _state,
      anchorLat: _anchorLat,
      anchorLng: _anchorLng,
      visitStartTime: _visitStartTime,
      nextPollInterval: _currentInterval(),
    );
  }

  DetectorResult _processMaybeMoving(GpsReading reading) {
    final dist = _distanceMeters(
        reading.latitude, reading.longitude, _anchorLat!, _anchorLng!);

    if (dist > TrackerConstants.stationaryRadiusMeters ||
        reading.speed >= TrackerConstants.stationarySpeedThreshold) {
      _farCount++;
      if (_farCount >= TrackerConstants.movingConfirmCount) {
        // Confirmed: device has left.
        final visitEnded = _visitStartTime != null;
        final oldAnchorLat = _anchorLat;
        final oldAnchorLng = _anchorLng;
        final oldStartTime = _visitStartTime;
        // Use the first far-reading timestamp as the actual departure time
        final actualDeparture = _firstFarTimestamp ?? reading.timestamp;

        _state = MotionState.moving;
        _anchorLat = null;
        _anchorLng = null;
        _visitStartTime = null;
        _firstNearTimestamp = null;
        _firstFarTimestamp = null;
        _nearCount = 0;
        _farCount = 0;

        return DetectorResult(
          state: _state,
          visitEnded: visitEnded,
          anchorLat: oldAnchorLat,
          anchorLng: oldAnchorLng,
          visitStartTime: oldStartTime,
          departureTime: visitEnded ? actualDeparture : null,
          nextPollInterval: _currentInterval(),
        );
      }
    } else {
      // Back within radius — was GPS drift.
      _state = MotionState.stationary;
      _farCount = 0;
      _firstFarTimestamp = null;
    }
    return DetectorResult(
      state: _state,
      anchorLat: _anchorLat,
      anchorLng: _anchorLng,
      visitStartTime: _visitStartTime,
      nextPollInterval: _currentInterval(),
    );
  }

  Duration _currentInterval() {
    // Zone custom interval only applies when confirmed stationary.
    // Capped at maxExitDetectionInterval so exit detection is never
    // delayed by more than 5 minutes. Services throttle Firebase sends
    // separately using zoneReportInterval.
    if (_zoneIntervalMinutes > 0 && _state == MotionState.stationary) {
      final zoneInterval = Duration(minutes: _zoneIntervalMinutes);
      if (zoneInterval > TrackerConstants.maxExitDetectionInterval) {
        return TrackerConstants.maxExitDetectionInterval;
      }
      return zoneInterval;
    }
    switch (_state) {
      case MotionState.moving:
      case MotionState.maybeStationary:
      case MotionState.maybeMoving:
        // maybeMoving needs fast polling to quickly confirm exit and
        // accurately detect geofence boundary crossings
        return TrackerConstants.movingPollInterval;
      case MotionState.stationary:
        return TrackerConstants.stationaryPollInterval;
    }
  }

  /// Approximate distance in meters using equirectangular projection.
  static double _distanceMeters(
      double lat1, double lng1, double lat2, double lng2) {
    const metersPerDegree = 111320.0;
    final dLat = (lat1 - lat2) * metersPerDegree;
    final dLng =
        (lng1 - lng2) * metersPerDegree * math.cos(lat2 * math.pi / 180);
    return math.sqrt(dLat * dLat + dLng * dLng);
  }

  /// Export state for persistence.
  Map<String, dynamic> toJson() {
    return {
      'state': _state.index,
      'anchorLat': _anchorLat,
      'anchorLng': _anchorLng,
      'visitStartTime': _visitStartTime?.toIso8601String(),
      'firstNearTimestamp': _firstNearTimestamp?.toIso8601String(),
      'firstFarTimestamp': _firstFarTimestamp?.toIso8601String(),
      'nearCount': _nearCount,
      'farCount': _farCount,
    };
  }

  /// Restore from persisted state.
  factory StationaryDetector.fromJson(Map<String, dynamic> json) {
    final detector = StationaryDetector();
    detector.restore(
      state: MotionState.values[json['state'] as int? ?? 0],
      anchorLat: (json['anchorLat'] as num?)?.toDouble(),
      anchorLng: (json['anchorLng'] as num?)?.toDouble(),
      visitStartTime: json['visitStartTime'] != null
          ? DateTime.parse(json['visitStartTime'] as String)
          : null,
      firstNearTimestamp: json['firstNearTimestamp'] != null
          ? DateTime.parse(json['firstNearTimestamp'] as String)
          : null,
      firstFarTimestamp: json['firstFarTimestamp'] != null
          ? DateTime.parse(json['firstFarTimestamp'] as String)
          : null,
      nearCount: json['nearCount'] as int? ?? 0,
      farCount: json['farCount'] as int? ?? 0,
    );
    return detector;
  }
}
