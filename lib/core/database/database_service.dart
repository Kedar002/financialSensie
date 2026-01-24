import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

import 'table_definition.dart';
import 'tables/user_profile_table.dart';
import 'tables/income_sources_table.dart';
import 'tables/fixed_expenses_table.dart';
import 'tables/variable_expenses_table.dart';
import 'tables/emergency_fund_table.dart';
import 'tables/allocations_table.dart';
import 'tables/planned_expenses_table.dart';
import 'tables/transactions_table.dart';
import 'tables/financial_snapshot_table.dart';

/// Database service following Open/Closed Principle.
/// To add new tables, simply add them to [_tables] list.
class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static Database? _database;

  factory DatabaseService() => _instance;

  DatabaseService._internal();

  /// All table definitions - add new tables here.
  /// Order matters for foreign key constraints.
  final List<TableDefinition> _tables = [
    UserProfileTable(),
    IncomeSourcesTable(),
    FixedExpensesTable(),
    VariableExpensesTable(),
    EmergencyFundTable(),
    AllocationsTable(),
    PlannedExpensesTable(),
    TransactionsTable(),
    FinancialSnapshotTable(),
  ];

  static const int _version = 1;
  static const String _dbName = 'financesensei.db';

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);

    return await openDatabase(
      path,
      version: _version,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onConfigure: _onConfigure,
    );
  }

  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future<void> _onCreate(Database db, int version) async {
    for (final table in _tables) {
      await db.execute(table.createTableSQL);
      for (final index in table.indexes) {
        await db.execute(index);
      }
    }
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    for (final table in _tables) {
      final migrations = table.getMigrationSQL(oldVersion, newVersion);
      for (final sql in migrations) {
        await db.execute(sql);
      }
    }
  }

  Future<int> insert(String table, Map<String, dynamic> data) async {
    final db = await database;
    return await db.insert(table, data);
  }

  Future<List<Map<String, dynamic>>> query(
    String table, {
    String? where,
    List<dynamic>? whereArgs,
    String? orderBy,
    int? limit,
  }) async {
    final db = await database;
    return await db.query(
      table,
      where: where,
      whereArgs: whereArgs,
      orderBy: orderBy,
      limit: limit,
    );
  }

  Future<int> update(
    String table,
    Map<String, dynamic> data, {
    String? where,
    List<dynamic>? whereArgs,
  }) async {
    final db = await database;
    return await db.update(table, data, where: where, whereArgs: whereArgs);
  }

  Future<int> delete(
    String table, {
    String? where,
    List<dynamic>? whereArgs,
  }) async {
    final db = await database;
    return await db.delete(table, where: where, whereArgs: whereArgs);
  }

  Future<List<Map<String, dynamic>>> rawQuery(
    String sql, [
    List<dynamic>? args,
  ]) async {
    final db = await database;
    return await db.rawQuery(sql, args);
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }
}
