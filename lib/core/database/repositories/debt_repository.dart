import 'package:uuid/uuid.dart';
import '../database_service.dart';
import '../amount_converter.dart';

/// Debt priority based on interest rate.
enum DebtPriority { high, medium, low }

/// Repository for debts and debt_payments tables.
class DebtRepository {
  final DatabaseService _db = DatabaseService();
  final Uuid _uuid = const Uuid();

  // ============ DEBTS ============

  /// Get all active debts ordered by interest rate (highest first).
  Future<List<Map<String, dynamic>>> getActiveDebts() async {
    final db = await _db.database;
    return await db.query(
      'debts',
      where: "status = 'active' AND deleted_at IS NULL",
      orderBy: 'interest_rate DESC',
    );
  }

  /// Get all debts (including paid off).
  Future<List<Map<String, dynamic>>> getAllDebts() async {
    final db = await _db.database;
    return await db.query(
      'debts',
      where: 'deleted_at IS NULL',
      orderBy: 'status ASC, interest_rate DESC',
    );
  }

  /// Get debt by ID.
  Future<Map<String, dynamic>?> getById(String id) async {
    final db = await _db.database;
    final results = await db.query(
      'debts',
      where: 'id = ?',
      whereArgs: [id],
    );
    return results.isEmpty ? null : results.first;
  }

  /// Get total remaining debt.
  Future<int> getTotalRemaining() async {
    final db = await _db.database;
    final result = await db.rawQuery('''
      SELECT SUM(remaining_amount) as total
      FROM debts
      WHERE status = 'active' AND deleted_at IS NULL
    ''');
    return (result.first['total'] as int?) ?? 0;
  }

  /// Calculate priority for a debt based on interest rate.
  static DebtPriority calculatePriority(double interestRate) {
    if (interestRate > 15) return DebtPriority.high;
    if (interestRate >= 8) return DebtPriority.medium;
    return DebtPriority.low;
  }

  /// Insert a new debt.
  Future<String> insert({
    required String name,
    String? lender,
    required double totalAmount,
    double? remainingAmount,
    required double interestRate,
    double minimumPayment = 0,
  }) async {
    final db = await _db.database;
    final id = _uuid.v4();
    final now = DateTime.now().toIso8601String();
    final totalPaise = AmountConverter.toPaise(totalAmount);

    await db.insert('debts', {
      'id': id,
      'name': name,
      'lender': lender,
      'total_amount': totalPaise,
      'remaining_amount':
          remainingAmount != null
              ? AmountConverter.toPaise(remainingAmount)
              : totalPaise,
      'interest_rate': interestRate,
      'minimum_payment': AmountConverter.toPaise(minimumPayment),
      'status': 'active',
      'created_at': now,
      'updated_at': now,
    });

    return id;
  }

  /// Update a debt.
  Future<void> update(
    String id, {
    String? name,
    String? lender,
    double? totalAmount,
    double? remainingAmount,
    double? interestRate,
    double? minimumPayment,
    String? status,
  }) async {
    final db = await _db.database;
    final updates = <String, dynamic>{
      'updated_at': DateTime.now().toIso8601String(),
    };

    if (name != null) updates['name'] = name;
    if (lender != null) updates['lender'] = lender;
    if (totalAmount != null) {
      updates['total_amount'] = AmountConverter.toPaise(totalAmount);
    }
    if (remainingAmount != null) {
      updates['remaining_amount'] = AmountConverter.toPaise(remainingAmount);
    }
    if (interestRate != null) updates['interest_rate'] = interestRate;
    if (minimumPayment != null) {
      updates['minimum_payment'] = AmountConverter.toPaise(minimumPayment);
    }
    if (status != null) updates['status'] = status;

    await db.update(
      'debts',
      updates,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Soft delete a debt.
  Future<void> delete(String id) async {
    final db = await _db.database;
    await db.update(
      'debts',
      {
        'deleted_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ============ PAYMENTS ============

  /// Get payments for a debt.
  Future<List<Map<String, dynamic>>> getPayments(String debtId) async {
    final db = await _db.database;
    return await db.query(
      'debt_payments',
      where: 'debt_id = ?',
      whereArgs: [debtId],
      orderBy: 'date DESC, created_at DESC',
    );
  }

  /// Add a payment to a debt.
  /// Also updates the debt's remaining_amount.
  Future<String> addPayment({
    required String debtId,
    required double amount,
    String? expenseId,
    DateTime? date,
    String? note,
  }) async {
    final db = await _db.database;
    final id = _uuid.v4();
    final now = DateTime.now();
    final amountPaise = AmountConverter.toPaise(amount);

    // Insert payment
    await db.insert('debt_payments', {
      'id': id,
      'debt_id': debtId,
      'expense_id': expenseId,
      'amount': amountPaise,
      'date': (date ?? now).toIso8601String().split('T')[0],
      'note': note,
      'created_at': now.toIso8601String(),
    });

    // Update debt's remaining_amount
    await db.rawUpdate('''
      UPDATE debts
      SET remaining_amount = remaining_amount - ?,
          updated_at = ?,
          status = CASE
            WHEN remaining_amount - ? <= 0 THEN 'paid_off'
            ELSE status
          END,
          paid_off_at = CASE
            WHEN remaining_amount - ? <= 0 THEN ?
            ELSE paid_off_at
          END
      WHERE id = ?
    ''', [
      amountPaise,
      now.toIso8601String(),
      amountPaise,
      amountPaise,
      now.toIso8601String(),
      debtId,
    ]);

    return id;
  }

  /// Get total paid for a debt.
  Future<int> getTotalPaid(String debtId) async {
    final db = await _db.database;
    final result = await db.rawQuery('''
      SELECT SUM(amount) as total
      FROM debt_payments
      WHERE debt_id = ?
    ''', [debtId]);
    return (result.first['total'] as int?) ?? 0;
  }
}
