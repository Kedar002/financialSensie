import '../table_definition.dart';

/// Table for tracking monthly savings totals.
class SavingsTrackerTable extends TableDefinition {
  @override
  String get tableName => 'savings_tracker';

  @override
  int get version => 4;

  @override
  String get createTableSQL => '''
    CREATE TABLE savings_tracker (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      user_id INTEGER NOT NULL,
      month TEXT NOT NULL,
      emergency_fund_balance REAL NOT NULL DEFAULT 0,
      investment_total REAL NOT NULL DEFAULT 0,
      goals_total REAL NOT NULL DEFAULT 0,
      completed_goals_total REAL NOT NULL DEFAULT 0,
      total_savings REAL NOT NULL DEFAULT 0,
      recorded_at INTEGER NOT NULL,
      FOREIGN KEY (user_id) REFERENCES user_profile(id) ON DELETE CASCADE,
      UNIQUE (user_id, month)
    )
  ''';

  @override
  List<String> get indexes => [
    'CREATE INDEX idx_savings_tracker_user ON savings_tracker(user_id)',
    'CREATE INDEX idx_savings_tracker_month ON savings_tracker(month)',
  ];

  @override
  List<String> getMigrationSQL(int fromVersion, int toVersion) {
    final migrations = <String>[];

    // New table added in version 4
    if (fromVersion < 4 && toVersion >= 4) {
      migrations.add(createTableSQL);
      migrations.addAll(indexes);
    }

    return migrations;
  }
}
