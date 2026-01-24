import '../repositories/user_repository.dart';
import '../repositories/transaction_repository.dart';
import 'financial_calculation_service.dart';

/// Safe-to-spend specific calculations.
/// The core user-facing metric of the app.
/// Now uses payment cycles (salary date to salary date) instead of calendar months.
class SafeToSpendService {
  final FinancialCalculationService _calcService = FinancialCalculationService();
  final UserRepository _userRepo = UserRepository();
  final TransactionRepository _transactionRepo = TransactionRepository();

  /// Daily safe-to-spend amount
  Future<double> getDailySafeToSpend(int userId) async {
    final status = await getStatus(userId);
    return status.dailyAmount;
  }

  /// Weekly safe-to-spend amount
  Future<double> getWeeklySafeToSpend(int userId) async {
    final daily = await getDailySafeToSpend(userId);
    return daily * 7;
  }

  /// Get complete safe-to-spend status using payment cycle
  Future<SafeToSpendStatus> getStatus(int userId) async {
    final user = await _userRepo.getCurrentUser();
    if (user == null) {
      return SafeToSpendStatus.empty();
    }

    final monthlyBudget = await _calcService.getMonthlySafeToSpend(userId);

    // Get spending within current payment cycle
    final cycleStart = user.currentCycleStart;
    final cycleEnd = user.currentCycleEnd;
    final spent = await _transactionRepo.getCycleSpending(userId, cycleStart, cycleEnd);

    final remaining = monthlyBudget - spent;
    final daysLeft = user.daysRemainingInCycle;
    final dailyAmount = daysLeft > 0 ? remaining / daysLeft : remaining;

    return SafeToSpendStatus(
      monthlyBudget: monthlyBudget,
      spentThisCycle: spent,
      remaining: remaining,
      daysRemaining: daysLeft,
      dailyAmount: dailyAmount,
      weeklyAmount: dailyAmount * 7,
      cycleStart: cycleStart,
      cycleEnd: cycleEnd,
      salaryDay: user.salaryDay,
    );
  }

  /// Preview impact of a potential spend
  Future<SpendImpact> previewSpendImpact(int userId, double amount) async {
    final status = await getStatus(userId);
    final newRemaining = status.remaining - amount;
    final daysLeft = status.daysRemaining;
    final newDaily = daysLeft > 0 ? newRemaining / daysLeft : newRemaining;

    return SpendImpact(
      currentDaily: status.dailyAmount,
      newDaily: newDaily,
      dailyReduction: status.dailyAmount - newDaily,
      isOverBudget: newRemaining < 0,
      remainingAfterSpend: newRemaining,
    );
  }

  /// Get recent transactions for current cycle
  Future<List<RecentTransaction>> getRecentTransactions(int userId, {int limit = 5}) async {
    final transactions = await _transactionRepo.getRecent(userId, limit: limit);
    return transactions.map((t) => RecentTransaction(
      id: t.id,
      amount: t.amount,
      category: t.category,
      description: t.description,
      date: DateTime.fromMillisecondsSinceEpoch(t.date * 1000),
    )).toList();
  }
}

class SafeToSpendStatus {
  final double monthlyBudget;
  final double spentThisCycle;
  final double remaining;
  final int daysRemaining;
  final double dailyAmount;
  final double weeklyAmount;
  final DateTime? cycleStart;
  final DateTime? cycleEnd;
  final int salaryDay;

  const SafeToSpendStatus({
    required this.monthlyBudget,
    required this.spentThisCycle,
    required this.remaining,
    required this.daysRemaining,
    required this.dailyAmount,
    required this.weeklyAmount,
    this.cycleStart,
    this.cycleEnd,
    this.salaryDay = 1,
  });

  factory SafeToSpendStatus.empty() {
    return const SafeToSpendStatus(
      monthlyBudget: 0,
      spentThisCycle: 0,
      remaining: 0,
      daysRemaining: 0,
      dailyAmount: 0,
      weeklyAmount: 0,
    );
  }

  // Keep old name for compatibility
  double get spentThisMonth => spentThisCycle;

  double get percentSpent =>
      monthlyBudget > 0 ? (spentThisCycle / monthlyBudget) * 100 : 0;

  bool get isOverBudget => remaining < 0;
  bool get isLow => remaining < (monthlyBudget * 0.2);
  bool get isWarning => percentSpent > 70 && daysRemaining > 7;
}

class SpendImpact {
  final double currentDaily;
  final double newDaily;
  final double dailyReduction;
  final bool isOverBudget;
  final double remainingAfterSpend;

  const SpendImpact({
    required this.currentDaily,
    required this.newDaily,
    required this.dailyReduction,
    required this.isOverBudget,
    required this.remainingAfterSpend,
  });

  double get percentReduction =>
      currentDaily > 0 ? (dailyReduction / currentDaily) * 100 : 0;
}

class RecentTransaction {
  final int? id;
  final double amount;
  final String category;
  final String? description;
  final DateTime date;

  const RecentTransaction({
    this.id,
    required this.amount,
    required this.category,
    this.description,
    required this.date,
  });
}
