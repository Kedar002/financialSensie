import 'logger.dart';

/// Application environment
enum AppEnvironment {
  development,
  staging,
  production,
}

/// Centralized application configuration.
/// Manages environment-specific settings and feature toggles.
class AppConfig {
  static AppConfig? _instance;
  static AppConfig get instance => _instance ?? AppConfig._();

  AppConfig._();

  late AppEnvironment _environment;
  late AppSettings _settings;

  /// Initialize configuration for environment
  static Future<void> init({
    AppEnvironment environment = AppEnvironment.development,
  }) async {
    _instance = AppConfig._();
    _instance!._environment = environment;
    _instance!._settings = AppSettings.forEnvironment(environment);

    // Configure logger based on environment
    Logger.setEnabled(_instance!._settings.enableLogging);
    Logger.setMinLevel(_instance!._settings.logLevel);

    Logger.info(
      'AppConfig initialized for ${environment.name}',
      tag: 'Config',
      data: _instance!._settings.toJson(),
    );
  }

  /// Current environment
  AppEnvironment get environment => _environment;

  /// Current settings
  AppSettings get settings => _settings;

  /// Check if running in development
  bool get isDevelopment => _environment == AppEnvironment.development;

  /// Check if running in production
  bool get isProduction => _environment == AppEnvironment.production;

  /// Get a setting value
  static T get<T>(String key, T defaultValue) {
    return instance._settings.get<T>(key) ?? defaultValue;
  }
}

/// Application settings container
class AppSettings {
  final String appName;
  final String appVersion;
  final bool enableLogging;
  final LogLevel logLevel;
  final bool enableAnalytics;
  final bool enableCrashReporting;
  final int maxTransactionHistory;
  final int maxSnapshotHistory;
  final int cacheExpirationMinutes;
  final String? apiBaseUrl;
  final int apiTimeoutSeconds;
  final bool enableOfflineMode;
  final Map<String, dynamic> _customSettings;

  const AppSettings({
    required this.appName,
    required this.appVersion,
    required this.enableLogging,
    required this.logLevel,
    required this.enableAnalytics,
    required this.enableCrashReporting,
    required this.maxTransactionHistory,
    required this.maxSnapshotHistory,
    required this.cacheExpirationMinutes,
    this.apiBaseUrl,
    required this.apiTimeoutSeconds,
    required this.enableOfflineMode,
    Map<String, dynamic>? customSettings,
  }) : _customSettings = customSettings ?? const {};

  /// Create settings for a specific environment
  factory AppSettings.forEnvironment(AppEnvironment env) {
    switch (env) {
      case AppEnvironment.development:
        return const AppSettings(
          appName: 'FinanceSensei (Dev)',
          appVersion: '1.0.0-dev',
          enableLogging: true,
          logLevel: LogLevel.debug,
          enableAnalytics: false,
          enableCrashReporting: false,
          maxTransactionHistory: 1000,
          maxSnapshotHistory: 24,
          cacheExpirationMinutes: 5,
          apiBaseUrl: null, // Offline-first
          apiTimeoutSeconds: 30,
          enableOfflineMode: true,
        );
      case AppEnvironment.staging:
        return const AppSettings(
          appName: 'FinanceSensei (Staging)',
          appVersion: '1.0.0-staging',
          enableLogging: true,
          logLevel: LogLevel.info,
          enableAnalytics: true,
          enableCrashReporting: true,
          maxTransactionHistory: 5000,
          maxSnapshotHistory: 24,
          cacheExpirationMinutes: 15,
          apiBaseUrl: null, // Will be set when backend is ready
          apiTimeoutSeconds: 30,
          enableOfflineMode: true,
        );
      case AppEnvironment.production:
        return const AppSettings(
          appName: 'FinanceSensei',
          appVersion: '1.0.0',
          enableLogging: false,
          logLevel: LogLevel.error,
          enableAnalytics: true,
          enableCrashReporting: true,
          maxTransactionHistory: 10000,
          maxSnapshotHistory: 24,
          cacheExpirationMinutes: 30,
          apiBaseUrl: null, // Will be set when backend is ready
          apiTimeoutSeconds: 30,
          enableOfflineMode: true,
        );
    }
  }

  /// Get a custom setting
  T? get<T>(String key) {
    return _customSettings[key] as T?;
  }

  Map<String, dynamic> toJson() {
    return {
      'appName': appName,
      'appVersion': appVersion,
      'enableLogging': enableLogging,
      'logLevel': logLevel.name,
      'enableAnalytics': enableAnalytics,
      'enableCrashReporting': enableCrashReporting,
      'maxTransactionHistory': maxTransactionHistory,
      'maxSnapshotHistory': maxSnapshotHistory,
      'cacheExpirationMinutes': cacheExpirationMinutes,
      'apiBaseUrl': apiBaseUrl,
      'apiTimeoutSeconds': apiTimeoutSeconds,
      'enableOfflineMode': enableOfflineMode,
    };
  }
}
