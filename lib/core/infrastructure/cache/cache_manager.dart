import '../logger.dart';
import '../app_config.dart';

/// A cached entry with expiration
class CacheEntry<T> {
  final T data;
  final DateTime createdAt;
  final Duration ttl;

  CacheEntry({
    required this.data,
    required this.createdAt,
    required this.ttl,
  });

  bool get isExpired => DateTime.now().isAfter(createdAt.add(ttl));
}

/// In-memory cache manager for performance optimization.
/// Caches expensive calculations and database queries.
///
/// Usage:
/// ```dart
/// final cache = CacheManager.instance;
///
/// // Get or compute
/// final data = await cache.getOrCompute(
///   'user_summary_123',
///   () => calculateSummary(123),
/// );
///
/// // Invalidate when data changes
/// cache.invalidate('user_summary_123');
/// cache.invalidatePrefix('user_'); // Invalidate all user-related caches
/// ```
class CacheManager {
  static final CacheManager _instance = CacheManager._internal();
  static CacheManager get instance => _instance;

  CacheManager._internal();

  final Map<String, CacheEntry<dynamic>> _cache = {};
  Duration _defaultTtl = const Duration(minutes: 15);

  /// Initialize with config
  void init() {
    _defaultTtl = Duration(minutes: AppConfig.instance.settings.cacheExpirationMinutes);
    Logger.info('CacheManager initialized with TTL: ${_defaultTtl.inMinutes}min', tag: 'Cache');
  }

  /// Get a cached value
  T? get<T>(String key) {
    final entry = _cache[key];
    if (entry == null) {
      Logger.debug('Cache miss: $key', tag: 'Cache');
      return null;
    }

    if (entry.isExpired) {
      Logger.debug('Cache expired: $key', tag: 'Cache');
      _cache.remove(key);
      return null;
    }

    Logger.debug('Cache hit: $key', tag: 'Cache');
    return entry.data as T;
  }

  /// Set a cached value
  void set<T>(String key, T value, {Duration? ttl}) {
    _cache[key] = CacheEntry<T>(
      data: value,
      createdAt: DateTime.now(),
      ttl: ttl ?? _defaultTtl,
    );
    Logger.debug('Cache set: $key', tag: 'Cache');
  }

  /// Get or compute a value
  Future<T> getOrCompute<T>(
    String key,
    Future<T> Function() compute, {
    Duration? ttl,
  }) async {
    final cached = get<T>(key);
    if (cached != null) {
      return cached;
    }

    final value = await compute();
    set(key, value, ttl: ttl);
    return value;
  }

  /// Get or compute synchronously
  T getOrComputeSync<T>(
    String key,
    T Function() compute, {
    Duration? ttl,
  }) {
    final cached = get<T>(key);
    if (cached != null) {
      return cached;
    }

    final value = compute();
    set(key, value, ttl: ttl);
    return value;
  }

  /// Invalidate a specific key
  void invalidate(String key) {
    if (_cache.containsKey(key)) {
      _cache.remove(key);
      Logger.debug('Cache invalidated: $key', tag: 'Cache');
    }
  }

  /// Invalidate all keys with a prefix
  void invalidatePrefix(String prefix) {
    final keysToRemove = _cache.keys.where((key) => key.startsWith(prefix)).toList();
    for (final key in keysToRemove) {
      _cache.remove(key);
    }
    Logger.debug('Cache invalidated ${keysToRemove.length} keys with prefix: $prefix', tag: 'Cache');
  }

  /// Invalidate all keys matching a pattern
  void invalidatePattern(RegExp pattern) {
    final keysToRemove = _cache.keys.where((key) => pattern.hasMatch(key)).toList();
    for (final key in keysToRemove) {
      _cache.remove(key);
    }
    Logger.debug('Cache invalidated ${keysToRemove.length} keys matching pattern', tag: 'Cache');
  }

  /// Clear all cached values
  void clear() {
    final count = _cache.length;
    _cache.clear();
    Logger.info('Cache cleared: $count entries', tag: 'Cache');
  }

  /// Remove expired entries
  void cleanup() {
    final expiredKeys = _cache.entries
        .where((entry) => entry.value.isExpired)
        .map((entry) => entry.key)
        .toList();

    for (final key in expiredKeys) {
      _cache.remove(key);
    }

    if (expiredKeys.isNotEmpty) {
      Logger.debug('Cache cleanup: removed ${expiredKeys.length} expired entries', tag: 'Cache');
    }
  }

  /// Get cache statistics
  CacheStats get stats {
    int expiredCount = 0;
    int validCount = 0;

    for (final entry in _cache.values) {
      if (entry.isExpired) {
        expiredCount++;
      } else {
        validCount++;
      }
    }

    return CacheStats(
      totalEntries: _cache.length,
      validEntries: validCount,
      expiredEntries: expiredCount,
    );
  }
}

/// Cache statistics
class CacheStats {
  final int totalEntries;
  final int validEntries;
  final int expiredEntries;

  const CacheStats({
    required this.totalEntries,
    required this.validEntries,
    required this.expiredEntries,
  });

  @override
  String toString() {
    return 'CacheStats(total: $totalEntries, valid: $validEntries, expired: $expiredEntries)';
  }
}

/// Cache keys for the application
class CacheKeys {
  static String userSummary(int userId) => 'user_summary_$userId';
  static String safeToSpendStatus(int userId) => 'safe_to_spend_$userId';
  static String budgetSheet(int userId) => 'budget_sheet_$userId';
  static String emergencyFund(int userId) => 'emergency_fund_$userId';
  static String goals(int userId) => 'goals_$userId';
  static String recentTransactions(int userId) => 'recent_transactions_$userId';
  static String savingsHistory(int userId) => 'savings_history_$userId';

  /// Prefix for user-specific caches
  static String userPrefix(int userId) => 'user_${userId}_';
}
