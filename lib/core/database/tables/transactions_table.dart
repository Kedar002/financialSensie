import '../table_definition.dart';

class TransactionsTable extends TableDefinition {
  @override
  String get tableName => 'transactions';

  @override
  String get createTableSQL => '''
    CREATE TABLE IF NOT EXISTS transactions (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      user_id INTEGER NOT NULL,
      amount REAL NOT NULL,
      category TEXT NOT NULL,
      description TEXT,
      date INTEGER NOT NULL,
      is_planned INTEGER NOT NULL DEFAULT 0,
      planned_expense_id INTEGER,
      created_at INTEGER NOT NULL,
      FOREIGN KEY (user_id) REFERENCES user_profile (id),
      FOREIGN KEY (planned_expense_id) REFERENCES planned_expenses (id)
    )
  ''';

  @override
  List<String> get indexes => [
    'CREATE INDEX IF NOT EXISTS idx_trans_user_date ON transactions (user_id, date)',
  ];
}
