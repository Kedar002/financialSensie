import '../table_definition.dart';

class VariableExpensesTable extends TableDefinition {
  @override
  String get tableName => 'variable_expenses';

  @override
  String get createTableSQL => '''
    CREATE TABLE IF NOT EXISTS variable_expenses (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      user_id INTEGER NOT NULL,
      category TEXT NOT NULL,
      estimated_amount REAL NOT NULL,
      is_essential INTEGER NOT NULL DEFAULT 0,
      created_at INTEGER NOT NULL,
      updated_at INTEGER NOT NULL,
      FOREIGN KEY (user_id) REFERENCES user_profile (id)
    )
  ''';

  @override
  List<String> get indexes => [
    'CREATE INDEX IF NOT EXISTS idx_variable_user ON variable_expenses (user_id)',
  ];
}
