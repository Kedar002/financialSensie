# FinanceSensei Scalability Guide

## Overview

This document describes the scalability infrastructure added to FinanceSensei to support growth from a single-user offline app to a multi-user, cloud-synced platform with AI capabilities.

## Infrastructure Components

### 1. Logging System (`lib/core/infrastructure/logger.dart`)

Centralized logging with levels, tags, and structured data.

```dart
// Usage
Logger.info('User logged in', tag: 'Auth');
Logger.error('Failed to save', error: e, stackTrace: st, tag: 'Database');

// Configuration
Logger.setEnabled(true);
Logger.setMinLevel(LogLevel.info);

// Export logs for debugging
final logs = Logger.exportLogs();
```

**Log Levels:**
- `debug` - Development details
- `info` - Important events
- `warning` - Potential issues
- `error` - Errors with optional stack traces

### 2. Result Type (`lib/core/infrastructure/result.dart`)

Type-safe error handling without exceptions.

```dart
// Usage
Result<User> result = await userRepo.getUser(id);

result.when(
  success: (user) => print('Got user: ${user.name}'),
  failure: (error) => print('Error: ${error.message}'),
);

// Chaining
final name = result
    .map((user) => user.name)
    .getOrDefault('Unknown');

// Error types
AppError.database('Failed to insert');
AppError.network('Connection timeout');
AppError.validation('Invalid email');
AppError.notFound('User');
```

### 3. Service Locator (`lib/core/infrastructure/service_locator.dart`)

Dependency injection container for all services and repositories.

```dart
// Initialize at app startup
await ServiceLocator.init();

// Get services anywhere
final userRepo = ServiceLocator.get<UserRepository>();
final calcService = ServiceLocator.get<FinancialCalculationService>();

// Testing
ServiceLocator.registerMock<UserRepository>(MockUserRepo());
```

### 4. App Configuration (`lib/core/infrastructure/app_config.dart`)

Environment-specific settings management.

```dart
// Initialize with environment
await AppConfig.init(environment: AppEnvironment.production);

// Access settings
final settings = AppConfig.instance.settings;
print(settings.apiBaseUrl);
print(settings.maxTransactionHistory);

// Environment checks
if (AppConfig.instance.isDevelopment) {
  // Dev-only features
}
```

**Environments:**
- `development` - Full logging, no analytics
- `staging` - Moderate logging, analytics enabled
- `production` - Error logging only, full analytics

### 5. API Client (`lib/core/infrastructure/network/api_client.dart`)

Ready-to-use HTTP client for future backend integration.

```dart
final client = ApiClient();

// Set auth token
client.setAuthToken(token);

// Make requests
final result = await client.get('/users/1');
final result = await client.post('/transactions', body: {...});

// Handle response
result.when(
  success: (data) => print(data),
  failure: (error) => print(error.message),
);
```

### 6. Sync Queue (`lib/core/infrastructure/network/sync_queue.dart`)

Offline-first sync queue for future cloud sync.

```dart
// Queue an operation
SyncQueue.instance.enqueue(
  entityType: 'transaction',
  entityId: 123,
  operation: SyncOperation.create,
  data: {...},
);

// Process when online
await SyncQueue.instance.processQueue((item) async {
  return await apiClient.post('/sync', body: item.data).isSuccess;
});

// Check pending
if (SyncQueue.instance.hasPending) {
  showSyncBadge();
}
```

### 7. Cache Manager (`lib/core/infrastructure/cache/cache_manager.dart`)

In-memory caching for expensive calculations.

```dart
final cache = CacheManager.instance;

// Get or compute
final summary = await cache.getOrCompute(
  CacheKeys.userSummary(userId),
  () => calculateSummary(userId),
  ttl: Duration(minutes: 5),
);

// Invalidate when data changes
cache.invalidate(CacheKeys.userSummary(userId));
cache.invalidatePrefix('user_123_'); // All user-related caches
```

### 8. Analytics (`lib/core/infrastructure/analytics/analytics_service.dart`)

Event tracking foundation for product analytics.

```dart
// Initialize
Analytics.init();

// Track events
Analytics.logEvent('button_clicked', {'button': 'save'});
Analytics.logScreenView('HomeScreen');

// Domain-specific events
Analytics.logTransaction(amount: 100, category: 'food');
Analytics.logGoalCreated(targetAmount: 50000, monthsToTarget: 12);
Analytics.logBudgetWarning(percentSpent: 85, daysRemaining: 5);
```

### 9. Feature Flags (`lib/core/infrastructure/feature_flags.dart`)

Gradual feature rollout and A/B testing.

```dart
// Initialize
FeatureFlags.init();

// Check flags
if (FeatureFlags.isEnabled(Features.cloudSync)) {
  showSyncUI();
}

if (FeatureFlags.isEnabled(Features.aiInsights)) {
  showAIInsights();
}

// Runtime overrides (for testing)
FeatureFlags.setOverride(Features.debugMode, true);
```

**Current Flags:**
- `offline_mode` - Enabled
- `cloud_sync` - Disabled (future)
- `pdf_export` - Enabled
- `budget_history` - Enabled
- `savings_tracker` - Enabled
- `bank_integration` - Disabled (future)
- `ai_insights` - Disabled (future)

### 10. Data Export/Import (`lib/core/services/data_export_service.dart`)

Backup and restore functionality.

