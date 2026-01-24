import '../table_definition.dart';

class AllocationsTable extends TableDefinition {
  @override
  String get tableName => 'allocations';

  @override
  String get createTableSQL => '''
    CREATE TABLE IF NOT EXISTS allocations (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      user_id INTEGER NOT NULL,
      type TEXT NOT NULL,
      name TEXT NOT NULL,
      percentage REAL,
      fixed_amount REAL,
      priority INTEGER NOT NULL,
      is_active INTEGER NOT NULL DEFAULT 1,
      created_at INTEGER NOT NULL,
      FOREIGN KEY (user_id) REFERENCES user_profile (id)
    )
  ''';

  @override
  List<String> get indexes => [
    'CREATE INDEX IF NOT EXISTS idx_alloc_user ON allocations (user_id)',
  ];
}
