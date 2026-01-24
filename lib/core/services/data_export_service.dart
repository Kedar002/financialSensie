import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../database/database_service.dart';
import '../infrastructure/logger.dart';
import '../infrastructure/result.dart';

/// Data export format version for compatibility
const int _exportVersion = 1;

/// Exported data structure
class ExportData {
  final int version;
  final DateTime exportedAt;
  final String appVersion;
  final Map<String, List<Map<String, dynamic>>> tables;

  ExportData({
    required this.version,
    required this.exportedAt,
    required this.appVersion,
    required this.tables,
  });

  Map<String, dynamic> toJson() {
    return {
      'version': version,
      'exportedAt': exportedAt.toIso8601String(),
      'appVersion': appVersion,
      'tables': tables,
    };
  }

  factory ExportData.fromJson(Map<String, dynamic> json) {
    return ExportData(
      version: json['version'] as int,
      exportedAt: DateTime.parse(json['exportedAt'] as String),
      appVersion: json['appVersion'] as String,
      tables: (json['tables'] as Map<String, dynamic>).map(
        (key, value) => MapEntry(
          key,
          (value as List).map((e) => e as Map<String, dynamic>).toList(),
        ),
      ),
    );
  }
}

/// Service for exporting and importing user data.
/// Enables backup and restore functionality.
///
/// Usage:
/// ```dart
/// final service = DataExportService();
///
/// // Export all data
/// final result = await service.exportAllData();
/// if (result.isSuccess) {
///   final json = result.dataOrNull!;
///   // Save to file or share
/// }
///
/// // Import from backup
/// await service.importData(jsonString);
/// ```
class DataExportService {
  final DatabaseService _db = DatabaseService();

  /// Tables to export/import in order (respects foreign key constraints)
  static const List<String> _tableOrder = [
    'user_profile',
    'income_sources',
    'fixed_expenses',
    'variable_expenses',
    'emergency_fund',
    'allocations',
    'planned_expenses',
    'transactions',
    'financial_snapshot',
    'savings_tracker',
  ];

  /// Export all data to JSON string
  Future<Result<String>> exportAllData() async {
    try {
      Logger.info('Starting data export', tag: 'Export');

      final tables = <String, List<Map<String, dynamic>>>{};

      for (final tableName in _tableOrder) {
        final data = await _db.query(tableName);
        tables[tableName] = data;
        Logger.debug('Exported ${data.length} records from $tableName', tag: 'Export');
      }

      final exportData = ExportData(
        version: _exportVersion,
        exportedAt: DateTime.now(),
        appVersion: '1.0.0', // Should come from package_info
        tables: tables,
      );

      final json = jsonEncode(exportData.toJson());
      Logger.info('Data export complete: ${json.length} bytes', tag: 'Export');

      return Result.success(json);
    } catch (e, st) {
      Logger.error('Data export failed', error: e, stackTrace: st, tag: 'Export');
      return Result.failure(AppError.database('Failed to export data', error: e, stackTrace: st));
    }
  }

  /// Export data to a file
  Future<Result<File>> exportToFile({String? fileName}) async {
    final exportResult = await exportAllData();

    if (exportResult.isFailure) {
      return Result.failure(exportResult.errorOrNull!);
    }

    final json = exportResult.dataOrNull!;

    try {
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
      final name = fileName ?? 'financesensei_backup_$timestamp.json';
      final file = File('${directory.path}/$name');

      await file.writeAsString(json);
      Logger.info('Exported to file: ${file.path}', tag: 'Export');

      return Result.success(file);
    } catch (e, st) {
      Logger.error('Failed to write export file', error: e, stackTrace: st, tag: 'Export');
      return Result.failure(AppError.database('Failed to write export file', error: e, stackTrace: st));
    }
  }

