import 'financial_calculation_service.dart';

/// Safe-to-spend specific calculations.
/// The core user-facing metric of the app.
class SafeToSpendService {
  final FinancialCalculationService _calcService = FinancialCalculationService();

  /// Daily safe-to-spend amount
  Future<double> getDailySafeToSpend(int userId) async {
    final remaining = await _calcService.getRemainingThisMonth(userId);
    final daysLeft = _getDaysRemainingInMonth();

    if (daysLeft <= 0) return remaining;
    return remaining / daysLeft;
  }

  /// Weekly safe-to-spend amount
  Future<double> getWeeklySafeToSpend(int userId) async {
    final daily = await getDailySafeToSpend(userId);
    return daily * 7;
  }

  /// Get complete safe-to-spend status
  Future<SafeToSpendStatus> getStatus(int userId) async {
    final monthlyBudget = await _calcService.getMonthlySafeToSpend(userId);
    final spent = await _calcService.getMonthlySpent(userId);
    final remaining = monthlyBudget - spent;
    final daysLeft = _getDaysRemainingInMonth();
    final dailyAmount = daysLeft > 0 ? remaining / daysLeft : remaining;

    return SafeToSpendStatus(
      monthlyBudget: monthlyBudget,
      spentThisMonth: spent,
      remaining: remaining,
      daysRemaining: daysLeft,
      dailyAmount: dailyAmount,
      weeklyAmount: dailyAmount * 7,
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

  int _getDaysRemainingInMonth() {
    final now = DateTime.now();
    final lastDay = DateTime(now.year, now.month + 1, 0);
    return lastDay.day - now.day + 1;
  }
}

class SafeToSpendStatus {
  final double monthlyBudget;
  final double spentThisMonth;
  final double remaining;
  final int daysRemaining;
  final double dailyAmount;
  final double weeklyAmount;

  const SafeToSpendStatus({
    required this.monthlyBudget,
    required this.spentThisMonth,
    required this.remaining,
    required this.daysRemaining,
    required this.dailyAmount,
    required this.weeklyAmount,
  });

  double get percentSpent =>
      monthlyBudget > 0 ? (spentThisMonth / monthlyBudget) * 100 : 0;

  bool get isOverBudget => remaining < 0;
  bool get isLow => remaining < (monthlyBudget * 0.2);
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
