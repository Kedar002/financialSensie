import 'base_repository.dart';
import '../models/user_profile.dart';

class UserRepository extends BaseRepository<UserProfile> {
  @override
  String get tableName => 'user_profile';

  @override
  UserProfile fromMap(Map<String, dynamic> map) => UserProfile.fromMap(map);

  @override
  Map<String, dynamic> toMap(UserProfile entity) => entity.toMap();

  Future<UserProfile?> getCurrentUser() async {
    final results = await db.query(tableName, limit: 1);
    if (results.isEmpty) return null;
    return fromMap(results.first);
  }

  Future<int> createUser(String name, {String currency = 'INR', int salaryDay = 1}) async {
    final user = UserProfile(
      name: name,
      currency: currency,
      salaryDay: salaryDay,
      createdAt: timestamp,
      updatedAt: timestamp,
    );
    return await insert(user);
  }

  Future<bool> hasUser() async {
    final user = await getCurrentUser();
    return user != null;
  }

  Future<int> updateSalaryDay(int userId, int salaryDay) async {
    return await db.update(
      tableName,
      {
        'salary_day': salaryDay.clamp(1, 28),
        'updated_at': timestamp,
      },
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  /// Get current payment cycle dates for the user
  Future<PaymentCycle?> getCurrentPaymentCycle() async {
    final user = await getCurrentUser();
    if (user == null) return null;

    return PaymentCycle(
      startDate: user.currentCycleStart,
      endDate: user.currentCycleEnd,
      daysRemaining: user.daysRemainingInCycle,
      salaryDay: user.salaryDay,
    );
  }
}

class PaymentCycle {
  final DateTime startDate;
  final DateTime endDate;
  final int daysRemaining;
  final int salaryDay;

  const PaymentCycle({
    required this.startDate,
    required this.endDate,
    required this.daysRemaining,
    required this.salaryDay,
  });

  int get totalDays => endDate.difference(startDate).inDays + 1;
  int get daysPassed => totalDays - daysRemaining;
}
