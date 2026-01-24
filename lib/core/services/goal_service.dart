import '../repositories/planned_expense_repository.dart';
import '../models/planned_expense.dart';
import 'financial_calculation_service.dart';

/// Goal/Planned expense calculations.
class GoalService {
  final PlannedExpenseRepository _goalRepo = PlannedExpenseRepository();
  final FinancialCalculationService _calcService = FinancialCalculationService();

  /// Get all active goals
  Future<List<PlannedExpense>> getActiveGoals(int userId) async {
    return await _goalRepo.getActiveGoals(userId);
  }

  /// Get total monthly amount needed for all goals
  Future<double> getTotalMonthlyRequired(int userId) async {
    return await _goalRepo.getTotalMonthlyRequired(userId);
  }

  /// Check if a new goal is realistic given current finances
  Future<GoalFeasibility> checkFeasibility(
    int userId,
    double targetAmount,
    DateTime targetDate,
  ) async {
    final monthlyRequired = PlannedExpense.calculateMonthlyRequired(
      targetAmount,
      0,
      targetDate.millisecondsSinceEpoch ~/ 1000,
    );

    final safeToSpend = await _calcService.getMonthlySafeToSpend(userId);
    final currentGoalCommitments = await getTotalMonthlyRequired(userId);
    final availableForNewGoal = safeToSpend - currentGoalCommitments;

    final isRealistic = monthlyRequired <= availableForNewGoal;
    final percentOfDisposable = safeToSpend > 0
        ? (monthlyRequired / safeToSpend) * 100.0
        : 100.0;

    // Calculate suggested date if not realistic
    DateTime? suggestedDate;
    if (!isRealistic && availableForNewGoal > 0) {
      final monthsNeeded = (targetAmount / availableForNewGoal).ceil();
      suggestedDate = DateTime.now().add(Duration(days: monthsNeeded * 30));
    }

    return GoalFeasibility(
      isRealistic: isRealistic,
      monthlyRequired: monthlyRequired,
      availableBudget: availableForNewGoal,
      percentOfDisposable: percentOfDisposable,
      suggestedDate: suggestedDate,
    );
  }

  /// Create a new goal
  Future<int> createGoal({
    required int userId,
    required String name,
    required double targetAmount,
    required DateTime targetDate,
    int priority = 1,
  }) async {
    return await _goalRepo.addGoal(
      userId: userId,
      name: name,
      targetAmount: targetAmount,
      targetDate: targetDate,
      priority: priority,
    );
  }

  /// Add contribution to a goal
  Future<void> contributeToGoal(int goalId, double amount) async {
    await _goalRepo.addToGoal(goalId, amount);
  }

  /// Get summary of all goals
  Future<GoalsSummary> getSummary(int userId) async {
    final goals = await getActiveGoals(userId);
    final totalTarget = goals.fold(0.0, (sum, g) => sum + g.targetAmount);
    final totalSaved = goals.fold(0.0, (sum, g) => sum + g.currentAmount);
    final monthlyRequired = goals.fold(0.0, (sum, g) => sum + g.monthlyRequired);

    return GoalsSummary(
      activeGoalsCount: goals.length,
      totalTargetAmount: totalTarget,
      totalSavedAmount: totalSaved,
      totalMonthlyRequired: monthlyRequired,
      overallProgress: totalTarget > 0 ? (totalSaved / totalTarget) * 100 : 0,
    );
  }
}

class GoalFeasibility {
  final bool isRealistic;
  final double monthlyRequired;
  final double availableBudget;
  final double percentOfDisposable;
  final DateTime? suggestedDate;

  const GoalFeasibility({
    required this.isRealistic,
    required this.monthlyRequired,
    required this.availableBudget,
    required this.percentOfDisposable,
    this.suggestedDate,
  });

  bool get isAggressive => percentOfDisposable > 50;
}

class GoalsSummary {
  final int activeGoalsCount;
  final double totalTargetAmount;
  final double totalSavedAmount;
  final double totalMonthlyRequired;
  final double overallProgress;

  const GoalsSummary({
    required this.activeGoalsCount,
    required this.totalTargetAmount,
    required this.totalSavedAmount,
    required this.totalMonthlyRequired,
    required this.overallProgress,
  });

  double get remainingAmount => totalTargetAmount - totalSavedAmount;
}
