import 'logger.dart';
import 'app_config.dart';

/// Feature flag definition
class FeatureFlag {
  final String key;
  final String description;
  final bool defaultValue;
  final bool? overrideValue;

  const FeatureFlag({
    required this.key,
    required this.description,
    required this.defaultValue,
    this.overrideValue,
  });

  bool get isEnabled => overrideValue ?? defaultValue;
}

/// Centralized feature flags management.
/// Enables gradual rollout of features and A/B testing.
///
/// Usage:
/// ```dart
/// if (FeatureFlags.isEnabled(Features.cloudSync)) {
///   // Show cloud sync UI
/// }
/// ```
class FeatureFlags {
  static final Map<String, FeatureFlag> _flags = {};
  static final Map<String, bool> _overrides = {};

  /// Initialize feature flags
  static void init() {
    // Register all feature flags
    _registerDefaultFlags();
    Logger.info('FeatureFlags initialized with ${_flags.length} flags', tag: 'Features');
  }

  /// Register default feature flags
  static void _registerDefaultFlags() {
    final env = AppConfig.instance.environment;

    // Core features
    register(FeatureFlag(
      key: Features.offlineMode,
      description: 'Enable offline-first mode',
      defaultValue: true,
    ));

    register(FeatureFlag(
      key: Features.cloudSync,
      description: 'Enable cloud synchronization',
      defaultValue: false, // Not yet implemented
    ));

    register(FeatureFlag(
      key: Features.pdfExport,
      description: 'Enable PDF export functionality',
      defaultValue: true,
    ));

    register(FeatureFlag(
      key: Features.budgetHistory,
      description: 'Enable budget history view',
      defaultValue: true,
    ));

    register(FeatureFlag(
      key: Features.savingsTracker,
      description: 'Enable savings tracking',
      defaultValue: true,
    ));

    // Upcoming features
    register(FeatureFlag(
      key: Features.bankIntegration,
      description: 'Enable bank account integration',
      defaultValue: false,
    ));

    register(FeatureFlag(
      key: Features.aiInsights,
      description: 'Enable AI-powered insights',
      defaultValue: false,
    ));

    register(FeatureFlag(
      key: Features.budgetPredictions,
      description: 'Enable budget predictions',
      defaultValue: false,
    ));

    register(FeatureFlag(
      key: Features.multiCurrency,
      description: 'Enable multi-currency support',
      defaultValue: false,
    ));

    register(FeatureFlag(
      key: Features.familySharing,
      description: 'Enable family budget sharing',
      defaultValue: false,
    ));

    // Development features
    register(FeatureFlag(
      key: Features.debugMode,
      description: 'Enable debug mode features',
      defaultValue: env == AppEnvironment.development,
    ));

    register(FeatureFlag(
      key: Features.mockData,
      description: 'Use mock data for testing',
      defaultValue: false,
    ));
  }

  /// Register a feature flag
  static void register(FeatureFlag flag) {
    _flags[flag.key] = flag;
  }

  /// Check if a feature is enabled
  static bool isEnabled(String key) {
    // Check overrides first
    if (_overrides.containsKey(key)) {
      return _overrides[key]!;
    }

    // Check registered flags
    final flag = _flags[key];
    if (flag != null) {
      return flag.isEnabled;
    }

    // Unknown flag - default to false
    Logger.warning('Unknown feature flag: $key', tag: 'Features');
    return false;
  }

  /// Set a runtime override for a flag
  static void setOverride(String key, bool value) {
    _overrides[key] = value;
    Logger.info('Feature flag override: $key = $value', tag: 'Features');
  }

  /// Clear a specific override
  static void clearOverride(String key) {
    _overrides.remove(key);
  }

  /// Clear all overrides
  static void clearAllOverrides() {
    _overrides.clear();
  }

  /// Get all registered flags
  static List<FeatureFlag> get allFlags => _flags.values.toList();

  /// Get flag details
  static FeatureFlag? getFlag(String key) => _flags[key];

  /// Export current flag states (for debugging)
  static Map<String, bool> exportState() {
    return Map.fromEntries(
      _flags.keys.map((key) => MapEntry(key, isEnabled(key))),
    );
  }
}

/// Feature flag keys
class Features {
  // Core features
  static const String offlineMode = 'offline_mode';
  static const String cloudSync = 'cloud_sync';
  static const String pdfExport = 'pdf_export';
  static const String budgetHistory = 'budget_history';
  static const String savingsTracker = 'savings_tracker';

  // Upcoming features
  static const String bankIntegration = 'bank_integration';
  static const String aiInsights = 'ai_insights';
  static const String budgetPredictions = 'budget_predictions';
  static const String multiCurrency = 'multi_currency';
  static const String familySharing = 'family_sharing';

  // Development features
  static const String debugMode = 'debug_mode';
  static const String mockData = 'mock_data';
}
