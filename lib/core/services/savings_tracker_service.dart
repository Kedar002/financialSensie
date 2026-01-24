import '../models/savings_tracker.dart';
import '../models/allocation.dart';
import '../repositories/savings_tracker_repository.dart';
import '../repositories/emergency_fund_repository.dart';
import '../repositories/allocation_repository.dart';
import '../repositories/planned_expense_repository.dart';
import '../repositories/income_repository.dart';

/// Service for tracking monthly savings totals.
/// Tracks emergency fund, investments (SIP), goals, and completed goals.
class SavingsTrackerService {
  final SavingsTrackerRepository _trackerRepo = SavingsTrackerRepository();
  final EmergencyFundRepository _emergencyRepo = EmergencyFundRepository();
  final AllocationRepository _allocationRepo = AllocationRepository();
  final PlannedExpenseRepository _goalRepo = PlannedExpenseRepository();
  final IncomeRepository _incomeRepo = IncomeRepository();

  /// Get current month's savings record
  Future<SavingsTracker?> getCurrentMonth(int userId) async {
    final now = DateTime.now();
    final month = '${now.year}-${now.month.toString().padLeft(2, '0')}';
    return await _trackerRepo.getByMonth(userId, month);
  }

  /// Get savings history (newest first)
  Future<List<SavingsTracker>> getHistory(int userId, {int limit = 24}) async {
    return await _trackerRepo.getHistory(userId, limit: limit);
  }

  /// Get the latest savings record
  Future<SavingsTracker?> getLatest(int userId) async {
    return await _trackerRepo.getLatest(userId);
  }

  /// Calculate current savings totals
  Future<SavingsTotals> calculateCurrentTotals(int userId) async {
    // Get emergency fund balance
    final emergencyFund = await _emergencyRepo.getByUserId(userId);
    final emergencyBalance = emergencyFund?.currentAmount ?? 0;

    // Get total monthly income for investment calculation
    final totalIncome = await _incomeRepo.getTotalMonthlyIncome(userId);

    // Get investment allocations (SIP, etc.)
    final allocations = await _allocationRepo.getByUserId(userId);
    double investmentTotal = 0;
    for (final alloc in allocations) {
      if (alloc.type == AllocationType.investment) {
        investmentTotal += alloc.calculateAmount(totalIncome);
      }
    }

    // Get active goals total (amount saved so far)
    final activeGoals = await _goalRepo.getActiveGoals(userId);
    final goalsTotal = activeGoals.fold<double>(
      0,
      (sum, goal) => sum + goal.currentAmount,
    );

    // Get completed goals total
    final completedGoals = await _goalRepo.getByUserId(userId, status: 'completed');
    final completedTotal = completedGoals.fold<double>(
      0,
      (sum, goal) => sum + goal.targetAmount,
    );

    // Calculate total savings (emergency + investment cumulative + goals + completed)
    // For investment, we track monthly allocation amount as cumulative
    final totalSavings = emergencyBalance + goalsTotal + completedTotal;

    return SavingsTotals(
      emergencyFundBalance: emergencyBalance,
      investmentTotal: investmentTotal, // Monthly investment allocation
      goalsTotal: goalsTotal,
      completedGoalsTotal: completedTotal,
      totalSavings: totalSavings,
    );
  }

  /// Record savings for current month
  Future<int> recordCurrentMonth(int userId) async {
    final now = DateTime.now();
    final month = '${now.year}-${now.month.toString().padLeft(2, '0')}';

    final totals = await calculateCurrentTotals(userId);

    final tracker = SavingsTracker(
      userId: userId,
      month: month,
      emergencyFundBalance: totals.emergencyFundBalance,
      investmentTotal: totals.investmentTotal,
      goalsTotal: totals.goalsTotal,
      completedGoalsTotal: totals.completedGoalsTotal,
      totalSavings: totals.totalSavings,
      recordedAt: now.millisecondsSinceEpoch ~/ 1000,
    );

    return await _trackerRepo.save(tracker);
  }

  /// Record savings for a specific month (used for snapshots)
  Future<int> recordForMonth(int userId, String month) async {
    final totals = await calculateCurrentTotals(userId);

    final tracker = SavingsTracker(
      userId: userId,
      month: month,
      emergencyFundBalance: totals.emergencyFundBalance,
      investmentTotal: totals.investmentTotal,
      goalsTotal: totals.goalsTotal,
      completedGoalsTotal: totals.completedGoalsTotal,
      totalSavings: totals.totalSavings,
      recordedAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
    );

    return await _trackerRepo.save(tracker);
  }

  /// Get savings growth summary
  Future<SavingsGrowth> getSavingsGrowth(int userId) async {
    final history = await getHistory(userId, limit: 13); // 13 to calculate 12 month changes

    if (history.isEmpty) {
      final current = await calculateCurrentTotals(userId);
      return SavingsGrowth(
        currentTotal: current.totalSavings,
        monthlyChange: 0,
        yearlyChange: 0,
        averageMonthly: 0,
      );
    }

    final current = history.first;
    double monthlyChange = 0;
    double yearlyChange = 0;

    if (history.length >= 2) {
      monthlyChange = current.totalSavings - history[1].totalSavings;
    }

    if (history.length >= 13) {
      yearlyChange = current.totalSavings - history[12].totalSavings;
    } else if (history.length >= 2) {
      yearlyChange = current.totalSavings - history.last.totalSavings;
    }

    final avgMonthly = await _trackerRepo.getAverageMonthly(userId);

    return SavingsGrowth(
      currentTotal: current.totalSavings,
      monthlyChange: monthlyChange,
      yearlyChange: yearlyChange,
      averageMonthly: avgMonthly,
    );
  }

  /// Cleanup old records (keep last 24 months)
  Future<void> cleanupOldRecords(int userId) async {
    await _trackerRepo.deleteOlderThan(userId, 24);
  }
}

/// Current savings totals
class SavingsTotals {
  final double emergencyFundBalance;
  final double investmentTotal;
  final double goalsTotal;
  final double completedGoalsTotal;
  final double totalSavings;

  const SavingsTotals({
    required this.emergencyFundBalance,
    required this.investmentTotal,
    required this.goalsTotal,
    required this.completedGoalsTotal,
    required this.totalSavings,
  });
}

/// Savings growth summary
class SavingsGrowth {
  final double currentTotal;
  final double monthlyChange;
  final double yearlyChange;
  final double averageMonthly;

  const SavingsGrowth({
    required this.currentTotal,
    required this.monthlyChange,
    required this.yearlyChange,
    required this.averageMonthly,
  });

  bool get isGrowing => monthlyChange > 0;
}
