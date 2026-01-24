import '../table_definition.dart';

class FinancialSnapshotTable extends TableDefinition {
  @override
  String get tableName => 'financial_snapshot';

  @override
  String get createTableSQL => '''
    CREATE TABLE IF NOT EXISTS financial_snapshot (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      user_id INTEGER NOT NULL,
      month TEXT NOT NULL,
      total_income REAL NOT NULL,
      total_fixed_expenses REAL NOT NULL,
      total_variable_expenses REAL NOT NULL,
      total_savings REAL NOT NULL,
      safe_to_spend_budget REAL NOT NULL,
      actual_spent REAL NOT NULL DEFAULT 0,
      emergency_fund_balance REAL NOT NULL,
      created_at INTEGER NOT NULL,
      FOREIGN KEY (user_id) REFERENCES user_profile (id)
    )
  ''';

  @override
  List<String> get indexes => [
    'CREATE INDEX IF NOT EXISTS idx_snapshot_user_month ON financial_snapshot (user_id, month)',
  ];
}
