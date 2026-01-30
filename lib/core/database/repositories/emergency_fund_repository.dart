import 'package:uuid/uuid.dart';
import '../database_service.dart';
import '../amount_converter.dart';

/// Repository for emergency_fund and fund_contributions tables.
class EmergencyFundRepository {
  final DatabaseService _db = DatabaseService();
  final Uuid _uuid = const Uuid();
  static const String _defaultFundId = 'default_fund';

  // ============ EMERGENCY FUND ============

  /// Get the emergency fund.
  Future<Map<String, dynamic>?> getFund() async {
    final db = await _db.database;
    final results = await db.query(
      'emergency_fund',
      where: 'id = ?',
      whereArgs: [_defaultFundId],
    );
    return results.isEmpty ? null : results.first;
  }

  /// Get current amount in paise.
  Future<int> getCurrentAmount() async {
    final fund = await getFund();
    return (fund?['current_amount'] as int?) ?? 0;
  }

  /// Get target months.
  Future<int> getTargetMonths() async {
    final fund = await getFund();
    return (fund?['target_months'] as int?) ?? 6;
  }

  /// Get monthly essentials in paise.
  Future<int> getMonthlyEssentials() async {
    final fund = await getFund();
    return (fund?['monthly_essentials'] as int?) ?? 0;
  }

  /// Calculate target amount based on monthly essentials and target months.
  Future<int> getTargetAmount() async {
    final monthlyEssentials = await getMonthlyEssentials();
    final targetMonths = await getTargetMonths();
    return monthlyEssentials * targetMonths;
  }

  /// Calculate runway months (how long the fund would last).
  Future<double> getRunwayMonths() async {
    final currentAmount = await getCurrentAmount();
    final monthlyEssentials = await getMonthlyEssentials();
    if (monthlyEssentials == 0) return 0;
    return currentAmount / monthlyEssentials;
  }

  /// Update emergency fund settings.
  Future<void> update({
    int? targetMonths,
    int? monthlyEssentials,
    String? instrument,
  }) async {
    final db = await _db.database;
    final updates = <String, dynamic>{
      'updated_at': DateTime.now().toIso8601String(),
    };

    if (targetMonths != null) updates['target_months'] = targetMonths;
    if (monthlyEssentials != null) {
      updates['monthly_essentials'] = monthlyEssentials;
    }
    if (instrument != null) updates['instrument'] = instrument;

    await db.update(
      'emergency_fund',
      updates,
      where: 'id = ?',
      whereArgs: [_defaultFundId],
    );
  }

  /// Update monthly essentials from settings.
  /// Call this when income or needs_percent changes.
  Future<void> syncMonthlyEssentials(int monthlyEssentials) async {
    await update(monthlyEssentials: monthlyEssentials);
  }

  // ============ CONTRIBUTIONS ============

  /// Get all contributions.
  Future<List<Map<String, dynamic>>> getContributions() async {
    final db = await _db.database;
    return await db.query(
      'fund_contributions',
      where: 'fund_id = ?',
      whereArgs: [_defaultFundId],
      orderBy: 'date DESC, created_at DESC',
    );
  }

  /// Add a contribution to the emergency fund.
  /// Also updates the fund's current_amount.
  Future<String> addContribution({
    required double amount,
    String? expenseId,
    String type = 'contribution',
    DateTime? date,
    String? note,
  }) async {
    final db = await _db.database;
    final id = _uuid.v4();
    final now = DateTime.now();
    final amountPaise = AmountConverter.toPaise(amount);

    // Insert contribution
    await db.insert('fund_contributions', {
      'id': id,
      'fund_id': _defaultFundId,
      'expense_id': expenseId,
      'amount': amountPaise,
      'type': type,
      'date': (date ?? now).toIso8601String().split('T')[0],
      'note': note,
      'created_at': now.toIso8601String(),
    });

    // Update fund's current_amount
    await db.rawUpdate('''
      UPDATE emergency_fund
      SET current_amount = current_amount + ?,
          updated_at = ?
      WHERE id = ?
    ''', [amountPaise, now.toIso8601String(), _defaultFundId]);

    return id;
  }

  /// Reverse a contribution (for expense deletion).
  Future<void> reverseContribution({
    required double amount,
    required String expenseId,
    String? note,
  }) async {
    await addContribution(
      amount: -amount,
      expenseId: expenseId,
      type: 'withdrawal',
      note: note ?? 'Reversed: expense deleted',
    );
  }

  /// Adjust a contribution (for expense amount change).
  Future<void> adjustContribution({
    required double difference,
    required String expenseId,
    String? note,
  }) async {
    if (difference == 0) return;
    await addContribution(
      amount: difference,
      expenseId: expenseId,
      type: 'adjustment',
      note: note ?? 'Adjusted: expense modified',
    );
  }
}
