import 'dart:convert';
import '../repositories/financial_snapshot_repository.dart';
import '../repositories/user_repository.dart';
import '../repositories/transaction_repository.dart';
import '../models/financial_snapshot.dart';
import 'budget_sheet_service.dart';
import 'savings_tracker_service.dart';

/// Service for capturing and managing budget snapshots.
/// Automatically captures snapshots at end of payment cycles.
class BudgetSnapshotService {
  final FinancialSnapshotRepository _snapshotRepo = FinancialSnapshotRepository();
  final BudgetSheetService _budgetSheetService = BudgetSheetService();
  final UserRepository _userRepo = UserRepository();
  final TransactionRepository _transactionRepo = TransactionRepository();
  final SavingsTrackerService _savingsService = SavingsTrackerService();

  /// Capture a snapshot of the current budget sheet
  Future<int> captureSnapshot(int userId, {DateTime? forMonth}) async {
    final budgetSheet = await _budgetSheetService.getBudgetSheet(userId);
    final targetMonth = forMonth ?? DateTime.now();
    final monthKey = _formatMonth(targetMonth);

    // Get actual spending for this month/cycle
    final user = await _userRepo.getCurrentUser();
    double actualSpent = 0;
    if (user != null) {
      actualSpent = await _transactionRepo.getCycleSpending(
        userId,
        user.currentCycleStart,
        user.currentCycleEnd,
      );
    }

    final snapshot = FinancialSnapshot(
      userId: userId,
      month: monthKey,
      totalIncome: budgetSheet.totalIncome,
      totalFixedExpenses: budgetSheet.totalNeeds,
      totalVariableExpenses: budgetSheet.totalWants,
      totalSavings: budgetSheet.totalSavings,
      safeToSpendBudget: budgetSheet.safeToSpend,
      actualSpent: actualSpent,
      emergencyFundBalance: budgetSheet.emergencyFundCurrent,
      emergencyFundTarget: budgetSheet.emergencyFundTarget,
      needsPercent: budgetSheet.needsPercent,
      wantsPercent: budgetSheet.wantsPercent,
      savingsPercent: budgetSheet.savingsPercent,
      safeToSpendPercent: budgetSheet.safeToSpendPercent,
      incomeBreakdown: _serializeIncome(budgetSheet),
      needsBreakdown: _serializeNeeds(budgetSheet),
      wantsBreakdown: _serializeWants(budgetSheet),
      savingsBreakdown: _serializeSavings(budgetSheet),
      createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
    );

    final snapshotId = await _snapshotRepo.saveSnapshot(snapshot);

    // Also record savings for this month
    await _savingsService.recordForMonth(userId, monthKey);

    return snapshotId;
  }

  /// Check if we should capture a snapshot (cycle ended without snapshot)
  Future<bool> shouldCaptureSnapshot(int userId) async {
    final user = await _userRepo.getCurrentUser();
    if (user == null) return false;

    // Get the previous cycle's month
    final previousCycle = _getPreviousCycleMonth(user.salaryDay);
    final previousMonthKey = _formatMonth(previousCycle);

    // Check if snapshot exists for previous month
    final hasSnapshot = await _snapshotRepo.hasSnapshot(userId, previousMonthKey);

    // If no snapshot for previous month and we're at least 1 day into new cycle
    return !hasSnapshot && DateTime.now().day >= user.salaryDay;
  }

  /// Get the month that just ended (for auto-capture)
  DateTime _getPreviousCycleMonth(int salaryDay) {
    final now = DateTime.now();

    // If we're past salary day, previous cycle was last month
    // If we're before salary day, previous cycle was 2 months ago
    if (now.day >= salaryDay) {
      // We're in a new cycle, previous was last month
      return DateTime(now.year, now.month - 1, salaryDay);
    } else {
      // We're still in same cycle as last month, previous was 2 months ago
      return DateTime(now.year, now.month - 2, salaryDay);
    }
  }

  /// Capture snapshot for previous cycle if needed
  Future<void> captureIfNeeded(int userId) async {
    final shouldCapture = await shouldCaptureSnapshot(userId);
    if (shouldCapture) {
      final user = await _userRepo.getCurrentUser();
      if (user != null) {
        final previousMonth = _getPreviousCycleMonth(user.salaryDay);
        await captureSnapshot(userId, forMonth: previousMonth);
      }
    }

    // Cleanup old snapshots (keep only 24 months)
    await _snapshotRepo.deleteOlderThan(userId, months: 24);
  }

  /// Get snapshot for a specific month
  Future<FinancialSnapshot?> getSnapshotForMonth(int userId, String month) async {
    return await _snapshotRepo.getByMonth(userId, month);
  }

  /// Get history of all snapshots
  Future<List<FinancialSnapshot>> getHistory(int userId, {int limit = 24}) async {
    return await _snapshotRepo.getHistory(userId, limit: limit);
  }

  /// Get latest snapshot
  Future<FinancialSnapshot?> getLatestSnapshot(int userId) async {
    return await _snapshotRepo.getLatest(userId);
  }

  // Helper to format month as "YYYY-MM"
  String _formatMonth(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}';
  }

  // Serialize income sources to JSON
  String _serializeIncome(BudgetSheet sheet) {
    final items = sheet.incomeSources.map((s) => {
      'name': s.name,
      'amount': s.monthlyAmount,
      'frequency': s.frequency,
    }).toList();
    return jsonEncode(items);
  }

  // Serialize needs (essential expenses) to JSON
  String _serializeNeeds(BudgetSheet sheet) {
    final items = <Map<String, dynamic>>[];

    for (final e in sheet.essentialFixedExpenses) {
      items.add({
        'name': e.name,
        'amount': e.amount,
        'category': e.category,
        'isFixed': true,
      });
    }

    for (final e in sheet.essentialVariableExpenses) {
      items.add({
        'name': e.category,
        'amount': e.estimatedAmount,
        'category': e.category,
        'isFixed': false,
        'isEstimate': true,
      });
    }

    return jsonEncode(items);
  }

  // Serialize wants (non-essential expenses) to JSON
  String _serializeWants(BudgetSheet sheet) {
    final items = <Map<String, dynamic>>[];

    for (final e in sheet.nonEssentialFixedExpenses) {
      items.add({
        'name': e.name,
        'amount': e.amount,
        'category': e.category,
        'isFixed': true,
      });
    }

    for (final e in sheet.nonEssentialVariableExpenses) {
      items.add({
        'name': e.category,
        'amount': e.estimatedAmount,
        'category': e.category,
        'isFixed': false,
        'isEstimate': true,
      });
    }

    return jsonEncode(items);
  }

  // Serialize savings (allocations + goals) to JSON
  String _serializeSavings(BudgetSheet sheet) {
    final items = <Map<String, dynamic>>[];

    for (final a in sheet.allocations) {
      items.add({
        'name': a.name,
        'amount': a.amount,
        'type': a.type,
      });
    }

    for (final g in sheet.goals) {
      items.add({
        'name': g.name,
        'amount': g.amount,
        'type': 'goal',
      });
    }

    return jsonEncode(items);
  }
}
