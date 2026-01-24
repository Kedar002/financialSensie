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

  Future<int> createUser(String name, {String currency = 'INR'}) async {
    final user = UserProfile(
      name: name,
      currency: currency,
      createdAt: timestamp,
      updatedAt: timestamp,
    );
    return await insert(user);
  }

  Future<bool> hasUser() async {
    final user = await getCurrentUser();
    return user != null;
  }
}
