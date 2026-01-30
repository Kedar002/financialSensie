import 'package:sqflite/sqflite.dart';
import '../database_service.dart';

/// Repository for app_settings table.
/// Key-value store for all user preferences.
class SettingsRepository {
  final DatabaseService _db = DatabaseService();

  /// Get a setting value by key.
  Future<String?> get(String key) async {
    final db = await _db.database;
    final results = await db.query(
      'app_settings',
      columns: ['value'],
      where: 'key = ?',
      whereArgs: [key],
    );
    if (results.isEmpty) return null;
    return results.first['value'] as String?;
  }

  /// Get a setting as int.
  Future<int> getInt(String key, {int defaultValue = 0}) async {
    final value = await get(key);
    if (value == null || value.isEmpty) return defaultValue;
    return int.tryParse(value) ?? defaultValue;
  }

  /// Get a setting as bool.
  Future<bool> getBool(String key, {bool defaultValue = false}) async {
    final value = await get(key);
    if (value == null) return defaultValue;
    return value == 'true';
  }

  /// Set a setting value.
  Future<void> set(String key, String value) async {
    final db = await _db.database;
    await db.insert(
      'app_settings',
      {
        'key': key,
        'value': value,
        'updated_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Set an int setting.
  Future<void> setInt(String key, int value) async {
    await set(key, value.toString());
  }

  /// Set a bool setting.
  Future<void> setBool(String key, bool value) async {
    await set(key, value.toString());
  }

  /// Get all settings as a map.
  Future<Map<String, String>> getAll() async {
    final db = await _db.database;
    final results = await db.query('app_settings');
    return {
      for (final row in results) row['key'] as String: row['value'] as String,
    };
  }

  /// Get monthly income in paise.
  Future<int> getMonthlyIncome() => getInt('monthly_income');

  /// Set monthly income in paise.
  Future<void> setMonthlyIncome(int paise) => setInt('monthly_income', paise);

  /// Get fixed expenses (all three combined) in paise.
  Future<int> getTotalFixedExpenses() async {
    final rent = await getInt('fixed_expenses_rent');
    final utilities = await getInt('fixed_expenses_utilities');
    final other = await getInt('fixed_expenses_other');
    return rent + utilities + other;
  }

  /// Get individual fixed expense.
  Future<int> getFixedExpenseRent() => getInt('fixed_expenses_rent');
  Future<int> getFixedExpenseUtilities() => getInt('fixed_expenses_utilities');
  Future<int> getFixedExpenseOther() => getInt('fixed_expenses_other');

  /// Set individual fixed expense.
  Future<void> setFixedExpenseRent(int paise) =>
      setInt('fixed_expenses_rent', paise);
  Future<void> setFixedExpenseUtilities(int paise) =>
      setInt('fixed_expenses_utilities', paise);
  Future<void> setFixedExpenseOther(int paise) =>
      setInt('fixed_expenses_other', paise);

  /// Get budget percentages.
  Future<int> getNeedsPercent() => getInt('needs_percent', defaultValue: 50);
  Future<int> getWantsPercent() => getInt('wants_percent', defaultValue: 30);
  Future<int> getSavingsPercent() => getInt('savings_percent', defaultValue: 20);

  /// Set budget percentages.
  Future<void> setNeedsPercent(int percent) => setInt('needs_percent', percent);
  Future<void> setWantsPercent(int percent) => setInt('wants_percent', percent);
  Future<void> setSavingsPercent(int percent) =>
      setInt('savings_percent', percent);

  /// Get cycle settings.
  Future<String> getCycleType() async =>
      await get('cycle_type') ?? 'calendar';
  Future<int> getCycleStartDay() =>
      getInt('cycle_start_day', defaultValue: 1);

  /// Set cycle settings.
  Future<void> setCycleType(String type) => set('cycle_type', type);
  Future<void> setCycleStartDay(int day) => setInt('cycle_start_day', day);

  /// Check if onboarding is complete.
  Future<bool> isOnboardingComplete() => getBool('onboarding_complete');

  /// Mark onboarding as complete.
  Future<void> completeOnboarding() async {
    await setBool('onboarding_complete', true);
    final firstLaunch = await get('app_first_launch');
    if (firstLaunch == null || firstLaunch.isEmpty) {
      await set('app_first_launch', DateTime.now().toIso8601String());
    }
  }

  /// Get app first launch date.
  Future<DateTime?> getFirstLaunchDate() async {
    final value = await get('app_first_launch');
    if (value == null || value.isEmpty) return null;
    return DateTime.tryParse(value);
  }

  /// Calculate monthly essentials (needs budget).
  /// Used for emergency fund target calculation.
  Future<int> calculateMonthlyEssentials() async {
    final income = await getMonthlyIncome();
    final needsPercent = await getNeedsPercent();
    return (income * needsPercent / 100).round();
  }
}
