import 'base_repository.dart';
import '../models/transaction.dart';

class TransactionRepository extends BaseRepository<Transaction> {
  @override
  String get tableName => 'transactions';

  @override
  Transaction fromMap(Map<String, dynamic> map) => Transaction.fromMap(map);

  @override
  Map<String, dynamic> toMap(Transaction entity) => entity.toMap();

  Future<List<Transaction>> getByUserId(int userId, {int? limit}) async {
    final results = await db.query(
      tableName,
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'date DESC',
      limit: limit,
    );
    return results.map((map) => fromMap(map)).toList();
  }

  Future<List<Transaction>> getByDateRange(
    int userId,
    DateTime start,
    DateTime end,
  ) async {
    final startTs = start.millisecondsSinceEpoch ~/ 1000;
    final endTs = end.millisecondsSinceEpoch ~/ 1000;

    final results = await db.query(
      tableName,
      where: 'user_id = ? AND date >= ? AND date <= ?',
      whereArgs: [userId, startTs, endTs],
      orderBy: 'date DESC',
    );
    return results.map((map) => fromMap(map)).toList();
  }

  Future<double> getMonthlySpending(int userId, {DateTime? month}) async {
    final targetMonth = month ?? DateTime.now();
    final start = DateTime(targetMonth.year, targetMonth.month, 1);
    final end = DateTime(targetMonth.year, targetMonth.month + 1, 0, 23, 59, 59);

    final transactions = await getByDateRange(userId, start, end);
    return transactions.fold<double>(0.0, (sum, t) => sum + t.amount);
  }

  Future<int> addTransaction({
    required int userId,
    required double amount,
    required String category,
    String? description,
    DateTime? date,
    bool isPlanned = false,
    int? plannedExpenseId,
  }) async {
    final transactionDate = date ?? DateTime.now();
    final transaction = Transaction(
      userId: userId,
      amount: amount,
      category: category,
      description: description,
      date: transactionDate.millisecondsSinceEpoch ~/ 1000,
      isPlanned: isPlanned,
      plannedExpenseId: plannedExpenseId,
      createdAt: timestamp,
    );
    return await insert(transaction);
  }
}
