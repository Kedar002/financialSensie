/// Budget cycle configuration.
/// Defines when a budget cycle starts and ends.
class BudgetCycle {
  final DateTime startDate;
  final DateTime endDate;
  final double monthlyVariableBudget;

  const BudgetCycle({
    required this.startDate,
    required this.endDate,
    required this.monthlyVariableBudget,
  });

  /// Total days in this cycle.
  int get totalDays {
    return endDate.difference(startDate).inDays + 1;
  }

  /// Check if a date falls within this cycle.
  bool containsDate(DateTime date) {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    final normalizedStart = DateTime(startDate.year, startDate.month, startDate.day);
    final normalizedEnd = DateTime(endDate.year, endDate.month, endDate.day);

    return !normalizedDate.isBefore(normalizedStart) &&
           !normalizedDate.isAfter(normalizedEnd);
  }

  /// Create a cycle for the current month (1st to last day).
  factory BudgetCycle.currentMonth({required double budget}) {
    final now = DateTime.now();
    final startDate = DateTime(now.year, now.month, 1);
    final endDate = DateTime(now.year, now.month + 1, 0);

    return BudgetCycle(
      startDate: startDate,
      endDate: endDate,
      monthlyVariableBudget: budget,
    );
  }

  /// Create a cycle with custom start day (e.g., salary day).
  /// If today is before the cycle day, uses previous month's cycle.
  factory BudgetCycle.fromCycleDay({
    required int cycleDay,
    required double budget,
  }) {
    final now = DateTime.now();
    final today = now.day;

    DateTime startDate;
    DateTime endDate;

    if (today >= cycleDay) {
      // Current cycle started this month
      startDate = DateTime(now.year, now.month, cycleDay);
      endDate = DateTime(now.year, now.month + 1, cycleDay - 1);
    } else {
      // Current cycle started last month
      startDate = DateTime(now.year, now.month - 1, cycleDay);
      endDate = DateTime(now.year, now.month, cycleDay - 1);
    }

    return BudgetCycle(
      startDate: startDate,
      endDate: endDate,
      monthlyVariableBudget: budget,
    );
  }
}
