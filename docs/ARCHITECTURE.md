# Architecture Documentation

This document describes the overall architecture of FinanceSensei.

---

## Overview

FinanceSensei is an **offline-first Personal Financial Operating System (PF-OS)** built with Flutter. All data is stored locally using SQLite, ensuring the app works without internet connectivity.

**Core Philosophy:**
> "I don't track money. My system does."

---

## Architecture Principles

### 1. Offline-First
- ALL data stored in local SQLite database
- No network dependency for core functionality
- Instant performance - local queries only

### 2. Domain-Driven Design (DDD)
- Clear separation of domains
- Each domain has its own models, services, and UI
- Domains communicate through defined interfaces

### 3. Event-Based (Future-Ready)
- Key actions stored as snapshots
- Enables future ML/predictions
- Scales to event sourcing when needed

### 4. Clean Architecture
- Presentation (UI) → Services (Business Logic) → Repositories (Data) → Database

---

## Domain Model

```
┌─────────────────────────────────────────────────────────────────┐
│                        CORE DOMAINS                              │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌──────────┐   ┌──────────┐   ┌──────────┐   ┌──────────┐     │
│  │  User    │   │  Income  │   │ Expense  │   │Allocation│     │
│  │ Profile  │   │          │   │          │   │          │     │
│  └────┬─────┘   └────┬─────┘   └────┬─────┘   └────┬─────┘     │
│       │              │              │              │            │
│       └──────────────┴──────────────┴──────────────┘            │
│                              │                                   │
│                              ▼                                   │
│                    ┌─────────────────┐                          │
│                    │ Decision Engine │                          │
│                    │ (Calculations)  │                          │
│                    └────────┬────────┘                          │
│                             │                                    │
│              ┌──────────────┼──────────────┐                    │
│              ▼              ▼              ▼                    │
│       ┌──────────┐   ┌──────────┐   ┌──────────┐               │
│       │Emergency │   │ Planned  │   │ Safe-to- │               │
│       │  Fund    │   │ Expenses │   │  Spend   │               │
│       └──────────┘   └──────────┘   └──────────┘               │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### Core Domains

| Domain | Responsibility | Tables |
|--------|---------------|--------|
| **UserProfile** | User settings, preferences, risk level | `user_profile` |
| **Income** | Income sources, amounts, pay schedules | `income_sources` |
| **Expense** | Fixed and variable expenses | `fixed_expenses`, `variable_expenses` |
| **Allocation** | Pay-yourself-first rules | `allocations` |
| **EmergencyFund** | Emergency fund tracking and targets | `emergency_fund` |
| **PlannedExpense** | Future goals and planned expenses | `planned_expenses` |
| **Transaction** | Spending records | `transactions` |
| **Snapshot** | Historical financial snapshots | `financial_snapshot` |

---

## Folder Structure

```
lib/
├── main.dart                          # App entry point
│
├── core/                              # Shared core functionality
│   ├── constants/
│   │   ├── app_constants.dart         # App-wide constants
│   │   └── categories.dart            # Expense categories
│   │
│   ├── database/
│   │   ├── database_service.dart      # SQLite initialization & migrations
│   │   └── tables/                    # Table creation SQL
│   │       ├── user_profile_table.dart
│   │       ├── income_table.dart
│   │       ├── expense_table.dart
│   │       └── ...
│   │
│   ├── models/                        # Shared data models
│   │   ├── user_profile.dart
│   │   ├── income_source.dart
│   │   ├── fixed_expense.dart
│   │   ├── variable_expense.dart
│   │   ├── emergency_fund.dart
│   │   ├── allocation.dart
│   │   ├── planned_expense.dart
│   │   ├── transaction.dart
│   │   └── financial_snapshot.dart
│   │
│   ├── repositories/                  # Data access layer
│   │   ├── base_repository.dart
│   │   ├── user_repository.dart
│   │   ├── income_repository.dart
│   │   ├── expense_repository.dart
│   │   ├── emergency_fund_repository.dart
│   │   ├── allocation_repository.dart
│   │   ├── planned_expense_repository.dart
│   │   └── transaction_repository.dart
│   │
│   ├── services/                      # Business logic (calculations)
│   │   ├── calculation_service.dart   # Core financial calculations
│   │   ├── safe_to_spend_service.dart # Safe-to-spend logic
│   │   ├── emergency_fund_service.dart
│   │   ├── allocation_service.dart
│   │   └── goal_service.dart
│   │
│   └── theme/
│       └── app_theme.dart             # Steve Jobs approved theme
│
├── features/                          # Feature modules
│   │
│   ├── onboarding/                    # First-time setup
│   │   ├── screens/
│   │   │   ├── welcome_screen.dart
│   │   │   ├── income_setup_screen.dart
│   │   │   ├── expenses_setup_screen.dart
│   │   │   └── profile_setup_screen.dart
│   │   └── widgets/
│   │
│   ├── home/                          # Safe-to-Spend (Main screen)
│   │   ├── screens/
│   │   │   ├── home_screen.dart
│   │   │   └── log_spending_screen.dart
│   │   └── widgets/
│   │       ├── safe_to_spend_card.dart
│   │       └── quick_log_button.dart
│   │
│   ├── emergency_fund/                # Emergency Fund tracking
│   │   ├── screens/
│   │   │   └── emergency_fund_screen.dart
│   │   └── widgets/
│   │       ├── runway_indicator.dart
│   │       └── progress_ring.dart
│   │
│   ├── goals/                         # Planned Expenses
│   │   ├── screens/
│   │   │   ├── goals_list_screen.dart
│   │   │   └── add_goal_screen.dart
│   │   └── widgets/
│   │       └── goal_card.dart
│   │
│   ├── allocations/                   # Pay-Yourself-First setup
│   │   ├── screens/
│   │   │   └── allocations_screen.dart
│   │   └── widgets/
│   │
│   ├── profile/                       # Profile management
│   │   ├── screens/
│   │   │   └── profile_screen.dart
│   │   └── widgets/
│   │
│   └── overview/                      # Monthly overview
│       ├── screens/
│       │   └── overview_screen.dart
│       └── widgets/
│
└── shared/                            # Shared UI components
    ├── widgets/
    │   ├── app_card.dart
    │   ├── app_button.dart
    │   ├── amount_display.dart
    │   └── progress_bar.dart
    └── utils/
        ├── formatters.dart            # Currency, date formatting
        └── validators.dart
