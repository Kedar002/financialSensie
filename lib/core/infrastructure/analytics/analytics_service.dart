import '../logger.dart';
import '../app_config.dart';

/// Analytics event for tracking user actions
class AnalyticsEvent {
  final String name;
  final Map<String, dynamic>? parameters;
  final DateTime timestamp;

  AnalyticsEvent({
    required this.name,
    this.parameters,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'parameters': parameters,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

/// Analytics provider interface for different backends
abstract class AnalyticsProvider {
  Future<void> logEvent(AnalyticsEvent event);
  Future<void> setUserId(String userId);
  Future<void> setUserProperty(String name, String value);
  Future<void> logScreenView(String screenName);
}

/// Local analytics provider that stores events locally
/// Can be replaced with Firebase Analytics, Mixpanel, etc.
class LocalAnalyticsProvider implements AnalyticsProvider {
  final List<AnalyticsEvent> _events = [];
  final int _maxEvents = 1000;

  @override
  Future<void> logEvent(AnalyticsEvent event) async {
    _events.add(event);
    if (_events.length > _maxEvents) {
      _events.removeAt(0);
    }
    Logger.debug('Analytics event: ${event.name}', tag: 'Analytics', data: event.parameters);
  }

  @override
  Future<void> setUserId(String userId) async {
    Logger.debug('Analytics user ID: $userId', tag: 'Analytics');
  }

  @override
  Future<void> setUserProperty(String name, String value) async {
    Logger.debug('Analytics user property: $name = $value', tag: 'Analytics');
  }

  @override
  Future<void> logScreenView(String screenName) async {
    await logEvent(AnalyticsEvent(
      name: 'screen_view',
      parameters: {'screen_name': screenName},
    ));
  }

  List<AnalyticsEvent> get events => List.unmodifiable(_events);
}

/// Centralized analytics service.
/// Provides a simple API for tracking events across the app.
///
/// Usage:
/// ```dart
/// Analytics.logEvent('button_clicked', {'button_name': 'save'});
/// Analytics.logScreenView('HomeScreen');
/// Analytics.logTransaction(amount: 100, category: 'food');
/// ```
class Analytics {
  static AnalyticsProvider? _provider;
  static bool _enabled = false;

  /// Initialize analytics with a provider
  static void init({AnalyticsProvider? provider}) {
    _enabled = AppConfig.instance.settings.enableAnalytics;
    if (_enabled) {
      _provider = provider ?? LocalAnalyticsProvider();
      Logger.info('Analytics initialized', tag: 'Analytics');
    } else {
      Logger.info('Analytics disabled', tag: 'Analytics');
    }
  }

  /// Log a custom event
  static Future<void> logEvent(String name, [Map<String, dynamic>? parameters]) async {
    if (!_enabled || _provider == null) return;
    await _provider!.logEvent(AnalyticsEvent(name: name, parameters: parameters));
  }

  /// Set user ID for analytics
  static Future<void> setUserId(String userId) async {
    if (!_enabled || _provider == null) return;
    await _provider!.setUserId(userId);
  }

  /// Set user property
  static Future<void> setUserProperty(String name, String value) async {
    if (!_enabled || _provider == null) return;
    await _provider!.setUserProperty(name, value);
  }

  /// Log screen view
  static Future<void> logScreenView(String screenName) async {
    if (!_enabled || _provider == null) return;
    await _provider!.logScreenView(screenName);
  }

  // ===== Domain-specific events =====

  /// Log onboarding step completion
  static Future<void> logOnboardingStep(String step) async {
    await logEvent('onboarding_step', {'step': step});
  }

  /// Log onboarding completion
  static Future<void> logOnboardingComplete() async {
    await logEvent('onboarding_complete');
  }

  /// Log transaction logged
  static Future<void> logTransaction({
    required double amount,
    required String category,
  }) async {
    await logEvent('transaction_logged', {
      'amount': amount,
      'category': category,
    });
  }

  /// Log goal created
  static Future<void> logGoalCreated({
    required double targetAmount,
    required int monthsToTarget,
  }) async {
    await logEvent('goal_created', {
      'target_amount': targetAmount,
      'months_to_target': monthsToTarget,
    });
  }

  /// Log goal completed
  static Future<void> logGoalCompleted({required String goalName}) async {
    await logEvent('goal_completed', {'goal_name': goalName});
  }

  /// Log emergency fund contribution
  static Future<void> logEmergencyFundContribution({required double amount}) async {
    await logEvent('emergency_fund_contribution', {'amount': amount});
  }

  /// Log budget sheet viewed
  static Future<void> logBudgetSheetViewed() async {
    await logEvent('budget_sheet_viewed');
  }

  /// Log PDF exported
  static Future<void> logPdfExported({required String month}) async {
    await logEvent('pdf_exported', {'month': month});
  }

  /// Log budget warning
  static Future<void> logBudgetWarning({
    required double percentSpent,
    required int daysRemaining,
  }) async {
    await logEvent('budget_warning', {
      'percent_spent': percentSpent,
      'days_remaining': daysRemaining,
    });
  }

  /// Log over budget
  static Future<void> logOverBudget({required double overBy}) async {
    await logEvent('over_budget', {'over_by': overBy});
  }
}

/// Predefined event names for consistency
class AnalyticsEvents {
  static const String onboardingStep = 'onboarding_step';
  static const String onboardingComplete = 'onboarding_complete';
  static const String transactionLogged = 'transaction_logged';
  static const String goalCreated = 'goal_created';
  static const String goalCompleted = 'goal_completed';
  static const String emergencyFundContribution = 'emergency_fund_contribution';
  static const String budgetSheetViewed = 'budget_sheet_viewed';
  static const String pdfExported = 'pdf_exported';
  static const String budgetWarning = 'budget_warning';
  static const String overBudget = 'over_budget';
  static const String screenView = 'screen_view';
}