  /// Import data from JSON string
  Future<Result<ImportResult>> importData(String json, {bool clearExisting = true}) async {
    try {
      Logger.info('Starting data import', tag: 'Import');

      // Parse and validate
      final data = ExportData.fromJson(jsonDecode(json) as Map<String, dynamic>);

      // Version check
      if (data.version > _exportVersion) {
        return Result.failure(AppError.validation(
          'Export file version ${data.version} is newer than supported version $_exportVersion',
        ));
      }

      int totalRecords = 0;
      final recordCounts = <String, int>{};

      // Clear existing data if requested
      if (clearExisting) {
        Logger.info('Clearing existing data', tag: 'Import');
        await _db.deleteAllData();
      }

      // Import tables in order
      for (final tableName in _tableOrder) {
        final tableData = data.tables[tableName];
        if (tableData == null || tableData.isEmpty) {
          recordCounts[tableName] = 0;
          continue;
        }

        int count = 0;
        for (final record in tableData) {
          // Remove auto-generated ID to let database generate new one
          // if we cleared existing data
          if (clearExisting) {
            record.remove('id');
          }

          await _db.insert(tableName, record);
          count++;
        }

        recordCounts[tableName] = count;
        totalRecords += count;
        Logger.debug('Imported $count records to $tableName', tag: 'Import');
      }

      Logger.info('Data import complete: $totalRecords total records', tag: 'Import');

      return Result.success(ImportResult(
        totalRecords: totalRecords,
        recordCounts: recordCounts,
        exportedAt: data.exportedAt,
        appVersion: data.appVersion,
      ));
    } catch (e, st) {
      Logger.error('Data import failed', error: e, stackTrace: st, tag: 'Import');
      return Result.failure(AppError.database('Failed to import data', error: e, stackTrace: st));
    }
  }

  /// Import data from a file
  Future<Result<ImportResult>> importFromFile(File file, {bool clearExisting = true}) async {
    try {
      if (!await file.exists()) {
        return Result.failure(AppError.notFound('Backup file'));
      }

      final json = await file.readAsString();
      return await importData(json, clearExisting: clearExisting);
    } catch (e, st) {
      Logger.error('Failed to read import file', error: e, stackTrace: st, tag: 'Import');
      return Result.failure(AppError.database('Failed to read import file', error: e, stackTrace: st));
    }
  }

  /// Validate export data without importing
  Future<Result<ExportValidation>> validateExport(String json) async {
    try {
      final data = ExportData.fromJson(jsonDecode(json) as Map<String, dynamic>);

      final issues = <String>[];

      // Version check
      if (data.version > _exportVersion) {
        issues.add('Export version ${data.version} is newer than supported version $_exportVersion');
      }

      // Check for required tables
      for (final tableName in _tableOrder) {
        if (!data.tables.containsKey(tableName)) {
          issues.add('Missing table: $tableName');
        }
      }

      // Count records
      int totalRecords = 0;
      for (final tableData in data.tables.values) {
        totalRecords += tableData.length;
      }

      return Result.success(ExportValidation(
        isValid: issues.isEmpty,
        issues: issues,
        totalRecords: totalRecords,
        exportedAt: data.exportedAt,
        appVersion: data.appVersion,
      ));
    } catch (e) {
      return Result.failure(AppError.validation('Invalid export format: $e'));
    }
  }

  /// Get list of backup files
  Future<Result<List<BackupFile>>> getBackupFiles() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final files = directory.listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.json') && f.path.contains('financesensei_backup'))
          .map((f) => BackupFile(
                file: f,
                name: f.path.split('/').last,
                size: f.lengthSync(),
                createdAt: f.statSync().modified,
              ))
          .toList();

      files.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return Result.success(files);
    } catch (e, st) {
      return Result.failure(AppError.database('Failed to list backup files', error: e, stackTrace: st));
    }
  }
}

/// Result of an import operation
class ImportResult {
  final int totalRecords;
  final Map<String, int> recordCounts;
  final DateTime exportedAt;
  final String appVersion;

  const ImportResult({
    required this.totalRecords,
    required this.recordCounts,
    required this.exportedAt,
    required this.appVersion,
  });
}

/// Validation result for export data
class ExportValidation {
  final bool isValid;
  final List<String> issues;
  final int totalRecords;
  final DateTime exportedAt;
  final String appVersion;

  const ExportValidation({
    required this.isValid,
    required this.issues,
    required this.totalRecords,
    required this.exportedAt,
    required this.appVersion,
  });
}

/// Backup file info
class BackupFile {
  final File file;
  final String name;
  final int size;
  final DateTime createdAt;

  const BackupFile({
    required this.file,
    required this.name,
    required this.size,
    required this.createdAt,
  });

  String get sizeFormatted {
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
