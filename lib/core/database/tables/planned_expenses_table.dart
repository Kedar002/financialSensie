import '../table_definition.dart';

class PlannedExpensesTable extends TableDefinition {
  @override
  String get tableName => 'planned_expenses';

  @override
  String get createTableSQL => '''
    CREATE TABLE IF NOT EXISTS planned_expenses (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      user_id INTEGER NOT NULL,
      name TEXT NOT NULL,
      target_amount REAL NOT NULL,
      current_amount REAL NOT NULL DEFAULT 0,
      target_date INTEGER NOT NULL,
      monthly_required REAL NOT NULL,
      priority INTEGER NOT NULL DEFAULT 1,
      status TEXT NOT NULL DEFAULT 'active',
      created_at INTEGER NOT NULL,
      updated_at INTEGER NOT NULL,
      FOREIGN KEY (user_id) REFERENCES user_profile (id)
    )
  ''';

  @override
  List<String> get indexes => [
    'CREATE INDEX IF NOT EXISTS idx_planned_user_status ON planned_expenses (user_id, status)',
  ];
}
