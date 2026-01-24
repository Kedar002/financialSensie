import '../table_definition.dart';

class FixedExpensesTable extends TableDefinition {
  @override
  String get tableName => 'fixed_expenses';

  @override
  String get createTableSQL => '''
    CREATE TABLE IF NOT EXISTS fixed_expenses (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      user_id INTEGER NOT NULL,
      name TEXT NOT NULL,
      amount REAL NOT NULL,
      category TEXT NOT NULL,
      is_essential INTEGER NOT NULL DEFAULT 1,
      due_day INTEGER,
      is_active INTEGER NOT NULL DEFAULT 1,
      created_at INTEGER NOT NULL,
      updated_at INTEGER NOT NULL,
      FOREIGN KEY (user_id) REFERENCES user_profile (id)
    )
  ''';

  @override
  List<String> get indexes => [
    'CREATE INDEX IF NOT EXISTS idx_fixed_user ON fixed_expenses (user_id)',
  ];
}
