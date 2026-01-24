import '../database/database_service.dart';
import '../repositories/user_repository.dart';
import '../repositories/income_repository.dart';
import '../repositories/expense_repository.dart';
import '../repositories/emergency_fund_repository.dart';
import '../repositories/allocation_repository.dart';
import '../repositories/planned_expense_repository.dart';
import '../repositories/transaction_repository.dart';
import '../repositories/financial_snapshot_repository.dart';
import '../repositories/savings_tracker_repository.dart';
import '../services/financial_calculation_service.dart';
import '../services/safe_to_spend_service.dart';
import '../services/emergency_fund_service.dart';
import '../services/budget_sheet_service.dart';
import '../services/budget_snapshot_service.dart';
import '../services/goal_service.dart';
import '../services/savings_tracker_service.dart';
import '../services/pdf_export_service.dart';
import 'logger.dart';

/// Service Locator for dependency injection.
/// Provides centralized access to all services and repositories.
///
/// Usage:
/// ```dart
/// await ServiceLocator.init();
/// final userRepo = ServiceLocator.get<UserRepository>();
/// ```
class ServiceLocator {
  static final ServiceLocator _instance = ServiceLocator._internal();
  static ServiceLocator get instance => _instance;

  ServiceLocator._internal();

  final Map<Type, dynamic> _services = {};
  bool _initialized = false;

  /// Initialize all services
  static Future<void> init() async {
    if (_instance._initialized) {
      Logger.warning('ServiceLocator already initialized', tag: 'DI');
      return;
    }

    Logger.info('Initializing ServiceLocator', tag: 'DI');

    // Core
    _instance._registerSingleton<DatabaseService>(DatabaseService());

    // Repositories (singletons for connection reuse)
    _instance._registerSingleton<UserRepository>(UserRepository());
    _instance._registerSingleton<IncomeRepository>(IncomeRepository());
    _instance._registerSingleton<FixedExpenseRepository>(FixedExpenseRepository());
    _instance._registerSingleton<VariableExpenseRepository>(VariableExpenseRepository());
    _instance._registerSingleton<EmergencyFundRepository>(EmergencyFundRepository());
    _instance._registerSingleton<AllocationRepository>(AllocationRepository());
    _instance._registerSingleton<PlannedExpenseRepository>(PlannedExpenseRepository());
    _instance._registerSingleton<TransactionRepository>(TransactionRepository());
    _instance._registerSingleton<FinancialSnapshotRepository>(FinancialSnapshotRepository());
    _instance._registerSingleton<SavingsTrackerRepository>(SavingsTrackerRepository());

    // Services (singletons for state management)
    _instance._registerSingleton<FinancialCalculationService>(FinancialCalculationService());
    _instance._registerSingleton<SafeToSpendService>(SafeToSpendService());
    _instance._registerSingleton<EmergencyFundService>(EmergencyFundService());
    _instance._registerSingleton<BudgetSheetService>(BudgetSheetService());
    _instance._registerSingleton<BudgetSnapshotService>(BudgetSnapshotService());
    _instance._registerSingleton<GoalService>(GoalService());
    _instance._registerSingleton<SavingsTrackerService>(SavingsTrackerService());
    _instance._registerSingleton<PdfExportService>(PdfExportService());

    _instance._initialized = true;
    Logger.info('ServiceLocator initialized with ${_instance._services.length} services', tag: 'DI');
  }

  /// Register a singleton instance
  void _registerSingleton<T>(T instance) {
    _services[T] = instance;
    Logger.debug('Registered singleton: $T', tag: 'DI');
  }

  /// Get a registered service
  static T get<T>() {
    if (_instance._services.containsKey(T)) {
      return _instance._services[T] as T;
    }

    throw ServiceNotFoundError('Service not registered: $T');
  }

  /// Check if a service is registered
  static bool isRegistered<T>() {
    return _instance._services.containsKey(T);
  }

  /// Reset the service locator (mainly for testing)
  static void reset() {
    _instance._services.clear();
    _instance._initialized = false;
    Logger.info('ServiceLocator reset', tag: 'DI');
  }

  /// Register a mock service (for testing)
  static void registerMock<T>(T mock) {
    _instance._services[T] = mock;
    Logger.debug('Registered mock: $T', tag: 'DI');
  }
}

/// Error thrown when a service is not found
class ServiceNotFoundError extends Error {
  final String message;

  ServiceNotFoundError(this.message);

  @override
  String toString() => 'ServiceNotFoundError: $message';
}

/// Convenience getters for commonly used services
extension ServiceLocatorExtensions on ServiceLocator {
  static UserRepository get userRepo => ServiceLocator.get<UserRepository>();
  static IncomeRepository get incomeRepo => ServiceLocator.get<IncomeRepository>();
  static TransactionRepository get transactionRepo => ServiceLocator.get<TransactionRepository>();
  static SafeToSpendService get safeToSpendService => ServiceLocator.get<SafeToSpendService>();
  static BudgetSheetService get budgetSheetService => ServiceLocator.get<BudgetSheetService>();
}
