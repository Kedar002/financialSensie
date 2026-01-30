import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

/// Database service - single entry point for all database operations.
/// Handles initialization, migrations, and provides access to the database.
class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static Database? _database;

  DatabaseService._internal();

  factory DatabaseService() => _instance;

  /// Get the database instance, initializing if needed.
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// Initialize the database.
  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'financesensei.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onConfigure: _onConfigure,
    );
  }

  /// Configure database settings.
  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  /// Create initial schema (version 1).
  Future<void> _onCreate(Database db, int version) async {
    // Settings table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS app_settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL,
        updated_at TEXT NOT NULL DEFAULT (datetime('now'))
      )
    ''');

    // Expenses table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS expenses (
        id TEXT PRIMARY KEY,
        amount INTEGER NOT NULL CHECK (amount > 0),
        category TEXT NOT NULL CHECK (category IN ('needs', 'wants', 'savings')),
        subcategory TEXT NOT NULL,
        goal_id TEXT,
        is_fund_contribution INTEGER NOT NULL DEFAULT 0,
        date TEXT NOT NULL,
        note TEXT,
        created_at TEXT NOT NULL DEFAULT (datetime('now')),
        updated_at TEXT NOT NULL DEFAULT (datetime('now')),
        deleted_at TEXT,
        FOREIGN KEY (goal_id) REFERENCES goals(id) ON DELETE SET NULL
      )
    ''');

    // Goals table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS goals (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        target_amount INTEGER NOT NULL CHECK (target_amount > 0),
        current_amount INTEGER NOT NULL DEFAULT 0,
        target_date TEXT NOT NULL,
        instrument TEXT NOT NULL,
        status TEXT NOT NULL DEFAULT 'active',
        completed_at TEXT,
        created_at TEXT NOT NULL DEFAULT (datetime('now')),
        updated_at TEXT NOT NULL DEFAULT (datetime('now')),
        deleted_at TEXT
      )
    ''');

    // Goal contributions table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS goal_contributions (
        id TEXT PRIMARY KEY,
        goal_id TEXT NOT NULL,
        expense_id TEXT,
        amount INTEGER NOT NULL,
        type TEXT NOT NULL DEFAULT 'contribution',
        date TEXT NOT NULL,
        note TEXT,
        created_at TEXT NOT NULL DEFAULT (datetime('now')),
        FOREIGN KEY (goal_id) REFERENCES goals(id) ON DELETE CASCADE,
        FOREIGN KEY (expense_id) REFERENCES expenses(id) ON DELETE SET NULL
      )
    ''');

    // Emergency fund table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS emergency_fund (
        id TEXT PRIMARY KEY DEFAULT 'default_fund',
        current_amount INTEGER NOT NULL DEFAULT 0,
        target_months INTEGER NOT NULL DEFAULT 6,
        monthly_essentials INTEGER NOT NULL DEFAULT 0,
        instrument TEXT NOT NULL DEFAULT 'savings_account',
        updated_at TEXT NOT NULL DEFAULT (datetime('now'))
      )
    ''');

    // Fund contributions table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS fund_contributions (
        id TEXT PRIMARY KEY,
        fund_id TEXT NOT NULL DEFAULT 'default_fund',
        expense_id TEXT,
        amount INTEGER NOT NULL,
        type TEXT NOT NULL DEFAULT 'contribution',
        date TEXT NOT NULL,
        note TEXT,
        created_at TEXT NOT NULL DEFAULT (datetime('now')),
        FOREIGN KEY (fund_id) REFERENCES emergency_fund(id) ON DELETE CASCADE,
        FOREIGN KEY (expense_id) REFERENCES expenses(id) ON DELETE SET NULL
      )
    ''');

    // Debts table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS debts (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        lender TEXT,
        total_amount INTEGER NOT NULL CHECK (total_amount > 0),
        remaining_amount INTEGER NOT NULL CHECK (remaining_amount >= 0),
        interest_rate REAL NOT NULL CHECK (interest_rate >= 0),
        minimum_payment INTEGER NOT NULL DEFAULT 0,
        status TEXT NOT NULL DEFAULT 'active',
        paid_off_at TEXT,
        created_at TEXT NOT NULL DEFAULT (datetime('now')),
        updated_at TEXT NOT NULL DEFAULT (datetime('now')),
        deleted_at TEXT
      )
    ''');

    // Debt payments table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS debt_payments (
        id TEXT PRIMARY KEY,
        debt_id TEXT NOT NULL,
        expense_id TEXT,
        amount INTEGER NOT NULL CHECK (amount > 0),
        date TEXT NOT NULL,
        note TEXT,
        created_at TEXT NOT NULL DEFAULT (datetime('now')),
        FOREIGN KEY (debt_id) REFERENCES debts(id) ON DELETE CASCADE,
        FOREIGN KEY (expense_id) REFERENCES expenses(id) ON DELETE SET NULL
      )
    ''');

    // Monthly snapshots table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS monthly_snapshots (
        id TEXT PRIMARY KEY,
        year INTEGER NOT NULL,
        month INTEGER NOT NULL CHECK (month BETWEEN 1 AND 12),
        total_budget INTEGER NOT NULL DEFAULT 0,
        needs_budget INTEGER NOT NULL DEFAULT 0,
        wants_budget INTEGER NOT NULL DEFAULT 0,
        savings_budget INTEGER NOT NULL DEFAULT 0,
        total_spent INTEGER NOT NULL DEFAULT 0,
        needs_spent INTEGER NOT NULL DEFAULT 0,
        wants_spent INTEGER NOT NULL DEFAULT 0,
        savings_spent INTEGER NOT NULL DEFAULT 0,
        remaining INTEGER NOT NULL DEFAULT 0,
        transaction_count INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL DEFAULT (datetime('now')),
        updated_at TEXT NOT NULL DEFAULT (datetime('now')),
        UNIQUE(year, month)
      )
    ''');

    // Create indexes
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_expenses_date ON expenses(date) WHERE deleted_at IS NULL');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_expenses_category ON expenses(category) WHERE deleted_at IS NULL');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_goals_status ON goals(status) WHERE deleted_at IS NULL');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_debts_status ON debts(status) WHERE deleted_at IS NULL');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_snapshots_date ON monthly_snapshots(year DESC, month DESC)');

    // Insert default settings
    await _insertDefaultSettings(db);

    // Insert default emergency fund
    await db.execute(
        "INSERT OR IGNORE INTO emergency_fund (id) VALUES ('default_fund')");
  }

  /// Insert default settings.
  Future<void> _insertDefaultSettings(Database db) async {
    final defaults = {
      'monthly_income': '0',
      'fixed_expenses_rent': '0',
      'fixed_expenses_utilities': '0',
      'fixed_expenses_other': '0',
      'needs_percent': '50',
      'wants_percent': '30',
      'savings_percent': '20',
      'cycle_type': 'calendar',
      'cycle_start_day': '1',
      'onboarding_complete': 'false',
      'app_first_launch': '',
      'schema_version': '1',
    };

    for (final entry in defaults.entries) {
      await db.execute(
        'INSERT OR IGNORE INTO app_settings (key, value) VALUES (?, ?)',
        [entry.key, entry.value],
      );
    }
  }

  /// Handle database upgrades.
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Future migrations will be added here
    // Example:
    // if (oldVersion < 2) {
    //   await _migrateV1ToV2(db);
    // }
  }

  /// Close the database.
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }

  /// Delete the database (for testing/reset).
  Future<void> deleteDatabase() async {
    await close();
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'financesensei.db');
    await databaseFactory.deleteDatabase(path);
  }
}
