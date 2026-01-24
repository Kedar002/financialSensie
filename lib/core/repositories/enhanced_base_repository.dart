import '../database/database_service.dart';
import '../infrastructure/result.dart';
import '../infrastructure/logger.dart';
import '../infrastructure/cache/cache_manager.dart';

/// Enhanced base repository with Result types for better error handling.
/// Provides caching, logging, and type-safe error handling.
///
/// Usage:
/// ```dart
/// class UserRepo extends EnhancedBaseRepository<User> {
///   @override
///   String get tableName => 'users';
///
///   @override
///   User fromMap(Map<String, dynamic> map) => User.fromMap(map);
///
///   @override
///   Map<String, dynamic> toMap(User entity) => entity.toMap();
/// }
/// ```
abstract class EnhancedBaseRepository<T> {
  final DatabaseService _db = DatabaseService();
  final CacheManager _cache = CacheManager.instance;

  String get tableName;
  T fromMap(Map<String, dynamic> map);
  Map<String, dynamic> toMap(T entity);

  /// Optional: Cache key prefix for this entity type
  String get cacheKeyPrefix => tableName;

  /// Database access
  DatabaseService get db => _db;

  /// Current Unix timestamp
  int get timestamp => DateTime.now().millisecondsSinceEpoch ~/ 1000;

  /// Insert entity and return Result
  Future<Result<int>> insertSafe(T entity) async {
    try {
      final id = await _db.insert(tableName, toMap(entity));
      Logger.debug('Inserted $tableName #$id', tag: 'Repository');
      _invalidateListCache();
      return Result.success(id);
    } catch (e, st) {
      Logger.error('Failed to insert $tableName', error: e, stackTrace: st, tag: 'Repository');
      return Result.failure(AppError.database('Failed to insert $tableName', error: e, stackTrace: st));
    }
  }

  /// Get all entities with Result
  Future<Result<List<T>>> getAllSafe({String? orderBy}) async {
    try {
      final results = await _db.query(tableName, orderBy: orderBy);
      final entities = results.map((map) => fromMap(map)).toList();
      Logger.debug('Retrieved ${entities.length} $tableName records', tag: 'Repository');
      return Result.success(entities);
    } catch (e, st) {
      Logger.error('Failed to get all $tableName', error: e, stackTrace: st, tag: 'Repository');
      return Result.failure(AppError.database('Failed to retrieve $tableName records', error: e, stackTrace: st));
    }
  }

  /// Get entity by ID with Result
  Future<Result<T>> getByIdSafe(int id) async {
    try {
      final results = await _db.query(
        tableName,
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );

      if (results.isEmpty) {
        return Result.failure(AppError.notFound('$tableName #$id'));
      }

      return Result.success(fromMap(results.first));
    } catch (e, st) {
      Logger.error('Failed to get $tableName #$id', error: e, stackTrace: st, tag: 'Repository');
      return Result.failure(AppError.database('Failed to retrieve $tableName #$id', error: e, stackTrace: st));
    }
  }

  /// Update entity with Result
  Future<Result<int>> updateSafe(T entity, int id) async {
    try {
      final count = await _db.update(
        tableName,
        toMap(entity),
        where: 'id = ?',
        whereArgs: [id],
      );
      Logger.debug('Updated $tableName #$id', tag: 'Repository');
      _invalidateCache(id);
      return Result.success(count);
    } catch (e, st) {
      Logger.error('Failed to update $tableName #$id', error: e, stackTrace: st, tag: 'Repository');
      return Result.failure(AppError.database('Failed to update $tableName #$id', error: e, stackTrace: st));
    }
  }

  /// Delete entity with Result
  Future<Result<int>> deleteSafe(int id) async {
    try {
      final count = await _db.delete(tableName, where: 'id = ?', whereArgs: [id]);
      Logger.debug('Deleted $tableName #$id', tag: 'Repository');
      _invalidateCache(id);
      return Result.success(count);
    } catch (e, st) {
      Logger.error('Failed to delete $tableName #$id', error: e, stackTrace: st, tag: 'Repository');
      return Result.failure(AppError.database('Failed to delete $tableName #$id', error: e, stackTrace: st));
    }
  }

  /// Check if entity exists
  Future<Result<bool>> exists(int id) async {
    try {
      final results = await _db.query(
        tableName,
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      return Result.success(results.isNotEmpty);
    } catch (e, st) {
      Logger.error('Failed to check existence $tableName #$id', error: e, stackTrace: st, tag: 'Repository');
      return Result.failure(AppError.database('Failed to check existence', error: e, stackTrace: st));
    }
  }

  /// Count all entities
  Future<Result<int>> count({String? where, List<dynamic>? whereArgs}) async {
    try {
      final result = await _db.rawQuery(
        'SELECT COUNT(*) as count FROM $tableName${where != null ? ' WHERE $where' : ''}',
        whereArgs,
      );
      final count = result.first['count'] as int;
      return Result.success(count);
    } catch (e, st) {
      Logger.error('Failed to count $tableName', error: e, stackTrace: st, tag: 'Repository');
      return Result.failure(AppError.database('Failed to count $tableName', error: e, stackTrace: st));
    }
  }

  /// Batch insert entities
  Future<Result<List<int>>> batchInsert(List<T> entities) async {
    try {
      final ids = <int>[];
      for (final entity in entities) {
        final id = await _db.insert(tableName, toMap(entity));
        ids.add(id);
      }
      Logger.debug('Batch inserted ${ids.length} $tableName records', tag: 'Repository');
      _invalidateListCache();
      return Result.success(ids);
    } catch (e, st) {
      Logger.error('Failed to batch insert $tableName', error: e, stackTrace: st, tag: 'Repository');
      return Result.failure(AppError.database('Failed to batch insert $tableName', error: e, stackTrace: st));
    }
  }

  /// Delete by condition
  Future<Result<int>> deleteWhere(String where, List<dynamic> whereArgs) async {
    try {
      final count = await _db.delete(tableName, where: where, whereArgs: whereArgs);
      Logger.debug('Deleted $count $tableName records', tag: 'Repository');
      _invalidateListCache();
      return Result.success(count);
    } catch (e, st) {
      Logger.error('Failed to delete $tableName with condition', error: e, stackTrace: st, tag: 'Repository');
      return Result.failure(AppError.database('Failed to delete $tableName', error: e, stackTrace: st));
    }
  }

  // ===== Backward compatibility methods (same as base repository) =====

  Future<int> insert(T entity) async {
    return await _db.insert(tableName, toMap(entity));
  }

  Future<List<T>> getAll({String? orderBy}) async {
    final results = await _db.query(tableName, orderBy: orderBy);
    return results.map((map) => fromMap(map)).toList();
  }

  Future<T?> getById(int id) async {
    final results = await _db.query(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (results.isEmpty) return null;
    return fromMap(results.first);
  }

  Future<int> update(T entity, int id) async {
    return await _db.update(
      tableName,
      toMap(entity),
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> delete(int id) async {
    return await _db.delete(tableName, where: 'id = ?', whereArgs: [id]);
  }

  // ===== Cache helpers =====

  void _invalidateCache(int id) {
    _cache.invalidate('${cacheKeyPrefix}_$id');
  }

  void _invalidateListCache() {
    _cache.invalidatePrefix('${cacheKeyPrefix}_');
  }

  /// Get with caching
  Future<T?> getByIdCached(int id, {Duration? ttl}) async {
    return await _cache.getOrCompute(
      '${cacheKeyPrefix}_$id',
      () => getById(id),
      ttl: ttl,
    );
  }
}
