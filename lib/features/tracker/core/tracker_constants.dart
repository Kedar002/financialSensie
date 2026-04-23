/// Central place for tracker timing and algorithm constants.
class TrackerConstants {
  TrackerConstants._();

  // --- Polling intervals ---

  /// GPS poll interval while moving.
  static const movingPollInterval = Duration(seconds: 30);

  /// GPS poll interval while stationary (battery saving).
  static const stationaryPollInterval = Duration(seconds: 120);

  /// Maximum GPS poll interval for exit detection when in a zone.
  /// Even with a 60-min zone interval, we still poll GPS at this rate
  /// so exit detection is never more than 5 minutes late.
  /// Firebase sends are throttled separately at the full zone interval.
  static const maxExitDetectionInterval = Duration(minutes: 5);

  /// Backward-compat alias used by location_service / tracking_screen foreground timer.
  static const locationInterval = movingPollInterval;

  // --- State machine thresholds ---

  /// Readings within this distance (meters) from the anchor count as "same place".
  static const double stationaryRadiusMeters = 80.0;

  /// Speed below this (m/s) is considered "not moving" (~5.4 km/h).
  /// GPS drift when stationary often reports 0.5–2.0 m/s.
  static const double stationarySpeedThreshold = 1.5;

  /// Consecutive near-anchor readings needed to confirm stationary.
  static const int stationaryConfirmCount = 3;

  /// Consecutive far-from-anchor readings needed to confirm movement resumed.
  static const int movingConfirmCount = 2;

  /// Visits shorter than this are discarded as noise (e.g. traffic lights).
  static const Duration minimumVisitDuration = Duration(minutes: 3);

  /// GPS readings with accuracy worse than this are ignored for state transitions.
  /// Indoor GPS is often 30–80m, so 100m allows indoor detection.
  static const double maxAccuracyMeters = 100.0;

  /// Convert a frequency setting name to a fixed Duration.
  /// Returns null for 'smart' mode (use detector's recommendation instead).
  static Duration? fixedIntervalForFrequency(
      String frequency, int customSeconds) {
    switch (frequency) {
      case 'realtime':
        return const Duration(seconds: 10);
      case 'normal':
        return const Duration(seconds: 30);
      case 'power_saver':
        return const Duration(minutes: 2);
      case 'custom':
        return Duration(seconds: customSeconds.clamp(5, 3600));
      default:
        return null; // 'smart' — use detector
    }
  }
}
