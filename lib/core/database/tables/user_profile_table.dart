import '../table_definition.dart';

class UserProfileTable extends TableDefinition {
  @override
  String get tableName => 'user_profile';

  @override
  int get version => 2;

  @override
  String get createTableSQL => '''
    CREATE TABLE IF NOT EXISTS user_profile (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      currency TEXT NOT NULL DEFAULT 'INR',
      risk_level TEXT NOT NULL DEFAULT 'moderate',
      dependents INTEGER NOT NULL DEFAULT 0,
      salary_day INTEGER NOT NULL DEFAULT 1,
      created_at INTEGER NOT NULL,
      updated_at INTEGER NOT NULL
    )
  ''';

  @override
  List<String> getMigrationSQL(int fromVersion, int toVersion) {
    final migrations = <String>[];

    if (fromVersion < 2 && toVersion >= 2) {
      migrations.add('ALTER TABLE user_profile ADD COLUMN salary_day INTEGER NOT NULL DEFAULT 1');
    }

    return migrations;
  }
}
