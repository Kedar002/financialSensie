/// Cycle type - how the budget cycle is defined.
enum CycleType {
  /// Calendar month (1st to last day)
  calendarMonth,

  /// Custom day (e.g., 25th to 24th for salary cycles)
  customDay;

  String get label {
    switch (this) {
      case CycleType.calendarMonth:
        return 'Calendar month';
      case CycleType.customDay:
        return 'Custom cycle';
    }
  }

  String get description {
    switch (this) {
      case CycleType.calendarMonth:
        return '1st to end of month';
      case CycleType.customDay:
        return 'Paycheck to paycheck';
    }
  }
}

/// User's cycle configuration.
/// Stored in preferences/database.
class CycleSettings {
  final CycleType type;
  final int customStartDay; // Only used when type == customDay

  const CycleSettings({
    this.type = CycleType.calendarMonth,
    this.customStartDay = 1,
  });

  /// Default settings (calendar month).
  static const CycleSettings defaultSettings = CycleSettings();

  /// Create settings for calendar month.
  factory CycleSettings.calendarMonth() {
    return const CycleSettings(type: CycleType.calendarMonth);
  }

  /// Create settings for custom cycle day.
  factory CycleSettings.customDay(int startDay) {
    return CycleSettings(
      type: CycleType.customDay,
      customStartDay: startDay.clamp(1, 28), // Avoid issues with short months
    );
  }

  /// Get display label for current settings.
  String get displayLabel {
    switch (type) {
      case CycleType.calendarMonth:
        return '1st to end of month';
      case CycleType.customDay:
        return '${_ordinal(customStartDay)} to ${_ordinal(customStartDay - 1 == 0 ? 28 : customStartDay - 1)}';
    }
  }

  /// Get the current cycle dates based on settings.
  ({DateTime start, DateTime end}) getCurrentCycleDates() {
    final now = DateTime.now();

    switch (type) {
      case CycleType.calendarMonth:
        final start = DateTime(now.year, now.month, 1);
        final end = DateTime(now.year, now.month + 1, 0);
        return (start: start, end: end);

      case CycleType.customDay:
        final today = now.day;
        DateTime start;
        DateTime end;

        if (today >= customStartDay) {
          // Current cycle started this month
          start = DateTime(now.year, now.month, customStartDay);
          // End is day before start day in next month
          final nextMonth = DateTime(now.year, now.month + 1, customStartDay);
          end = nextMonth.subtract(const Duration(days: 1));
        } else {
          // Current cycle started last month
          start = DateTime(now.year, now.month - 1, customStartDay);
          // End is day before start day in current month
          end = DateTime(now.year, now.month, customStartDay - 1);
        }

        return (start: start, end: end);
    }
  }

  String _ordinal(int day) {
    if (day >= 11 && day <= 13) {
      return '${day}th';
    }
    switch (day % 10) {
      case 1:
        return '${day}st';
      case 2:
        return '${day}nd';
      case 3:
        return '${day}rd';
      default:
        return '${day}th';
    }
  }

  CycleSettings copyWith({
    CycleType? type,
    int? customStartDay,
  }) {
    return CycleSettings(
      type: type ?? this.type,
      customStartDay: customStartDay ?? this.customStartDay,
    );
  }
}