```

---

## Data Flow

```
┌─────────────────────────────────────────────────────────────┐
│                         UI LAYER                             │
│                   (Screens & Widgets)                        │
│                                                              │
│   HomeScreen    GoalsScreen    EmergencyFundScreen   ...    │
└──────────────────────────┬──────────────────────────────────┘
                           │
                           │ Uses
                           ▼
┌─────────────────────────────────────────────────────────────┐
│                      SERVICE LAYER                           │
│                   (Business Logic)                           │
│                                                              │
│   SafeToSpendService   EmergencyFundService   GoalService   │
│                                                              │
│   • Calculations                                             │
│   • Validation                                               │
│   • Business rules                                           │
└──────────────────────────┬──────────────────────────────────┘
                           │
                           │ Calls
                           ▼
┌─────────────────────────────────────────────────────────────┐
│                    REPOSITORY LAYER                          │
│                    (Data Access)                             │
│                                                              │
│   IncomeRepository   ExpenseRepository   TransactionRepo    │
│                                                              │
│   • CRUD operations                                          │
│   • Query methods                                            │
│   • Model mapping                                            │
└──────────────────────────┬──────────────────────────────────┘
                           │
                           │ Queries
                           ▼
┌─────────────────────────────────────────────────────────────┐
│                    DATABASE LAYER                            │
│                      (SQLite)                                │
│                                                              │
│                   DatabaseService                            │
│                                                              │
│   • Connection management                                    │
│   • Migrations                                               │
│   • Raw queries                                              │
└─────────────────────────────────────────────────────────────┘
```

---

## Key Services & Their Responsibilities

### CalculationService
The brain of the app. Handles all financial calculations.

```dart
// Core calculations
double getMonthlyIncome(int userId);
double getMonthlyFixedExpenses(int userId);
double getMonthlyEssentialExpenses(int userId);
double getMonthlyAllocations(int userId);
double getMonthlySafeToSpend(int userId);
```

### SafeToSpendService
Calculates daily/weekly safe-to-spend amounts.

```dart
double getDailySafeToSpend(int userId);
double getWeeklySafeToSpend(int userId);
double getRemainingThisMonth(int userId);
SpendImpact previewSpendImpact(int userId, double amount);
```

### EmergencyFundService
Manages emergency fund calculations and status.

```dart
double calculateTarget(int userId);
double getRunwayMonths(int userId);
double getProgressPercentage(int userId);
void recalculateOnExpenseChange(int userId);
```

### GoalService
Handles planned expense calculations.

```dart
double calculateMonthlyRequired(PlannedExpense goal);
bool isGoalRealistic(PlannedExpense goal, int userId);
DateTime suggestRealisticDate(PlannedExpense goal, int userId);
```

---

## State Management

### V1: Provider (Simple)
- Use `ChangeNotifierProvider` for each feature
- Keep state close to where it's used
- Services are injected via Provider

```dart
// Example
class HomeProvider extends ChangeNotifier {
  final SafeToSpendService _service;

