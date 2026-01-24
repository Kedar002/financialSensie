import '../repositories/income_repository.dart';
import '../repositories/expense_repository.dart';
import '../repositories/allocation_repository.dart';
import '../repositories/planned_expense_repository.dart';
import '../repositories/transaction_repository.dart';

/// Core financial calculations.
/// All business logic lives here - UI only displays results.
class FinancialCalculationService {
  final IncomeRepository _incomeRepo = IncomeRepository();
  final FixedExpenseRepository _fixedExpenseRepo = FixedExpenseRepository();
  final VariableExpenseRepository _variableExpenseRepo = VariableExpenseRepository();
  final AllocationRepository _allocationRepo = AllocationRepository();
  final PlannedExpenseRepository _goalRepo = PlannedExpenseRepository();
  final TransactionRepository _transactionRepo = TransactionRepository();

  /// Total monthly income from all active sources
  Future<double> getMonthlyIncome(int userId) async {
    return await _incomeRepo.getTotalMonthlyIncome(userId);
  }

  /// Total fixed monthly expenses
  Future<double> getMonthlyFixedExpenses(int userId) async {
    return await _fixedExpenseRepo.getTotalMonthly(userId);
  }

  /// Total estimated variable expenses
  Future<double> getMonthlyVariableExpenses(int userId) async {
    return await _variableExpenseRepo.getTotalEstimated(userId);
  }

  /// Total essential expenses (for emergency fund calculation)
  Future<double> getMonthlyEssentialExpenses(int userId) async {
    final fixedEssential = await _fixedExpenseRepo.getTotalEssential(userId);
    final variableEssential = await _variableExpenseRepo.getTotalEssential(userId);
    return fixedEssential + variableEssential;
  }

  /// Total allocations (savings, investments, goals)
  Future<double> getMonthlyAllocations(int userId) async {
    final income = await getMonthlyIncome(userId);
    final allocationAmount = await _allocationRepo.getTotalAllocations(userId, income);
    final goalAmount = await _goalRepo.getTotalMonthlyRequired(userId);
    return allocationAmount + goalAmount;
  }

  /// Monthly safe-to-spend budget
  Future<double> getMonthlySafeToSpend(int userId) async {
    final income = await getMonthlyIncome(userId);
    final fixed = await getMonthlyFixedExpenses(userId);
    final allocations = await getMonthlyAllocations(userId);

    return income - fixed - allocations;
  }

  /// Amount spent this month
  Future<double> getMonthlySpent(int userId) async {
    return await _transactionRepo.getMonthlySpending(userId);
  }

  /// Remaining safe-to-spend for the month
  Future<double> getRemainingThisMonth(int userId) async {
    final budget = await getMonthlySafeToSpend(userId);
    final spent = await getMonthlySpent(userId);
    return budget - spent;
  }

  /// Summary of financial status
  Future<FinancialSummary> getSummary(int userId) async {
    final income = await getMonthlyIncome(userId);
    final fixedExpenses = await getMonthlyFixedExpenses(userId);
    final variableExpenses = await getMonthlyVariableExpenses(userId);
    final allocations = await getMonthlyAllocations(userId);
    final safeToSpend = await getMonthlySafeToSpend(userId);
    final spent = await getMonthlySpent(userId);

    return FinancialSummary(
      monthlyIncome: income,
      fixedExpenses: fixedExpenses,
      variableExpenses: variableExpenses,
      allocations: allocations,
      safeToSpendBudget: safeToSpend,
      spentThisMonth: spent,
    );
  }
}

class FinancialSummary {
  final double monthlyIncome;
  final double fixedExpenses;
  final double variableExpenses;
  final double allocations;
  final double safeToSpendBudget;
  final double spentThisMonth;

  const FinancialSummary({
    required this.monthlyIncome,
    required this.fixedExpenses,
    required this.variableExpenses,
    required this.allocations,
    required this.safeToSpendBudget,
    required this.spentThisMonth,
  });

  double get totalExpenses => fixedExpenses + variableExpenses;
  double get remaining => safeToSpendBudget - spentThisMonth;
  double get savingsRate => monthlyIncome > 0 ? (allocations / monthlyIncome) * 100 : 0;
}
