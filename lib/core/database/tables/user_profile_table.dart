import '../table_definition.dart';

class UserProfileTable extends TableDefinition {
  @override
  String get tableName => 'user_profile';

  @override
  String get createTableSQL => '''
    CREATE TABLE IF NOT EXISTS user_profile (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      currency TEXT NOT NULL DEFAULT 'INR',
      risk_level TEXT NOT NULL DEFAULT 'moderate',
      dependents INTEGER NOT NULL DEFAULT 0,
      created_at INTEGER NOT NULL,
      updated_at INTEGER NOT NULL
    )
  ''';
}
