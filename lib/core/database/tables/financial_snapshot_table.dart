import '../table_definition.dart';

class FinancialSnapshotTable extends TableDefinition {
  @override
  String get tableName => 'financial_snapshot';

  @override
  int get version => 3;

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
      emergency_fund_target REAL NOT NULL DEFAULT 0,
      needs_percent REAL NOT NULL DEFAULT 0,
      wants_percent REAL NOT NULL DEFAULT 0,
      savings_percent REAL NOT NULL DEFAULT 0,
      safe_to_spend_percent REAL NOT NULL DEFAULT 0,
      income_breakdown TEXT,
      needs_breakdown TEXT,
      wants_breakdown TEXT,
      savings_breakdown TEXT,
      created_at INTEGER NOT NULL,
      FOREIGN KEY (user_id) REFERENCES user_profile (id)
    )
  ''';

  @override
  List<String> get indexes => [
    'CREATE INDEX IF NOT EXISTS idx_snapshot_user_month ON financial_snapshot (user_id, month)',
  ];

  @override
  List<String> getMigrationSQL(int fromVersion, int toVersion) {
    final migrations = <String>[];

    if (fromVersion < 3 && toVersion >= 3) {
      // Add new columns for enhanced snapshot storage
      migrations.add('ALTER TABLE financial_snapshot ADD COLUMN emergency_fund_target REAL NOT NULL DEFAULT 0');
      migrations.add('ALTER TABLE financial_snapshot ADD COLUMN needs_percent REAL NOT NULL DEFAULT 0');
      migrations.add('ALTER TABLE financial_snapshot ADD COLUMN wants_percent REAL NOT NULL DEFAULT 0');
      migrations.add('ALTER TABLE financial_snapshot ADD COLUMN savings_percent REAL NOT NULL DEFAULT 0');
      migrations.add('ALTER TABLE financial_snapshot ADD COLUMN safe_to_spend_percent REAL NOT NULL DEFAULT 0');
      migrations.add('ALTER TABLE financial_snapshot ADD COLUMN income_breakdown TEXT');
      migrations.add('ALTER TABLE financial_snapshot ADD COLUMN needs_breakdown TEXT');
      migrations.add('ALTER TABLE financial_snapshot ADD COLUMN wants_breakdown TEXT');
      migrations.add('ALTER TABLE financial_snapshot ADD COLUMN savings_breakdown TEXT');
    }

    return migrations;
  }
}
