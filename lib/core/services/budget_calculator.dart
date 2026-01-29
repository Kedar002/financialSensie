import '../../features/home/models/expense.dart';
import '../models/budget_cycle.dart';

/// Budget calculation result.
/// Contains all computed values for display.
class BudgetSnapshot {
  /// Fixed daily budget for the entire cycle.
  /// = monthlyVariableBudget / totalDaysInCycle
  final double plannedDailyBudget;

  /// Dynamic daily allowance based on remaining budget.
  /// = remainingBudget / remainingDays
  final double rollingDailyAllowance;

  /// Total budget for the cycle.
  final double totalBudget;

  /// Total spent so far in this cycle.
  final double totalSpent;

  /// Remaining budget (can be negative if overspent).
  final double remainingBudget;

  /// Days remaining in cycle (including today).
  final int remainingDays;

  /// Total days in cycle.
  final int totalDays;

  /// Whether user is over budget.
  final bool isOverBudget;

  /// Amount over budget (0 if not over).
  final double overBudgetAmount;

  /// Progress through budget (0.0 to 1.0+).
  final double spentProgress;

  /// Progress through cycle time (0.0 to 1.0).
  final double timeProgress;

  const BudgetSnapshot({
    required this.plannedDailyBudget,
    required this.rollingDailyAllowance,
    required this.totalBudget,
    required this.totalSpent,
    required this.remainingBudget,
    required this.remainingDays,
    required this.totalDays,
    required this.isOverBudget,
    required this.overBudgetAmount,
    required this.spentProgress,
    required this.timeProgress,
  });
}

/// Budget calculator service.
/// Pure functions, no state. Feed it data, get results.
class BudgetCalculator {
  const BudgetCalculator._();

  /// Calculate budget snapshot for current state.
  ///
  /// [cycle] - The budget cycle configuration
  /// [expenses] - All expenses (will be filtered to cycle)
  /// [asOfDate] - Calculate as of this date (defaults to now)
  static BudgetSnapshot calculate({
    required BudgetCycle cycle,
    required List<Expense> expenses,
    DateTime? asOfDate,
  }) {
    final today = asOfDate ?? DateTime.now();
    final normalizedToday = DateTime(today.year, today.month, today.day);

    // FIXED: Planned daily budget (constant for entire cycle)
    final plannedDailyBudget = cycle.monthlyVariableBudget / cycle.totalDays;

    // Calculate total spent in cycle
    final cycleExpenses = _filterExpensesInCycle(expenses, cycle);
    final totalSpent = cycleExpenses.fold(0.0, (sum, e) => sum + e.amount);

    // Calculate remaining budget
    final remainingBudget = cycle.monthlyVariableBudget - totalSpent;

    // Calculate remaining days (minimum 1 to avoid division by zero)
    final normalizedEnd = DateTime(
      cycle.endDate.year,
      cycle.endDate.month,
      cycle.endDate.day,
    );
    int remainingDays = normalizedEnd.difference(normalizedToday).inDays + 1;

    // Handle edge cases
    if (remainingDays <= 0) {
      // Cycle is complete
      return BudgetSnapshot(
        plannedDailyBudget: plannedDailyBudget,
        rollingDailyAllowance: remainingBudget, // Show what's left (or owed)
        totalBudget: cycle.monthlyVariableBudget,
        totalSpent: totalSpent,
        remainingBudget: remainingBudget,
        remainingDays: 0,
        totalDays: cycle.totalDays,
        isOverBudget: remainingBudget < 0,
        overBudgetAmount: remainingBudget < 0 ? remainingBudget.abs() : 0,
        spentProgress: totalSpent / cycle.monthlyVariableBudget,
        timeProgress: 1.0,
      );
    }

    // DYNAMIC: Rolling daily allowance
    double rollingDailyAllowance;
    if (remainingBudget <= 0) {
      // Over budget - show 0 (can't spend more)
      rollingDailyAllowance = 0;
    } else {
      rollingDailyAllowance = remainingBudget / remainingDays;
    }

    // Calculate progress metrics
    final spentProgress = totalSpent / cycle.monthlyVariableBudget;
    final daysElapsed = cycle.totalDays - remainingDays;
    final timeProgress = daysElapsed / cycle.totalDays;

    return BudgetSnapshot(
      plannedDailyBudget: plannedDailyBudget,
      rollingDailyAllowance: rollingDailyAllowance,
      totalBudget: cycle.monthlyVariableBudget,
      totalSpent: totalSpent,
      remainingBudget: remainingBudget,
      remainingDays: remainingDays,
      totalDays: cycle.totalDays,
      isOverBudget: remainingBudget < 0,
      overBudgetAmount: remainingBudget < 0 ? remainingBudget.abs() : 0,
      spentProgress: spentProgress,
      timeProgress: timeProgress,
    );
  }

  /// Get expenses for a specific date.
  static List<Expense> getExpensesForDate(
    List<Expense> expenses,
    DateTime date,
  ) {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    return expenses.where((e) {
      final expenseDate = DateTime(e.date.year, e.date.month, e.date.day);
      return expenseDate == normalizedDate;
    }).toList();
  }

  /// Get total spent on a specific date.
  static double getTotalForDate(List<Expense> expenses, DateTime date) {
    return getExpensesForDate(expenses, date)
        .fold(0.0, (sum, e) => sum + e.amount);
  }

  /// Filter expenses to only those within the cycle.
  static List<Expense> _filterExpensesInCycle(
    List<Expense> expenses,
    BudgetCycle cycle,
  ) {
    return expenses.where((e) => cycle.containsDate(e.date)).toList();
  }

  /// Calculate spending breakdown by category for a cycle.
  static Map<ExpenseCategory, double> getCategoryBreakdown(
    List<Expense> expenses,
    BudgetCycle cycle,
  ) {
    final cycleExpenses = _filterExpensesInCycle(expenses, cycle);
    final breakdown = <ExpenseCategory, double>{};

    for (final category in ExpenseCategory.values) {
      breakdown[category] = cycleExpenses
          .where((e) => e.category == category)
          .fold(0.0, (sum, e) => sum + e.amount);
    }

    return breakdown;
  }
}
