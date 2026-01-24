import '../table_definition.dart';

class EmergencyFundTable extends TableDefinition {
  @override
  String get tableName => 'emergency_fund';

  @override
  String get createTableSQL => '''
    CREATE TABLE IF NOT EXISTS emergency_fund (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      user_id INTEGER NOT NULL UNIQUE,
      target_amount REAL NOT NULL,
      current_amount REAL NOT NULL DEFAULT 0,
      target_months INTEGER NOT NULL DEFAULT 6,
      monthly_essential REAL NOT NULL,
      updated_at INTEGER NOT NULL,
      FOREIGN KEY (user_id) REFERENCES user_profile (id)
    )
  ''';
}