```dart
final service = DataExportService();

// Export
final result = await service.exportToFile();
result.when(
  success: (file) => shareFile(file),
  failure: (error) => showError(error.message),
);

// Import
final importResult = await service.importFromFile(file);
print('Imported ${importResult.totalRecords} records');

// Validate before import
final validation = await service.validateExport(json);
if (!validation.isValid) {
  print(validation.issues);
}
```

### 11. Enhanced Base Repository (`lib/core/repositories/enhanced_base_repository.dart`)

Improved repository with Result types and caching.

```dart
class UserRepo extends EnhancedBaseRepository<User> {
  @override
  String get tableName => 'users';

  // Use safe methods with Result types
  Future<void> example() async {
    final result = await insertSafe(user);
    result.when(
      success: (id) => print('Created user #$id'),
      failure: (error) => handleError(error),
    );
  }
}
```

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                        Presentation Layer                        │
│                    (Screens, Widgets, Providers)                 │
└─────────────────────────────────────────────────────────────────┘
                                  │
                                  ▼
┌─────────────────────────────────────────────────────────────────┐
│                         Service Layer                            │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐             │
│  │ SafeToSpend │  │ BudgetSheet │  │   Goal      │  ...        │
│  │   Service   │  │   Service   │  │  Service    │             │
│  └─────────────┘  └─────────────┘  └─────────────┘             │
└─────────────────────────────────────────────────────────────────┘
                                  │
                                  ▼
┌─────────────────────────────────────────────────────────────────┐
│                       Repository Layer                           │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐             │
│  │    User     │  │ Transaction │  │  Snapshot   │  ...        │
│  │ Repository  │  │ Repository  │  │ Repository  │             │
│  └─────────────┘  └─────────────┘  └─────────────┘             │
└─────────────────────────────────────────────────────────────────┘
                                  │
                                  ▼
┌─────────────────────────────────────────────────────────────────┐
│                      Infrastructure Layer                        │
│  ┌────────┐  ┌────────┐  ┌────────┐  ┌────────┐  ┌────────┐   │
│  │ Logger │  │ Cache  │  │  API   │  │  Sync  │  │Feature │   │
│  │        │  │Manager │  │ Client │  │ Queue  │  │ Flags  │   │
│  └────────┘  └────────┘  └────────┘  └────────┘  └────────┘   │
│  ┌────────┐  ┌────────┐  ┌────────┐  ┌────────┐              │
│  │ Result │  │ Config │  │Analytics│ │Service │              │
│  │  Type  │  │        │  │        │  │Locator │              │
│  └────────┘  └────────┘  └────────┘  └────────┘              │
└─────────────────────────────────────────────────────────────────┘
                                  │
                                  ▼
┌─────────────────────────────────────────────────────────────────┐
│                        Database Layer                            │
│                    SQLite (sqflite) + Migrations                 │
└─────────────────────────────────────────────────────────────────┘
```

## Initialization Order

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Configuration first
  await AppConfig.init(environment: AppEnvironment.production);

  // 2. Initialize infrastructure
  CacheManager.instance.init();
  FeatureFlags.init();
  Analytics.init();

  // 3. Initialize services
  await ServiceLocator.init();

  // 4. Run app
  runApp(const FinanceSenseiApp());
}
```

## Scalability Roadmap

### V1 (Current) - Foundation
- [x] Offline-first architecture
- [x] Logging system
- [x] Error handling with Result type
- [x] Dependency injection
- [x] Configuration management
- [x] Caching layer
- [x] Analytics foundation
- [x] Feature flags
- [x] Data export/import

### V2 - Cloud Ready
- [ ] User authentication (Firebase Auth)
- [ ] Cloud sync (Firestore)
- [ ] Push notifications
- [ ] Multi-device support

### V3 - Intelligence
- [ ] AI-powered insights
- [ ] Budget predictions (ML)
- [ ] Expense categorization (ML)
- [ ] Anomaly detection

### V4 - Ecosystem
- [ ] Bank integration (Plaid/Finicity)
- [ ] Investment tracking
- [ ] Multi-currency support
- [ ] Family budget sharing

## Performance Guidelines

1. **Use caching for expensive calculations**
   ```dart
   await cache.getOrCompute(key, () => expensiveCalculation());
   ```

2. **Use Result types for error handling**
   ```dart
   final result = await repo.getSafe(id);
   // No try-catch needed
   ```

3. **Use feature flags for gradual rollout**
   ```dart
   if (FeatureFlags.isEnabled(Features.newFeature)) {
     // New code
   }
   ```

4. **Log important events**
   ```dart
   Logger.info('Important event', tag: 'Module', data: context);
   ```

5. **Track user actions**
   ```dart
   Analytics.logEvent('action', parameters);
   ```

## Testing

The infrastructure supports easy testing:

```dart
void main() {
  setUp(() {
    ServiceLocator.reset();
    ServiceLocator.registerMock<UserRepository>(MockUserRepo());
  });

  test('example', () async {
    final repo = ServiceLocator.get<UserRepository>();
    // repo is now the mock
  });
}
```

## Migration from Old Code

Existing code continues to work. New features can use enhanced infrastructure:

```dart
// Old style (still works)
final user = await userRepo.getById(id);
if (user == null) handleNotFound();

// New style (with Result)
final result = await userRepo.getByIdSafe(id);
result.when(
  success: (user) => process(user),
  failure: (error) => handleError(error),
);
```
