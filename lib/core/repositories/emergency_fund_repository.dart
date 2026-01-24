import 'base_repository.dart';
import '../models/emergency_fund.dart';

class EmergencyFundRepository extends BaseRepository<EmergencyFund> {
  @override
  String get tableName => 'emergency_fund';

  @override
  EmergencyFund fromMap(Map<String, dynamic> map) => EmergencyFund.fromMap(map);

  @override
  Map<String, dynamic> toMap(EmergencyFund entity) => entity.toMap();

  Future<EmergencyFund?> getByUserId(int userId) async {
    final results = await db.query(
      tableName,
      where: 'user_id = ?',
      whereArgs: [userId],
      limit: 1,
    );
    if (results.isEmpty) return null;
    return fromMap(results.first);
  }

  Future<int> createOrUpdate({
    required int userId,
    required double targetAmount,
    required double monthlyEssential,
    double currentAmount = 0,
    int targetMonths = 6,
  }) async {
    final existing = await getByUserId(userId);

    final fund = EmergencyFund(
      id: existing?.id,
      userId: userId,
      targetAmount: targetAmount,
      currentAmount: currentAmount,
      targetMonths: targetMonths,
      monthlyEssential: monthlyEssential,
      updatedAt: timestamp,
    );

    if (existing != null) {
      return await update(fund, existing.id!);
    }
    return await insert(fund);
  }

  Future<int> updateCurrentAmount(int userId, double amount) async {
    return await db.update(
      tableName,
      {'current_amount': amount, 'updated_at': timestamp},
      where: 'user_id = ?',
      whereArgs: [userId],
    );
  }

  Future<int> addToFund(int userId, double amount) async {
    final fund = await getByUserId(userId);
    if (fund == null) return 0;

    final newAmount = fund.currentAmount + amount;
    return await updateCurrentAmount(userId, newAmount);
  }
}
