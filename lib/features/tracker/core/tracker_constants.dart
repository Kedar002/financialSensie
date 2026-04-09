/// Central place for tracker timing constants.
class TrackerConstants {
  TrackerConstants._();

  /// How often the foreground UI and background service poll for a new location.
  static const locationInterval = Duration(seconds: 30);
}
