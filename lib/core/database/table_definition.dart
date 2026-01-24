/// Abstract base for all table definitions.
/// Following Open/Closed Principle - extend to add new tables,
/// never modify existing ones.
abstract class TableDefinition {
  String get tableName;
  String get createTableSQL;
  List<String> get indexes => [];

  int get version => 1;

  List<String> getMigrationSQL(int fromVersion, int toVersion) => [];
}
