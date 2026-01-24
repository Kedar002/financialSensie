import 'dart:developer' as developer;

/// Log levels for categorizing log messages.
enum LogLevel {
  debug,
  info,
  warning,
  error,
}

/// Centralized logging service for the application.
/// Provides structured logging with levels, tags, and optional stack traces.
///
/// Usage:
/// ```dart
/// Logger.info('User logged in', tag: 'Auth');
/// Logger.error('Failed to save', error: e, stackTrace: st, tag: 'Database');
/// ```
class Logger {
  static bool _enabled = true;
  static LogLevel _minLevel = LogLevel.debug;
  static final List<LogEntry> _logs = [];
  static const int _maxLogEntries = 1000;

  /// Enable or disable logging
  static void setEnabled(bool enabled) {
    _enabled = enabled;
  }

  /// Set minimum log level
  static void setMinLevel(LogLevel level) {
    _minLevel = level;
  }

  /// Log a debug message
  static void debug(String message, {String? tag, Map<String, dynamic>? data}) {
    _log(LogLevel.debug, message, tag: tag, data: data);
  }

  /// Log an info message
  static void info(String message, {String? tag, Map<String, dynamic>? data}) {
    _log(LogLevel.info, message, tag: tag, data: data);
  }

  /// Log a warning message
  static void warning(String message, {String? tag, Map<String, dynamic>? data}) {
    _log(LogLevel.warning, message, tag: tag, data: data);
  }

  /// Log an error message with optional error object and stack trace
  static void error(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    String? tag,
    Map<String, dynamic>? data,
  }) {
    _log(
      LogLevel.error,
      message,
      error: error,
      stackTrace: stackTrace,
      tag: tag,
      data: data,
    );
  }

  /// Internal logging method
  static void _log(
    LogLevel level,
    String message, {
    Object? error,
    StackTrace? stackTrace,
    String? tag,
    Map<String, dynamic>? data,
  }) {
    if (!_enabled || level.index < _minLevel.index) return;

    final entry = LogEntry(
      level: level,
      message: message,
      tag: tag,
      error: error,
      stackTrace: stackTrace,
      data: data,
      timestamp: DateTime.now(),
    );

    // Store in memory (with limit)
    _logs.add(entry);
    if (_logs.length > _maxLogEntries) {
      _logs.removeAt(0);
    }

    // Output to console
    final prefix = '[${level.name.toUpperCase()}]';
    final tagStr = tag != null ? '[$tag]' : '';
    final fullMessage = '$prefix$tagStr $message';

    developer.log(
      fullMessage,
      name: 'FinanceSensei',
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// Get all stored logs
  static List<LogEntry> getLogs() => List.unmodifiable(_logs);

  /// Get logs filtered by level
  static List<LogEntry> getLogsByLevel(LogLevel level) {
    return _logs.where((log) => log.level == level).toList();
  }

  /// Get logs filtered by tag
  static List<LogEntry> getLogsByTag(String tag) {
    return _logs.where((log) => log.tag == tag).toList();
  }

  /// Clear all stored logs
  static void clearLogs() {
    _logs.clear();
  }

  /// Export logs as a formatted string (for debugging/support)
  static String exportLogs() {
    final buffer = StringBuffer();
    buffer.writeln('=== FinanceSensei Logs ===');
    buffer.writeln('Exported at: ${DateTime.now().toIso8601String()}');
    buffer.writeln('Total entries: ${_logs.length}');
    buffer.writeln('');

    for (final log in _logs) {
      buffer.writeln(log.toFormattedString());
    }

    return buffer.toString();
  }
}

/// Represents a single log entry
class LogEntry {
  final LogLevel level;
  final String message;
  final String? tag;
  final Object? error;
  final StackTrace? stackTrace;
  final Map<String, dynamic>? data;
  final DateTime timestamp;

  const LogEntry({
    required this.level,
    required this.message,
    this.tag,
    this.error,
    this.stackTrace,
    this.data,
    required this.timestamp,
  });

  String toFormattedString() {
    final buffer = StringBuffer();
    buffer.write('[${timestamp.toIso8601String()}]');
    buffer.write('[${level.name.toUpperCase()}]');
    if (tag != null) buffer.write('[$tag]');
    buffer.write(' $message');
    if (error != null) buffer.write('\nError: $error');
    if (data != null) buffer.write('\nData: $data');
    if (stackTrace != null) buffer.write('\nStack: $stackTrace');
    return buffer.toString();
  }

  Map<String, dynamic> toJson() {
    return {
      'level': level.name,
      'message': message,
      'tag': tag,
      'error': error?.toString(),
      'data': data,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}