  double _dailySafeToSpend = 0;

  Future<void> refresh() async {
    _dailySafeToSpend = await _service.getDailySafeToSpend(userId);
    notifyListeners();
  }
}
```

### Future: Riverpod or Bloc
- Migrate when complexity increases
- Current structure supports easy migration

---

## Database Initialization Flow

```
App Launch
    │
    ▼
DatabaseService.init()
    │
    ├─► Check if database exists
    │       │
    │       ├─► No: Create database + all tables
    │       │
    │       └─► Yes: Check version
    │               │
    │               └─► Run migrations if needed
    │
    ▼
App Ready
```

---

## Key Design Decisions

| Date | Decision | Rationale |
|------|----------|-----------|
| 2026-01-24 | SQLite for local storage | Mature, reliable, excellent Flutter support via sqflite |
| 2026-01-24 | Offline-first | User requirement, better UX, instant performance |
| 2026-01-24 | Repository pattern | Clean separation, testable, database-agnostic |
| 2026-01-24 | Provider for state management | Simple for V1, easy to migrate later |
| 2026-01-24 | Feature-first folder structure | Better scalability, clear boundaries |
| 2026-01-24 | Monthly snapshots | Enables future ML/predictions without full event sourcing |

---

## Future Architecture Extensions

### V2: Event Sourcing (When Needed)
```dart
abstract class DomainEvent {
  final DateTime timestamp;
  final int userId;
}

class IncomeAddedEvent extends DomainEvent { ... }
class ExpenseLoggedEvent extends DomainEvent { ... }
class AllocationChangedEvent extends DomainEvent { ... }
```

### V3: AI/ML Integration Points
- `financial_snapshot` table provides training data
- Services designed to accept prediction inputs
- Calculation service can be extended with AI recommendations

### V4: Backend Sync (Optional)
- Repository pattern allows easy swap to remote data source
- Can implement sync layer without touching business logic

---

## Testing Strategy

### Unit Tests
- All services (calculation logic)
- All repositories (data access)
- Model serialization

### Widget Tests
- Individual widgets
- Screen rendering

### Integration Tests
- Full user flows
- Database operations

---

## Notes for Developers

1. **Never bypass layers** - UI should never directly access database
2. **Keep services pure** - No UI dependencies in services
3. **Models are immutable** - Use `copyWith` for modifications
4. **Repository = CRUD only** - No business logic in repositories
5. **Services = Business logic** - All calculations here
6. **One provider per feature** - Don't create god providers
