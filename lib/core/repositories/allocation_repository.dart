import 'base_repository.dart';
import '../models/allocation.dart';

class AllocationRepository extends BaseRepository<Allocation> {
  @override
  String get tableName => 'allocations';

  @override
  Allocation fromMap(Map<String, dynamic> map) => Allocation.fromMap(map);

  @override
  Map<String, dynamic> toMap(Allocation entity) => entity.toMap();

  Future<List<Allocation>> getByUserId(int userId, {bool activeOnly = true}) async {
    final where = activeOnly ? 'user_id = ? AND is_active = 1' : 'user_id = ?';
    final results = await db.query(
      tableName,
      where: where,
      whereArgs: [userId],
      orderBy: 'priority ASC',
    );
    return results.map((map) => fromMap(map)).toList();
  }

  Future<double> getTotalAllocations(int userId, double totalIncome) async {
    final allocations = await getByUserId(userId);
    return allocations.fold<double>(
      0.0,
      (sum, alloc) => sum + alloc.calculateAmount(totalIncome),
    );
  }

  Future<int> addAllocation({
    required int userId,
    required String type,
    required String name,
    double? percentage,
    double? fixedAmount,
    required int priority,
  }) async {
    final allocation = Allocation(
      userId: userId,
      type: type,
      name: name,
      percentage: percentage,
      fixedAmount: fixedAmount,
      priority: priority,
      createdAt: timestamp,
    );
    return await insert(allocation);
  }
}
