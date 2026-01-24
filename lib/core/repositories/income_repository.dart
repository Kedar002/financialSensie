import 'base_repository.dart';
import '../models/income_source.dart';

class IncomeRepository extends BaseRepository<IncomeSource> {
  @override
  String get tableName => 'income_sources';

  @override
  IncomeSource fromMap(Map<String, dynamic> map) => IncomeSource.fromMap(map);

  @override
  Map<String, dynamic> toMap(IncomeSource entity) => entity.toMap();

  Future<List<IncomeSource>> getByUserId(int userId, {bool activeOnly = true}) async {
    final where = activeOnly ? 'user_id = ? AND is_active = 1' : 'user_id = ?';
    final results = await db.query(
      tableName,
      where: where,
      whereArgs: [userId],
      orderBy: 'amount DESC',
    );
    return results.map((map) => fromMap(map)).toList();
  }

  Future<double> getTotalMonthlyIncome(int userId) async {
    final sources = await getByUserId(userId);
    return sources.fold<double>(0.0, (sum, source) => sum + source.monthlyAmount);
  }

  Future<int> addIncome({
    required int userId,
    required String name,
    required double amount,
    String frequency = 'monthly',
    int? payDay,
  }) async {
    final income = IncomeSource(
      userId: userId,
      name: name,
      amount: amount,
      frequency: frequency,
      payDay: payDay,
      createdAt: timestamp,
      updatedAt: timestamp,
    );
    return await insert(income);
  }
}
