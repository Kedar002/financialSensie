import '../repositories/emergency_fund_repository.dart';
import '../repositories/user_repository.dart';
import '../models/emergency_fund.dart';
import 'financial_calculation_service.dart';

/// Emergency fund calculations and management.
class EmergencyFundService {
  final EmergencyFundRepository _fundRepo = EmergencyFundRepository();
  final UserRepository _userRepo = UserRepository();
  final FinancialCalculationService _calcService = FinancialCalculationService();

  /// Calculate target based on essential expenses and risk level
  Future<double> calculateTarget(int userId) async {
    final user = await _userRepo.getById(userId);
    final monthlyEssential = await _calcService.getMonthlyEssentialExpenses(userId);

    final months = user?.emergencyFundMonths ?? 6;
    return monthlyEssential * months;
  }

  /// Get or create emergency fund for user
  Future<EmergencyFund> getOrCreateFund(int userId) async {
    var fund = await _fundRepo.getByUserId(userId);

    if (fund == null) {
      final target = await calculateTarget(userId);
      final monthlyEssential = await _calcService.getMonthlyEssentialExpenses(userId);

      await _fundRepo.createOrUpdate(
        userId: userId,
        targetAmount: target,
        monthlyEssential: monthlyEssential,
      );
      fund = await _fundRepo.getByUserId(userId);
    }

    return fund!;
  }

  /// Get current status of emergency fund
  Future<EmergencyFundStatus> getStatus(int userId) async {
    final fund = await getOrCreateFund(userId);

    return EmergencyFundStatus(
      currentAmount: fund.currentAmount,
      targetAmount: fund.targetAmount,
      monthlyEssential: fund.monthlyEssential,
      targetMonths: fund.targetMonths,
      runwayMonths: fund.runwayMonths,
      progressPercentage: fund.progressPercentage,
      isComplete: fund.isComplete,
      isLow: fund.isLow,
    );
  }

  /// Update fund when expenses change
  Future<void> recalculateTarget(int userId) async {
    final fund = await _fundRepo.getByUserId(userId);
    if (fund == null) return;

    final newTarget = await calculateTarget(userId);
    final monthlyEssential = await _calcService.getMonthlyEssentialExpenses(userId);

    await _fundRepo.createOrUpdate(
      userId: userId,
      targetAmount: newTarget,
      currentAmount: fund.currentAmount,
      targetMonths: fund.targetMonths,
      monthlyEssential: monthlyEssential,
    );
  }

  /// Add money to emergency fund
  Future<void> addToFund(int userId, double amount) async {
    await _fundRepo.addToFund(userId, amount);
  }

  /// Calculate monthly contribution needed to reach target in X months
  double calculateMonthlyContribution(
    double currentAmount,
    double targetAmount,
    int monthsToGoal,
  ) {
    if (monthsToGoal <= 0) return targetAmount - currentAmount;
    final remaining = targetAmount - currentAmount;
    if (remaining <= 0) return 0;
    return remaining / monthsToGoal;
  }
}

class EmergencyFundStatus {
  final double currentAmount;
  final double targetAmount;
  final double monthlyEssential;
  final int targetMonths;
  final double runwayMonths;
  final double progressPercentage;
  final bool isComplete;
  final bool isLow;

  const EmergencyFundStatus({
    required this.currentAmount,
    required this.targetAmount,
    required this.monthlyEssential,
    required this.targetMonths,
    required this.runwayMonths,
    required this.progressPercentage,
    required this.isComplete,
    required this.isLow,
  });

  double get remainingAmount => (targetAmount - currentAmount).clamp(0, double.infinity);
}
