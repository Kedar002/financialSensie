import '../repositories/income_repository.dart';
import '../repositories/expense_repository.dart';
import '../repositories/allocation_repository.dart';
import '../repositories/planned_expense_repository.dart';
import '../models/income_source.dart';
import '../models/fixed_expense.dart';
import '../models/variable_expense.dart';
import 'emergency_fund_service.dart';

/// Budget Sheet - Complete monthly financial overview.
/// Aggregates all financial data for the budget sheet view.
class BudgetSheetService {
  final IncomeRepository _incomeRepo = IncomeRepository();
  final FixedExpenseRepository _fixedExpenseRepo = FixedExpenseRepository();
  final VariableExpenseRepository _variableExpenseRepo = VariableExpenseRepository();
  final AllocationRepository _allocationRepo = AllocationRepository();
  final PlannedExpenseRepository _goalRepo = PlannedExpenseRepository();
  final EmergencyFundService _emergencyFundService = EmergencyFundService();

  /// Get complete budget sheet data
  Future<BudgetSheet> getBudgetSheet(int userId) async {
    // Income
    final incomeSources = await _incomeRepo.getByUserId(userId);
    final totalIncome = incomeSources.fold<double>(
      0.0,
      (sum, source) => sum + source.monthlyAmount,
    );

    // Essential expenses (Needs)
    final fixedExpenses = await _fixedExpenseRepo.getByUserId(userId);
    final essentialFixed = fixedExpenses.where((e) => e.isEssential).toList();
    final nonEssentialFixed = fixedExpenses.where((e) => !e.isEssential).toList();

    final variableExpenses = await _variableExpenseRepo.getByUserId(userId);
    final essentialVariable = variableExpenses.where((e) => e.isEssential).toList();
    final nonEssentialVariable = variableExpenses.where((e) => !e.isEssential).toList();

    final totalNeeds = essentialFixed.fold<double>(0.0, (sum, e) => sum + e.amount) +
        essentialVariable.fold<double>(0.0, (sum, e) => sum + e.estimatedAmount);

    // Wants (non-essential)
    final totalWants = nonEssentialFixed.fold<double>(0.0, (sum, e) => sum + e.amount) +
        nonEssentialVariable.fold<double>(0.0, (sum, e) => sum + e.estimatedAmount);

    // Savings - Allocations
    final allocations = await _allocationRepo.getByUserId(userId);
    final allocationItems = allocations.map((a) => BudgetLineItem(
      name: a.name,
      amount: a.calculateAmount(totalIncome),
      type: a.type,
    )).toList();

    // Savings - Goals
    final goals = await _goalRepo.getActiveGoals(userId);
    final goalItems = goals.map((g) => BudgetLineItem(
      name: g.name,
      amount: g.monthlyRequired,
      type: 'goal',
    )).toList();

    // Emergency Fund contribution (if any active allocation)
    final emergencyStatus = await _emergencyFundService.getStatus(userId);

    final totalAllocations = allocationItems.fold<double>(0.0, (sum, i) => sum + i.amount);
    final totalGoals = goalItems.fold<double>(0.0, (sum, i) => sum + i.amount);
    final totalSavings = totalAllocations + totalGoals;

    // Calculate percentages
    final needsPercent = totalIncome > 0 ? (totalNeeds / totalIncome) * 100 : 0.0;
    final wantsPercent = totalIncome > 0 ? (totalWants / totalIncome) * 100 : 0.0;
    final savingsPercent = totalIncome > 0 ? (totalSavings / totalIncome) * 100 : 0.0;

    // Safe to spend
    final safeToSpend = totalIncome - totalNeeds - totalSavings;

    return BudgetSheet(
      month: DateTime.now(),
      // Income
      incomeSources: incomeSources,
      totalIncome: totalIncome,
      // Needs
      essentialFixedExpenses: essentialFixed,
      essentialVariableExpenses: essentialVariable,
      totalNeeds: totalNeeds,
      needsPercent: needsPercent,
      // Wants
      nonEssentialFixedExpenses: nonEssentialFixed,
      nonEssentialVariableExpenses: nonEssentialVariable,
      totalWants: totalWants,
      wantsPercent: wantsPercent,
      // Savings
      allocations: allocationItems,
      goals: goalItems,
      totalSavings: totalSavings,
      savingsPercent: savingsPercent,
      // Emergency Fund Status
      emergencyFundCurrent: emergencyStatus.currentAmount,
      emergencyFundTarget: emergencyStatus.targetAmount,
      emergencyFundRunway: emergencyStatus.runwayMonths,
      // Summary
      safeToSpend: safeToSpend,
      safeToSpendPercent: totalIncome > 0 ? (safeToSpend / totalIncome) * 100 : 0.0,
    );
  }
}

class BudgetSheet {
  final DateTime month;

  // Income
  final List<IncomeSource> incomeSources;
  final double totalIncome;

  // Needs (Essential)
  final List<FixedExpense> essentialFixedExpenses;
  final List<VariableExpense> essentialVariableExpenses;
  final double totalNeeds;
  final double needsPercent;

  // Wants (Non-essential)
  final List<FixedExpense> nonEssentialFixedExpenses;
  final List<VariableExpense> nonEssentialVariableExpenses;
  final double totalWants;
  final double wantsPercent;

  // Savings
  final List<BudgetLineItem> allocations;
  final List<BudgetLineItem> goals;
  final double totalSavings;
  final double savingsPercent;

  // Emergency Fund
  final double emergencyFundCurrent;
  final double emergencyFundTarget;
  final double emergencyFundRunway;

  // Summary
  final double safeToSpend;
  final double safeToSpendPercent;

  const BudgetSheet({
    required this.month,
    required this.incomeSources,
    required this.totalIncome,
    required this.essentialFixedExpenses,
    required this.essentialVariableExpenses,
    required this.totalNeeds,
    required this.needsPercent,
    required this.nonEssentialFixedExpenses,
    required this.nonEssentialVariableExpenses,
    required this.totalWants,
    required this.wantsPercent,
    required this.allocations,
    required this.goals,
    required this.totalSavings,
    required this.savingsPercent,
    required this.emergencyFundCurrent,
    required this.emergencyFundTarget,
    required this.emergencyFundRunway,
    required this.safeToSpend,
    required this.safeToSpendPercent,
  });

  bool get isHealthy => savingsPercent >= 20 && needsPercent <= 50;

  double get totalAllocated => totalNeeds + totalWants + totalSavings;

  double get unallocated => totalIncome - totalAllocated;
}

class BudgetLineItem {
  final String name;
  final double amount;
  final String type;

  const BudgetLineItem({
    required this.name,
    required this.amount,
    required this.type,
  });
}
